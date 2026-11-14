package com.threely.skyward.poc;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * PoC-2 主壳：底部 4 Tab（首页 / 代理 / 配置 / 我的）+ 分组卡片内容页。
 *
 * 纯原生 View，无 XML 布局 / 无 Compose / 无 Flutter / 无第三方依赖。
 * 0.1.0.6 相对上一版：
 *  - 状态持久化：attach(Application Context) 读回 SharedPreferences；连接态按原
 *    连接时刻恢复内核会话，累计字节作种子，读数连续。
 *  - 会话真值：首页时长 / 上下行 / 速率 / 连接数由 Rust 内核计算，不再写死；
 *    onStop 落盘，页面代次 pageEpoch 用于干净地停掉首页秒级刷新。
 *  - 液态玻璃默认关闭（沿用既定规则），状态栏 / 导航栏颜色随之联动。
 */
public class MainActivity extends Activity {

    private static final String[] TABS = {"仪表盘", "代理", "规则", "配置", "我的"};
    private static final IconView.Glyph[] TAB_ICONS = {
            IconView.Glyph.HOME, IconView.Glyph.GLOBE, IconView.Glyph.RULES,
            IconView.Glyph.PROFILE, IconView.Glyph.PERSON
    };

    private int current = 0;
    private LinearLayout root;
    private FrameLayout content;
    private LinearLayout dock;
    private final TextView[] tabLabels = new TextView[5];
    private final IconView[] tabIcons = new IconView[5];

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // 浅色状态栏 + 深色图标，避免内容顶到状态栏
        Window w = getWindow();
        w.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
        w.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
        w.setStatusBarColor(Ui.PAGE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            View decor = w.getDecorView();
            decor.setSystemUiVisibility(decor.getSystemUiVisibility()
                    | View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
        }
        w.setNavigationBarColor(Ui.CARD);

        // 读回持久化状态；若上次是连接态，恢复内核会话（时长 / 累计字节连续）
        CrashGuard.install(getApplicationContext());
        AppState.get().attach(this);

        root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Ui.PAGE);
        root.setFitsSystemWindows(true);

        content = new FrameLayout(this);
        content.setLayoutParams(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));
        root.addView(content);

        dock = buildDock();
        root.addView(dock);

        setContentView(root);
        render();
    }

    @Override
    protected void onResume() {
        super.onResume();
        render();
    }

    @Override
    protected void onStop() {
        // 退后台：停掉首页秒级刷新并落盘最新会话累计字节
        AppState.get().pageEpoch++;
        AppState.get().save();
        super.onStop();
    }

    private LinearLayout buildDock() {
        LinearLayout bar = new LinearLayout(this);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setBackgroundColor(Ui.CARD);
        int padTop = Ui.dp(this, 8);
        int padBottom = Ui.dp(this, 10);
        bar.setPadding(Ui.dp(this, 10), padTop, Ui.dp(this, 10), padBottom);

        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Ui.CARD);
        bg.setStroke(1, Ui.SEP);
        bar.setBackground(bg);

        for (int i = 0; i < TABS.length; i++) {
            final int idx = i;
            LinearLayout item = new LinearLayout(this);
            item.setOrientation(LinearLayout.VERTICAL);
            item.setGravity(Gravity.CENTER);
            item.setPadding(Ui.dp(this, 4), Ui.dp(this, 4), Ui.dp(this, 4), Ui.dp(this, 2));
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0,
                    ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
            item.setLayoutParams(lp);

            IconView iv = new IconView(this, TAB_ICONS[i], Ui.TEXT3);
            int s = Ui.dp(this, 23);
            iv.setLayoutParams(new LinearLayout.LayoutParams(s, s));
            tabIcons[i] = iv;
            item.addView(iv);

            TextView label = new TextView(this);
            label.setText(TABS[i]);
            label.setTextSize(10.5f);
            label.setTextColor(Ui.TEXT3);
            label.setGravity(Gravity.CENTER);
            label.setPadding(0, Ui.dp(this, 2), 0, 0);
            tabLabels[i] = label;
            item.addView(label);

            item.setClickable(true);
            item.setOnClickListener(v -> {
                if (current == idx) return;
                current = idx;
                render();
            });
            bar.addView(item);
        }
        return bar;
    }

    private void syncDock() {
        for (int i = 0; i < TABS.length; i++) {
            int c = (i == current) ? Ui.BLUE : Ui.TEXT3;
            tabIcons[i].setTint(c);
            tabLabels[i].setTextColor(c);
            tabLabels[i].setTypeface(i == current ? Typeface.DEFAULT_BOLD : Typeface.DEFAULT);
        }
    }

    private void render() {
        final AppState s = AppState.get();
        // 页面代次递增：旧页挂的秒级刷新会在下一次 tick 时自动退出
        s.pageEpoch++;
        boolean glass = s.liquidGlass;
        int pageBg = glass ? Color.parseColor("#DDE7F2") : Ui.PAGE;
        int barBg  = glass ? Color.parseColor("#CCFFFFFF") : Ui.CARD;
        root.setBackgroundColor(pageBg);
        dock.setBackgroundColor(barBg);
        getWindow().setStatusBarColor(pageBg);
        getWindow().setNavigationBarColor(barBg);
        syncDock();
        content.removeAllViews();
        Runnable refresh = this::render;
        View v;
        switch (current) {
            case 1:  v = Pages.proxies(this, refresh); break;
            case 2:  v = Pages.rules(this, refresh); break;
            case 3:  v = Pages.profiles(this, refresh); break;
            case 4:  v = Pages.mine(this, refresh); break;
            default: v = Pages.home(this, refresh); break;
        }
        content.addView(v, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
    }
}
