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

/** 四个页面的内容骨架：首页 / 代理 / 配置 / 我的。纯原生 View，分组卡片边界清晰。 */
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
    public static View home(Context c, Runnable refresh) {
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
                ? "规则模式 · " + AppState.NODE_REGION[s.selectedNode] + " · 演示状态"
                : "点击下方按钮开始 · 演示状态，内核未接管真实流量");
        sub.setTextSize(12);
        sub.setTextColor(Color.parseColor("#CCFFFFFF"));
        sub.setPadding(0, 0, 0, Ui.dp(c, 16));
        hero.addView(sub);

        // 流量/时长三栏
        LinearLayout stats = new LinearLayout(c);
        stats.setOrientation(LinearLayout.HORIZONTAL);
        String[][] cells = s.connected
                ? new String[][]{{"↑ 上传", "186 MB"}, {"↓ 下载", "1.24 GB"}, {"运行时长", "00:42:18"}}
                : new String[][]{{"↑ 上传", "—"}, {"↓ 下载", "—"}, {"运行时长", "—"}};
        for (String[] cell : cells) {
            LinearLayout col = new LinearLayout(c);
            col.setOrientation(LinearLayout.VERTICAL);
            col.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
            TextView v = new TextView(c);
            v.setText(cell[1]);
            v.setTextSize(16);
            v.setTypeface(Typeface.DEFAULT_BOLD);
            v.setTextColor(Color.WHITE);
            TextView k = new TextView(c);
            k.setText(cell[0]);
            k.setTextSize(11);
            k.setTextColor(Color.parseColor("#B8FFFFFF"));
            col.addView(v); col.addView(k);
            stats.addView(col);
        }
        hero.addView(stats);

        TextView btn = Ui.primaryButton(c, s.connected ? "断开连接" : "连接",
                s.connected ? Color.parseColor("#FFFFFF") : Color.parseColor("#007AFF"),
                v -> {
                    s.connected = !s.connected;
                    s.connectSinceMs = s.connected ? System.currentTimeMillis() : 0L;
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
        swSys.setOnCheckedChangeListener((b, on) -> s.systemProxy = on);
        ctrl.addView(Ui.row(c, IconView.Glyph.SWITCH, Ui.BLUE, "系统代理",
                "演示开关 · 不修改系统设置", swSys, null));
        ctrl.addView(Ui.separator(c));
        Switch swTun = Ui.toggle(c, s.tunMode);
        swTun.setOnCheckedChangeListener((b, on) -> s.tunMode = on);
        ctrl.addView(Ui.row(c, IconView.Glyph.TUN, Ui.PURPLE, "TUN 模式",
                "PoC 未建立真实 tun，开关仅作界面占位", swTun, null));
        body.addView(ctrl);

        body.addView(Ui.groupTitle(c, "网络概览"));
        LinearLayout net = Ui.newCard(c);
        net.addView(Ui.row(c, IconView.Glyph.ARROW_UP, Ui.GREEN, "实时上传",
                "演示数值", Ui.valueText(c, s.connected ? "128 KB/s" : "0 KB/s"), null));
        net.addView(Ui.separator(c));
        net.addView(Ui.row(c, IconView.Glyph.ARROW_DOWN, Ui.BLUE, "实时下载",
                "演示数值", Ui.valueText(c, s.connected ? "1.8 MB/s" : "0 KB/s"), null));
        net.addView(Ui.separator(c));
        net.addView(Ui.row(c, IconView.Glyph.LIST, Ui.ORANGE, "活动连接",
                "来自 Rust 连接表", Ui.valueText(c, RustCore.nativeConnCount() + " 条"), null));
        body.addView(net);

        body.addView(Ui.groupTitle(c, "路由与配置"));
        LinearLayout route = Ui.newCard(c);
        route.addView(Ui.row(c, IconView.Glyph.ROUTE, Ui.TEAL, "路由模式",
                "点击切换", Ui.valueText(c, s.ruleModeLabel()),
                v -> { s.ruleMode = (s.ruleMode + 1) % 3; refresh.run(); }));
        route.addView(Ui.separator(c));
        route.addView(Ui.row(c, IconView.Glyph.LAYERS, Ui.BLUE, "代理组",
                AppState.GROUPS[s.selectedGroup] + " · 演示", null,
                v -> Ui.toast(c, "代理组列表请到「代理」页查看")));
        route.addView(Ui.separator(c));
        route.addView(Ui.row(c, IconView.Glyph.PROFILE, Ui.ORANGE, "当前配置",
                "本地配置 · 已启用 · 2 个订阅", Ui.valueText(c, "演示"), null));
        body.addView(route);

        body.addView(Ui.groupTitle(c, "内核信息（Rust 实时读数）"));
        LinearLayout mem = Ui.newCard(c);
        mem.addView(Ui.monoBlock(c, s.coreInfo()));
        body.addView(mem);

        body.addView(note(c, "说明：状态、流量、节点、配置均为界面演示数据；"
                + "本版 Rust 内核只跑规则/连接表/数据面模拟，未接管真实流量。内核信息栏为 JNI 真值。"));
        return page(c, body);
    }

    // ===================== 代理 =====================
    public static View proxies(Context c, Runnable refresh) {
        final AppState s = AppState.get();
        LinearLayout body = Ui.pageBody(c);
        body.addView(Ui.pageHeader(c, "代理", "代理组 · 节点延迟"));

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
            t.setOnClickListener(v -> { s.selectedGroup = idx; refresh.run(); });
            tabs.addView(t);
        }
        android.widget.HorizontalScrollView hs = new android.widget.HorizontalScrollView(c);
        hs.setHorizontalScrollBarEnabled(false);
        hs.addView(tabs);
        body.addView(hs);

        body.addView(Ui.groupTitle(c, AppState.GROUPS[s.selectedGroup] + " · 节点列表（演示）"));
        LinearLayout list = Ui.newCard(c);
        for (int i = 0; i < AppState.NODE_NAMES.length; i++) {
            final int idx = i;
            int ms = AppState.NODE_LATENCY[i];
            TextView lat = new TextView(c);
            lat.setText(AppState.latencyLabel(ms));
            lat.setTextSize(13);
            lat.setTextColor(AppState.latencyColor(ms));
            lat.setTypeface(Typeface.DEFAULT_BOLD);
            View trailing = (i == s.selectedNode)
                    ? new IconView(c, IconView.Glyph.CHECK, Ui.BLUE) : lat;
            if (i == s.selectedNode) {
                trailing.setLayoutParams(new LinearLayout.LayoutParams(Ui.dp(c, 20), Ui.dp(c, 20)));
            }
            list.addView(Ui.row(c, IconView.Glyph.GLOBE,
                    AppState.latencyColor(ms),
                    AppState.NODE_NAMES[i],
                    AppState.NODE_REGION[i] + " · " + AppState.latencyLabel(ms),
                    trailing,
                    v -> { s.selectedNode = idx; refresh.run(); }));
            if (i != AppState.NODE_NAMES.length - 1) list.addView(Ui.separator(c));
        }
        body.addView(list);

        body.addView(Ui.groupTitle(c, "代理组设置"));
        LinearLayout gset = Ui.newCard(c);
        gset.addView(Ui.row(c, IconView.Glyph.CHART, Ui.GREEN, "按延迟着色",
                "绿 < 80ms · 橙 < 150ms · 红 ≥ 150ms", null, null));
        gset.addView(Ui.separator(c));
        gset.addView(Ui.row(c, IconView.Glyph.CLOCK, Ui.ORANGE, "延迟测速",
                "演示入口 · 未发起真实探测", null,
                v -> Ui.toast(c, "PoC 阶段未接入真实延迟探测")));
        body.addView(gset);

        body.addView(note(c, "节点与延迟为演示数据，用于验证列表骨架与选中交互；"
                + "真实节点来自订阅解析，属后续阶段。"));
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
        body.addView(cur);

        body.addView(Ui.groupTitle(c, "订阅（演示）"));
        LinearLayout subs = Ui.newCard(c);
        String[][] items = {
                {"订阅 A · 主线路", "8 个节点 · 2 小时前更新 · 演示"},
                {"订阅 B · 备用", "5 个节点 · 昨天更新 · 演示"},
        };
        for (int i = 0; i < items.length; i++) {
            subs.addView(Ui.row(c, IconView.Glyph.GLOBE, i == 0 ? Ui.GREEN : Ui.TEAL,
                    items[i][0], items[i][1], null,
                    v -> Ui.toast(c, "订阅解析未接入，本版为界面占位")));
            if (i != items.length - 1) subs.addView(Ui.separator(c));
        }
        body.addView(subs);

        body.addView(Ui.groupTitle(c, "添加"));
        LinearLayout add = Ui.newCard(c);
        add.addView(Ui.row(c, IconView.Glyph.PLUS, Ui.BLUE, "添加订阅",
                "从链接导入 · 演示入口", null,
                v -> Ui.toast(c, "订阅导入未接入，本版为界面占位")));
        add.addView(Ui.separator(c));
        add.addView(Ui.row(c, IconView.Glyph.PROFILE, Ui.ORANGE, "新建配置",
                "本地空白配置 · 演示入口", null,
                v -> Ui.toast(c, "配置编辑未接入，本版为界面占位")));
        body.addView(add);

        body.addView(note(c, "配置与订阅均为界面演示数据；真实解析、落盘与切换属后续阶段。"));
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
                "点击切换", Ui.valueText(c, s.themeLabel()),
                v -> { s.themeMode = (s.themeMode + 1) % 3; refresh.run(); }));
        appearance.addView(Ui.separator(c));
        appearance.addView(Ui.row(c, IconView.Glyph.HOME, Ui.BLUE, "语言",
                "简体中文", Ui.valueText(c, "跟随系统"), null));
        appearance.addView(Ui.separator(c));
        Switch swGlass = Ui.toggle(c, s.liquidGlass);
        swGlass.setOnCheckedChangeListener((b, on) -> {
            s.liquidGlass = on;
            refresh.run();   // 重绘：卡片转半透明 + 页面底色转冷
            Ui.toast(c, on ? "液态玻璃：开" : "液态玻璃：关（默认）");
        });
        appearance.addView(Ui.row(c, IconView.Glyph.LAYERS, Ui.TEAL, "液态玻璃效果",
                "默认关闭 · 需手动开启", swGlass, null));
        body.addView(appearance);

        body.addView(Ui.groupTitle(c, "通用与内核"));
        LinearLayout general = Ui.newCard(c);
        general.addView(Ui.row(c, IconView.Glyph.ROUTE, Ui.ORANGE, "路由模式",
                "点击切换", Ui.valueText(c, s.ruleModeLabel()),
                v -> { s.ruleMode = (s.ruleMode + 1) % 3; refresh.run(); }));
        general.addView(Ui.separator(c));
        Switch swV6 = Ui.toggle(c, s.ipv6);
        swV6.setOnCheckedChangeListener((b, on) -> s.ipv6 = on);
        general.addView(Ui.row(c, IconView.Glyph.GLOBE, Ui.BLUE, "IPv6",
                "演示开关", swV6, null));
        general.addView(Ui.separator(c));
        Switch swAuto = Ui.toggle(c, s.autoUpdate);
        swAuto.setOnCheckedChangeListener((b, on) -> s.autoUpdate = on);
        general.addView(Ui.row(c, IconView.Glyph.ARROW_DOWN, Ui.GREEN, "订阅自动更新",
                "演示开关", swAuto, null));
        general.addView(Ui.separator(c));
        general.addView(Ui.row(c, IconView.Glyph.MEMORY, Ui.TEAL, "内核版本",
                "Rust core（JNI 实时）", Ui.valueText(c, "v" + RustCore.nativeVersion()), null));
        body.addView(general);

        body.addView(Ui.groupTitle(c, "工具"));
        LinearLayout tools = Ui.newCard(c);
        tools.addView(Ui.row(c, IconView.Glyph.CHART, Ui.BLUE, "性能基准",
                "按需运行 · 分段刷新，不再启动时全量跑", null,
                v -> Ui.toast(c, "请点下方「运行性能基准」按钮")));
        tools.addView(Ui.separator(c));
        tools.addView(Ui.row(c, IconView.Glyph.LIST, Ui.ORANGE, "实时连接",
                "演示入口", null, v -> Ui.toast(c, "连接面板未接入")));
        tools.addView(Ui.separator(c));
        tools.addView(Ui.row(c, IconView.Glyph.DNS, Ui.PURPLE, "DNS 查询",
                "演示入口", null, v -> Ui.toast(c, "DNS 面板未接入")));
        tools.addView(Ui.separator(c));
        tools.addView(Ui.row(c, IconView.Glyph.LIST, Ui.TEXT2, "日志",
                "演示入口", null, v -> Ui.toast(c, "日志面板未接入")));
        body.addView(tools);

        // 基准区：按需点击、子线程分段执行、逐段回刷 UI
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

        body.addView(Ui.groupTitle(c, "关于"));
        LinearLayout about = Ui.newCard(c);
        about.addView(Ui.row(c, IconView.Glyph.INFO, Ui.BLUE, "关于 Skyward",
                "Rust 内核 + 原生 Android 壳", null,
                v -> Ui.toast(c, "PoC-2 UI 骨架版 · 非可用代理客户端")));
        about.addView(Ui.separator(c));
        about.addView(Ui.row(c, IconView.Glyph.SHIELD, Ui.GREEN, "当前版本",
                "0.1.0-dev · arm64-v8a", Ui.valueText(c, "Dev"), null));
        about.addView(Ui.separator(c));
        about.addView(Ui.row(c, IconView.Glyph.BOLT, Ui.ORANGE, "构建链",
                "aapt2 / javac / d8 / zipalign / apksigner", null, null));
        body.addView(about);

        body.addView(note(c, "边界：本版仍不含协议栈、geo、订阅解析与真实 tun 转发，不能连代理；"
                + "此页用于验证设置中心分组、开关与基准交互。"));
        return page(c, body);
    }

    /** 基准：规模下调 + 子线程分段 + 逐段 post，避免 ANR 与长期空白。 */
    private static void runBench(Context c, TextView btn, TextView out) {
        btn.setEnabled(false);
        btn.setText("运行中…");
        out.setText("starting...\n");
        new Thread(() -> {
            StringBuilder b = new StringBuilder();
            try {
                int ver = RustCore.nativeVersion();
                long warmUs = RustCore.nativeInitNs() / 1000;
                b.append(String.format(Locale.getDefault(),
                        "== 内核 ==\ncore version   : %d\n首次 JNI 冷启动: %,d us\nno GC / no runtime / no VM\n\n",
                        ver, warmUs));
            } catch (Throwable t) {
                b.append("内核调用失败: ").append(t).append('\n');
            }
            post(out, b.toString());

            int[][] stages = {{9, 200000}, {1000, 50000}, {10000, 5000}};
            b.append("== 规则引擎（Rust，含 Mutex 查表）==\n");
            post(out, b.toString());
            for (int[] st : stages) {
                try {
                    RustCore.nativeLoadRules(st[0]);
                    double ms = RustCore.nativeBenchMatches(st[1]);
                    double mops = (st[1] / 1e6) / (ms / 1000.0);
                    b.append(String.format(Locale.getDefault(),
                            "rules=%-6d %8.2f ms  %8.2f Mops/s\n", st[0], ms, mops));
                } catch (Throwable t) {
                    b.append("stage failed: ").append(t).append('\n');
                }
                post(out, b.toString());
            }

            try {
                RustCore.nativeLoadRules(1000);
                double pms = RustCore.nativeBenchPackets(100000, 1500);
                b.append(String.format(Locale.getDefault(),
                        "\n== 数据面（内存模拟，不接管 tun）==\n100000 x 1500 B = 143.1 MB\n%8.2f ms  %.2f Mpps  %.2f GB/s\n",
                        pms, (100000 / 1e6) / (pms / 1000.0),
                        (100000.0 * 1500 / 1e9) / (pms / 1000.0)));
                b.append(String.format(Locale.getDefault(),
                        "connections : %d\n", RustCore.nativeConnCount()));
            } catch (Throwable t) {
                b.append("packet stage failed: ").append(t).append('\n');
            }
            try {
                b.append(String.format(Locale.getDefault(),
                        "\n== 内存 ==\nprocess RSS        : %.2f MB\nRust logical state: %,d B\n",
                        RustCore.nativeRssBytes() / 1048576.0, RustCore.nativeLogicalBytes()));
            } catch (Throwable t) {
                b.append("mem read failed: ").append(t).append('\n');
            }
            b.append("\nDONE · 规模已下调（最高 1 万规则 / 5 千次），避免真机卡顿。");
            post(out, b.toString());
            MAIN.post(() -> { btn.setEnabled(true); btn.setText("运行性能基准"); });
        }, "bench").start();
    }

    private static void post(TextView out, String text) {
        MAIN.post(() -> out.setText(text));
    }
}
