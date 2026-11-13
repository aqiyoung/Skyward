package com.threely.skyward.poc;

import android.content.Context;
import android.content.SharedPreferences;

import java.util.Locale;

/**
 * UI 状态层（PoC-2）。
 *
 * 数据分两类，界面上明确区分，避免把 PoC 演示成"能用的客户端"：
 *  - 内核真值：全部经 JNI 取自 Rust core（版本 / 规则 / 索引 / 内存 / 连接表 /
 *    会话时长 / 上下行字节 / 包数）。连接后的时长与流量不再写死常量。
 *  - 演示数据：产品结构占位（节点 / 配置 / 订阅），未接入真实协议栈与订阅解析。
 *
 * 状态持久化：开关、主题、路由、选中项、会话种子写入 SharedPreferences，
 * 进程重启后可恢复；连接态恢复时以原连接时刻为起点，累计字节作种子，读数连续。
 * 液态玻璃默认关闭（既定规则）。
 */
public final class AppState {

    private static final AppState I = new AppState();
    public static AppState get() { return I; }
    private AppState() {}

    private static final String PREF = "skyward_state";
    private SharedPreferences prefs;

    // ---- 可交互的产品状态 ----
    public boolean connected = false;
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

    /** 页面代次：每次 render 递增，首页秒级刷新据此自动退出，避免切页后空转 / 泄漏。 */
    public int pageEpoch = 0;

    public static final String[] NODE_NAMES = {
            "HK-01 · 自动选择", "Tokyo-02", "Singapore-03", "US-West-04",
            "HK-05 备用", "Taiwan-06", "London-07", "DIRECT 直连"
    };
    public static final int[] NODE_LATENCY = { 38, 62, 89, 156, 47, 118, 231, -1 };
    public static final String[] NODE_REGION = {
            "中国香港 · BGP", "日本 · 东京", "新加坡", "美国 · 洛杉矶",
            "中国香港 · CN2", "中国台湾", "英国 · 伦敦", "绕过代理"
    };
    public static final String[] GROUPS = { "节点选择", "自动选择", "流媒体", "广告拦截" };

    public static String latencyLabel(int ms) {
        return ms < 0 ? "直连" : ms + " ms";
    }

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
        // 启动即解析内置示例订阅，让「代理」页首屏即为真实节点（非演示占位）。
        try { RustCore.nativeLoadSampleConfig(); } catch (Throwable ignored) {}
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
        // 防御：越界值兜底，避免旧数据把数组索引打崩
        if (themeMode < 0 || themeMode > 2) themeMode = 0;
        if (ruleMode < 0 || ruleMode > 2) ruleMode = 0;
        if (selectedNode < 0 || selectedNode >= NODE_NAMES.length) selectedNode = 0;
        if (selectedGroup < 0 || selectedGroup >= GROUPS.length) selectedGroup = 0;
    }

    /** 落盘；会话进行中时先同步内核累计字节，保证重启后读数不丢。 */
    public void save() {
        if (prefs == null) return;
        if (connected) syncSessionFromCore();
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
                .apply();
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
        if (connected) return;
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
