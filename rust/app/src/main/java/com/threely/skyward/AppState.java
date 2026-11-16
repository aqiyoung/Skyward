package com.threely.skyward;

import android.content.Context;
import android.content.SharedPreferences;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Locale;
import java.util.UUID;

/** 应用设置与持久化代理配置；节点数据和解析逻辑由 Rust core 提供。 */
public final class AppState {

    private static final AppState I = new AppState();
    public static AppState get() { return I; }
    private AppState() {}

    private static final String PREF = "skyward_state";
    private SharedPreferences prefs;

    public static final class Profile {
        public String id;
        public String name;
        public String url;
        public String content;
        public long updatedAt;
        public int selectedNode;

        Profile(String id, String name, String url, String content, long updatedAt, int selectedNode) {
            this.id = id;
            this.name = name;
            this.url = url;
            this.content = content;
            this.updatedAt = updatedAt;
            this.selectedNode = selectedNode;
        }
    }

    public final ArrayList<Profile> profiles = new ArrayList<>();
    public String activeProfileId = "";

    // ---- 可交互的产品状态 ----
    public boolean connected = false;
    public boolean proxyRunning = false;
    public volatile boolean configBusy = false;
    public boolean systemProxy = true;
    public boolean tunMode = false;
    public boolean ipv6 = false;
    public boolean autoUpdate = true;
    public boolean liquidGlass = false;   // 明确不默认开启
    public boolean pureBlack = false;
    public int themeMode = 0;             // 0 跟随系统 / 1 浅色 / 2 深色
    public int ruleMode = 0;              // 0 规则 / 1 全局 / 2 直连
    public int selectedNode = 0;
    public int selectedGroup = 0;
    public long connectSinceMs = 0L;
    public long sessionUp = 0L;           // 落盘的累计上行字节（会话种子）
    public long sessionDown = 0L;

    // 当前选择节点的出站参数，由 Rust 节点表填充。
    public String ssServer = "";
    public int ssPort = 0;
    public String ssPassword = "";
    public int socksPort = 1080;

    public String outProtocol = "";
    public boolean outTls = false;
    public String outSni = "";            // 空 = 用服务器地址

    /** 页面代次：每次 render 递增，首页秒级刷新据此自动退出，避免切页后空转 / 泄漏。 */
    public int pageEpoch = 0;

    public static final String[] GROUPS = { "节点选择", "自动选择", "流媒体", "广告拦截" };

    public static int latencyColor(int ms) {
        if (ms < 0) return Ui.TEXT3;
        if (ms < 80) return Ui.GREEN;
        if (ms < 150) return Ui.ORANGE;
        return Ui.RED;
    }

    /** 节点类型整型编码 → 展示标签（与 Rust 侧 node_type_code 对应）。 */
    public static String nodeTypeLabel(int code) {
        switch (code) {
            case 0:  return "SS";
            case 1:  return "SSR";
            case 2:  return "VMess";
            case 3:  return "VLESS";
            case 4:  return "Trojan";
            case 5:  return "Hysteria";
            case 6:  return "Hysteria2";
            case 7:  return "Socks5";
            case 8:  return "HTTP";
            case 9:  return "TUIC";
            case 10: return "WireGuard";
            case 11: return "Snell";
            case 12: return "ShadowQUIC";
            case 13: return "直连";
            default: return "?";
        }
    }

    /** 节点类型 → 图标井着色。 */
    public static int nodeTypeColor(int code) {
        if (code == 13) return Ui.TEXT3;
        if (code == 7 || code == 8) return Ui.ORANGE;
        if (code == 0 || code == 1) return Ui.GREEN;
        if (code == 3 || code == 4) return Ui.BLUE;
        return Ui.TEAL;
    }

    public String themeLabel() {
        return new String[]{"跟随系统", "浅色", "深色"}[themeMode];
    }
    public String ruleModeLabel() {
        return new String[]{"规则模式", "全局代理", "直连模式"}[ruleMode];
    }

    // ================= 持久化 =================

