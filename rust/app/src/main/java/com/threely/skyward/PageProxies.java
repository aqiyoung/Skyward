package com.threely.skyward;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.Switch;
import android.widget.TextView;

import java.util.Locale;

import static com.threely.skyward.Widgets.*;

/** 代理页：Rust 解析的节点、数据面读数和当前出站入口。 */
public final class PageProxies {
    private PageProxies() {}

    public static View proxies(Context c, Runnable refresh) {
        final AppState s = AppState.get();
        LinearLayout body = Ui.pageBody(c);
        body.addView(Ui.pageHeader(c, "代理", "代理组 · 节点延迟"));

        // ===== 数据面：TUN 是否真的在转发，只有这里有数 =====
        LinearLayout dpCard = lcard(c);
        LinearLayout.LayoutParams dpLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        dpLp.bottomMargin = Ui.dp(c, 12);
        final TextView dpChip = chip(c, s.tunMode ? "已接管" : "未接管",
                s.tunMode ? Ui.GREEN : Ui.TEXT2,
                s.tunMode ? Color.parseColor("#1400A94F") : Color.parseColor("#14000000"));
        dpCard.addView(cardHead(c, IconView.Glyph.SHIELD, "数据面", dpChip));

        LinearLayout dpRow = new LinearLayout(c);
        dpRow.setOrientation(LinearLayout.HORIZONTAL);
        dpRow.setPadding(0, Ui.dp(c, 12), 0, 0);
        final TextView[] live = new TextView[4];
        dpRow.addView(kvLive(c, "读入（TUN）", live, 0),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        LinearLayout.LayoutParams l1 = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        l1.leftMargin = Ui.dp(c, 8);
        dpRow.addView(kvLive(c, "写回（TUN）", live, 1), l1);
        dpCard.addView(dpRow);

        LinearLayout dpRow2 = new LinearLayout(c);
        dpRow2.setOrientation(LinearLayout.HORIZONTAL);
        dpRow2.setPadding(0, Ui.dp(c, 12), 0, 0);
        dpRow2.addView(kvLive(c, "TCP 连接", live, 2),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        LinearLayout.LayoutParams l3 = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        l3.leftMargin = Ui.dp(c, 8);
        dpRow2.addView(kvLive(c, "UDP 流", live, 3), l3);
        dpCard.addView(dpRow2);
        body.addView(dpCard, dpLp);

        // 秒级刷新读数：页面切走即停（靠 pageEpoch）
        final int dpEpoch = s.pageEpoch;
        MAIN.post(new Runnable() {
            @Override public void run() {
                if (s.pageEpoch != dpEpoch) return;
                String csv = "0,0,0,0,0,0,0";
                try { csv = RustCore.nativeTunStats(); } catch (Throwable ignored) {}
                String[] p = csv.split(",");
                if (p.length >= 7) {
                    long bytes = safeLong(p[0]);
                    long packets = safeLong(p[1]);
                    long tx = safeLong(p[4]);
                    long conns = safeLong(p[5]);
                    long udpFlows = safeLong(p[6]);
                    if (live[0] != null) live[0].setText(packets + " 包 / " + AppState.humanBytes(bytes));
                    if (live[1] != null) live[1].setText(AppState.humanBytes(tx));
                    if (live[2] != null) live[2].setText(String.valueOf(conns));
                    if (live[3] != null) live[3].setText(String.valueOf(udpFlows));
                }
                MAIN.postDelayed(this, 800);
            }
        });

        // 组选择（横向胶囊）
        LinearLayout tabs = new LinearLayout(c);
        tabs.setOrientation(LinearLayout.HORIZONTAL);
        tabs.setPadding(0, Ui.dp(c, 4), 0, Ui.dp(c, 6));
        for (int i = 0; i < AppState.GROUPS.length; i++) {
            final int idx = i;
            TextView t = new TextView(c);
            t.setText(AppState.GROUPS[i]);
            t.setTextSize(13);
            t.setTypeface(Typeface.DEFAULT_BOLD);
            t.setGravity(Gravity.CENTER);
            t.setPadding(Ui.dp(c, 14), Ui.dp(c, 8), Ui.dp(c, 14), Ui.dp(c, 8));
            GradientDrawable g = new GradientDrawable();
            g.setColor(i == s.selectedGroup ? Ui.BLUE : Color.WHITE);
            g.setCornerRadius(Ui.dp(c, 18));
            g.setStroke(1, i == s.selectedGroup ? Ui.BLUE : Ui.SEP);
            t.setBackground(g);
            t.setTextColor(i == s.selectedGroup ? Color.WHITE : Ui.TEXT2);
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            lp.rightMargin = Ui.dp(c, 8);
            t.setLayoutParams(lp);
            t.setOnClickListener(v -> { s.selectedGroup = idx; s.save(); refresh.run(); });
            tabs.addView(t);
        }
        android.widget.HorizontalScrollView hs = new android.widget.HorizontalScrollView(c);
        hs.setHorizontalScrollBarEnabled(false);
        hs.addView(tabs);
        body.addView(hs);

        int n = s.configBusy ? 0 : nodeCount();
        body.addView(Ui.groupTitle(c, s.configBusy ? "配置正在处理" :
                AppState.GROUPS[s.selectedGroup] + " · 节点列表（已解析 " + n + " 个）"));
        LinearLayout list = Ui.newCard(c);
        if (s.configBusy) {
            list.addView(Ui.row(c, IconView.Glyph.INFO, Ui.TEXT2, "正在更新配置",
                    "完成后节点列表会自动刷新", null, null));
        } else if (n == 0) {
            list.addView(Ui.row(c, IconView.Glyph.INFO, Ui.TEXT2, "当前配置没有节点",
                    "请到配置页导入订阅或粘贴配置文本", null, null));
        }
        for (int i = 0; i < n; i++) {
            final int idx = i;
            String name = RustCore.nativeNodeName(i);
            int typeCode = RustCore.nativeNodeType(i);
            String server = RustCore.nativeNodeServer(i);
            int port = RustCore.nativeNodePort(i);
            int ms = RustCore.nativeNodeDelay(i);
            boolean supported = RustCore.nativeNodeSupported(i) != 0;
            String addr = (port > 0 ? server + ":" + port : server)
                    + " · " + AppState.nodeTypeLabel(typeCode);
            if (typeCode == 0) {
                String cipher = RustCore.nativeNodeCipher(i);
                if (!cipher.isEmpty()) addr += " · " + cipher;
            }
            int tint = AppState.nodeTypeColor(typeCode);
            View trailing;
            if (i == s.selectedNode) {
                IconView chk = new IconView(c, IconView.Glyph.CHECK, Ui.BLUE);
                chk.setLayoutParams(new LinearLayout.LayoutParams(Ui.dp(c, 20), Ui.dp(c, 20)));
                trailing = chk;
            } else if (!supported) {
                TextView status = new TextView(c);
                status.setText("暂不支持");
                status.setTextSize(11);
                status.setTextColor(Ui.TEXT3);
                trailing = status;
            } else {
                TextView lat = new TextView(c);
                lat.setText(typeCode == 13 ? "直连" : (ms < 0 ? "未测" : ms + " ms"));
                lat.setTextSize(13);
                lat.setTextColor(AppState.latencyColor(ms));
                lat.setTypeface(Typeface.DEFAULT_BOLD);
                trailing = lat;
            }
            list.addView(Ui.row(c, IconView.Glyph.GLOBE, tint, name, addr, trailing, v -> {
                if (!s.selectNode(idx)) {
                    Ui.toast(c, "该节点协议或传输方式尚不支持");
                    return;
                }
                if (s.connected || s.proxyRunning || s.tunMode) {
                    Ui.toast(c, "已保存节点；当前通道需重连后应用");
                }
                refresh.run();
            }));
            if (i != n - 1) list.addView(Ui.separator(c));
        }
        body.addView(list);

        body.addView(Ui.groupTitle(c, "代理组设置"));
        LinearLayout gset = Ui.newCard(c);
        gset.addView(Ui.row(c, IconView.Glyph.CHART, Ui.GREEN, "按延迟着色",
                "绿 < 80ms · 橙 < 150ms · 红 ≥ 150ms", null, null));
        gset.addView(Ui.separator(c));
        gset.addView(Ui.row(c, IconView.Glyph.CLOCK, Ui.ORANGE, "延迟测速",
                n > 0 ? "已解析 " + n + " 个节点 · 点击实测 TCP 建连" : "请先导入配置", null,
                v -> {
                    if (n == 0) { Ui.toast(c, "请先导入配置"); return; }
                    Ui.toast(c, "测速中…");
                    final Handler main = new Handler(Looper.getMainLooper());
                    new Thread(() -> {
                        int tested;
                        try { tested = RustCore.nativeTestAllDelays(3000); }
                        catch (Throwable t) { tested = -1; }
                        final int done = tested;
                        main.post(() -> {
                            Ui.toast(c, done >= 0 ? "已实测 " + done + " 个节点" : "测速失败");
                            refresh.run();
                        });
                    }, "sky-delay-probe").start();
                }));
        body.addView(gset);

        body.addView(Ui.groupTitle(c, "本地代理入口（真实转发）"));
        LinearLayout entryCard = Ui.newCard(c);
        Switch swEntry = Ui.toggle(c, s.proxyRunning);
        swEntry.setOnCheckedChangeListener((b, on) -> {
            if (on) {
                if (!s.applySelectedNode()) {
                    Ui.toast(c, "请先选择支持的节点");
                    b.setChecked(false);
                    return;
                }
                try {
                    int started = RustCore.nativeStartProxy(s.socksPort, s.ssServer, s.ssPort,
                            s.ssPassword, s.ssCipher, s.outProtocol, s.outTls, s.outSni);
                    if (started == 0) throw new IllegalStateException("参数无效");
                    s.proxyRunning = true;
                    MainActivity.requestVpn(c, true);
                    Ui.toast(c, "SOCKS5:" + s.socksPort + " → " + protoLabel(s.outProtocol)
                            + " " + s.ssServer + ":" + s.ssPort);
                } catch (Throwable t) {
                    s.proxyRunning = false;
                    try { RustCore.nativeStopProxy(); } catch (Throwable ignored) {}
                    try { MainActivity.stopVpn(c); } catch (Throwable ignored) {}
                    b.setChecked(false);
                    Ui.toast(c, "开启失败：" + t.getMessage());
                }
            } else {
                s.proxyRunning = false;
                try { RustCore.nativeStopProxy(); } catch (Throwable ignored) {}
                try { MainActivity.stopVpn(c); } catch (Throwable ignored) {}
            }
        });
        entryCard.addView(Ui.row(c, IconView.Glyph.BOLT, Ui.ORANGE, "本地代理入口",
                "SOCKS5 → 当前选择节点 · 需 VPN 授权", swEntry, null));
        entryCard.addView(Ui.separator(c));
        String selectedName = s.selectedNode >= 0 && s.selectedNode < n
                ? RustCore.nativeNodeName(s.selectedNode) : "未选择";
        String endpoint = s.ssServer.isEmpty() ? "请选择可用节点"
                : protoLabel(s.outProtocol) + " · " + s.ssServer + ":" + s.ssPort;
        entryCard.addView(Ui.row(c, IconView.Glyph.GLOBE, Ui.BLUE, selectedName,
                endpoint + (s.outSni.isEmpty() ? "" : " · SNI " + s.outSni), null, null));
        entryCard.addView(Ui.separator(c));
        entryCard.addView(editRow(c, "本地 SOCKS5 端口", String.valueOf(s.socksPort), v -> {
            try {
                int port = Integer.parseInt(v.trim());
                if (port < 1 || port > 65535) throw new NumberFormatException();
                s.socksPort = port;
            } catch (Throwable t) {
                s.socksPort = 1080;
                Ui.toast(c, "端口无效，已恢复 1080");
            }
            s.save();
        }));
        body.addView(entryCard);

        // 路由规则测试：输入域名，查命中规则与动作（来自 Rust 索引引擎）
        body.addView(Ui.groupTitle(c, "路由规则测试"));
        LinearLayout routeTest = Ui.newCard(c);
        final android.widget.EditText input = new android.widget.EditText(c);
        input.setHint("输入域名，如 www.google.com");
        input.setText("www.google.com");
        input.setTextSize(14);
        input.setPadding(Ui.dp(c, 14), Ui.dp(c, 10), Ui.dp(c, 14), Ui.dp(c, 10));
        input.setBackgroundResource(0);
        routeTest.addView(input);
        routeTest.addView(Ui.separator(c));
        final TextView result = new TextView(c);
        result.setTextSize(13);
        result.setTextColor(Ui.TEXT);
        result.setPadding(Ui.dp(c, 14), Ui.dp(c, 10), Ui.dp(c, 14), Ui.dp(c, 10));
        routeTest.addView(result);
        View probe = Ui.primaryButton(c, "查询命中规则", Ui.BLUE, v -> {
            String h = input.getText().toString().trim();
            if (h.isEmpty()) { Ui.toast(c, "请输入域名"); return; }
            long packed = RustCore.nativeDecide(h);
            int matched = (int) (packed >>> 63);
            if (matched == 0) {
                result.setText("未命中任何规则 → 动作：直连（DIRECT）\n（域名不在规则集内）");
                return;
            }
            int order = (int) ((packed >>> 16) & 0x7FFFFFFF);
            int kind = (int) ((packed >>> 8) & 0xFF);
            int action = (int) (packed & 0xFF);
            String[] kindName = {"DOMAIN-SUFFIX", "DOMAIN-KEYWORD", "IP-CIDR", "DOMAIN"};
            String[] actName = {"直连 DIRECT", "代理 PROXY", "拒绝 REJECT"};
            result.setText("命中规则 #" + (order + 1) + " · 类型 " + kindName[kind]
                    + "\n动作：" + actName[action]);
        });
        LinearLayout btnWrap = new LinearLayout(c);
        btnWrap.setPadding(Ui.dp(c, 14), Ui.dp(c, 6), Ui.dp(c, 14), Ui.dp(c, 10));
        btnWrap.addView(probe);
        routeTest.addView(btnWrap);
        body.addView(routeTest);

        body.addView(note(c, "节点凭据直接来自 Rust 解析的当前配置；未测延迟显示为“未测”。"
                + "路由规则测试调用 Rust 索引引擎。"));
        return page(c, body);
    }

    static String protoLabel(String p) {
        if ("trojan".equals(p)) return "Trojan";
        if ("vless".equals(p)) return "VLESS";
        return "Shadowsocks";
    }

    static View editRow(Context c, String label, String value,
                                OnValueChange cb) {
        LinearLayout row = new LinearLayout(c);
        row.setOrientation(LinearLayout.VERTICAL);
        row.setPadding(Ui.dp(c, 16), Ui.dp(c, 11), Ui.dp(c, 16), Ui.dp(c, 11));
        TextView lab = new TextView(c);
        lab.setText(label);
        lab.setTextSize(12);
        lab.setTextColor(Ui.TEXT2);
        row.addView(lab);
        final android.widget.EditText et = new android.widget.EditText(c);
        et.setText(value);
        et.setTextSize(14);
        et.setTextColor(Ui.TEXT);
        et.setPadding(0, Ui.dp(c, 4), 0, 0);
        et.setBackgroundResource(0);
        et.setSingleLine(true);
        et.setOnEditorActionListener((v, actionId, event) -> {
            cb.onChange(et.getText().toString());
            return false;
        });
        et.setOnFocusChangeListener((v, hasFocus) -> {
            if (!hasFocus) cb.onChange(et.getText().toString());
        });
        row.addView(et);
        return row;
    }

    private interface OnValueChange {
        void onChange(String value);
    }
}
