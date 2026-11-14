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

/** 首页 · 仪表盘。结构照搬原 Flutter 版 lib/views/dashboard：大标题 + 状态行 + 7 张卡。 */
public final class PageHome {
    private PageHome() {}

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
}