    /** 绑定 Application Context，读回状态并恢复内核会话。由 MainActivity.onCreate 调用。 */
    public void attach(Context c) {
        prefs = c.getApplicationContext().getSharedPreferences(PREF, Context.MODE_PRIVATE);
        load();
        warmUp();
        boolean restored = false;
        Profile active = findProfile(activeProfileId);
        if (active != null) {
            int count = RustCore.nativeParseConfig(active.content);
            if (count > 0) {
                activeProfileId = active.id;
                selectedNode = Math.max(0, Math.min(active.selectedNode, count - 1));
                if (!applySelectedNode()) selectedNode = firstSupportedNode();
                applySelectedNode();
                restored = true;
            }
        }
        if (!restored) {
            activeProfileId = "";
            selectedNode = 0;
            clearOutbound();
            if (prefs != null) {
                prefs.edit().putString("activeProfileId", "").putInt("selectedNode", 0)
                        .putString("ssServer", "").putInt("ssPort", 0)
                        .putString("ssPassword", "").putString("outProtocol", "")
                        .putBoolean("outTls", false).putString("outSni", "").apply();
            }
        }
        if (connected && connectSinceMs > 0L) {
            try {
                RustCore.nativeSessionStart(connectSinceMs, sessionUp, sessionDown);
            } catch (Throwable ignored) {}
        }
    }

    private void load() {
        if (prefs == null) return;
        SharedPreferences p = prefs;
        connected      = p.getBoolean("connected", false);
        systemProxy    = p.getBoolean("systemProxy", true);
        tunMode        = p.getBoolean("tunMode", false);
        ipv6           = p.getBoolean("ipv6", false);
        autoUpdate     = p.getBoolean("autoUpdate", true);
        liquidGlass    = p.getBoolean("liquidGlass", false);
        pureBlack      = p.getBoolean("pureBlack", false);
        themeMode      = p.getInt("themeMode", 0);
        ruleMode       = p.getInt("ruleMode", 0);
        selectedNode   = p.getInt("selectedNode", 0);
        selectedGroup  = p.getInt("selectedGroup", 0);
        connectSinceMs = p.getLong("connectSinceMs", 0L);
        sessionUp      = p.getLong("sessionUp", 0L);
        sessionDown    = p.getLong("sessionDown", 0L);
        ssServer       = p.getString("ssServer", "");
        ssPort         = p.getInt("ssPort", 0);
        ssPassword     = p.getString("ssPassword", "");
        socksPort      = p.getInt("socksPort", 1080);
        outProtocol    = p.getString("outProtocol", "");
        outTls         = p.getBoolean("outTls", false);
        outSni         = p.getString("outSni", "");
        activeProfileId = p.getString("activeProfileId", "");
        profiles.clear();
        try {
            JSONArray saved = new JSONArray(p.getString("profiles_json", "[]"));
            for (int i = 0; i < saved.length(); i++) {
                JSONObject item = saved.getJSONObject(i);
                profiles.add(new Profile(item.optString("id"), item.optString("name"),
                        item.optString("url"), item.optString("content"),
                        item.optLong("updatedAt"), item.optInt("selectedNode", 0)));
            }
        } catch (JSONException ignored) {}
        if (themeMode < 0 || themeMode > 2) themeMode = 0;
        if (ruleMode < 0 || ruleMode > 2) ruleMode = 0;
        if (selectedNode < 0) selectedNode = 0;
        if (socksPort < 1 || socksPort > 65535) socksPort = 1080;
        if (selectedGroup < 0 || selectedGroup >= GROUPS.length) selectedGroup = 0;
    }

    /** 落盘；会话进行中时先同步内核累计字节，保证重启后读数不丢。 */
    public void save() {
        if (prefs == null) return;
        if (connected) syncSessionFromCore();
        Profile active = findProfile(activeProfileId);
        if (active != null) active.selectedNode = selectedNode;
        prefs.edit()
                .putBoolean("connected", connected)
                .putBoolean("systemProxy", systemProxy)
                .putBoolean("tunMode", tunMode)
                .putBoolean("ipv6", ipv6)
                .putBoolean("autoUpdate", autoUpdate)
                .putBoolean("liquidGlass", liquidGlass)
                .putBoolean("pureBlack", pureBlack)
                .putInt("themeMode", themeMode)
                .putInt("ruleMode", ruleMode)
                .putInt("selectedNode", selectedNode)
                .putInt("selectedGroup", selectedGroup)
                .putLong("connectSinceMs", connectSinceMs)
                .putLong("sessionUp", sessionUp)
                .putLong("sessionDown", sessionDown)
                .putString("ssServer", ssServer)
                .putInt("ssPort", ssPort)
                .putString("ssPassword", ssPassword)
                .putInt("socksPort", socksPort)
                .putString("outProtocol", outProtocol)
                .putBoolean("outTls", outTls)
                .putString("outSni", outSni)
                .putString("activeProfileId", activeProfileId)
                .putString("profiles_json", encodeProfiles())
                .apply();
    }

