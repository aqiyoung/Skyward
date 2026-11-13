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
 * 与 PoC-1 的区别：
 *  - 启动不再跑全量基准（真机上 5 万规则档会卡住界面，截图里 "running..." 即此问题）；
 *    基准移到「我的 → 工具 → 运行性能基准」，规模下调、子线程分段、逐段刷新。
 *  - 界面按现行 Flutter 版信息架构铺开：4 Tab + 状态卡 + 分组卡片，模块边界清晰。
 *  - 液态玻璃默认关闭（沿用既定规则），仅在设置里提供开关占位。
 *  - 内核真值全部经 JNI 取自 Rust core；产品数据明确标注「演示」。
 */
public class MainActivity extends Activity {

    private static final String[] TABS = {"首页", "代理", "配置", "我的"};
    private static final IconView.Glyph[] TAB_ICONS = {
            IconView.Glyph.HOME, IconView.Glyph.GLOBE,
            IconView.Glyph.PROFILE, IconView.Glyph.PERSON
    };

    private int current = 0;
    private LinearLayout root;
    private FrameLayout content;
    private LinearLayout dock;
    private final TextView[] tabLabels = new TextView[4];
    private final IconView[] tabIcons = new IconView[4];

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

        // 轻量预热：只触发 Rust OnceLock 初始化，不做任何重基准
        AppState.get().warmUp();
        render();
    }

    private LinearLayout buildDock() {
        LinearLayout bar = new LinearLayout(this);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setBackgroundColor(Ui.CARD);
        int padTop = Ui.dp(this, 8);
        int padBottom = Ui.dp(this, 10);
        bar.setPadding(Ui.dp(this, 10), padTop, Ui.dp(this, 10), padBottom);

        // 顶部分隔线用一张卡片背景描边实现
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
        // 玻璃开启时页面底色转冷，半透明卡片才有可透的层次；默认关闭时为标准灰
        boolean glass = AppState.get().liquidGlass;
        root.setBackgroundColor(glass ? Color.parseColor("#DDE7F2") : Ui.PAGE);
        dock.setBackgroundColor(glass ? Color.parseColor("#CCFFFFFF") : Ui.CARD);
        syncDock();
        content.removeAllViews();
        Runnable refresh = this::render;
        View v;
        switch (current) {
            case 1:  v = Pages.proxies(this, refresh); break;
            case 2:  v = Pages.profiles(this, refresh); break;
            case 3:  v = Pages.mine(this, refresh); break;
            default: v = Pages.home(this, refresh); break;
        }
        content.addView(v, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
    }
}
