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

/** 代理页：入口开关、出站协议与凭据、数据面实时读数、节点列表。 */
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

        int n = nodeCount();
        body.addView(Ui.groupTitle(c,
                AppState.GROUPS[s.selectedGroup] + " · 节点列表（已解析 " + n + " 个）"));
        LinearLayout list = Ui.newCard(c);
        int shown = n > 0 ? n : AppState.NODE_NAMES.length;
        for (int i = 0; i < shown; i++) {
            final int idx = i;
            String name, addr;
            int ms, tint;
            if (n > 0) {
                name = RustCore.nativeNodeName(i);
                int typeCode = RustCore.nativeNodeType(i);
                String server = RustCore.nativeNodeServer(i);
                int port = RustCore.nativeNodePort(i);
                ms = RustCore.nativeNodeDelay(i);
                addr = (port > 0 ? server + ":" + port : server)
                        + " · " + AppState.nodeTypeLabel(typeCode);
                tint = AppState.nodeTypeColor(typeCode);
            } else {
                name = AppState.NODE_NAMES[i];
                ms = AppState.NODE_LATENCY[i];
                addr = AppState.NODE_REGION[i] + " · " + AppState.latencyLabel(ms);
                tint = AppState.latencyColor(ms);
            }
            View trailing;
            if (i == s.selectedNode) {
                IconView chk = new IconView(c, IconView.Glyph.CHECK, Ui.BLUE);
                chk.setLayoutParams(new LinearLayout.LayoutParams(Ui.dp(c, 20), Ui.dp(c, 20)));
                trailing = chk;
            } else {
                TextView lat = new TextView(c);
                lat.setText(AppState.latencyLabel(ms));
                lat.setTextSize(13);
                lat.setTextColor(AppState.latencyColor(ms));
                lat.setTypeface(Typeface.DEFAULT_BOLD);
                trailing = lat;
            }
            list.addView(Ui.row(c, IconView.Glyph.GLOBE, tint, name, addr, trailing,
                    v -> { s.selectedNode = idx; s.save(); refresh.run(); }));
            if (i != shown - 1) list.addView(Ui.separator(c));
        }
        body.addView(list);

        body.addView(Ui.groupTitle(c, "代理组设置"));
        LinearLayout gset = Ui.newCard(c);
        gset.addView(Ui.row(c, IconView.Glyph.CHART, Ui.GREEN, "按延迟着色",
                "绿 < 80ms · 橙 < 150ms · 红 ≥ 150ms", null, null));
        gset.addView(Ui.separator(c));
        gset.addView(Ui.row(c, IconView.Glyph.CLOCK, Ui.ORANGE, "延迟测速",
                n > 0 ? "已解析 " + n + " 个节点" : "演示入口", null,
                v -> Ui.toast(c, "PoC 阶段未接入真实延迟探测（当前为模拟值）")));
        body.addView(gset);

        // ===== 本地代理入口（PoC-6）：真实 SOCKS5 → SS 转发，需系统 VPN 授权 =====
        body.addView(Ui.groupTitle(c, "本地代理入口（真实转发）"));
        LinearLayout entryCard = Ui.newCard(c);
        Switch swEntry = Ui.toggle(c, false);
        swEntry.setOnCheckedChangeListener((b, on) -> {
            if (on) {
                // 先向系统申请 VPN 权限（首授权后由 onActivityResult 拉起 VpnService）；
                // VpnService 建立 tun 并 nativeOpenTun 后，内核即可在独立线程读帧。
                MainActivity.requestVpn(c);
                // 拉起 SOCKS5 入口 + SS 出站（即使 tun fd 未到位，SOCKS5 端口也已就绪）
                try {
                    RustCore.nativeStartProxy(s.socksPort, s.ssServer, s.ssPort, s.ssPassword,
                            s.outProtocol, s.outTls, s.outSni);
                    Ui.toast(c, "本地代理入口已开启 · SOCKS5:" + s.socksPort
                            + " → " + protoLabel(s.outProtocol) + " " + s.ssServer + ":" + s.ssPort);
                } catch (Throwable t) {
                    Ui.toast(c, "开启失败：" + t.getClass().getSimpleName());
                }
            } else {
                try { RustCore.nativeStopProxy(); } catch (Throwable ignored) {}
                try { MainActivity.stopVpn(c); } catch (Throwable ignored) {}
                Ui.toast(c, "本地代理入口已关闭");
            }
        });
        entryCard.addView(Ui.row(c, IconView.Glyph.BOLT, Ui.ORANGE, "本地代理入口",
                "SOCKS5 → " + protoLabel(s.outProtocol) + " 转发 · 需 VPN 授权", swEntry, null));

        // 出站协议 + 远端配置 + 本地 SOCKS5 端口（改动即落盘）
        entryCard.addView(Ui.separator(c));
        entryCard.addView(protocolPicker(c, s, refresh));
        entryCard.addView(editRow(c, "远端服务器", s.ssServer, v -> {
            s.ssServer = v.trim(); s.save();
        }));
        entryCard.addView(Ui.separator(c));
        entryCard.addView(editRow(c, "远端端口", String.valueOf(s.ssPort), v -> {
            try { s.ssPort = Integer.parseInt(v.trim()); } catch (Throwable t) { s.ssPort = 8388; }
            s.save();
        }));
        entryCard.addView(Ui.separator(c));
        entryCard.addView(editRow(c, secretLabel(s.outProtocol), s.ssPassword, v -> {
            s.ssPassword = v; s.save();
        }));
        if (!"ss".equals(s.outProtocol)) {
            Switch swTls = Ui.toggle(c, s.outTls);
            swTls.setEnabled(!"trojan".equals(s.outProtocol));
            swTls.setOnCheckedChangeListener((b, on) -> {
                if ("trojan".equals(s.outProtocol)) { b.setChecked(true); return; }
                s.outTls = on; s.save();
            });
            entryCard.addView(Ui.separator(c));
            entryCard.addView(Ui.row(c, IconView.Glyph.SHIELD, Ui.BLUE, "TLS",
                    "trojan 强制开启；VLESS 可关（80 / 回源）", swTls, null));
            entryCard.addView(Ui.separator(c));
            entryCard.addView(editRow(c, "SNI（可选，空则用服务器地址）", s.outSni, v -> {
                s.outSni = v.trim(); s.save();
            }));
        }
        entryCard.addView(Ui.separator(c));
        entryCard.addView(editRow(c, "本地 SOCKS5 端口", String.valueOf(s.socksPort), v -> {
            try { s.socksPort = Integer.parseInt(v.trim()); } catch (Throwable t) { s.socksPort = 1080; }
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
            String[] kindName = {"DOMAIN-SUFFIX", "DOMAIN-KEYWORD", "IP-CIDR"};
            String[] actName = {"直连 DIRECT", "代理 PROXY", "拒绝 REJECT"};
            result.setText("命中规则 #" + (order + 1) + " · 类型 " + kindName[kind]
                    + "\n动作：" + actName[action]);
        });
        LinearLayout btnWrap = new LinearLayout(c);
        btnWrap.setPadding(Ui.dp(c, 14), Ui.dp(c, 6), Ui.dp(c, 14), Ui.dp(c, 10));
        btnWrap.addView(probe);
        routeTest.addView(btnWrap);
        body.addView(routeTest);

        body.addView(note(c, "节点由 Rust 内核解析示例订阅得到（非界面占位）；"
                + "延迟为模拟值，真实探测属后续阶段。路由测试直接调用内核索引引擎，"
                + "与「工具」页基准同源。"));
        return page(c, body);
    }

    static String protoLabel(String p) {
        if ("trojan".equals(p)) return "Trojan";
        if ("vless".equals(p)) return "VLESS";
        return "Shadowsocks";
    }

    static String secretLabel(String p) {
        if ("trojan".equals(p)) return "Trojan 密码";
        if ("vless".equals(p)) return "VLESS UUID";
        return "SS 密码";
    }

    static LinearLayout protocolPicker(Context c, AppState s, Runnable refresh) {
        LinearLayout row = new LinearLayout(c);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(Ui.dp(c, 16), Ui.dp(c, 12), Ui.dp(c, 16), Ui.dp(c, 2));
        String[] keys = {"ss", "trojan", "vless"};
        String[] labels = {"Shadowsocks", "Trojan", "VLESS"};
        for (int i = 0; i < keys.length; i++) {
            final String key = keys[i];
            boolean on = key.equals(s.outProtocol);
            TextView t = new TextView(c);
            t.setText(labels[i]);
            t.setTextSize(12);
            t.setTypeface(Typeface.DEFAULT_BOLD);
            t.setGravity(Gravity.CENTER);
            t.setPadding(Ui.dp(c, 12), Ui.dp(c, 7), Ui.dp(c, 12), Ui.dp(c, 7));
            GradientDrawable g = new GradientDrawable();
            g.setColor(on ? Ui.BLUE : Color.WHITE);
            g.setCornerRadius(Ui.dp(c, 16));
            g.setStroke(1, on ? Ui.BLUE : Ui.SEP);
            t.setBackground(g);
            t.setTextColor(on ? Color.WHITE : Ui.TEXT2);
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            lp.rightMargin = Ui.dp(c, 8);
            t.setLayoutParams(lp);
            t.setOnClickListener(v -> {
                s.outProtocol = key;
                if ("trojan".equals(key)) s.outTls = true;
                s.save();
                refresh.run();
            });
            row.addView(t);
        }
        return row;
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