    private String encodeProfiles() {
        JSONArray encoded = new JSONArray();
        for (Profile profile : profiles) {
            JSONObject item = new JSONObject();
            try {
                item.put("id", profile.id);
                item.put("name", profile.name);
                item.put("url", profile.url);
                item.put("content", profile.content);
                item.put("updatedAt", profile.updatedAt);
                item.put("selectedNode", profile.selectedNode);
            } catch (JSONException ignored) {}
            encoded.put(item);
        }
        return encoded.toString();
    }

    public Profile activeProfile() {
        return findProfile(activeProfileId);
    }

    public Profile findProfile(String id) {
        if (id == null || id.isEmpty()) return null;
        for (Profile profile : profiles) if (id.equals(profile.id)) return profile;
        return null;
    }

    public boolean activateProfile(String id) {
        if (configBusy) return false;
        Profile profile = findProfile(id);
        return profile != null && activateParsedProfile(id, RustCore.nativeParseConfig(profile.content));
    }

    public boolean activateParsedProfile(String id, int count) {
        Profile profile = findProfile(id);
        if (configBusy || profile == null || count <= 0) return false;
        activeProfileId = profile.id;
        selectedNode = Math.max(0, Math.min(profile.selectedNode, count - 1));
        if (!applySelectedNode()) {
            selectedNode = firstSupportedNode();
            applySelectedNode();
        }
        save();
        return true;
    }

    public boolean importProfile(String url, String content, String name) {
        if (configBusy || content == null || content.trim().isEmpty()
                || content.length() > 5 * 1024 * 1024) return false;
        return importProfileParsed(url, content, name, RustCore.nativeParseConfig(content));
    }

    public boolean importProfileParsed(String url, String content, String name, int count) {
        if (configBusy || content == null || content.trim().isEmpty()
                || content.length() > 5 * 1024 * 1024 || count <= 0) return false;
        Profile profile = null;
        if (url != null && !url.isEmpty()) {
            for (Profile item : profiles) {
                if (url.equals(item.url)) { profile = item; break; }
            }
        }
        if (profile == null) {
            profile = new Profile(UUID.randomUUID().toString(), name, url == null ? "" : url,
                    content, System.currentTimeMillis(), 0);
            profiles.add(profile);
        } else {
            profile.name = name;
            profile.content = content;
            profile.updatedAt = System.currentTimeMillis();
        }
        activeProfileId = profile.id;
        selectedNode = Math.max(0, Math.min(profile.selectedNode, count - 1));
        if (!applySelectedNode()) {
            selectedNode = firstSupportedNode();
            applySelectedNode();
        }
        save();
        return true;
    }

    public boolean selectNode(int index) {
        if (configBusy || index < 0 || index >= RustCore.nativeNodeCount()
                || RustCore.nativeNodeSupported(index) == 0) return false;
        int previous = selectedNode;
        selectedNode = index;
        if (!applySelectedNode()) {
            selectedNode = previous;
            return false;
        }
        save();
        return true;
    }

    public boolean applySelectedNode() {
        if (configBusy) return false;
        try {
            if (selectedNode < 0 || selectedNode >= RustCore.nativeNodeCount()
                    || RustCore.nativeNodeSupported(selectedNode) == 0) {
                clearOutbound();
                return false;
            }
            ssServer = RustCore.nativeNodeServer(selectedNode);
            ssPort = RustCore.nativeNodePort(selectedNode);
            ssPassword = RustCore.nativeNodeSecret(selectedNode);
            outProtocol = RustCore.nativeNodeProtocol(selectedNode);
            outTls = RustCore.nativeNodeTls(selectedNode) != 0;
            outSni = RustCore.nativeNodeSni(selectedNode);
            return !ssServer.isEmpty() && ssPort > 0 && !ssPassword.isEmpty();
        } catch (Throwable ignored) {
            clearOutbound();
            return false;
        }
    }

