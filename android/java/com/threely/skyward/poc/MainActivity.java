package com.threely.skyward.poc;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.net.VpnService;
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.LinearLayout;

/**
 * 主壳：5 个页面（仪表盘 / 代理 / 规则 / 配置 / 我的）+ 悬浮液态玻璃胶囊 dock。
 *
 * 对齐 4tab 定稿设计：底部为浮在内容之上的半透明胶囊 dock（仅图标，5 项），
 * 页面背景 #F2F2F7、白色 22 圆角卡片。纯原生 View，零 XML / 零依赖。
 */
public class MainActivity extends Activity {

    private static final String[] TABS = {"仪表盘", "代理", "规则", "配置", "我的"};
    private static final IconView.Glyph[] TAB_ICONS = {
            IconView.Glyph.HOME, IconView.Glyph.GLOBE, IconView.Glyph.RULES,
            IconView.Glyph.PROFILE, IconView.Glyph.PERSON
    };

    private int current = 0;
    private FrameLayout root;
    private FrameLayout content;
    private LinearLayout dock;
    private final FrameLayout[] dockItems = new FrameLayout[5];
    private final IconView[] tabIcons = new IconView[5];

    public static final int VPN_REQ = 9001;

    /** 请求 VPN 权限并启动系统流量接管（VpnService）。首次需用户授权。
     *  接受 Context（调用方多为页面里的 Context，运行时即 Activity）。 */
    public static void requestVpn(Context a) {
        Intent intent = VpnService.prepare(a);
        if (intent != null) {
            if (a instanceof Activity) {
                ((Activity) a).startActivityForResult(intent, VPN_REQ);
            } else {
                a.startActivity(intent);
            }
        } else {
            a.startService(new Intent(a, SkywardVpnService.class));
        }
    }

    /** 停止系统流量接管。 */
    public static void stopVpn(Context a) {
        a.stopService(new Intent(a, SkywardVpnService.class));
    }

    @Override
    protected void onActivityResult(int req, int res, android.content.Intent data) {
        if (req == VPN_REQ && res == Activity.RESULT_OK) {
            startService(new Intent(this, SkywardVpnService.class));
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Window w = getWindow();
        w.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
        w.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
        w.setStatusBarColor(Ui.PAGE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            View decor = w.getDecorView();
            decor.setSystemUiVisibility(decor.getSystemUiVisibility()
                    | View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
        }
        w.setNavigationBarColor(Ui.PAGE);

        AppState.get().attach(this);

        root = new FrameLayout(this);
        root.setBackgroundColor(Ui.PAGE);
        root.setFitsSystemWindows(true);

        content = new FrameLayout(this);
        content.setLayoutParams(new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        content.setPadding(0, 0, 0, Ui.dp(this, 84));   // 底部给悬浮 dock 留白
        root.addView(content);

        dock = buildDock();
        FrameLayout.LayoutParams dlp = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        dlp.gravity = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
        dlp.bottomMargin = Ui.dp(this, 18);
        root.addView(dock, dlp);

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
        AppState.get().pageEpoch++;
        AppState.get().save();
        super.onStop();
    }

    /** 悬浮液态玻璃胶囊 dock：仅图标，5 项，当前项蓝色高亮圆角底。 */
    private LinearLayout buildDock() {
        LinearLayout pill = new LinearLayout(this);
        pill.setOrientation(LinearLayout.HORIZONTAL);
        pill.setGravity(Gravity.CENTER);
        pill.setPadding(Ui.dp(this, 8), Ui.dp(this, 8), Ui.dp(this, 8), Ui.dp(this, 8));
        applyDockBg(pill, false);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            pill.setElevation(Ui.dp(this, 14));
        }

        for (int i = 0; i < TABS.length; i++) {
            final int idx = i;
            FrameLayout item = new FrameLayout(this);
            LinearLayout.LayoutParams ilp = new LinearLayout.LayoutParams(
                    Ui.dp(this, 50), Ui.dp(this, 46));
            ilp.leftMargin = Ui.dp(this, 2);
            ilp.rightMargin = Ui.dp(this, 2);
            item.setLayoutParams(ilp);

            IconView iv = new IconView(this, TAB_ICONS[i], Ui.TEXT3);
            int s = Ui.dp(this, 23);
            FrameLayout.LayoutParams ip = new FrameLayout.LayoutParams(s, s);
            ip.gravity = Gravity.CENTER;
            iv.setLayoutParams(ip);
            item.addView(iv);
            tabIcons[i] = iv;
            dockItems[i] = item;

            item.setClickable(true);
            item.setOnClickListener(v -> {
                if (current == idx) return;
                current = idx;
                render();
            });
            pill.addView(item);
        }
        return pill;
    }

    private void applyDockBg(LinearLayout pill, boolean glass) {
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(glass ? Color.parseColor("#D9FFFFFF") : Color.parseColor("#EAF2F2F7"));
        bg.setCornerRadius(Ui.dp(this, 28));
        bg.setStroke(1, Color.parseColor("#40FFFFFF"));
        pill.setBackground(bg);
    }

    private void itemBg(FrameLayout item, boolean active) {
        if (!active) { item.setBackground(null); return; }
        GradientDrawable g = new GradientDrawable();
        g.setColor(Color.parseColor("#1A007AFF"));
        g.setCornerRadius(Ui.dp(this, 16));
        item.setBackground(g);
    }

    private void syncDock() {
        for (int i = 0; i < TABS.length; i++) {
            boolean on = (i == current);
            tabIcons[i].setTint(on ? Ui.BLUE : Ui.TEXT3);
            itemBg(dockItems[i], on);
        }
    }

    private void render() {
        final AppState s = AppState.get();
        s.pageEpoch++;
        boolean glass = s.liquidGlass;
        int pageBg = glass ? Color.parseColor("#DDE7F2") : Ui.PAGE;
        root.setBackgroundColor(pageBg);
        applyDockBg(dock, glass);
        getWindow().setStatusBarColor(pageBg);
        getWindow().setNavigationBarColor(pageBg);
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
