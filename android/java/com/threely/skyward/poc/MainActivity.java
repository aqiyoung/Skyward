package com.threely.skyward.poc;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Process;
import android.view.Gravity;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

/**
 * PoC-1 主界面：纯原生 View，无 XML 布局、无 Compose、无 Flutter。
 * 只负责展示 Rust 内核的实测数字，Java 侧不含任何业务逻辑。
 */
public class MainActivity extends Activity {

    private TextView out;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(28, 40, 28, 28);
        root.setBackgroundColor(Color.parseColor("#F7F8FA"));

        TextView title = new TextView(this);
        title.setText("Skyward · Rust Core PoC-1");
        title.setTextSize(20);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        title.setTextColor(Color.parseColor("#1A1A1A"));
        root.addView(title);

        TextView sub = new TextView(this);
        sub.setText("Rust 内核 + 原生 Android 壳（零 UI 运行时）");
        sub.setTextSize(13);
        sub.setTextColor(Color.parseColor("#6B7280"));
        sub.setPadding(0, 6, 0, 20);
        root.addView(sub);

        Button run = new Button(this);
        run.setText("运行基准测试");
        run.setAllCaps(false);
        root.addView(run);

        out = new TextView(this);
        out.setTextSize(13);
        out.setTypeface(Typeface.MONOSPACE);
        out.setTextColor(Color.parseColor("#111827"));
        out.setPadding(0, 24, 0, 0);
        out.setGravity(Gravity.START);

        ScrollView scroll = new ScrollView(this);
        scroll.addView(out);
        root.addView(scroll);

        setContentView(root);
        run.setOnClickListener(v -> runBench());
        runBench();
    }

    private void runBench() {
        out.setText("running...\n");
        new Thread(() -> {
            StringBuilder b = new StringBuilder();

            // 冷启动：首次 JNI 调用会触发 Rust OnceLock 初始化
            long t0 = System.nanoTime();
            int version = RustCore.nativeVersion();
            long warmNs = System.nanoTime() - t0;
            long initNs = RustCore.nativeInitNs();

            b.append("== 内核 ==\n");
            b.append(String.format("core version      : %d%n", version));
            b.append(String.format("Rust init         : %,.0f us%n", initNs / 1000.0));
            b.append(String.format("first JNI call    : %,.0f us%n", warmNs / 1000.0));
            b.append("no GC / no runtime / no VM\n\n");

            // 规则引擎吞吐
            b.append("== 规则引擎（Rust，含 Mutex 查表）==\n");
            int[] ruleSizes = {9, 1000, 10000, 50000};
            int iters = 200000;
            for (int n : ruleSizes) {
                RustCore.nativeLoadRules(n);
                double ms = RustCore.nativeBenchMatches(iters);
                b.append(String.format(
                        "rules=%-6d %8.2f ms  %8.2f Mops/s%n",
                        n, ms, (iters / 1e6) / (ms / 1000.0)));
            }
            b.append('\n');

            // 数据面模拟吞吐
            int packets = 1_000_000;
            int size = 1500;
            RustCore.nativeLoadRules(1000);
            double pms = RustCore.nativeBenchPackets(packets, size);
            b.append("== 数据面（内存模拟，不接管 tun）==\n");
            b.append(String.format("%d x %d B = %.1f MB%n", packets, size,
                    packets * size / 1048576.0));
            b.append(String.format("%8.2f ms  %.2f Mpps  %.2f GB/s%n",
                    pms, (packets / 1e6) / (pms / 1000.0),
                    (packets * (double) size / 1e9) / (pms / 1000.0)));
            b.append(String.format("connections       : %d%n", RustCore.nativeConnCount()));
            b.append(String.format("loopback bytes    : %d%n\n", RustCore.nativeLoopbackBytes()));

            // 内存
            long rss = RustCore.nativeRssBytes();
            long logical = RustCore.nativeLogicalBytes();
            int pid = Process.myPid();
            android.app.ActivityManager am =
                    (android.app.ActivityManager) getSystemService(ACTIVITY_SERVICE);
            android.os.Debug.MemoryInfo[] mem =
                    am.getProcessMemoryInfo(new int[]{pid});
            long pssKb = mem.length > 0 ? mem[0].getTotalPss() : 0;

            b.append("== 内存 ==\n");
            b.append(String.format("process RSS       : %.2f MB%n", rss / 1048576.0));
            b.append(String.format("process PSS       : %.2f MB%n", pssKb / 1024.0));
            b.append(String.format("Rust logical state: %d B%n", logical));
            b.append("(Go 内核基线: 常驻 runtime + GC 显著更高)\n\n");

            b.append("== 体积基线（对照现行 Flutter 版）==\n");
            b.append("Flutter+Go  : 60.30 MB\n");
            b.append("  Go core   : 23.62 MB\n");
            b.append("  Flutter   : 11.72 MB\n");
            b.append("  geo data  : 15.55 MB\n");
            b.append("本 PoC 不含 geo / 内核协议栈，\n");
            b.append("仅用于量架构开销，见报告。\n");

            final String text = b.toString();
            runOnUiThread(() -> out.setText(text));
        }, "bench").start();
    }
}
