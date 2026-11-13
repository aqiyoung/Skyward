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
                if (!s.connected || s.pageEpoch != epoch) return;
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
                anchor.postDelayed(this, 1000);
            }
        };
        if (s.connected) anchor.postDelayed(ticker, 1000);

        body.addView(note(c, "说明：连接时长、上传/下载、实时速率、活动连接、规则与内存均由 Rust 内核计算"
                + "（模拟数据面，不接管真实网卡）；节点、配置、订阅为界面演示占位。"));
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
            t.setOnClickListener(v -> { s.selectedGroup = idx; s.save(); refresh.run(); });
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
                    v -> { s.selectedNode = idx; s.save(); refresh.run(); }));
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
                + "选中结果已落盘，重启后保留。真实节点来自订阅解析，属后续阶段。"));
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
        tools.addView(Ui.row(c, IconView.Glyph.DNS, Ui.PURPLE, "DNS 查询",
                "演示入口", null, v -> Ui.toast(c, "DNS 面板未接入")));
        tools.addView(Ui.separator(c));
        tools.addView(Ui.row(c, IconView.Glyph.LIST, Ui.TEXT2, "日志",
                "演示入口", null, v -> Ui.toast(c, "日志面板未接入")));
        body.addView(tools);

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
                v -> Ui.toast(c, "PoC-2 · 会话真值 / 索引引擎版 · 非可用代理客户端")));
        about.addView(Ui.separator(c));
        about.addView(Ui.row(c, IconView.Glyph.SHIELD, Ui.GREEN, "当前版本",
                "0.1.0.8-dev · arm64-v8a", Ui.valueText(c, "Dev"), null));
        about.addView(Ui.separator(c));
        about.addView(Ui.row(c, IconView.Glyph.BOLT, Ui.ORANGE, "构建链",
                "aapt2 / javac / d8 / zipalign / apksigner", null, null));
        body.addView(about);

        body.addView(note(c, "边界：本版仍不含协议栈、geo、订阅解析与真实 tun 转发，不能连代理；"
                + "会话时长与流量是 Rust 内核模拟数据面计数，不是真实网卡字节。"));
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
}
