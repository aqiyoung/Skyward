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

/** 跨页面复用的原生控件构造器：卡片、分隔线、键值行、速率列、服务格、树形行等。
 * 页面类只负责「摆哪些控件」，尺寸与配色统一收在这里，避免五页各写一套。 */
public final class Widgets {
    private Widgets() {}

    /** 主线程回调，供各页做延迟刷新。 */
    static final Handler MAIN = new Handler(Looper.getMainLooper());

    static ScrollView page(Context c, LinearLayout body) {
        ScrollView sv = new ScrollView(c);
        sv.setFillViewport(true);
        sv.setVerticalScrollBarEnabled(false);
        sv.addView(body, new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        return sv;
    }

    static TextView note(Context c, String text) {
        TextView t = new TextView(c);
        t.setText(text);
        t.setTextSize(11.5f);
        t.setTextColor(Ui.TEXT3);
        t.setPadding(Ui.dp(c, 4), Ui.dp(c, 8), Ui.dp(c, 4), 0);
        t.setLineSpacing(Ui.dp(c, 2), 1f);
        return t;
    }

    static LinearLayout lcard(Context c) {
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

    static LinearLayout.LayoutParams cardGap(Context c) {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.topMargin = Ui.dp(c, 8);
        return lp;
    }

    static LinearLayout cardHead(Context c, IconView.Glyph glyph, String title,
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

    static LinearLayout svcCell(Context c, IconView.Glyph glyph, String name,
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

    static GradientDrawable chipBg(Context c, String hex) {
        GradientDrawable g = new GradientDrawable();
        g.setColor(Color.parseColor(hex));
        g.setCornerRadius(Ui.dp(c, 8));
        return g;
    }

    static TextView chip(Context c, String text, int fg, int bgColor) {
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

    static LinearLayout rateCol(Context c, boolean up,
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

    static LinearLayout tile(Context c, String title, String sub) {
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

    static LinearLayout rcol(Context c, String label, String value, String sub) {
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

    static TextView rarrow(Context c) {
        TextView t = new TextView(c);
        t.setText("›");
        t.setTextSize(18);
        t.setTextColor(Color.parseColor("#C0C0C6"));
        t.setPadding(Ui.dp(c, 2), 0, Ui.dp(c, 2), 0);
        return t;
    }

    static String shortName(String name) {
        if (name == null || name.isEmpty()) return "自动选择";
        return name.length() > 10 ? name.substring(0, 9) + "…" : name;
    }

    static LinearLayout kvLive(Context c, String label, TextView[] sink, int idx) {
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

    static LinearLayout kv(Context c, String label, String value) {
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

    static String humanK(long v) {
        if (v < 1000L) return String.valueOf(v);
        if (v < 1_000_000L) return String.format(Locale.getDefault(), "%.1fK", v / 1000.0);
        return String.format(Locale.getDefault(), "%.2fM", v / 1_000_000.0);
    }

    static long safeLong(String s) {
        try { return Long.parseLong(s.trim()); } catch (Throwable t) { return 0; }
    }

    static int nodeCount() {
        try { return RustCore.nativeNodeCount(); } catch (Throwable t) { return 0; }
    }

    static void post(TextView out, String text) {
        MAIN.post(() -> out.setText(text));
    }
}
