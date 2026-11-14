package com.threely.skyward.poc;

import android.content.Context;
import android.os.Build;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * 崩溃兜底：把未捕获异常的堆栈写到应用私有目录，下次启动可在「我的 → 关于」查看。
 * 只做记录，不吞异常（仍交给系统默认处理器），避免掩盖真实问题。
 */
public final class CrashGuard {

    private CrashGuard() {}

    private static File file(Context c) {
        File dir = c.getExternalFilesDir(null);
        if (dir == null) dir = c.getFilesDir();
        return new File(dir, "last-crash.txt");
    }

    public static void install(final Context app) {
        final Thread.UncaughtExceptionHandler prev = Thread.getDefaultUncaughtExceptionHandler();
        Thread.setDefaultUncaughtExceptionHandler((t, e) -> {
            try {
                StringWriter sw = new StringWriter();
                PrintWriter pw = new PrintWriter(sw);
                pw.println("time=" + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
                        .format(new Date()));
                pw.println("thread=" + t.getName()
                        + " sdk=" + Build.VERSION.SDK_INT
                        + " device=" + Build.MANUFACTURER + " " + Build.MODEL
                        + " pkg=" + app.getPackageName());
                e.printStackTrace(pw);
                pw.flush();
                File f = file(app);
                try (FileWriter fw = new FileWriter(f, false)) {
                    fw.write(sw.toString());
                }
            } catch (Throwable ignored) {
                // 记录失败不影响原始崩溃处理
            }
            if (prev != null) prev.uncaughtException(t, e);
        });
    }

    /** 最近一次崩溃堆栈（没有则返回空串）。 */
    public static String last(Context c) {
        try {
            File f = file(c);
            if (!f.exists() || f.length() == 0) return "";
            int n = (int) Math.min(f.length(), 12000);
            byte[] b = new byte[n];
            try (FileInputStream in = new FileInputStream(f)) {
                int off = 0;
                while (off < n) {
                    int r = in.read(b, off, n - off);
                    if (r <= 0) break;
                    off += r;
                }
            }
            return new String(b, "UTF-8");
        } catch (Throwable t) {
            return "";
        }
    }

    public static void clear(Context c) {
        try {
            File f = file(c);
            if (f.exists()) f.delete();
        } catch (Throwable ignored) {
        }
    }
}
