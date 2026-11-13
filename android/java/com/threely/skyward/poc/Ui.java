package com.threely.skyward.poc;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.RippleDrawable;
import android.content.res.ColorStateList;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

/** 通用 UI 构建器：iOS 分组卡片风格，纯代码布局，零 XML / 零资源 / 零依赖。 */
public final class Ui {

    // 页面与卡片（对齐既有 4tab 原型的 iOS 色板）
    public static final int PAGE      = Color.parseColor("#F2F2F7");
    public static final int CARD      = Color.parseColor("#FFFFFF");
    public static final int TONE      = Color.parseColor("#F2F2F7");
    public static final int SEP       = Color.parseColor("#E5E5EA");
    public static final int TEXT      = Color.parseColor("#1C1C1E");
    public static final int TEXT2     = Color.parseColor("#6E6E73");
    public static final int TEXT3     = Color.parseColor("#8E8E93");
    public static final int BLUE      = Color.parseColor("#007AFF");
    public static final int GREEN     = Color.parseColor("#00A94F");
    public static final int ORANGE    = Color.parseColor("#FF9F0A");
    public static final int RED       = Color.parseColor("#FF3B30");
    public static final int PURPLE    = Color.parseColor("#AF52DE");
    public static final int TEAL      = Color.parseColor("#30B0C7");

    private Ui() {}

