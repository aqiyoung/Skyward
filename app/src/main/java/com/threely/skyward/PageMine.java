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

/** 我的页：会话真值、内核基准、诊断工具。 */
public final class PageMine {
    private PageMine() {}

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

    static void runBench(Context c, TextView btn, TextView out) {
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

    static long[] parseCsv9(String s) {
        long[] out = new long[9];
        if (s == null) return out;
        String[] p = s.split(",");
        for (int i = 0; i < 9 && i < p.length; i++) {
            try { out[i] = Long.parseLong(p[i].trim()); } catch (Throwable t) { out[i] = 0; }
        }
        return out;
    }

    static void runKernelProbe(final String host, final int port, final TextView out) {
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

    static void applyProbeResult(TextView out, String csv) {
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
}