    private int firstSupportedNode() {
        int count = RustCore.nativeNodeCount();
        for (int i = 0; i < count; i++) {
            if (RustCore.nativeNodeSupported(i) != 0) return i;
        }
        return -1;
    }

    private void clearOutbound() {
        ssServer = "";
        ssPort = 0;
        ssPassword = "";
        outProtocol = "";
        outTls = false;
        outSni = "";
    }

    private void syncSessionFromCore() {
        if (!connected) return;
        try {
            sessionUp = RustCore.nativeSessionUpBytes();
            sessionDown = RustCore.nativeSessionDownBytes();
        } catch (Throwable ignored) {}
    }

    // ================= 会话（内核真值） =================

    public void connect() {
        if (connected || configBusy) return;
        connected = true;
        connectSinceMs = System.currentTimeMillis();
        try {
            RustCore.nativeSessionStart(connectSinceMs, sessionUp, sessionDown);
        } catch (Throwable ignored) {}
        save();
    }

    public void disconnect() {
        if (!connected) return;
        syncSessionFromCore();
        try { RustCore.nativeSessionStop(); } catch (Throwable ignored) {}
        connected = false;
        save();
    }

    /** 每秒由首页调用：让内核跑一小段模拟数据面，累加会话真值。 */
    public void tick() {
        if (!connected) return;
        try { RustCore.nativeSessionTick(200, 1500); } catch (Throwable ignored) {}
    }

    public long uptimeSec() {
        try {
            return RustCore.nativeSessionUptimeSec(System.currentTimeMillis());
        } catch (Throwable t) { return 0L; }
    }

    public long upBytes() {
        try { return RustCore.nativeSessionUpBytes(); } catch (Throwable t) { return sessionUp; }
    }

    public long downBytes() {
        try { return RustCore.nativeSessionDownBytes(); } catch (Throwable t) { return sessionDown; }
    }

    public static String humanBytes(long b) {
        if (b < 1024L) return b + " B";
        if (b < 1048576L) return String.format(Locale.getDefault(), "%.1f KB", b / 1024.0);
        if (b < 1073741824L) return String.format(Locale.getDefault(), "%.1f MB", b / 1048576.0);
        return String.format(Locale.getDefault(), "%.2f GB", b / 1073741824.0);
    }

    public static String humanDuration(long sec) {
        long h = sec / 3600, m = (sec % 3600) / 60, s = sec % 60;
        return String.format(Locale.getDefault(), "%02d:%02d:%02d", h, m, s);
    }

    public static String rate(long bytesPerSec) {
        return humanBytes(bytesPerSec) + "/s";
    }

    // ================= 内核读数 =================

    public String coreInfo() {
        try {
            int ver = RustCore.nativeVersion();
            long initUs = RustCore.nativeInitNs() / 1000;
            long rss = RustCore.nativeRssBytes();
            long logical = RustCore.nativeLogicalBytes();
            int rules = RustCore.nativeRuleCount();
            int nodes = RustCore.nativeIndexNodes();
            int conns = RustCore.nativeConnCount();
            long pkts = RustCore.nativeSessionPackets();
            return String.format(Locale.getDefault(),
                    "core version   : %d (PoC-2)%n" +
                    "规则引擎       : 索引 trie / 关键词分桶 / CIDR%n" +
                    "trie 节点      : %d%n" +
                    "首次 JNI 冷启动 : %,d us%n" +
                    "规则条数       : %d%n" +
                    "连接表         : %d 条%n" +
                    "会话累计包数   : %,d%n" +
                    "逻辑状态       : %,d B%n" +
                    "进程 RSS       : %.2f MB%n%n" +
                    "no GC / no runtime / no VM%n" +
                    "以上读数来自 Rust core（JNI 实时）",
                    ver, nodes, initUs, rules, conns, pkts, logical, rss / 1048576.0);
        } catch (Throwable t) {
            return "内核读数不可用：" + t;
        }
    }

    /** 轻量冷启动探测：只触发 OnceLock 初始化，不做重基准。 */
    public void warmUp() {
        try { RustCore.nativeVersion(); } catch (Throwable ignored) {}
    }
}
