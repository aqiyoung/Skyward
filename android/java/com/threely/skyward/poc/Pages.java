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

    // ===================== 首页 / 仪表盘（旧版，保留） =====================
    public static View homeLegacy(Context c, Runnable refresh) {
        final AppState s = AppState.get();
        LinearLayout body = Ui.pageBody(c);
        body.addView(Ui.pageHeader(c, "首页", "仪表盘 · 当前状态一览"));

        // --- 主状态大卡 ---
        LinearLayout hero = new LinearLayout(c);
        hero.setOrientation(LinearLayout.VERTICAL);
        GradientDrawable hg = new GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                s.connected ? new int[]{Color.parseColor("#00A94F"), Color.parseColor("#0B8A6B")}
                            : new int[]{Color.parseColor("#3A3A3C"), Color.parseColor("#636366")});
        hg.setCornerRadius(Ui.dp(c, 18));
        hero.setBackground(hg);
        hero.setPadding(Ui.dp(c, 20), Ui.dp(c, 20), Ui.dp(c, 20), Ui.dp(c, 18));

        TextView stateLabel = new TextView(c);
        stateLabel.setText(s.connected ? "●  已连接" : "○  未连接");
        stateLabel.setTextSize(13);
        stateLabel.setTextColor(Color.parseColor("#E8FFFFFF"));
        hero.addView(stateLabel);

        TextView outbound = new TextView(c);
        outbound.setText(s.connected ? AppState.NODE_NAMES[s.selectedNode] : "尚未连接");
        outbound.setTextSize(24);
        outbound.setTypeface(Typeface.DEFAULT_BOLD);
        outbound.setTextColor(Color.WHITE);
        outbound.setPadding(0, Ui.dp(c, 10), 0, Ui.dp(c, 2));
        hero.addView(outbound);

        TextView sub = new TextView(c);
        sub.setText(s.connected
                ? s.ruleModeLabel() + " · " + AppState.NODE_REGION[s.selectedNode] + " · 内核会话"
                : "点击下方按钮开始 · 内核未接管真实流量");
        sub.setTextSize(12);
        sub.setTextColor(Color.parseColor("#CCFFFFFF"));
        sub.setPadding(0, 0, 0, Ui.dp(c, 16));
        hero.addView(sub);

        // 流量/时长三栏（数值来自 Rust 会话，每秒刷新）
        LinearLayout stats = new LinearLayout(c);
        stats.setOrientation(LinearLayout.HORIZONTAL);
        final TextView[] statVals = new TextView[3];
        String[] keys = {"↑ 上传", "↓ 下载", "运行时长"};
        String[] vals = s.connected
                ? new String[]{AppState.humanBytes(s.upBytes()),
                              AppState.humanBytes(s.downBytes()),
                              AppState.humanDuration(s.uptimeSec())}
                : new String[]{"—", "—", "—"};
        for (int i = 0; i < keys.length; i++) {
            LinearLayout col = new LinearLayout(c);
            col.setOrientation(LinearLayout.VERTICAL);
            col.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
            TextView v = new TextView(c);
            v.setText(vals[i]);
            v.setTextSize(16);
            v.setTypeface(Typeface.DEFAULT_BOLD);
            v.setTextColor(Color.WHITE);
            statVals[i] = v;
            TextView k = new TextView(c);
            k.setText(keys[i]);
            k.setTextSize(11);
            k.setTextColor(Color.parseColor("#B8FFFFFF"));
            col.addView(v); col.addView(k);
            stats.addView(col);
        }
        hero.addView(stats);

        TextView btn = Ui.primaryButton(c, s.connected ? "断开连接" : "连接",
                s.connected ? Color.parseColor("#FFFFFF") : Color.parseColor("#007AFF"),
                v -> {
                    if (s.connected) s.disconnect(); else s.connect();
                    refresh.run();
                });
        if (s.connected) btn.setTextColor(Color.parseColor("#1C1C1E"));
        LinearLayout.LayoutParams blp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        blp.topMargin = Ui.dp(c, 18);
        btn.setLayoutParams(blp);
        hero.addView(btn);
        body.addView(hero);

        body.addView(Ui.groupTitle(c, "网络控制"));
        LinearLayout ctrl = Ui.newCard(c);
        Switch swSys = Ui.toggle(c, s.systemProxy);
        swSys.setOnCheckedChangeListener((b, on) -> { s.systemProxy = on; s.save(); });
        ctrl.addView(Ui.row(c, IconView.Glyph.SWITCH, Ui.BLUE, "系统代理",
                "演示开关 · 不修改系统设置", swSys, null));
        ctrl.addView(Ui.separator(c));
        Switch swTun = Ui.toggle(c, s.tunMode);
        swTun.setOnCheckedChangeListener((b, on) -> { s.tunMode = on; s.save(); });
        ctrl.addView(Ui.row(c, IconView.Glyph.TUN, Ui.PURPLE, "TUN 模式",
                "PoC 未建立真实 tun，开关仅作界面占位", swTun, null));
        body.addView(ctrl);

        body.addView(Ui.groupTitle(c, "网络概览（内核真值）"));
        LinearLayout net = Ui.newCard(c);
        final TextView rateUpV = Ui.valueText(c, "0 B/s");
        net.addView(Ui.row(c, IconView.Glyph.ARROW_UP, Ui.GREEN, "实时上传",
                "内核模拟数据面 · JNI 实时", rateUpV, null));
        net.addView(Ui.separator(c));
        final TextView rateDownV = Ui.valueText(c, "0 B/s");
        net.addView(Ui.row(c, IconView.Glyph.ARROW_DOWN, Ui.BLUE, "实时下载",
                "内核模拟数据面 · JNI 实时", rateDownV, null));
        net.addView(Ui.separator(c));
        final TextView connV = Ui.valueText(c, RustCore.nativeConnCount() + " 条");
        net.addView(Ui.row(c, IconView.Glyph.LIST, Ui.ORANGE, "活动连接",
                "Rust 连接表（JNI 实时）", connV, null));
        body.addView(net);

        body.addView(Ui.groupTitle(c, "路由与配置"));
        LinearLayout route = Ui.newCard(c);
        route.addView(Ui.row(c, IconView.Glyph.ROUTE, Ui.TEAL, "路由模式",
                "点击切换", Ui.valueText(c, s.ruleModeLabel()),
                v -> { s.ruleMode = (s.ruleMode + 1) % 3; s.save(); refresh.run(); }));
        route.addView(Ui.separator(c));
        route.addView(Ui.row(c, IconView.Glyph.LAYERS, Ui.BLUE, "代理组",
                AppState.GROUPS[s.selectedGroup] + " · 演示", null,
                v -> Ui.toast(c, "代理组列表请到「代理」页查看")));
        route.addView(Ui.separator(c));
        route.addView(Ui.row(c, IconView.Glyph.PROFILE, Ui.ORANGE, "当前配置",
                "本地配置 · 已启用 · 2 个订阅", Ui.valueText(c, "演示"), null));
        body.addView(route);

        body.addView(Ui.groupTitle(c, "流量分配（内核真值 · 按动作分桶）"));
        LinearLayout dist = Ui.newCard(c);
        final TextView[] distVals = new TextView[3];
        String[] actName = {"直连 DIRECT", "代理 PROXY", "拒绝 REJECT"};
        int[] actTint = {Ui.TEXT2, Ui.BLUE, Ui.RED};
        for (int i = 0; i < 3; i++) {
            final TextView v = Ui.valueText(c, "—");
            distVals[i] = v;
            dist.addView(Ui.row(c, IconView.Glyph.LIST, actTint[i], actName[i],
                    "内核会话分桶计数", v, null));
            if (i != 2) dist.addView(Ui.separator(c));
        }
        // 初次进入即填充一次内核真值（未连接时为 0）
        long[] b0 = parseCsv9(RustCore.nativeSessionBreakdown());
        distVals[0].setText(String.format(Locale.getDefault(),
                "%s · %s 包 · %d 连接", AppState.humanBytes(b0[0]), humanK(b0[1]), b0[2]));
        distVals[1].setText(String.format(Locale.getDefault(),
                "%s · %s 包 · %d 连接", AppState.humanBytes(b0[3]), humanK(b0[4]), b0[5]));
        distVals[2].setText(String.format(Locale.getDefault(),
                "%s · %s 包 · %d 连接", AppState.humanBytes(b0[6]), humanK(b0[7]), b0[8]));
        body.addView(dist);

        // 真实代理流量（PoC-6）：内核经 SS 出站真实转发的字节，区别于上方模拟会话。
        body.addView(Ui.groupTitle(c, "真实代理流量（PoC-6 · 非模拟）"));
        LinearLayout proxyCard = Ui.newCard(c);
        final TextView[] proxyVals = new TextView[2];
        String[] pKeys = {"↑ 代理上行", "↓ 代理下行"};
        for (int i = 0; i < 2; i++) {
            final TextView v = Ui.valueText(c, "0 B");
            proxyVals[i] = v;
            proxyCard.addView(Ui.row(c, i == 0 ? IconView.Glyph.ARROW_UP : IconView.Glyph.ARROW_DOWN,
                    i == 0 ? Ui.GREEN : Ui.BLUE, pKeys[i], "内核 SS 真实转发", v, null));
            if (i == 0) proxyCard.addView(Ui.separator(c));
        }
        long[] pv0 = parseCsv2(RustCore.nativeProxyStats());
        proxyVals[0].setText(AppState.humanBytes(pv0[0]));
        proxyVals[1].setText(AppState.humanBytes(pv0[1]));
        body.addView(proxyCard);

        // 真实数据面探针：内核经 tokio 运行时做真实 DNS 解析 + TCP 建连 + 收发试探字节。
        // 这是内核「真能收发字节」的实测证据，与上方由 session_tick 模拟出来的流量计数不是一回事。
        body.addView(Ui.groupTitle(c, "数据面验证（真实 socket · 非模拟）"));
        LinearLayout probeCard = Ui.newCard(c);
        final TextView probeOut = new TextView(c);
        probeOut.setTextSize(13);
        probeOut.setTextColor(Ui.TEXT2);
        probeOut.setPadding(Ui.dp(c, 14), Ui.dp(c, 12), Ui.dp(c, 14), Ui.dp(c, 12));
        probeOut.setText("内核 tokio 真实探针（默认 1.1.1.1:443）· 点「测一次」发起");
        probeCard.addView(probeOut);
        LinearLayout probeBtnWrap = new LinearLayout(c);
        probeBtnWrap.setPadding(Ui.dp(c, 14), Ui.dp(c, 6), Ui.dp(c, 14), Ui.dp(c, 10));
        final String PROBE_HOST = "1.1.1.1";
        final int PROBE_PORT = 443;
        TextView probeBtn = Ui.primaryButton(c, "测一次", Ui.BLUE, v -> {
            probeOut.setText("探测中…（内核 tokio socket · 真实 DNS + TCP）");
            probeOut.setTextColor(Ui.TEXT2);
            runKernelProbe(PROBE_HOST, PROBE_PORT, probeOut);
        });
        probeBtnWrap.addView(probeBtn);
        probeCard.addView(probeBtnWrap);
        body.addView(probeCard);
        // 进入页面即自动跑一次真实探针（后台线程，不阻塞 UI）
        runKernelProbe(PROBE_HOST, PROBE_PORT, probeOut);

        body.addView(Ui.groupTitle(c, "内核信息（Rust 实时读数）"));
        LinearLayout mem = Ui.newCard(c);
        mem.addView(Ui.monoBlock(c, s.coreInfo()));
        body.addView(mem);

        // 秒级刷新：只更新数字 TextView，不重建整页（避免滚动跳动）。
        // 切页 / 断开 / 退后台时 pageEpoch 变化，本 Runnable 自动退出，不泄漏。
        final int epoch = s.pageEpoch;
        final long[] prev = { s.upBytes(), s.downBytes(), System.currentTimeMillis() };
        final View anchor = body;
        final Runnable ticker = new Runnable() {
            @Override public void run() {
                if (s.pageEpoch != epoch) return;
                if (s.connected) {
                    s.tick();
                    long now = System.currentTimeMillis();
                    long dt = Math.max(1L, now - prev[2]);
                    long up = s.upBytes(), down = s.downBytes();
                    long rUp = (up - prev[0]) * 1000L / dt;
                    long rDown = (down - prev[1]) * 1000L / dt;
                    prev[0] = up; prev[1] = down; prev[2] = now;
                    statVals[0].setText(AppState.humanBytes(up));
                    statVals[1].setText(AppState.humanBytes(down));
                    statVals[2].setText(AppState.humanDuration(s.uptimeSec()));
                    rateUpV.setText(AppState.rate(rUp));
                    rateDownV.setText(AppState.rate(rDown));
                    connV.setText(RustCore.nativeConnCount() + " 条");
                    // 按动作分桶：dirBytes,dirPkts,dirConns,prxBytes,prxPkts,prxC,rejBytes,rejPkts,rejConns
                    long[] v = parseCsv9(RustCore.nativeSessionBreakdown());
                    distVals[0].setText(String.format(Locale.getDefault(),
                            "%s · %s 包 · %d 连接",
                            AppState.humanBytes(v[0]), humanK(v[1]), v[2]));
                    distVals[1].setText(String.format(Locale.getDefault(),
                            "%s · %s 包 · %d 连接",
                            AppState.humanBytes(v[3]), humanK(v[4]), v[5]));
                    distVals[2].setText(String.format(Locale.getDefault(),
                            "%s · %s 包 · %d 连接",
                            AppState.humanBytes(v[6]), humanK(v[7]), v[8]));
                }
                // 真实代理吞吐始终刷新（内核 SS 真实转发，不依赖「连接」开关）
                long[] p = parseCsv2(RustCore.nativeProxyStats());
                proxyVals[0].setText(AppState.humanBytes(p[0]));
                proxyVals[1].setText(AppState.humanBytes(p[1]));
                anchor.postDelayed(this, 1000);
            }
        };
        anchor.postDelayed(ticker, 1000);

        body.addView(note(c, "说明：上方「网络概览 / 流量分配」是内核模拟会话（不接管真实网卡）；"
                + "「真实代理流量」与「数据面验证」是内核经 tokio + SS 的真实 socket 收发字节（非模拟）。"
                + "节点、配置、订阅为界面演示占位。TUN 接管需系统 VPN 授权，真机验证。"));
        return page(c, body);
    }

    // ===================== 首页 / 仪表盘（对齐 4tab 定稿设计） =====================
    public static View home(Context c, Runnable refresh) {
        final AppState s = AppState.get();
        ScrollView sv = new ScrollView(c);
        sv.setFillViewport(true);
        sv.setVerticalScrollBarEnabled(false);
        final LinearLayout body = new LinearLayout(c);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(Ui.dp(c, 18), Ui.dp(c, 2), Ui.dp(c, 18), Ui.dp(c, 130));
        sv.addView(body, new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        // ---- 大标题 + DEV 徽章 ----
        LinearLayout titleRow = new LinearLayout(c);
        titleRow.setOrientation(LinearLayout.HORIZONTAL);
        titleRow.setGravity(Gravity.CENTER_VERTICAL);
        titleRow.setPadding(0, Ui.dp(c, 14), 0, 0);
        TextView h1 = new TextView(c);
        h1.setText("仪表盘");
        h1.setTextSize(32);
        h1.setTypeface(Typeface.DEFAULT_BOLD);
        h1.setTextColor(Ui.TEXT);
        titleRow.addView(h1, new LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        TextView dev = pillText(c, "DEV", Color.WHITE, Color.parseColor("#7C5CFF"));
        dev.setTextSize(11);
        titleRow.addView(dev);
        body.addView(titleRow);

        // ---- 状态行：● 已连接 · 00:00:00 ----
        LinearLayout statusLine = new LinearLayout(c);
        statusLine.setOrientation(LinearLayout.HORIZONTAL);
        statusLine.setGravity(Gravity.CENTER_VERTICAL);
        statusLine.setPadding(0, Ui.dp(c, 10), 0, 0);
        final View dot = new View(c);
        GradientDrawable dg = new GradientDrawable();
        dg.setShape(GradientDrawable.OVAL);
        dg.setColor(s.connected ? Ui.GREEN : Ui.TEXT3);
        dot.setBackground(dg);
        LinearLayout.LayoutParams dlp = new LinearLayout.LayoutParams(Ui.dp(c, 8), Ui.dp(c, 8));
        dlp.rightMargin = Ui.dp(c, 7);
        dot.setLayoutParams(dlp);
        statusLine.addView(dot);
        final TextView connTxt = new TextView(c);
        connTxt.setText(s.connected ? "已连接" : "未连接");
        connTxt.setTextSize(13.5f);
        connTxt.setTextColor(Ui.TEXT2);
        statusLine.addView(connTxt);
        final TextView timerV = new TextView(c);
        timerV.setText("  ·  " + AppState.humanDuration(s.uptimeSec()));
        timerV.setTextSize(13.5f);
        timerV.setTextColor(Ui.TEXT2);
        statusLine.addView(timerV);
        body.addView(statusLine);

        // ===== 状态卡 =====
        LinearLayout card1 = dashCard(c);
        LinearLayout.LayoutParams c1lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        c1lp.topMargin = Ui.dp(c, 14);
        card1.setLayoutParams(c1lp);
        card1.setPadding(Ui.dp(c, 18), Ui.dp(c, 16), Ui.dp(c, 18), Ui.dp(c, 16));

        LinearLayout top = new LinearLayout(c);
        top.setOrientation(LinearLayout.HORIZONTAL);
        top.setGravity(Gravity.CENTER_VERTICAL);
        TextView stLab = new TextView(c);
        stLab.setText("状态");
        stLab.setTextSize(12.5f);
        stLab.setTextColor(Ui.TEXT2);
        top.addView(stLab);
        LinearLayout.LayoutParams runLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        runLp.leftMargin = Ui.dp(c, 8);
        TextView runPill = pillText(c, "● 运行中", Ui.GREEN, Color.parseColor("#1400A94F"));
        runPill.setTextSize(11.5f);
        runPill.setLayoutParams(runLp);
        top.addView(runPill);
        top.addView(new View(c), new LinearLayout.LayoutParams(0, 1, 1f));

        final TextView upV = new TextView(c), upK = new TextView(c);
        final TextView dnV = new TextView(c), dnK = new TextView(c);
        upV.setText("0 B/s"); upV.setTextSize(14); upV.setTypeface(Typeface.DEFAULT_BOLD);
        upV.setTextColor(Ui.TEXT); upV.setGravity(Gravity.END);
        upK.setText("↑ 累计 0 B"); upK.setTextSize(10.5f); upK.setTextColor(Ui.TEXT3); upK.setGravity(Gravity.END);
        dnV.setText("0 B/s"); dnV.setTextSize(14); dnV.setTypeface(Typeface.DEFAULT_BOLD);
        dnV.setTextColor(Ui.TEXT); dnV.setGravity(Gravity.END);
        dnK.setText("↓ 累计 0 B"); dnK.setTextSize(10.5f); dnK.setTextColor(Ui.TEXT3); dnK.setGravity(Gravity.END);
        LinearLayout spdUp = new LinearLayout(c);
        spdUp.setOrientation(LinearLayout.VERTICAL);
        spdUp.addView(upV); spdUp.addView(upK);
        LinearLayout spdDn = new LinearLayout(c);
        spdDn.setOrientation(LinearLayout.VERTICAL);
        spdDn.addView(dnV); spdDn.addView(dnK);
        LinearLayout.LayoutParams sLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        sLp.leftMargin = Ui.dp(c, 16);
        top.addView(spdUp, sLp);
        LinearLayout.LayoutParams sLp2 = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        sLp2.leftMargin = Ui.dp(c, 14);
        top.addView(spdDn, sLp2);
        card1.addView(top);

        // 大 IP / 节点地址
        String srv = "";
        try { srv = RustCore.nativeNodeServer(s.selectedNode); } catch (Throwable ignored) {}
        if (srv == null || srv.isEmpty()) srv = "104.28.152.129";
        String nodeName = "";
        try { nodeName = RustCore.nativeNodeName(s.selectedNode); } catch (Throwable ignored) {}
        if (nodeName == null) nodeName = "";
        final String nodeNameF = nodeName;
        TextView ipBig = new TextView(c);
        ipBig.setText(srv);
        ipBig.setTextSize(25);
        ipBig.setTypeface(Typeface.DEFAULT_BOLD);
        ipBig.setTextColor(Ui.TEXT);
        LinearLayout.LayoutParams iplp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        iplp.topMargin = Ui.dp(c, 14);
        ipBig.setLayoutParams(iplp);
        card1.addView(ipBig);

        // 波形（氛围）
        Dash.SparklineView spark = new Dash.SparklineView(c);
        LinearLayout.LayoutParams sparkLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(c, 38));
        sparkLp.topMargin = Ui.dp(c, 4);
        spark.setLayoutParams(sparkLp);
        card1.addView(spark);

        // 底部：旗帜 + 机房/质量 + 组织  |  暂停按钮
        LinearLayout bot = new LinearLayout(c);
        bot.setOrientation(LinearLayout.HORIZONTAL);
        bot.setGravity(Gravity.CENTER_VERTICAL);
        bot.setPadding(0, Ui.dp(c, 8), 0, 0);
        TextView flag = new TextView(c);
        flag.setText(flagEmoji(nodeName));
        flag.setTextSize(22);
        LinearLayout.LayoutParams flagLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        flagLp.rightMargin = Ui.dp(c, 10);
        flag.setLayoutParams(flagLp);
        bot.addView(flag);

        LinearLayout info = new LinearLayout(c);
        info.setOrientation(LinearLayout.VERTICAL);
        LinearLayout line1 = new LinearLayout(c);
        line1.setOrientation(LinearLayout.HORIZONTAL);
        line1.setGravity(Gravity.CENTER_VERTICAL);
        TextView jf = new TextView(c);
        jf.setText("机房");
        jf.setTextSize(11);
        jf.setTextColor(Ui.TEXT2);
        line1.addView(jf);
        int delay = -1;
        try { delay = RustCore.nativeNodeDelay(s.selectedNode); } catch (Throwable ignored) {}
        String qtxt; int qfg;
        if (delay < 0)        { qtxt = "质量 直连"; qfg = Ui.TEXT3; }
        else if (delay < 80)  { qtxt = "质量 优质"; qfg = Ui.GREEN; }
        else if (delay < 150) { qtxt = "质量 一般"; qfg = Ui.ORANGE; }
        else                  { qtxt = "质量 风险"; qfg = Ui.ORANGE; }
        TextView qual = pillText(c, qtxt, qfg, Color.parseColor("#14FF9F0A"));
        qual.setTextSize(10.5f);
        LinearLayout.LayoutParams qualLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        qualLp.leftMargin = Ui.dp(c, 7);
        qual.setLayoutParams(qualLp);
        line1.addView(qual);
        info.addView(line1);
        String grp = "";
        try { grp = RustCore.nativeNodeGroup(s.selectedNode); } catch (Throwable ignored) {}
        TextView org = new TextView(c);
        org.setText("组织 " + (grp == null || grp.isEmpty() ? nodeNameF : grp));
        org.setTextSize(12);
        org.setTextColor(Ui.TEXT2);
        org.setSingleLine(true);
        org.setEllipsize(android.text.TextUtils.TruncateAt.END);
        org.setPadding(0, Ui.dp(c, 3), 0, 0);
        info.addView(org);
        bot.addView(info, new LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f));

        TextView pause = new TextView(c);
        pause.setText("II");
        pause.setTextSize(15);
        pause.setTypeface(Typeface.DEFAULT_BOLD);
        pause.setTextColor(Color.WHITE);
        pause.setGravity(Gravity.CENTER);
        GradientDrawable pg = new GradientDrawable();
        pg.setShape(GradientDrawable.OVAL);
        pg.setColor(s.connected ? Ui.GREEN : Color.parseColor("#C7C7CC"));
        pause.setBackground(pg);
        pause.setLayoutParams(new LinearLayout.LayoutParams(Ui.dp(c, 52), Ui.dp(c, 52)));
        pause.setClickable(true);
        pause.setOnClickListener(v -> {
            if (AppState.get().connected) AppState.get().disconnect();
            else AppState.get().connect();
            refresh.run();
        });
        bot.addView(pause);
        card1.addView(bot);
        body.addView(card1);

        // ===== 路由卡 =====
        LinearLayout routeCard = dashCard(c);
        LinearLayout.LayoutParams rlp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        rlp.topMargin = Ui.dp(c, 14);
        routeCard.setLayoutParams(rlp);
        routeCard.setPadding(Ui.dp(c, 18), Ui.dp(c, 15), Ui.dp(c, 18), Ui.dp(c, 14));

        LinearLayout rh = new LinearLayout(c);
        rh.setOrientation(LinearLayout.HORIZONTAL);
        rh.setGravity(Gravity.CENTER_VERTICAL);
        IconView gi = new IconView(c, IconView.Glyph.GLOBE, Ui.TEXT2);
        LinearLayout.LayoutParams gilp = new LinearLayout.LayoutParams(Ui.dp(c, 17), Ui.dp(c, 17));
        gilp.rightMargin = Ui.dp(c, 7);
        gi.setLayoutParams(gilp);
        rh.addView(gi);
        TextView rt = new TextView(c);
        rt.setText("路由");
        rt.setTextSize(14);
        rt.setTypeface(Typeface.DEFAULT_BOLD);
        rt.setTextColor(Ui.TEXT);
        rh.addView(rt, new LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        IconView chv = new IconView(c, IconView.Glyph.CHEVRON, Ui.TEXT3);
        chv.setLayoutParams(new LinearLayout.LayoutParams(Ui.dp(c, 16), Ui.dp(c, 16)));
        rh.addView(chv);
        routeCard.addView(rh);

        Dash.GlobeView globe = new Dash.GlobeView(c);
        LinearLayout.LayoutParams glp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(c, 150));
        glp.topMargin = Ui.dp(c, 4);
        globe.setLayoutParams(glp);
        routeCard.addView(globe);

        LinearLayout cols = new LinearLayout(c);
        cols.setOrientation(LinearLayout.HORIZONTAL);
        cols.setGravity(Gravity.CENTER_VERTICAL);
        cols.addView(routeCol(c, "本机", "陕西", "2409:8a70:10…"),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        cols.addView(routeArrow(c));
        cols.addView(routeCol(c, "节点", flagEmoji(nodeName) + " " + shortName(nodeName), "已选择"),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        cols.addView(routeArrow(c));
        cols.addView(routeCol(c, "目的地", "clients4.g…", "美国 · Mounta…"),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        routeCard.addView(cols);
        body.addView(routeCard);

        // ===== 网络控制卡 =====
        body.addView(Ui.groupTitle(c, "网络控制"));
        LinearLayout ctrl = Ui.newCard(c);
        Switch swSys = Ui.toggle(c, s.systemProxy);
        swSys.setOnCheckedChangeListener((b, on) -> { s.systemProxy = on; s.save(); });
        ctrl.addView(Ui.row(c, IconView.Glyph.SWITCH, Ui.BLUE, "系统代理",
                "演示开关 · 不修改系统设置", swSys, null));
        ctrl.addView(Ui.separator(c));
        Switch swTun = Ui.toggle(c, s.tunMode);
        swTun.setOnCheckedChangeListener((b, on) -> {
            s.tunMode = on; s.save();
            if (on) MainActivity.requestVpn(c); else MainActivity.stopVpn(c);
        });
        ctrl.addView(Ui.row(c, IconView.Glyph.TUN, Ui.PURPLE, "TUN 模式",
                "PoC-6 · 真实 tun 接管（需 VPN 授权）", swTun, null));
        body.addView(ctrl);

        // ===== 真实代理流量（内核 SS） =====
        body.addView(Ui.groupTitle(c, "真实代理流量（PoC-6 · 非模拟）"));
        LinearLayout proxyCard = Ui.newCard(c);
        final TextView pTx = Ui.valueText(c, "0 B");
        final TextView pRx = Ui.valueText(c, "0 B");
        proxyCard.addView(Ui.row(c, IconView.Glyph.ARROW_UP, Ui.GREEN, "代理上行",
                "内核 SS 真实转发", pTx, null));
        proxyCard.addView(Ui.separator(c));
        proxyCard.addView(Ui.row(c, IconView.Glyph.ARROW_DOWN, Ui.BLUE, "代理下行",
                "内核 SS 真实转发", pRx, null));
        body.addView(proxyCard);

        // ===== 数据面验证（真实 socket 探针） =====
        body.addView(Ui.groupTitle(c, "数据面验证（真实 socket · 非模拟）"));
        LinearLayout probeCard = Ui.newCard(c);
        final TextView probeOut = new TextView(c);
        probeOut.setTextSize(13);
        probeOut.setTextColor(Ui.TEXT2);
        probeOut.setPadding(Ui.dp(c, 14), Ui.dp(c, 12), Ui.dp(c, 14), Ui.dp(c, 6));
        probeOut.setText("内核 tokio 真实探针（默认 1.1.1.1:443）· 点「测一次」发起");
        probeCard.addView(probeOut);
        LinearLayout probeBtnWrap = new LinearLayout(c);
        probeBtnWrap.setPadding(Ui.dp(c, 14), 0, Ui.dp(c, 14), Ui.dp(c, 12));
        probeBtnWrap.addView(Ui.primaryButton(c, "测一次", Ui.BLUE, v -> {
            probeOut.setText("探测中…（内核 tokio socket · 真实 DNS + TCP）");
            probeOut.setTextColor(Ui.TEXT2);
            runKernelProbe("1.1.1.1", 443, probeOut);
        }));
        probeCard.addView(probeBtnWrap);
        body.addView(probeCard);
        runKernelProbe("1.1.1.1", 443, probeOut);

        // ===== 内核信息 =====
        body.addView(Ui.groupTitle(c, "内核信息（Rust 实时读数）"));
        LinearLayout mem = Ui.newCard(c);
        mem.addView(Ui.monoBlock(c, s.coreInfo()));
        body.addView(mem);

        body.addView(note(c, "本页为「仪表盘」新样式：状态卡（吞吐 / 出口 IP / 机房·质量·组织 / 暂停）、"
                + "路由卡（线框地球 + 本机→节点→目的地）、网络控制。数据来自 Rust 内核实时读数；"
                + "「真实代理流量」「数据面验证」为真实 socket 字节。液态玻璃默认关闭，底部为悬浮胶囊 dock。"));

        // ---- 秒级刷新 ----
        final int epoch = s.pageEpoch;
        final long[] prev = { s.upBytes(), s.downBytes(), System.currentTimeMillis() };
        final Runnable ticker = new Runnable() {
            @Override public void run() {
                if (s.pageEpoch != epoch) return;
                timerV.setText("  ·  " + AppState.humanDuration(s.uptimeSec()));
                connTxt.setText(s.connected ? "已连接" : "未连接");
                GradientDrawable d2 = new GradientDrawable();
                d2.setShape(GradientDrawable.OVAL);
                d2.setColor(s.connected ? Ui.GREEN : Ui.TEXT3);
                dot.setBackground(d2);
                long now = System.currentTimeMillis();
                long dt = Math.max(1L, now - prev[2]);
                long up = s.upBytes(), down = s.downBytes();
                long rUp = (up - prev[0]) * 1000L / dt;
                long rDn = (down - prev[1]) * 1000L / dt;
                prev[0] = up; prev[1] = down; prev[2] = now;
                upV.setText(AppState.rate(rUp));
                dnV.setText(AppState.rate(rDn));
                upK.setText("↑ 累计 " + AppState.humanBytes(up));
                dnK.setText("↓ 累计 " + AppState.humanBytes(down));
                long[] pv = parseCsv2(RustCore.nativeProxyStats());
                pTx.setText(AppState.humanBytes(pv[0]));
                pRx.setText(AppState.humanBytes(pv[1]));
                body.postDelayed(this, 1000);
            }
        };
        body.postDelayed(ticker, 1000);
        return page(c, body);
    }

    /** 白卡：22 圆角 + 细描边（对齐定稿设计稿）。 */
    private static LinearLayout dashCard(Context c) {
        LinearLayout card = new LinearLayout(c);
        card.setOrientation(LinearLayout.VERTICAL);
        GradientDrawable g = new GradientDrawable();
        g.setColor(Ui.CARD);
        g.setCornerRadius(Ui.dp(c, 22));
        g.setStroke(1, Color.parseColor("#EEEFF2"));
        card.setBackground(g);
        return card;
    }

    /** 小胶囊标签：圆角底 + 文本。 */
    private static TextView pillText(Context c, String text, int fg, int bg) {
        TextView t = new TextView(c);
        t.setText(text);
        t.setTextSize(11.5f);
        t.setTextColor(fg);
        t.setTypeface(Typeface.DEFAULT_BOLD);
        t.setPadding(Ui.dp(c, 9), Ui.dp(c, 4), Ui.dp(c, 9), Ui.dp(c, 4));
        GradientDrawable g = new GradientDrawable();
        g.setColor(bg);
        g.setCornerRadius(Ui.dp(c, 9));
        t.setBackground(g);
        return t;
    }

    /** 路由卡三列之一：小标签 + 主值 + 副值。 */
    private static LinearLayout routeCol(Context c, String label, String value, String sub) {
        LinearLayout col = new LinearLayout(c);
        col.setOrientation(LinearLayout.VERTICAL);
        TextView l = new TextView(c);
        l.setText(label);
        l.setTextSize(11);
        l.setTextColor(Ui.TEXT3);
        col.addView(l);
        TextView v = new TextView(c);
        v.setText(value);
        v.setTextSize(13.5f);
        v.setTypeface(Typeface.DEFAULT_BOLD);
        v.setTextColor(Ui.TEXT);
        v.setSingleLine(true);
        v.setEllipsize(android.text.TextUtils.TruncateAt.END);
        v.setPadding(0, Ui.dp(c, 3), 0, 0);
        col.addView(v);
        TextView subv = new TextView(c);
        subv.setText(sub);
        subv.setTextSize(11);
        subv.setTextColor(Ui.TEXT3);
        subv.setSingleLine(true);
        subv.setEllipsize(android.text.TextUtils.TruncateAt.END);
        col.addView(subv);
        return col;
    }

    /** 路由列之间的「›」分隔。 */
    private static TextView routeArrow(Context c) {
        TextView t = new TextView(c);
        t.setText("›");
        t.setTextSize(18);
        t.setTextColor(Color.parseColor("#C0C0C6"));
        t.setPadding(Ui.dp(c, 2), 0, Ui.dp(c, 2), 0);
        return t;
    }

    /** 节点名 → 旗帜 emoji（中国台湾按中国惯例用 🇨🇳）。 */
    private static String flagEmoji(String name) {
        if (name == null) return "🌐";
        if (name.contains("香港")) return "🇭🇰";
        if (name.contains("东京") || name.contains("日本")) return "🇯🇵";
        if (name.contains("新加坡")) return "🇸🇬";
        if (name.contains("洛杉矶") || name.contains("美国")) return "🇺🇸";
        if (name.contains("台湾")) return "🇨🇳";
        if (name.contains("伦敦") || name.contains("英国")) return "🇬🇧";
        return "🌐";
    }

    /** 截断过长的节点名，用于路由列。 */
    private static String shortName(String name) {
        if (name == null || name.isEmpty()) return "自动选择";
        return name.length() > 10 ? name.substring(0, 9) + "…" : name;
    }

    // ===================== 规则总览（内核真值） =====================
    public static View rules(Context c, Runnable refresh) {
        final AppState s = AppState.get();
        LinearLayout body = Ui.pageBody(c);
        body.addView(Ui.pageHeader(c, "规则", "路由规则 · 来自 Rust 内核索引引擎"));

        int n = 0;
        try { n = RustCore.nativeRuleCount(); } catch (Throwable t) { }
        int cntProxy = 0, cntDirect = 0, cntReject = 0;
        for (int i = 0; i < n; i++) {
            int a = 0;
            try { a = RustCore.nativeRuleAction(i); } catch (Throwable t) { }
            if (a == 1) cntProxy++;
            else if (a == 2) cntReject++;
            else cntDirect++;
        }

        // ===== 概览卡：总数 / 代理 / 直连 / 拒绝 =====
        LinearLayout sum = dashCard(c);
        LinearLayout.LayoutParams slp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        slp.topMargin = Ui.dp(c, 14);
        sum.setLayoutParams(slp);
        sum.setPadding(Ui.dp(c, 18), Ui.dp(c, 15), Ui.dp(c, 18), Ui.dp(c, 15));

        LinearLayout sumTop = new LinearLayout(c);
        sumTop.setOrientation(LinearLayout.HORIZONTAL);
        sumTop.setGravity(Gravity.CENTER_VERTICAL);
        TextView sumLab = new TextView(c);
        sumLab.setText("规则总数");
        sumLab.setTextSize(12.5f);
        sumLab.setTextColor(Ui.TEXT2);
        sumTop.addView(sumLab);
        LinearLayout.LayoutParams plp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        plp.leftMargin = Ui.dp(c, 8);
        TextView sumPill = pillText(c, n > 0 ? "已载入" : "未载入",
                n > 0 ? Ui.GREEN : Ui.TEXT3,
                n > 0 ? Color.parseColor("#1400A94F") : Color.parseColor("#14000000"));
        sumPill.setTextSize(11.5f);
        sumPill.setLayoutParams(plp);
        sumTop.addView(sumPill);
        sum.addView(sumTop);

        TextView sumBig = new TextView(c);
        sumBig.setText(String.valueOf(n));
        sumBig.setTextSize(30);
        sumBig.setTypeface(Typeface.DEFAULT_BOLD);
        sumBig.setTextColor(Ui.TEXT);
        sumBig.setPadding(0, Ui.dp(c, 4), 0, 0);
        sum.addView(sumBig);

        LinearLayout cols = new LinearLayout(c);
        cols.setOrientation(LinearLayout.HORIZONTAL);
        cols.setPadding(0, Ui.dp(c, 10), 0, 0);
        cols.addView(statCol(c, "代理 PROXY", String.valueOf(cntProxy), Ui.BLUE),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        cols.addView(statCol(c, "直连 DIRECT", String.valueOf(cntDirect), Ui.TEXT2),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        cols.addView(statCol(c, "拒绝 REJECT", String.valueOf(cntReject), Ui.RED),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        sum.addView(cols);
        body.addView(sum);

        // ===== 规则明细 =====
        body.addView(Ui.groupTitle(c, "规则明细 · 命中优先级自上而下，首条命中最先生效"));
        LinearLayout list = Ui.newCard(c);
        if (n == 0) {
            list.addView(Ui.row(c, IconView.Glyph.INFO, Ui.TEXT3, "暂无规则",
                    "内核未载入规则集", null, null));
        }
        String[] kindName = {"DOMAIN-SUFFIX", "DOMAIN-KEYWORD", "IP-CIDR"};
        String[] actName = {"直连", "代理", "拒绝"};
        int[] actFg = {Ui.TEXT2, Ui.BLUE, Ui.RED};
        int[] actBg = {Color.parseColor("#14000000"), Color.parseColor("#14007AFF"),
                Color.parseColor("#14FF3B30")};
        IconView.Glyph[] actIcon = {IconView.Glyph.CHECK, IconView.Glyph.GLOBE,
                IconView.Glyph.SHIELD};
        for (int i = 0; i < n; i++) {
            final int idx = i;
            String pattern, kindLabel;
            int action;
            try {
                pattern = RustCore.nativeRulePattern(i);
                int kind = RustCore.nativeRuleKind(i);
                action = RustCore.nativeRuleAction(i);
                kindLabel = kind >= 0 && kind < 3 ? kindName[kind] : "—";
            } catch (Throwable t) {
                pattern = "—"; kindLabel = "—"; action = 0;
            }
            if (action < 0 || action > 2) action = 0;
            final String kL = kindLabel;
            final int act = action;
            TextView tag = pillText(c, actName[action], actFg[action], actBg[action]);
            tag.setTextSize(11);
            list.addView(Ui.row(c, actIcon[action], actFg[action],
                    "#" + (idx + 1) + "  " + pattern,
                    kL + " → " + actName[act], tag,
                    v -> Ui.toast(c, "#" + (idx + 1) + " " + kL
                            + (act == 0 ? " 直连" : act == 1 ? " 代理" : " 拒绝"))));
            if (i != n - 1) list.addView(Ui.separator(c));
        }
        body.addView(list);

        body.addView(note(c, "以上规则由 Rust 内核索引引擎真实持有（反转域名 trie / 关键词分桶 / "
                + "CIDR 最长前缀）。「代理」页的路由测试与这里同源；命中优先级按列表自上而下，"
                + "首条命中生效。"));
        return page(c, body);
    }

    /** 概览卡里的一列：小标签 + 彩色数字。 */
    private static LinearLayout statCol(Context c, String label, String value, int color) {
        LinearLayout col = new LinearLayout(c);
        col.setOrientation(LinearLayout.VERTICAL);
        TextView l = new TextView(c);
        l.setText(label);
        l.setTextSize(11);
        l.setTextColor(Ui.TEXT3);
        col.addView(l);
        TextView v = new TextView(c);
        v.setText(value);
        v.setTextSize(20);
        v.setTypeface(Typeface.DEFAULT_BOLD);
        v.setTextColor(color);
        v.setPadding(0, Ui.dp(c, 2), 0, 0);
        col.addView(v);
        return col;
    }

    // ===================== 代理 =====================

    /** 已解析节点数（0 = 内核未载入配置）。 */
    private static int nodeCount() {
        try { return RustCore.nativeNodeCount(); } catch (Throwable t) { return 0; }
    }

    public static View proxies(Context c, Runnable refresh) {
        final AppState s = AppState.get();
        LinearLayout body = Ui.pageBody(c);
        body.addView(Ui.pageHeader(c, "代理", "代理组 · 节点 · 本地入口"));
        body.addView(proxySummary(c, s));

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
        body.addView(Ui.groupTitle(c, "本地代理入口（PoC-6 · 真实转发）"));
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
                "SOCKS5 → SS 真实转发 · 需 VPN 授权", swEntry, null));

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

    /** 代理页顶部摘要卡：当前节点 + 协议 + 延迟（与仪表盘状态卡同一套白卡语言）。 */
    private static LinearLayout proxySummary(Context c, AppState s) {
        int n = nodeCount();
        String name, server, proto;
        int port, delay;
        if (n > 0) {
            name = RustCore.nativeNodeName(s.selectedNode);
            server = RustCore.nativeNodeServer(s.selectedNode);
            port = RustCore.nativeNodePort(s.selectedNode);
            delay = RustCore.nativeNodeDelay(s.selectedNode);
            proto = AppState.nodeTypeLabel(RustCore.nativeNodeType(s.selectedNode));
        } else {
            int i = Math.max(0, Math.min(s.selectedNode, AppState.NODE_NAMES.length - 1));
            name = AppState.NODE_NAMES[i];
            server = "—";
            port = 0;
            delay = AppState.NODE_LATENCY[i];
            proto = "示例";
        }
        if (name == null) name = "未选择";

        LinearLayout card = dashCard(c);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.topMargin = Ui.dp(c, 14);
        card.setLayoutParams(lp);
        card.setPadding(Ui.dp(c, 18), Ui.dp(c, 15), Ui.dp(c, 18), Ui.dp(c, 15));

        LinearLayout head = new LinearLayout(c);
        head.setOrientation(LinearLayout.HORIZONTAL);
        head.setGravity(Gravity.CENTER_VERTICAL);
        TextView lab = new TextView(c);
        lab.setText("当前节点");
        lab.setTextSize(12.5f);
        lab.setTextColor(Ui.TEXT2);
        head.addView(lab);
        LinearLayout.LayoutParams plp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        plp.leftMargin = Ui.dp(c, 8);
        TextView inUse = pillText(c, "● 使用中", Ui.GREEN, Color.parseColor("#1400A94F"));
        inUse.setTextSize(11.5f);
        inUse.setLayoutParams(plp);
        head.addView(inUse);
        card.addView(head);

        LinearLayout mid = new LinearLayout(c);
        mid.setOrientation(LinearLayout.HORIZONTAL);
        mid.setGravity(Gravity.CENTER_VERTICAL);
        mid.setPadding(0, Ui.dp(c, 10), 0, 0);
        TextView flag = new TextView(c);
        flag.setText(flagEmoji(name));
        flag.setTextSize(24);
        LinearLayout.LayoutParams flp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        flp.rightMargin = Ui.dp(c, 10);
        flag.setLayoutParams(flp);
        mid.addView(flag);

        LinearLayout midCol = new LinearLayout(c);
        midCol.setOrientation(LinearLayout.VERTICAL);
        TextView nm = new TextView(c);
        nm.setText(name);
        nm.setTextSize(19);
        nm.setTypeface(Typeface.DEFAULT_BOLD);
        nm.setTextColor(Ui.TEXT);
        nm.setSingleLine(true);
        nm.setEllipsize(android.text.TextUtils.TruncateAt.END);
        midCol.addView(nm);
        String addr = (port > 0 ? server + ":" + port : server);
        TextView sub = new TextView(c);
        sub.setText(proto + " · " + addr);
        sub.setTextSize(11.5f);
        sub.setTextColor(Ui.TEXT3);
        sub.setSingleLine(true);
        sub.setEllipsize(android.text.TextUtils.TruncateAt.END);
        sub.setPadding(0, Ui.dp(c, 2), 0, 0);
        midCol.addView(sub);
        mid.addView(midCol, new LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f));

        LinearLayout latBox = new LinearLayout(c);
        latBox.setOrientation(LinearLayout.VERTICAL);
        TextView lat = new TextView(c);
        lat.setText(delay < 0 ? "—" : String.valueOf(delay));
        lat.setTextSize(22);
        lat.setTypeface(Typeface.DEFAULT_BOLD);
        lat.setTextColor(AppState.latencyColor(delay));
        lat.setGravity(Gravity.END);
        latBox.addView(lat);
        TextView ms = new TextView(c);
        ms.setText(delay < 0 ? "未测速" : "ms");
        ms.setTextSize(10.5f);
        ms.setTextColor(Ui.TEXT3);
        ms.setGravity(Gravity.END);
        latBox.addView(ms);
        mid.addView(latBox);
        card.addView(mid);

        TextView grp = new TextView(c);
        grp.setText("代理组 " + AppState.GROUPS[Math.max(0,
                Math.min(s.selectedGroup, AppState.GROUPS.length - 1))]);
        grp.setTextSize(11.5f);
        grp.setTextColor(Ui.TEXT2);
        grp.setPadding(0, Ui.dp(c, 10), 0, 0);
        card.addView(grp);
        return card;
    }

    // ===================== 配置 =====================
    public static View profiles(Context c, Runnable refresh) {
        LinearLayout body = Ui.pageBody(c);
        body.addView(Ui.pageHeader(c, "配置", "当前配置 · 订阅管理"));

        int nc0 = nodeCount();
        int rc0 = 0;
        try { rc0 = RustCore.nativeRuleCount(); } catch (Throwable t) { }
        int ic0 = 0;
        try { ic0 = RustCore.nativeIndexNodes(); } catch (Throwable t) { }

        // ===== 当前配置摘要卡 =====
        LinearLayout sum = dashCard(c);
        LinearLayout.LayoutParams slp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        slp.topMargin = Ui.dp(c, 14);
        sum.setLayoutParams(slp);
        sum.setPadding(Ui.dp(c, 18), Ui.dp(c, 15), Ui.dp(c, 18), Ui.dp(c, 15));

        LinearLayout head = new LinearLayout(c);
        head.setOrientation(LinearLayout.HORIZONTAL);
        head.setGravity(Gravity.CENTER_VERTICAL);
        TextView lab = new TextView(c);
        lab.setText("当前配置");
        lab.setTextSize(12.5f);
        lab.setTextColor(Ui.TEXT2);
        head.addView(lab);
        LinearLayout.LayoutParams plp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        plp.leftMargin = Ui.dp(c, 8);
        TextView onPill = pillText(c, "● 已启用", Ui.GREEN, Color.parseColor("#1400A94F"));
        onPill.setTextSize(11.5f);
        onPill.setLayoutParams(plp);
        head.addView(onPill);
        sum.addView(head);

        TextView cfgName = new TextView(c);
        cfgName.setText("默认配置");
        cfgName.setTextSize(24);
        cfgName.setTypeface(Typeface.DEFAULT_BOLD);
        cfgName.setTextColor(Ui.TEXT);
        cfgName.setPadding(0, Ui.dp(c, 6), 0, 0);
        sum.addView(cfgName);

        LinearLayout cols = new LinearLayout(c);
        cols.setOrientation(LinearLayout.HORIZONTAL);
        cols.setPadding(0, Ui.dp(c, 10), 0, 0);
        cols.addView(statCol(c, "节点", String.valueOf(nc0), Ui.BLUE),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        cols.addView(statCol(c, "规则", String.valueOf(rc0), Ui.GREEN),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        cols.addView(statCol(c, "索引节点", String.valueOf(ic0), Ui.TEAL),
                new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        sum.addView(cols);
        body.addView(sum);

        body.addView(Ui.groupTitle(c, "配置信息"));
        LinearLayout cur = Ui.newCard(c);
        cur.addView(Ui.row(c, IconView.Glyph.PROFILE, Ui.BLUE, "本地配置",
                nc0 > 0 ? "Rust 内核已载入节点" : "尚未载入节点", Ui.valueText(c, "默认"), null));
        cur.addView(Ui.separator(c));
        cur.addView(Ui.row(c, IconView.Glyph.CLOCK, Ui.TEXT2, "最近更新",
                "会话内首次解析完成的配置", null, null));
        cur.addView(Ui.separator(c));
        cur.addView(Ui.row(c, IconView.Glyph.LAYERS, Ui.TEAL, "规则引擎",
                "索引 trie / 关键词分桶 / CIDR",
                Ui.valueText(c, ic0 + " 节点"), null));
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
                "0.1.0.14-dev · arm64-v8a", Ui.valueText(c, "Dev"), null));
        about.addView(Ui.separator(c));
        about.addView(Ui.row(c, IconView.Glyph.BOLT, Ui.ORANGE, "构建链",
                "aapt2 / javac / d8 / zipalign / apksigner", null, null));
        body.addView(about);

        body.addView(note(c, "边界：本版内核已含 SOCKS5 入口 + Shadowsocks AEAD 出站真实转发，"
                + "并在 VpnService 授权后接管 TUN fd 读原始 IP 帧；界面上的会话时长与上下行"
                + "仍为内核模拟数据面计数，「真实代理流量」才是真实网卡/代理字节。"
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

    /** 可编辑文本行：左标签 + 右 EditText，失焦/回车时回传文本并落盘。 */
    private static View editRow(Context c, String label, String value,
                                OnValueChange cb) {
        LinearLayout row = new LinearLayout(c);
        row.setOrientation(LinearLayout.VERTICAL);
        row.setPadding(Ui.dp(c, 14), Ui.dp(c, 10), Ui.dp(c, 14), Ui.dp(c, 10));
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

    /** 可编辑文本行的回调：失焦 / 回车时把最新文本交回调用方落盘。 */
    private interface OnValueChange {
        void onChange(String value);
    }

    /** 解析 2 段逗号分隔的 long 序列（tx,rx），缺段补 0。 */
    private static long[] parseCsv2(String s) {
        long[] out = new long[2];
        if (s == null) return out;
        String[] p = s.split(",");
        for (int i = 0; i < 2 && i < p.length; i++) {
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
}