    public static int dp(Context c, float v) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v,
                c.getResources().getDisplayMetrics());
    }

    public static float sp(Context c, float v) { return v; }

    /** 分组卡片背景：默认不透明白 + 细描边，保证模块边界可区分（玻璃默认关闭）。
     *  手动开启液态玻璃后改为半透明 + 高光描边，透出页面冷色底。 */
    public static GradientDrawable cardBg(Context c) {
        GradientDrawable g = new GradientDrawable();
        boolean glass = AppState.get().liquidGlass;
        g.setColor(glass ? Color.parseColor("#E6FFFFFF") : CARD);
        g.setCornerRadius(dp(c, 14));
        g.setStroke(1, glass ? Color.parseColor("#99FFFFFF") : Color.parseColor("#E8E8ED"));
        return g;
    }

    /** 页面头部：iOS Large Title + 副标题。 */
    public static LinearLayout pageHeader(Context c, String title, String sub) {
        LinearLayout box = new LinearLayout(c);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(c, 20), dp(c, 8), dp(c, 20), dp(c, 6));
        TextView t = new TextView(c);
        t.setText(title);
        t.setTextSize(28);
        t.setTypeface(Typeface.DEFAULT_BOLD);
        t.setTextColor(TEXT);
        box.addView(t);
        TextView s = new TextView(c);
        s.setText(sub);
        s.setTextSize(12.5f);
        s.setTextColor(TEXT2);
        s.setPadding(0, dp(c, 3), 0, 0);
        box.addView(s);
        return box;
    }

    /** 分组标题（卡片上方的小字）。 */
    public static TextView groupTitle(Context c, String text) {
        TextView t = new TextView(c);
        t.setText(text);
        t.setTextSize(12.5f);
        t.setTypeface(Typeface.DEFAULT_BOLD);
        t.setTextColor(TEXT2);
        t.setPadding(dp(c, 4), dp(c, 18), dp(c, 4), dp(c, 7));
        return t;
    }

    public static LinearLayout newCard(Context c) {
        LinearLayout card = new LinearLayout(c);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setBackground(cardBg(c));
        return card;
    }

    /** 行内分隔线，左缩进对齐文字。 */
    public static View separator(Context c) {
        View v = new View(c);
        v.setBackgroundColor(SEP);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 1);
        lp.leftMargin = dp(c, 56);
        v.setLayoutParams(lp);
        return v;
    }

    /** 图标井：28dp 浅色圆角底 + 线性图标。 */
    public static FrameLayout iconWell(Context c, IconView.Glyph glyph, int tint) {
        FrameLayout well = new FrameLayout(c);
        int size = dp(c, 30);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(size, size);
        lp.rightMargin = dp(c, 12);
        well.setLayoutParams(lp);
        GradientDrawable g = new GradientDrawable();
        g.setColor(Color.parseColor("#F0F0F5"));
        g.setCornerRadius(dp(c, 8));
        well.setBackground(g);
        IconView iv = new IconView(c, glyph, tint);
        int icon = dp(c, 19);
        FrameLayout.LayoutParams ip = new FrameLayout.LayoutParams(icon, icon);
        ip.gravity = Gravity.CENTER;
        iv.setLayoutParams(ip);
        well.addView(iv);
        return well;
    }

    /** 标准设置行：图标 + 标题/副标题 + 右侧控件。 */
    public static LinearLayout row(Context c, IconView.Glyph glyph, int tint,
                                   String title, String subtitle, View trailing,
                                   View.OnClickListener click) {
        LinearLayout r = new LinearLayout(c);
        r.setOrientation(LinearLayout.HORIZONTAL);
        r.setGravity(Gravity.CENTER_VERTICAL);
        r.setMinimumHeight(dp(c, 52));
        r.setPadding(dp(c, 14), dp(c, 10), dp(c, 14), dp(c, 10));

        r.addView(iconWell(c, glyph, tint));

        LinearLayout textCol = new LinearLayout(c);
        textCol.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams tlp = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        textCol.setLayoutParams(tlp);
        TextView tv = new TextView(c);
        tv.setText(title);
        tv.setTextSize(15);
        tv.setTextColor(TEXT);
        textCol.addView(tv);
        if (subtitle != null && !subtitle.isEmpty()) {
            TextView sv = new TextView(c);
            sv.setText(subtitle);
            sv.setTextSize(11.5f);
            sv.setTextColor(TEXT3);
            sv.setPadding(0, dp(c, 2), 0, 0);
            textCol.addView(sv);
        }
        r.addView(textCol);

        if (trailing == null) {
            trailing = chevron(c);
        }
        r.addView(trailing);

        if (click != null) {
            GradientDrawable mask = new GradientDrawable();
            mask.setColor(Color.WHITE);   // mask 取 alpha 通道定形，必须不透明
            mask.setCornerRadius(dp(c, 12));
            RippleDrawable ripple = new RippleDrawable(
                    ColorStateList.valueOf(Color.parseColor("#22000000")), null, mask);
            r.setBackground(ripple);
            r.setClickable(true);
            if (trailing instanceof Switch) {
                final Switch sw = (Switch) trailing;
                r.setOnClickListener(v -> {
                    sw.setChecked(!sw.isChecked());
                    if (click != null) click.onClick(v);
                });
            } else {
                r.setOnClickListener(click);
            }
        }
        return r;
    }

    public static IconView chevron(Context c) {
        IconView iv = new IconView(c, IconView.Glyph.CHEVRON, TEXT3);
        int s = dp(c, 18);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(s, s);
        iv.setLayoutParams(lp);
        return iv;
    }

    public static TextView valueText(Context c, String text) {
        TextView t = new TextView(c);
        t.setText(text);
        t.setTextSize(13.5f);
        t.setTextColor(TEXT3);
        t.setPadding(dp(c, 6), 0, 0, 0);
        return t;
    }

    public static Switch toggle(Context c, boolean on) {
        Switch s = new Switch(c);
        s.setChecked(on);
        s.setThumbTintList(ColorStateList.valueOf(Color.WHITE));
        return s;
    }

    public static TextView primaryButton(Context c, String text, int bg, View.OnClickListener click) {
        TextView b = new TextView(c);
        b.setText(text);
        b.setTextSize(15);
        b.setTypeface(Typeface.DEFAULT_BOLD);
        b.setTextColor(Color.WHITE);
        b.setGravity(Gravity.CENTER);
        b.setPadding(dp(c, 16), dp(c, 13), dp(c, 16), dp(c, 13));
        GradientDrawable g = new GradientDrawable();
        g.setColor(bg);
        g.setCornerRadius(dp(c, 13));
        b.setBackground(g);
        b.setClickable(true);
        b.setOnClickListener(click);
        return b;
    }

    /** 等宽文本块（基准结果 / 内核读数）。 */
    public static TextView monoBlock(Context c, String text) {
        TextView t = new TextView(c);
        t.setText(text);
        t.setTextSize(11.5f);
        t.setTypeface(Typeface.MONOSPACE);
        t.setTextColor(TEXT);
        t.setPadding(dp(c, 14), dp(c, 12), dp(c, 14), dp(c, 12));
        t.setLineSpacing(dp(c, 3), 1f);
        return t;
    }

    public static void toast(Context c, String msg) {
        Toast.makeText(c, msg, Toast.LENGTH_SHORT).show();
    }

    /** 页面根容器：可滚动的分组列表。 */
    public static LinearLayout pageBody(Context c) {
        LinearLayout body = new LinearLayout(c);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(dp(c, 16), 0, dp(c, 16), dp(c, 24));
        return body;
    }
}
