package com.threely.skyward.poc;

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

/**
 * 四个页面的内容骨架：首页 / 代理 / 配置 / 我的。纯原生 View，分组卡片边界清晰。
 *
 * 0.1.0.6：连接后的时长、上传/下载、实时速率、活动连接改由 Rust 内核会话真值
 * 提供（每秒 tick 刷新，靠 pageEpoch 自动退出）；所有开关与选中项改动即落盘。
 * 节点 / 配置 / 订阅仍是界面演示占位，界面上明确标注。
 */
public final class Pages {

    private Pages() {}
    private static final Handler MAIN = new Handler(Looper.getMainLooper());

    /** 可滚动页面容器。 */
    private static ScrollView page(Context c, LinearLayout body) {
        ScrollView sv = new ScrollView(c);
        sv.setFillViewport(true);
        sv.setVerticalScrollBarEnabled(false);
        sv.addView(body, new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        return sv;
    }

    private static TextView note(Context c, String text) {
        TextView t = new TextView(c);
        t.setText(text);
        t.setTextSize(11.5f);
        t.setTextColor(Ui.TEXT3);
        t.setPadding(Ui.dp(c, 4), Ui.dp(c, 8), Ui.dp(c, 4), 0);
        t.setLineSpacing(Ui.dp(c, 2), 1f);
        return t;
    }

    // ===================== 首页 / 仪表盘 =====================
    // ===================== 首页 · 仪表盘（对齐原 Flutter 版布局） =====================
    // 结构照搬 lib/views/dashboard：大标题 + 状态行，下面 7 张卡（状态 / 网络控制 /
    // 网络概览 / 路由看板 / 配置 / 代理组 / 内存），mobile 卡片圆角 34、内边距 20/18。
    public static View home(Context c, Runnable refresh) {
        final AppState s = AppState.get();

        ScrollView sv = new ScrollView(c);
        sv.setFillViewport(true);
        sv.setVerticalScrollBarEnabled(false);
        final LinearLayout body = new LinearLayout(c);
        body.setOrientation(LinearLayout.VERTICAL);
        // 原版 dashboardMobileSideOf = max(16, (width - 560) / 2)：手机宽度下即 16dp，
        // 底部 16 + 系统手势条内边距。
        body.setPadding(Ui.dp(c, 16), 0, Ui.dp(c, 16), Ui.dp(c, 16));

        // ---- 大标题 ----
        TextView h1 = new TextView(c);
        h1.setText("仪表盘");
        h1.setTextSize(34);
        h1.setTypeface(Typeface.DEFAULT_BOLD);
        h1.setTextColor(Ui.TEXT);
        h1.setLetterSpacing(-0.02f);
        // 原版 PageLargeTitle 左右 22、顶部 statusBarTop + 12；卡片区左右 16，
        // 故标题在此再补 6dp 左右内边距。
        h1.setPadding(Ui.dp(c, 6), Ui.dp(c, 12), Ui.dp(c, 6), 0);
        body.addView(h1);

        // ---- 状态行：● 已连接 · 00:00:00 ----
        LinearLayout line = new LinearLayout(c);
        line.setOrientation(LinearLayout.HORIZONTAL);
        line.setGravity(Gravity.CENTER_VERTICAL);
        line.setPadding(Ui.dp(c, 6), Ui.dp(c, 10), Ui.dp(c, 6), Ui.dp(c, 12));
        final View dot = new View(c);
        GradientDrawable dg = new GradientDrawable();
        dg.setShape(GradientDrawable.OVAL);
        dg.setColor(s.connected ? Ui.GREEN : Ui.TEXT3);
        dot.setBackground(dg);
        dot.setLayoutParams(new LinearLayout.LayoutParams(Ui.dp(c, 8), Ui.dp(c, 8)));
        line.addView(dot);
        final TextView stateV = new TextView(c);
        stateV.setText(s.connected ? "已连接" : "未连接");
        stateV.setTextSize(15);
        stateV.setTextColor(Ui.TEXT2);
        LinearLayout.LayoutParams slp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        slp.leftMargin = Ui.dp(c, 8);
        stateV.setLayoutParams(slp);
        line.addView(stateV);
        final TextView timerV = new TextView(c);
        timerV.setText(s.connected ? "  ·  " + AppState.humanDuration(s.uptimeSec()) : "");
        timerV.setTextSize(15);
        timerV.setTextColor(Ui.TEXT2);
        line.addView(timerV);
        body.addView(line);

        // ===== 卡 1 · 状态（含启动按钮，原版唯一不可移除的卡）=====
        // 波形由卡片自身背景层绘制（WaveCard.dispatchDraw），不再挂铺满的子 View。
        Dash.WaveCard card1 = new Dash.WaveCard(c, 34);
        LinearLayout.LayoutParams c1lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        c1lp.topMargin = Ui.dp(c, 12);
        card1.setLayoutParams(c1lp);

        LinearLayout c1 = new LinearLayout(c);
        c1.setOrientation(LinearLayout.VERTICAL);
        c1.setPadding(Ui.dp(c, 20), Ui.dp(c, 18), Ui.dp(c, 16), Ui.dp(c, 18));
        card1.addView(c1, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        // 头部：图标 + 状态 + 芯片 | 右侧上下行速率
        LinearLayout r1 = new LinearLayout(c);
        r1.setOrientation(LinearLayout.HORIZONTAL);
        r1.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout hd = new LinearLayout(c);
        hd.setOrientation(LinearLayout.HORIZONTAL);
        hd.setGravity(Gravity.CENTER_VERTICAL);
        TextView stTx = new TextView(c);
        stTx.setText("状态");
        stTx.setTextSize(15);
        stTx.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        stTx.setTextColor(Ui.TEXT);
        stTx.setLayoutParams(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        hd.addView(stTx);
        final TextView stChip = chip(c, s.connected ? "运行中" : "未运行",
                s.connected ? Ui.GREEN : Ui.TEXT2,
                s.connected ? Color.parseColor("#1400A94F") : Color.parseColor("#14000000"));
        LinearLayout.LayoutParams chipLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        chipLp.leftMargin = Ui.dp(c, 7);
        stChip.setLayoutParams(chipLp);
        hd.addView(stChip);
        r1.addView(hd, new LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f));

        final TextView upRate = new TextView(c), upTot = new TextView(c);
        final TextView dnRate = new TextView(c), dnTot = new TextView(c);
        // 原版 _HeaderRates：定宽 150 / 高 38，右对齐，两列之间一条 0.5dp 竖线。
        LinearLayout rates = new LinearLayout(c);
        rates.setOrientation(LinearLayout.HORIZONTAL);
        rates.setGravity(Gravity.CENTER_VERTICAL);
        rates.addView(rateCol(c, true, upRate, upTot));
        View vline = new View(c);
        vline.setBackgroundColor(Ui.SEP);
        LinearLayout.LayoutParams vlp = new LinearLayout.LayoutParams(
                Math.max(1, Ui.dp(c, 0.5f)), Ui.dp(c, 26));
        vlp.leftMargin = Ui.dp(c, 8);
        vlp.rightMargin = Ui.dp(c, 8);
        rates.addView(vline, vlp);
        rates.addView(rateCol(c, false, dnRate, dnTot));
        r1.addView(rates, new LinearLayout.LayoutParams(
                Ui.dp(c, 150), Ui.dp(c, 38)));
        c1.addView(r1);

        // 出口 IP + 组织 | 启动按钮
        LinearLayout r2 = new LinearLayout(c);
        r2.setOrientation(LinearLayout.HORIZONTAL);
        r2.setGravity(Gravity.CENTER_VERTICAL);
        r2.setPadding(0, Ui.dp(c, 12), 0, 0);

        LinearLayout ipCol = new LinearLayout(c);
        ipCol.setOrientation(LinearLayout.VERTICAL);
        String srv = "";
        try { srv = RustCore.nativeNodeServer(s.selectedNode); } catch (Throwable ignored) {}
        if (srv == null || srv.isEmpty()) srv = "—";
        final TextView ipV = new TextView(c);
        ipV.setText(srv);
        ipV.setTextSize(22);
        ipV.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        ipV.setTextColor(s.connected ? Ui.TEXT : Ui.TEXT2);
        ipV.setLetterSpacing(0f);
        ipCol.addView(ipV);

        TextView orgLab = new TextView(c);
        orgLab.setText("IP 组织");
        orgLab.setTextSize(12);
        orgLab.setTextColor(Ui.TEXT3);
        orgLab.setPadding(0, Ui.dp(c, 12), 0, 0);
        ipCol.addView(orgLab);
        String grp = "";
        try { grp = RustCore.nativeNodeGroup(s.selectedNode); } catch (Throwable ignored) {}
        TextView orgVal = new TextView(c);
        orgVal.setText(grp == null || grp.isEmpty() ? "—" : grp);
        orgVal.setTextSize(15);
        orgVal.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        orgVal.setTextColor(Ui.TEXT);
        orgVal.setSingleLine(true);
        orgVal.setEllipsize(android.text.TextUtils.TruncateAt.END);
        orgVal.setPadding(0, Ui.dp(c, 2), 0, 0);
        ipCol.addView(orgVal);
        r2.addView(ipCol, new LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f));

        // 64dp 圆形启动/停止
        FrameLayout btn = new FrameLayout(c);
        GradientDrawable bg = new GradientDrawable();
        bg.setShape(GradientDrawable.OVAL);
        bg.setColor(s.connected ? Ui.GREEN : Color.parseColor("#C7C7CC"));
        btn.setBackground(bg);
        IconView bi = new IconView(c, s.connected ? IconView.Glyph.POWER : IconView.Glyph.POWER,
                Color.WHITE);
        FrameLayout.LayoutParams bilp = new FrameLayout.LayoutParams(
                Ui.dp(c, 26), Ui.dp(c, 26));
        bilp.gravity = Gravity.CENTER;
        bi.setLayoutParams(bilp);
        btn.addView(bi);
        btn.setLayoutParams(new LinearLayout.LayoutParams(Ui.dp(c, 64), Ui.dp(c, 64)));
        btn.setClickable(true);
        btn.setOnClickListener(v -> {
            if (AppState.get().connected) AppState.get().disconnect();
            else AppState.get().connect();
            refresh.run();
        });
        r2.addView(btn);
        c1.addView(r2);
        body.addView(card1);

        // ===== 卡 2 · 网络控制（模式 + VPN / 局域网 两块状态）=====
        LinearLayout card2 = lcard(c);
        card2.addView(cardHead(c, IconView.Glyph.SWITCH, "网络控制", null));

        // 出站模式：规则 / 全局 / 直连
        LinearLayout seg = new LinearLayout(c);
        seg.setOrientation(LinearLayout.HORIZONTAL);
        GradientDrawable segBg = new GradientDrawable();
        segBg.setColor(Color.parseColor("#F2F2F7"));
        segBg.setCornerRadius(Ui.dp(c, 12));
        seg.setBackground(segBg);
        seg.setPadding(Ui.dp(c, 3), Ui.dp(c, 3), Ui.dp(c, 3), Ui.dp(c, 3));
        String[] modes = {"规则", "全局", "直连"};
        for (int i = 0; i < 3; i++) {
            final int idx = i;
            TextView t = new TextView(c);
            t.setText(modes[i]);
            t.setTextSize(13);
            t.setGravity(Gravity.CENTER);
            t.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
            t.setPadding(0, Ui.dp(c, 7), 0, Ui.dp(c, 7));
            boolean on = s.ruleMode == i;
            GradientDrawable g = new GradientDrawable();
            g.setColor(on ? Color.WHITE : Color.TRANSPARENT);
            g.setCornerRadius(Ui.dp(c, 9));
            t.setBackground(g);
            t.setTextColor(on ? Ui.TEXT : Ui.TEXT2);
            t.setOnClickListener(v -> {
                AppState.get().ruleMode = idx;
                AppState.get().save();
                refresh.run();
            });
            seg.addView(t, new LinearLayout.LayoutParams(0,
                    ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        }
        LinearLayout.LayoutParams segLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        segLp.topMargin = Ui.dp(c, 12);
        card2.addView(seg, segLp);

        // VPN / 局域网：两块并排（手机版原样：无开关，点块切换）
        LinearLayout tiles = new LinearLayout(c);
        tiles.setOrientation(LinearLayout.HORIZONTAL);
        tiles.setPadding(0, Ui.dp(c, 10), 0, 0);
        LinearLayout vpnTile = tile(c, "VPN", s.tunMode ? "已接管" : "未接管");
        vpnTile.setClickable(true);
        vpnTile.setOnClickListener(v -> {
            if (AppState.get().tunMode) {
                try { RustCore.nativeCloseTun(); } catch (Throwable ignored) {}
                MainActivity.stopVpn(c);
                AppState.get().tunMode = false;
            } else {
                MainActivity.requestVpn(c);
                AppState.get().tunMode = true;
            }
            AppState.get().save();
            refresh.run();
        });
        tiles.addView(vpnTile,
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        LinearLayout.LayoutParams tlp2 = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        tlp2.leftMargin = Ui.dp(c, 8);
        tiles.addView(tile(c, "局域网", "未开启"), tlp2);
        card2.addView(tiles);
        body.addView(card2, cardGap(c));

        // ===== 卡 3 · 网络概览（服务格 2×2：36dp 徽章 + 名称 / 延迟，格高 50）=====
        LinearLayout card3 = lcard(c);
        final TextView verdict3 = chip(c, "", Ui.GREEN, Color.parseColor("#1400A94F"));
        verdict3.setVisibility(View.GONE);
        card3.addView(cardHead(c, IconView.Glyph.GLOBE, "网络概览", verdict3));

        final String gwIp = NetProbe.gateway(c);
        final String[] svcName = {"GitHub", "Google", "Cloudflare", "本机网关"};
        final String[] svcHost = {"github.com", "www.google.com", "1.1.1.1", gwIp};
        final int[] svcPort = {443, 443, 443, 80};
        final IconView.Glyph[] svcGlyph = {IconView.Glyph.LAYERS, IconView.Glyph.GLOBE,
                IconView.Glyph.BOLT, IconView.Glyph.ROUTE};
        final TextView[] svcState = new TextView[4];
        final boolean[] svcOk = new boolean[4];
        final int[] doneCount = {0};

        LinearLayout grid3 = new LinearLayout(c);
        grid3.setOrientation(LinearLayout.VERTICAL);
        grid3.setPadding(0, Ui.dp(c, 12), 0, 0);
        for (int r = 0; r < 2; r++) {
            LinearLayout svcLine = new LinearLayout(c);
            svcLine.setOrientation(LinearLayout.HORIZONTAL);
            if (r > 0) svcLine.setPadding(0, Ui.dp(c, 8), 0, 0);
            for (int col = 0; col < 2; col++) {
                int idx = r * 2 + col;
                LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                        0, Ui.dp(c, 50), 1f);
                if (col > 0) lp.leftMargin = Ui.dp(c, 8);
                svcLine.addView(svcCell(c, svcGlyph[idx], svcName[idx], svcState, idx), lp);
            }
            grid3.addView(svcLine);
        }
        card3.addView(grid3);

        // 四路并发探测，结果回主线程写格子；全部回来后再给标题补结论芯片。
        for (int i = 0; i < 4; i++) {
            final int idx = i;
            NetProbe.probe(svcHost[i], svcPort[i], 1800, new NetProbe.Cb() {
                @Override public void onResult(final int ms, final boolean ok) {
                    card3.post(new Runnable() {
                        @Override public void run() {
                            svcOk[idx] = ok;
                            svcState[idx].setText(ok ? ms + " ms" : "不可达");
                            svcState[idx].setTextColor(ok
                                    ? (ms < 250 ? Ui.GREEN : Ui.ORANGE) : Ui.TEXT3);
                            doneCount[0]++;
                            if (doneCount[0] < 4) return;
                            int bad = 0;
                            for (boolean b : svcOk) if (!b) bad++;
                            verdict3.setVisibility(View.VISIBLE);
                            if (bad > 0) {
                                verdict3.setText(bad + " 项异常");
                                verdict3.setTextColor(Ui.ORANGE);
                                verdict3.setBackground(chipBg(c, "#1AFF9F0A"));
                            } else {
                                verdict3.setText("全部可用");
                                verdict3.setTextColor(Ui.GREEN);
                                verdict3.setBackground(chipBg(c, "#1400A94F"));
                            }
                        }
                    });
                }
            });
        }
        body.addView(card3, cardGap(c));

        // ===== 卡 4 · 路由看板（线框地球 + 本机→节点→目的地）=====
        LinearLayout card4 = lcard(c);
        card4.addView(cardHead(c, IconView.Glyph.ROUTE, "路由看板", null));
        Dash.GlobeView globe = new Dash.GlobeView(c);
        LinearLayout.LayoutParams glp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(c, 150));
        glp.topMargin = Ui.dp(c, 14);
        globe.setLayoutParams(glp);
        card4.addView(globe);
        LinearLayout cols = new LinearLayout(c);
        cols.setOrientation(LinearLayout.HORIZONTAL);
        cols.setGravity(Gravity.CENTER_VERTICAL);
        cols.setPadding(0, Ui.dp(c, 16), 0, 0);
        String nodeName = "";
        try { nodeName = RustCore.nativeNodeName(s.selectedNode); } catch (Throwable ignored) {}
        cols.addView(rcol(c, "本机", "本设备", "局域网"),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        cols.addView(rarrow(c));
        cols.addView(rcol(c, "节点", nodeName == null || nodeName.isEmpty() ? "未选择" : shortName(nodeName),
                "已选择"), new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        cols.addView(rarrow(c));
        cols.addView(rcol(c, "目的地", "待解析", "按规则分流"),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        card4.addView(cols);
        body.addView(card4, cardGap(c));

        // ===== 卡 5 · 配置 =====
        int nc = 0;
        try { nc = RustCore.nativeNodeCount(); } catch (Throwable ignored) {}
        LinearLayout card5 = lcard(c);
        card5.addView(cardHead(c, IconView.Glyph.PROFILE, "配置", null));
        LinearLayout p5 = new LinearLayout(c);
        p5.setOrientation(LinearLayout.HORIZONTAL);
        p5.setGravity(Gravity.CENTER_VERTICAL);
        p5.setPadding(0, Ui.dp(c, 12), 0, 0);
        TextView pn = new TextView(c);
        pn.setText("默认配置");
        pn.setTextSize(17);
        pn.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        pn.setTextColor(Ui.TEXT);
        p5.addView(pn, new LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        p5.addView(chip(c, nc > 0 ? nc + " 节点" : "未载入", Ui.BLUE,
                Color.parseColor("#14007AFF")));
        card5.addView(p5);
        body.addView(card5, cardGap(c));

        // ===== 卡 6 · 代理组 =====
        LinearLayout card6 = lcard(c);
        card6.addView(cardHead(c, IconView.Glyph.LAYERS, "代理组", null));
        LinearLayout p6 = new LinearLayout(c);
        p6.setOrientation(LinearLayout.HORIZONTAL);
        p6.setGravity(Gravity.CENTER_VERTICAL);
        p6.setPadding(0, Ui.dp(c, 12), 0, 0);
        TextView gn = new TextView(c);
        gn.setText(AppState.GROUPS[Math.max(0,
                Math.min(s.selectedGroup, AppState.GROUPS.length - 1))]);
        gn.setTextSize(17);
        gn.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        gn.setTextColor(Ui.TEXT);
        p6.addView(gn, new LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        p6.addView(chip(c, "延迟自动", Ui.GREEN, Color.parseColor("#1400A94F")));
        card6.addView(p6);
        body.addView(card6, cardGap(c));

        // ===== 卡 7 · 内存信息（内核 + 进程 heap，真实读数）=====
        LinearLayout card7 = lcard(c);
        card7.addView(cardHead(c, IconView.Glyph.MEMORY, "内存信息", null));
        Runtime rt = Runtime.getRuntime();
        long used = rt.totalMemory() - rt.freeMemory();
        LinearLayout p7 = new LinearLayout(c);
        p7.setOrientation(LinearLayout.HORIZONTAL);
        p7.setPadding(0, Ui.dp(c, 12), 0, 0);
        p7.addView(kv(c, "进程 heap", AppState.humanBytes(used)),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        LinearLayout.LayoutParams k2 = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        k2.leftMargin = Ui.dp(c, 8);
        p7.addView(kv(c, "上限", AppState.humanBytes(rt.maxMemory())), k2);
        card7.addView(p7);
        body.addView(card7, cardGap(c));

        // ---- 秒级刷新：时长 / 速率 / 累计 ----
        final int epoch = s.pageEpoch;
        final long[] prev = { s.upBytes(), s.downBytes(), System.currentTimeMillis() };
        final Runnable ticker = new Runnable() {
            @Override public void run() {
                if (s.pageEpoch != epoch) return;
                timerV.setText(s.connected
                        ? "  ·  " + AppState.humanDuration(s.uptimeSec()) : "");
                stateV.setText(s.connected ? "已连接" : "未连接");
                GradientDrawable d2 = new GradientDrawable();
                d2.setShape(GradientDrawable.OVAL);
                d2.setColor(s.connected ? Ui.GREEN : Ui.TEXT3);
                dot.setBackground(d2);
                stChip.setText(s.connected ? "运行中" : "未运行");
                stChip.setTextColor(s.connected ? Ui.GREEN : Ui.TEXT2);
                stChip.setBackground(chipBg(c, s.connected ? "#1400A94F" : "#14000000"));
                long now = System.currentTimeMillis();
                long dt = Math.max(1L, now - prev[2]);
                long up = s.upBytes(), down = s.downBytes();
                upRate.setText(AppState.rate((up - prev[0]) * 1000L / dt));
                dnRate.setText(AppState.rate((down - prev[1]) * 1000L / dt));
                upTot.setText("累计 " + AppState.humanBytes(up));
                dnTot.setText("累计 " + AppState.humanBytes(down));
                prev[0] = up; prev[1] = down; prev[2] = now;
                body.postDelayed(this, 1000);
            }
        };
        body.postDelayed(ticker, 1000);
        return page(c, body);
    }

    /** 34 圆角白卡（LinearLayout 版），已带 20/18 内边距。 */
    private static LinearLayout lcard(Context c) {
        LinearLayout card = new LinearLayout(c);
        card.setOrientation(LinearLayout.VERTICAL);
        GradientDrawable g = new GradientDrawable();
        g.setColor(Color.WHITE);
        g.setCornerRadius(Ui.dp(c, 34));
        card.setBackground(g);
        card.setElevation(Ui.dp(c, 1));
        card.setPadding(Ui.dp(c, 20), Ui.dp(c, 18), Ui.dp(c, 20), Ui.dp(c, 18));
        return card;
    }

    /** 卡片间距（原版 cardSpacingOf：mobile = 8dp）。 */
    private static LinearLayout.LayoutParams cardGap(Context c) {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.topMargin = Ui.dp(c, 8);
        return lp;
    }

    /** 卡片标题行：原版 DashboardCardHeader —— 手机版不带前置图标，只有 15sp 中粗标题，
     *  行高固定 26dp；右侧 trailing 靠右对齐。 */
    private static LinearLayout cardHead(Context c, IconView.Glyph glyph, String title,
                                        View trailing) {
        LinearLayout row = new LinearLayout(c);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setLayoutParams(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(c, 26)));
        TextView t = new TextView(c);
        t.setText(title);
        t.setTextSize(15);
        t.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        t.setTextColor(Ui.TEXT);
        row.addView(t, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        if (trailing != null) {
            row.addView(new View(c), new LinearLayout.LayoutParams(0, 1, 1f));
            row.addView(trailing);
        }
        return row;
    }

    /**
     * 服务格（原版 _ServiceCell）：浅灰底、16 圆角、高 50，
     * 左侧 36dp 白底徽章 + 19dp 图标，右侧名称 12sp / 延迟 11sp。
     * 状态 TextView 回填到 sink，供探测结果后续改写。
     */
    private static LinearLayout svcCell(Context c, IconView.Glyph glyph, String name,
                                        TextView[] sink, int idx) {
        LinearLayout t = new LinearLayout(c);
        t.setOrientation(LinearLayout.HORIZONTAL);
        t.setGravity(Gravity.CENTER_VERTICAL);
        GradientDrawable g = new GradientDrawable();
        g.setColor(Ui.TONE);
        g.setCornerRadius(Ui.dp(c, 16));
        t.setBackground(g);
        t.setPadding(Ui.dp(c, 7), 0, Ui.dp(c, 12), 0);

        FrameLayout badge = new FrameLayout(c);
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.WHITE);
        bg.setCornerRadius(Ui.dp(c, 9));
        badge.setBackground(bg);
        IconView ic = new IconView(c, glyph, Ui.TEXT2);
        int is = Ui.dp(c, 19);
        FrameLayout.LayoutParams ilp = new FrameLayout.LayoutParams(is, is);
        ilp.gravity = Gravity.CENTER;
        badge.addView(ic, ilp);
        t.addView(badge, new LinearLayout.LayoutParams(Ui.dp(c, 36), Ui.dp(c, 36)));

        LinearLayout col = new LinearLayout(c);
        col.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams clp = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        clp.leftMargin = Ui.dp(c, 8);
        TextView n = new TextView(c);
        n.setText(name);
        n.setTextSize(12);
        n.setTextColor(Ui.TEXT2);
        n.setSingleLine(true);
        n.setEllipsize(android.text.TextUtils.TruncateAt.END);
        col.addView(n);
        TextView st = new TextView(c);
        st.setText("检测中…");
        st.setTextSize(11);
        st.setTextColor(Ui.TEXT3);
        st.setSingleLine(true);
        st.setPadding(0, Ui.dp(c, 1), 0, 0);
        col.addView(st);
        t.addView(col, clp);

        if (sink != null && idx >= 0 && idx < sink.length) sink[idx] = st;
        return t;
    }

    private static GradientDrawable chipBg(Context c, String hex) {
        GradientDrawable g = new GradientDrawable();
        g.setColor(Color.parseColor(hex));
        g.setCornerRadius(Ui.dp(c, 8));
        return g;
    }

    /** 状态芯片。 */
    private static TextView chip(Context c, String text, int fg, int bgColor) {
        TextView t = new TextView(c);
        t.setText(text);
        t.setTextSize(11.5f);
        t.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        t.setTextColor(fg);
        t.setPadding(Ui.dp(c, 8), Ui.dp(c, 3), Ui.dp(c, 8), Ui.dp(c, 3));
        GradientDrawable g = new GradientDrawable();
        g.setColor(bgColor);
        g.setCornerRadius(Ui.dp(c, 8));
        t.setBackground(g);
        return t;
    }

    /** 速率列（原版 _HeaderRate）：14dp 方向箭头 + 15sp 速率，下一行 11sp 累计。 */
    private static LinearLayout rateCol(Context c, boolean up,
                                        TextView rate, TextView total) {
        LinearLayout col = new LinearLayout(c);
        col.setOrientation(LinearLayout.VERTICAL);
        LinearLayout top = new LinearLayout(c);
        top.setOrientation(LinearLayout.HORIZONTAL);
        top.setGravity(Gravity.CENTER_VERTICAL);
        IconView a = new IconView(c, up ? IconView.Glyph.ARROW_UP : IconView.Glyph.ARROW_DOWN,
                up ? Ui.ORANGE : Ui.BLUE);
        a.setLayoutParams(new LinearLayout.LayoutParams(Ui.dp(c, 14), Ui.dp(c, 14)));
        top.addView(a);
        rate.setText("0 B/s");
        rate.setTextSize(15);
        rate.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        rate.setTextColor(Ui.TEXT);
        rate.setSingleLine(true);
        LinearLayout.LayoutParams rlp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        rlp.leftMargin = Ui.dp(c, 3);
        rate.setLayoutParams(rlp);
        top.addView(rate);
        col.addView(top);
        total.setText("累计 0 B");
        total.setTextSize(11);
        total.setTextColor(Ui.TEXT2);
        total.setSingleLine(true);
        total.setPadding(0, Ui.dp(c, 1), 0, 0);
        col.addView(total);
        return col;
    }

    /** 浅灰圆角块：标题 + 副标题（原版 tile）。 */
    private static LinearLayout tile(Context c, String title, String sub) {
        LinearLayout t = new LinearLayout(c);
        t.setOrientation(LinearLayout.VERTICAL);
        GradientDrawable g = new GradientDrawable();
        g.setColor(Color.parseColor("#F2F2F7"));
        g.setCornerRadius(Ui.dp(c, 20));
        t.setBackground(g);
        t.setPadding(Ui.dp(c, 16), Ui.dp(c, 12), Ui.dp(c, 16), Ui.dp(c, 12));
        TextView a = new TextView(c);
        a.setText(title);
        a.setTextSize(15);
        a.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        a.setTextColor(Ui.TEXT);
        a.setSingleLine(true);
        a.setEllipsize(android.text.TextUtils.TruncateAt.END);
        t.addView(a);
        TextView b = new TextView(c);
        b.setText(sub);
        b.setTextSize(12);
        b.setTextColor(Ui.TEXT2);
        b.setSingleLine(true);
        b.setPadding(0, Ui.dp(c, 4), 0, 0);
        t.addView(b);
        return t;
    }

    /** 路由看板一列：小标签 + 主值 + 副值。 */
    private static LinearLayout rcol(Context c, String label, String value, String sub) {
        LinearLayout col = new LinearLayout(c);
        col.setOrientation(LinearLayout.VERTICAL);
        TextView l = new TextView(c);
        l.setText(label);
        l.setTextSize(12);
        l.setTextColor(Ui.TEXT3);
        col.addView(l);
        TextView v = new TextView(c);
        v.setText(value);
        v.setTextSize(15);
        v.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        v.setTextColor(Ui.TEXT);
        v.setSingleLine(true);
        v.setEllipsize(android.text.TextUtils.TruncateAt.END);
        v.setPadding(0, Ui.dp(c, 3), 0, 0);
        col.addView(v);
        TextView s2 = new TextView(c);
        s2.setText(sub);
        s2.setTextSize(11);
        s2.setTextColor(Ui.TEXT3);
        s2.setSingleLine(true);
        s2.setEllipsize(android.text.TextUtils.TruncateAt.END);
        col.addView(s2);
        return col;
    }

    private static TextView rarrow(Context c) {
        TextView t = new TextView(c);
        t.setText("›");
        t.setTextSize(18);
        t.setTextColor(Color.parseColor("#C0C0C6"));
        t.setPadding(Ui.dp(c, 2), 0, Ui.dp(c, 2), 0);
        return t;
    }

    private static String shortName(String name) {
        if (name == null || name.isEmpty()) return "自动选择";
        return name.length() > 10 ? name.substring(0, 9) + "…" : name;
    }

    /** 内存卡的一格：上标签 + 下数值。 */
    /** 键值列，value 的 TextView 回填到 sink[idx]，供秒级刷新改写。 */
    private static LinearLayout kvLive(Context c, String label, TextView[] sink, int idx) {
        LinearLayout col = new LinearLayout(c);
        col.setOrientation(LinearLayout.VERTICAL);
        TextView l = new TextView(c);
        l.setText(label);
        l.setTextSize(11);
        l.setTextColor(Ui.TEXT3);
        l.setSingleLine(true);
        col.addView(l);
        TextView v = new TextView(c);
        v.setText("0");
        v.setTextSize(14);
        v.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        v.setTextColor(Ui.TEXT);
        v.setSingleLine(true);
        v.setEllipsize(android.text.TextUtils.TruncateAt.END);
        v.setPadding(0, Ui.dp(c, 2), 0, 0);
        col.addView(v);
        if (sink != null && idx >= 0 && idx < sink.length) sink[idx] = v;
        return col;
    }

    private static LinearLayout kv(Context c, String label, String value) {
        LinearLayout col = new LinearLayout(c);
        col.setOrientation(LinearLayout.VERTICAL);
        TextView l = new TextView(c);
        l.setText(label);
        l.setTextSize(12);
        l.setTextColor(Ui.TEXT3);
        col.addView(l);
        TextView v = new TextView(c);
        v.setText(value);
        v.setTextSize(15);
        v.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        v.setTextColor(Ui.TEXT);
        v.setPadding(0, Ui.dp(c, 3), 0, 0);
        col.addView(v);
        return col;
    }

    // ===================== 规则总览（内核真值） =====================
    public static View rules(Context c, Runnable refresh) {
        final AppState s = AppState.get();
        LinearLayout body = Ui.pageBody(c);
        body.addView(Ui.pageHeader(c, "规则", "路由规则总览 · 来自 Rust 内核"));

        int n = 0;
        try { n = RustCore.nativeRuleCount(); } catch (Throwable t) { }
        body.addView(Ui.groupTitle(c,
                "规则集（" + n + " 条）· 命中优先级按列表顺序"));

        LinearLayout list = Ui.newCard(c);
        if (n == 0) {
            list.addView(Ui.row(c, IconView.Glyph.INFO, Ui.TEXT3, "暂无规则",
                    "内核未载入规则集", null, null));
        }
        for (int i = 0; i < n; i++) {
            final int idx = i;
            String pattern, kindLabel;
            int action;
            try {
                pattern = RustCore.nativeRulePattern(i);
                int kind = RustCore.nativeRuleKind(i);
                action = RustCore.nativeRuleAction(i);
                kindLabel = new String[]{"DOMAIN-SUFFIX", "DOMAIN-KEYWORD", "IP-CIDR"}[kind];
            } catch (Throwable t) {
                pattern = "—"; kindLabel = "—"; action = 0;
            }
            String[] actName = {"直连 DIRECT", "代理 PROXY", "拒绝 REJECT"};
            int[] actTint = {Ui.TEXT2, Ui.BLUE, Ui.RED};
            // 标题行：规则序号 + 动作（着色）
            TextView title = new TextView(c);
            title.setText("#" + (idx + 1) + "  " + pattern);
            title.setTextSize(14);
            title.setTextColor(Ui.TEXT);
            title.setTypeface(Typeface.DEFAULT_BOLD);
            title.setPadding(Ui.dp(c, 14), Ui.dp(c, 12), Ui.dp(c, 14), 0);
            // 副信息行：类型 + 动作徽标
            TextView sub = new TextView(c);
            sub.setTextSize(12);
            sub.setTextColor(actTint[action]);
            sub.setPadding(Ui.dp(c, 14), Ui.dp(c, 2), Ui.dp(c, 14), Ui.dp(c, 12));
            sub.setText(kindLabel + " → " + actName[action]);
            list.addView(title);
            list.addView(sub);
            if (i != n - 1) list.addView(Ui.separator(c));
        }
        body.addView(list);

        body.addView(note(c, "以上规则由 Rust 内核索引引擎真实持有（反转域名 trie / 关键词分桶 / "
                + "CIDR 最长前缀）。「代理」页的路由测试、首页的流量分配均与这里同源；"
                + "命中优先级按列表自上而下，首条命中生效。"));
        return page(c, body);
    }

    // ===================== 代理 =====================

    /** 已解析节点数（0 = 内核未载入配置）。 */
    private static int nodeCount() {
        try { return RustCore.nativeNodeCount(); } catch (Throwable t) { return 0; }
    }

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
        final TextView[] live = new TextView[3];
        dpRow.addView(kvLive(c, "读入（TUN）", live, 0),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        LinearLayout.LayoutParams l1 = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        l1.leftMargin = Ui.dp(c, 8);
        dpRow.addView(kvLive(c, "写回（TUN）", live, 1), l1);
        LinearLayout.LayoutParams l2 = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        l2.leftMargin = Ui.dp(c, 8);
        dpRow.addView(kvLive(c, "活跃连接", live, 2), l2);
        dpCard.addView(dpRow);
        body.addView(dpCard, dpLp);

        // 秒级刷新读数：页面切走即停（靠 pageEpoch）
        final int dpEpoch = s.pageEpoch;
        MAIN.post(new Runnable() {
            @Override public void run() {
                if (s.pageEpoch != dpEpoch) return;
                String csv = "0,0,0,0,0,0";
                try { csv = RustCore.nativeTunStats(); } catch (Throwable ignored) {}
                String[] p = csv.split(",");
                if (p.length >= 6) {
                    long bytes = safeLong(p[0]);
                    long packets = safeLong(p[1]);
                    long tx = safeLong(p[4]);
                    long conns = safeLong(p[5]);
                    if (live[0] != null) live[0].setText(packets + " 包 / " + AppState.humanBytes(bytes));
                    if (live[1] != null) live[1].setText(AppState.humanBytes(tx));
                    if (live[2] != null) live[2].setText(String.valueOf(conns));
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
                    RustCore.nativeStartProxy(s.socksPort, s.ssServer, s.ssPort, s.ssPassword);
                    Ui.toast(c, "本地代理入口已开启 · SOCKS5:" + s.socksPort
                            + " → SS:" + s.ssServer + ":" + s.ssPort);
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
                "SOCKS5 → SS 转发 · 需 VPN 授权", swEntry, null));

        // 远端 SS 配置 + 本地 SOCKS5 端口（改动即落盘）
        entryCard.addView(Ui.separator(c));
        entryCard.addView(editRow(c, "远端 SS 服务器", s.ssServer, v -> {
            s.ssServer = v.trim(); s.save();
        }));
        entryCard.addView(Ui.separator(c));
        entryCard.addView(editRow(c, "远端 SS 端口", String.valueOf(s.ssPort), v -> {
            try { s.ssPort = Integer.parseInt(v.trim()); } catch (Throwable t) { s.ssPort = 8388; }
            s.save();
        }));
        entryCard.addView(Ui.separator(c));
        entryCard.addView(editRow(c, "SS 密码", s.ssPassword, v -> {
            s.ssPassword = v; s.save();
        }));
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

    // ===================== 配置 =====================
    public static View profiles(Context c, Runnable refresh) {
        LinearLayout body = Ui.pageBody(c);
        body.addView(Ui.pageHeader(c, "配置", "当前配置 · 订阅管理"));

        body.addView(Ui.groupTitle(c, "当前配置"));
        LinearLayout cur = Ui.newCard(c);
        cur.addView(Ui.row(c, IconView.Glyph.PROFILE, Ui.BLUE, "本地配置",
                "已启用 · 演示", Ui.valueText(c, "默认"), null));
        cur.addView(Ui.separator(c));
        cur.addView(Ui.row(c, IconView.Glyph.CLOCK, Ui.TEXT2, "最近更新",
                "演示：刚刚更新", null, null));
        cur.addView(Ui.separator(c));
        cur.addView(Ui.row(c, IconView.Glyph.LIST, Ui.TEXT2, "规则条数",
                "来自 Rust 内核", Ui.valueText(c, RustCore.nativeRuleCount() + " 条"), null));
        cur.addView(Ui.separator(c));
        cur.addView(Ui.row(c, IconView.Glyph.LAYERS, Ui.TEAL, "规则引擎",
                "索引 trie / 关键词分桶 / CIDR",
                Ui.valueText(c, RustCore.nativeIndexNodes() + " 节点"), null));
        body.addView(cur);

        body.addView(Ui.groupTitle(c, "订阅"));
        int nc = nodeCount();
        LinearLayout subs = Ui.newCard(c);
        if (nc > 0) {
            subs.addView(Ui.row(c, IconView.Glyph.GLOBE, Ui.GREEN, "示例订阅 · 已载入",
                    nc + " 个节点 · Rust 内核解析", Ui.valueText(c, "已解析"), null));
        } else {
            subs.addView(Ui.row(c, IconView.Glyph.GLOBE, Ui.TEAL, "示例订阅（未载入）",
                    "点击载入真实节点", null,
                    v -> { int k = RustCore.nativeLoadSampleConfig();
                           Ui.toast(c, "已解析 " + k + " 个节点"); refresh.run(); }));
        }
        subs.addView(Ui.separator(c));
        subs.addView(Ui.row(c, IconView.Glyph.PLUS, Ui.BLUE, "添加订阅",
                "从链接导入 · 演示入口", null,
                v -> Ui.toast(c, "订阅导入未接入，本版为界面占位")));
        body.addView(subs);

        body.addView(Ui.groupTitle(c, "添加"));
        LinearLayout add = Ui.newCard(c);
        add.addView(Ui.row(c, IconView.Glyph.PROFILE, Ui.ORANGE, "新建配置",
                "本地空白配置 · 演示入口", null,
                v -> Ui.toast(c, "配置编辑未接入，本版为界面占位")));
        body.addView(add);

        body.addView(note(c, "示例订阅由 Rust 内核按 Clash 风格解析（真实节点，非占位）；"
                + "订阅链接导入、落盘与切换属后续阶段。"));
        return page(c, body);
    }

    // ===================== 我的 / 设置中心 =====================
    public static View mine(Context c, Runnable refresh) {
        final AppState s = AppState.get();
        LinearLayout body = Ui.pageBody(c);
        body.addView(Ui.pageHeader(c, "我的", "设置中心 · 内核与工具"));

        body.addView(Ui.groupTitle(c, "外观与主题"));
        LinearLayout appearance = Ui.newCard(c);
        appearance.addView(Ui.row(c, IconView.Glyph.PALETTE, Ui.PURPLE, "主题",
                "点击切换 · 已落盘", Ui.valueText(c, s.themeLabel()),
                v -> { s.themeMode = (s.themeMode + 1) % 3; s.save(); refresh.run(); }));
        appearance.addView(Ui.separator(c));
        appearance.addView(Ui.row(c, IconView.Glyph.HOME, Ui.BLUE, "语言",
                "简体中文", Ui.valueText(c, "跟随系统"), null));
        appearance.addView(Ui.separator(c));
        Switch swGlass = Ui.toggle(c, s.liquidGlass);
        swGlass.setOnCheckedChangeListener((b, on) -> {
            s.liquidGlass = on;
            s.save();
            refresh.run();   // 重绘：卡片转半透明 + 页面底色转冷
            Ui.toast(c, on ? "液态玻璃：开" : "液态玻璃：关（默认）");
        });
        appearance.addView(Ui.row(c, IconView.Glyph.LAYERS, Ui.TEAL, "液态玻璃效果",
                "默认关闭 · 需手动开启 · 已落盘", swGlass, null));
        body.addView(appearance);

        body.addView(Ui.groupTitle(c, "通用与内核"));
        LinearLayout general = Ui.newCard(c);
        general.addView(Ui.row(c, IconView.Glyph.ROUTE, Ui.ORANGE, "路由模式",
                "点击切换 · 已落盘", Ui.valueText(c, s.ruleModeLabel()),
                v -> { s.ruleMode = (s.ruleMode + 1) % 3; s.save(); refresh.run(); }));
        general.addView(Ui.separator(c));
        Switch swV6 = Ui.toggle(c, s.ipv6);
        swV6.setOnCheckedChangeListener((b, on) -> { s.ipv6 = on; s.save(); });
        general.addView(Ui.row(c, IconView.Glyph.GLOBE, Ui.BLUE, "IPv6",
                "演示开关 · 已落盘", swV6, null));
        general.addView(Ui.separator(c));
        Switch swAuto = Ui.toggle(c, s.autoUpdate);
        swAuto.setOnCheckedChangeListener((b, on) -> { s.autoUpdate = on; s.save(); });
        general.addView(Ui.row(c, IconView.Glyph.ARROW_DOWN, Ui.GREEN, "订阅自动更新",
                "演示开关 · 已落盘", swAuto, null));
        general.addView(Ui.separator(c));
        general.addView(Ui.row(c, IconView.Glyph.MEMORY, Ui.TEAL, "内核版本",
                "Rust core（JNI 实时）", Ui.valueText(c, "v" + RustCore.nativeVersion()), null));
        general.addView(Ui.separator(c));
        general.addView(Ui.row(c, IconView.Glyph.LAYERS, Ui.BLUE, "规则引擎",
                "索引 trie / 关键词分桶 / CIDR 最长前缀",
                Ui.valueText(c, RustCore.nativeIndexNodes() + " 节点"), null));
        body.addView(general);

        body.addView(Ui.groupTitle(c, "工具"));
        LinearLayout tools = Ui.newCard(c);
        tools.addView(Ui.row(c, IconView.Glyph.CHART, Ui.BLUE, "性能基准",
                "索引 vs 线性对照 · 按需运行", null,
                v -> Ui.toast(c, "请点下方「运行性能基准」按钮")));
        tools.addView(Ui.separator(c));
        tools.addView(Ui.row(c, IconView.Glyph.LIST, Ui.ORANGE, "实时连接",
                "演示入口", null, v -> Ui.toast(c, "连接面板未接入")));
        tools.addView(Ui.separator(c));
        tools.addView(Ui.row(c, IconView.Glyph.DNS, Ui.GREEN, "内核网络探针",
                "真实 TCP · 见下方卡片", null, v -> Ui.toast(c, "见下方「内核网络探针」卡片")));
        tools.addView(Ui.separator(c));
        tools.addView(Ui.row(c, IconView.Glyph.LIST, Ui.TEXT2, "日志",
                "演示入口", null, v -> Ui.toast(c, "日志面板未接入")));
        body.addView(tools);

        // 真实内核网络探针（PoC-5）：可输入 host:port，内核经 tokio 做真实 DNS + TCP。
        body.addView(Ui.groupTitle(c, "内核网络探针（真实 socket · tokio）"));
        LinearLayout probeCard = Ui.newCard(c);
        final android.widget.EditText pinput = new android.widget.EditText(c);
        pinput.setHint("host:port，如 1.1.1.1:443 或 example.com:80");
        pinput.setText("1.1.1.1:443");
        pinput.setTextSize(14);
        pinput.setPadding(Ui.dp(c, 14), Ui.dp(c, 10), Ui.dp(c, 14), Ui.dp(c, 10));
        pinput.setBackgroundResource(0);
        probeCard.addView(pinput);
        probeCard.addView(Ui.separator(c));
        final TextView pout = new TextView(c);
        pout.setTextSize(13);
        pout.setTextColor(Ui.TEXT2);
        pout.setPadding(Ui.dp(c, 14), Ui.dp(c, 10), Ui.dp(c, 14), Ui.dp(c, 10));
        pout.setText("输入目标后点「发起探针」；内核将做真实 DNS 解析 + TCP 建连 + 收发试探字节。");
        probeCard.addView(pout);
        View pbtn = Ui.primaryButton(c, "发起探针", Ui.BLUE, v -> {
            String raw = pinput.getText().toString().trim();
            int colon = raw.lastIndexOf(':');
            String h; int pt;
            if (colon > 0) {
                h = raw.substring(0, colon);
                try { pt = Integer.parseInt(raw.substring(colon + 1).trim()); }
                catch (Throwable t) { pt = 443; }
            } else { h = raw; pt = 443; }
            if (h.isEmpty()) { Ui.toast(c, "请输入目标"); return; }
            pout.setText("探测中…（内核 tokio socket · 真实 DNS + TCP）");
            pout.setTextColor(Ui.TEXT2);
            runKernelProbe(h, pt, pout);
        });
        LinearLayout pbtnWrap = new LinearLayout(c);
        pbtnWrap.setPadding(Ui.dp(c, 14), Ui.dp(c, 6), Ui.dp(c, 14), Ui.dp(c, 10));
        pbtnWrap.addView(pbtn);
        probeCard.addView(pbtnWrap);
        body.addView(probeCard);

        // 基准区：按需点击、子线程分段、逐段回刷 UI；结束后恢复默认规则集
        TextView benchBtn = Ui.primaryButton(c, "运行性能基准", Ui.BLUE, null);
        LinearLayout.LayoutParams blp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        blp.topMargin = Ui.dp(c, 12);
        benchBtn.setLayoutParams(blp);
        body.addView(benchBtn);

        TextView benchOut = Ui.monoBlock(c, "未运行 · 点击上方按钮开始\n（规模已下调，避免真机卡顿）");
        LinearLayout benchCard = Ui.newCard(c);
        benchCard.addView(benchOut);
        body.addView(benchCard);

        benchBtn.setOnClickListener(v -> runBench(c, benchBtn, benchOut));

        // --- 品牌区：应用图标 + 名称 + 定位（图标来自 res/drawable-nodpi/ic_logo.png） ---
        LinearLayout brand = new LinearLayout(c);
        brand.setOrientation(LinearLayout.VERTICAL);
        brand.setGravity(Gravity.CENTER_HORIZONTAL);
        brand.setPadding(0, Ui.dp(c, 26), 0, Ui.dp(c, 8));
        int logoId = c.getResources().getIdentifier("ic_logo", "drawable", c.getPackageName());
        if (logoId != 0) {
            android.widget.ImageView logo = new android.widget.ImageView(c);
            logo.setImageResource(logoId);
            int px = Ui.dp(c, 78);
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(px, px);
            lp.bottomMargin = Ui.dp(c, 13);
            logo.setLayoutParams(lp);
            brand.addView(logo);
        }
        TextView brandName = new TextView(c);
        brandName.setText("Skyward");
        brandName.setTextSize(20);
        brandName.setTypeface(Typeface.DEFAULT_BOLD);
        brandName.setTextColor(Ui.TEXT);
        brandName.setGravity(Gravity.CENTER);
        brand.addView(brandName);
        TextView brandSub = new TextView(c);
        brandSub.setText("Rust 内核 · 原生 Android 壳");
        brandSub.setTextSize(12);
        brandSub.setTextColor(Ui.TEXT2);
        brandSub.setGravity(Gravity.CENTER);
        brandSub.setPadding(0, Ui.dp(c, 3), 0, 0);
        brand.addView(brandSub);
        body.addView(brand);

        body.addView(Ui.groupTitle(c, "关于"));
        LinearLayout about = Ui.newCard(c);
        about.addView(Ui.row(c, IconView.Glyph.INFO, Ui.BLUE, "关于 Skyward",
                "Rust 内核 + 原生 Android 壳", null,
                v -> Ui.toast(c, "PoC-6 · SOCKS5 + SS 真实转发 · TUN 接管版")));
        about.addView(Ui.separator(c));
        about.addView(Ui.row(c, IconView.Glyph.SHIELD, Ui.GREEN, "当前版本",
                "0.1.0.17-dev · arm64-v8a", Ui.valueText(c, "Dev"), null));
        about.addView(Ui.separator(c));
        about.addView(Ui.row(c, IconView.Glyph.BOLT, Ui.ORANGE, "构建链",
                "aapt2 / javac / d8 / zipalign / apksigner", null, null));
        body.addView(about);

        // 崩溃记录：仅当上次确实崩过时出现，方便定位（不打断正常界面）
        final String crash = CrashGuard.last(c);
        if (crash != null && !crash.isEmpty()) {
            body.addView(Ui.groupTitle(c, "上次崩溃记录（点右上可清空）"));
            LinearLayout crashCard = Ui.newCard(c);
            LinearLayout head = new LinearLayout(c);
            head.setOrientation(LinearLayout.HORIZONTAL);
            head.setGravity(Gravity.CENTER_VERTICAL);
            head.setPadding(Ui.dp(c, 14), Ui.dp(c, 10), Ui.dp(c, 14), 0);
            TextView t = new TextView(c);
            t.setText("堆栈已记录到应用私有目录");
            t.setTextSize(12);
            t.setTextColor(Ui.TEXT2);
            head.addView(t, new LinearLayout.LayoutParams(0,
                    ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
            TextView clear = Ui.valueText(c, "清空");
            clear.setTextColor(Ui.BLUE);
            clear.setPadding(Ui.dp(c, 8), Ui.dp(c, 4), Ui.dp(c, 4), Ui.dp(c, 4));
            clear.setClickable(true);
            clear.setOnClickListener(v -> { CrashGuard.clear(c); refresh.run(); });
            head.addView(clear);
            crashCard.addView(head);
            crashCard.addView(Ui.monoBlock(c, crash.length() > 1600
                    ? crash.substring(0, 1600) + "\n…（已截断）" : crash));
            body.addView(crashCard);
        }

        body.addView(note(c, "边界：内核已含 SOCKS5 入口 + Shadowsocks AEAD 出站真实转发，"
                + "并在 VpnService 授权后接管 TUN fd 读原始 IP 帧；界面上的会话时长与上下行"
                + "仍为内核模拟数据面计数，「真实代理流量」才是真实字节。"
                + "多协议出站、订阅导入、geo 分流属后续阶段。"));
        return page(c, body);
    }

    /** 基准：索引 vs 线性对照 + 规模下调 + 子线程分段 + 逐段 post，避免 ANR。 */
    private static void runBench(Context c, TextView btn, TextView out) {
        btn.setEnabled(false);
        btn.setText("运行中…");
        out.setText("starting...\n");
        new Thread(() -> {
            StringBuilder b = new StringBuilder();
            try {
                int ver = RustCore.nativeVersion();
                long warmUs = RustCore.nativeInitNs() / 1000;
                int nodes = RustCore.nativeIndexNodes();
                b.append(String.format(Locale.getDefault(),
                        "== 内核 ==\ncore version   : %d (PoC-2)\n规则引擎       : 索引 trie\ntrie 节点      : %d\n首次 JNI 冷启动: %,d us\nno GC / no runtime / no VM\n\n",
                        ver, nodes, warmUs));
            } catch (Throwable t) {
                b.append("内核调用失败: ").append(t).append('\n');
            }
            post(out, b.toString());

            // 索引化 vs PoC-1 线性扫描，同一份规则、同一批 host
            b.append("== 规则引擎：索引 vs 线性 ==\n");
            b.append(String.format("%-8s %9s %9s | %9s %9s%n",
                    "rules", "idx(ms)", "idx Mops", "lin(ms)", "lin Mops"));
            post(out, b.toString());
            // {规则数, 索引迭代, 线性迭代}（线性档刻意缩小，避免真机长卡）
            int[][] stages = {
                    {9, 100000, 100000}, {1000, 100000, 20000},
                    {10000, 50000, 2000}, {50000, 50000, 500}
            };
            for (int[] st : stages) {
                try {
                    RustCore.nativeLoadRules(st[0]);
                    double ims = RustCore.nativeBenchMatches(st[1]);
                    double lms = RustCore.nativeBenchMatchesLinear(st[2]);
                    double imops = (st[1] / 1e6) / (ims / 1000.0);
                    double lmops = (st[2] / 1e6) / (lms / 1000.0);
                    b.append(String.format(Locale.getDefault(),
                            "%-8d %9.2f %9.2f | %9.2f %9.2f%n",
                            st[0], ims, imops, lms, lmops));
                } catch (Throwable t) {
                    b.append("stage failed: ").append(t).append('\n');
                }
                post(out, b.toString());
            }
            b.append("索引吞吐随规则数持平；线性按 O(n) 塌方（PoC-1 缺陷）。\n");
            post(out, b.toString());

            try {
                RustCore.nativeLoadRules(1000);
                double pms = RustCore.nativeBenchPackets(100000, 1500);
                b.append(String.format(Locale.getDefault(),
                        "\n== 数据面（内存模拟，不接管 tun）==\n100000 x 1500 B = 143.1 MB\n%8.2f ms  %.2f Mpps  %.2f GB/s\nconnections : %d\n",
                        pms, (100000 / 1e6) / (pms / 1000.0),
                        (100000.0 * 1500 / 1e9) / (pms / 1000.0),
                        RustCore.nativeConnCount()));
            } catch (Throwable t) {
                b.append("packet stage failed: ").append(t).append('\n');
            }
            try {
                // 恢复默认规则集，避免首页「规则条数 / trie 节点」被基准污染
                int n = RustCore.nativeResetRules();
                b.append(String.format(Locale.getDefault(),
                        "\n规则集已恢复默认：%d 条 / %d trie 节点\n", n, RustCore.nativeIndexNodes()));
                b.append(String.format(Locale.getDefault(),
                        "\n== 内存 ==\nprocess RSS        : %.2f MB\nRust logical state: %,d B\n",
                        RustCore.nativeRssBytes() / 1048576.0, RustCore.nativeLogicalBytes()));
            } catch (Throwable t) {
                b.append("mem read failed: ").append(t).append('\n');
            }
            b.append("\nDONE · 规模已下调，避免真机卡顿。");
            post(out, b.toString());
            MAIN.post(() -> { btn.setEnabled(true); btn.setText("运行性能基准"); });
        }, "bench").start();
    }

    private static void post(TextView out, String text) {
        MAIN.post(() -> out.setText(text));
    }

    /** 解析 9 段逗号分隔的 long 序列（按动作分桶汇总），缺段补 0。 */
    private static long[] parseCsv9(String s) {
        long[] out = new long[9];
        if (s == null) return out;
        String[] p = s.split(",");
        for (int i = 0; i < 9 && i < p.length; i++) {
            try { out[i] = Long.parseLong(p[i].trim()); } catch (Throwable t) { out[i] = 0; }
        }
        return out;
    }

    /** 大整数千分位 / K 缩写，用于展示包数等计数。 */
    private static String humanK(long v) {
        if (v < 1000L) return String.valueOf(v);
        if (v < 1_000_000L) return String.format(Locale.getDefault(), "%.1fK", v / 1000.0);
        return String.format(Locale.getDefault(), "%.2fM", v / 1_000_000.0);
    }

    /** 真实内核 TCP 探针：后台线程执行（不阻塞 UI），结果回主线程渲染。
     *  内核经 tokio 做真实 DNS 解析 + TCP 建连 + 收发试探字节。 */
    private static void runKernelProbe(final String host, final int port, final TextView out) {
        new Thread(() -> {
            String csv;
            try {
                csv = RustCore.nativeProbe(host, port, 4000);
            } catch (Throwable t) {
                csv = "0,0,," + 0 + "," + 0 + "," + t.getClass().getSimpleName();
            }
            final String r = csv;
            MAIN.post(() -> applyProbeResult(out, r));
        }, "kernel-probe").start();
    }

    /** 把探针 CSV（ok,ms,ip,tx,rx,err）渲染成可读结果，并着色。 */
    private static void applyProbeResult(TextView out, String csv) {
        if (csv == null) csv = "";
        String[] p = csv.split(",");
        boolean ok = p.length > 0 && "1".equals(p[0].trim());
        long ms = p.length > 1 ? safeLong(p[1]) : 0;
        String ip = p.length > 2 ? p[2].trim() : "";
        long tx = p.length > 3 ? safeLong(p[3]) : 0;
        long rx = p.length > 4 ? safeLong(p[4]) : 0;
        String err = p.length > 5 ? p[5].trim() : "";
        StringBuilder sb = new StringBuilder();
        if (ok) {
            sb.append("● 成功   连接延迟 ").append(ms).append(" ms");
            if (!ip.isEmpty()) sb.append("\n解析 IP：").append(ip);
            sb.append("\n收发字节：↑").append(AppState.humanBytes(tx))
              .append("  ↓").append(AppState.humanBytes(rx)).append("（真实内核 socket）");
        } else {
            sb.append("✕ 失败   ").append(err.isEmpty() ? "未知错误" : err);
        }
        out.setText(sb.toString());
        out.setTextColor(ok ? Ui.GREEN : Ui.RED);
    }

    private static long safeLong(String s) {
        try { return Long.parseLong(s.trim()); } catch (Throwable t) { return 0; }
    }

    /** 可编辑行：上标签 + 下输入框（失焦或回车即回调，用于 SS 配置落盘）。 */
    private static View editRow(Context c, String label, String value,
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
