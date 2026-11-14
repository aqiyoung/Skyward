package com.threely.skyward.poc;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.VpnService;
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
    private FrameLayout root;
    private FrameLayout content;
    private FrameLayout dock;
    private final FrameLayout[] tabChips = new FrameLayout[5];
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

        root = new FrameLayout(this);
        root.setBackgroundColor(Ui.PAGE);
        root.setFitsSystemWindows(true);

        // 页面区全屏，底部让出悬浮胶囊 dock（76 + 20）的高度
        content = new FrameLayout(this);
        content.setPadding(0, 0, 0, Ui.dp(this, 96));
        root.addView(content, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        dock = buildDock();
        FrameLayout.LayoutParams dlp = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, Ui.dp(this, 76));
        dlp.gravity = Gravity.BOTTOM;
        dlp.leftMargin = Ui.dp(this, 16);
        dlp.rightMargin = Ui.dp(this, 16);
        dlp.bottomMargin = Ui.dp(this, 20);
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
        // 退后台：停掉首页秒级刷新并落盘最新会话累计字节
        AppState.get().pageEpoch++;
        AppState.get().save();
        super.onStop();
    }

    /**
     * 悬浮胶囊导航（原版 CapsuleNavigationDock）：高 76dp、全圆角 stadium、
     * 左右 16dp / 底部 20dp 边距、白色 90% 底 + 1.6dp 描边 + 投影。
     * 每项只有 30dp 图标，无文字标签；选中项落在 66dp 的深色淡圆里。
     */
    private FrameLayout buildDock() {
        FrameLayout bar = new FrameLayout(this);
        bar.setBackground(dockBg("#E6FFFFFF"));
        bar.setElevation(Ui.dp(this, 10));

        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        bar.addView(row, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        for (int i = 0; i < TABS.length; i++) {
            final int idx = i;
            FrameLayout slot = new FrameLayout(this);
            slot.setLayoutParams(new LinearLayout.LayoutParams(0,
                    ViewGroup.LayoutParams.MATCH_PARENT, 1f));

            FrameLayout chip = new FrameLayout(this);
            FrameLayout.LayoutParams clp = new FrameLayout.LayoutParams(
                    Ui.dp(this, 66), Ui.dp(this, 66));
            clp.gravity = Gravity.CENTER;
            chip.setLayoutParams(clp);
            GradientDrawable cbg = new GradientDrawable();
            cbg.setShape(GradientDrawable.OVAL);
            cbg.setColor(Color.TRANSPARENT);
            chip.setBackground(cbg);
            tabChips[i] = chip;

            IconView iv = new IconView(this, TAB_ICONS[i], Ui.TEXT2);
            FrameLayout.LayoutParams ilp = new FrameLayout.LayoutParams(
                    Ui.dp(this, 30), Ui.dp(this, 30));
            ilp.gravity = Gravity.CENTER;
            iv.setLayoutParams(ilp);
            tabIcons[i] = iv;
            chip.addView(iv);

            slot.addView(chip);
            slot.setClickable(true);
            slot.setOnClickListener(v -> {
                if (current == idx) return;
                current = idx;
                render();
            });
            row.addView(slot);
        }
        return bar;
    }

    /** 胶囊底色 + 1.6dp 描边（原版 floating 0.90 白 / outlineVariant 0.72）。 */
    private GradientDrawable dockBg(String colorHex) {
        GradientDrawable g = new GradientDrawable();
        g.setCornerRadius(Ui.dp(this, 38));
        g.setColor(Color.parseColor(colorHex));
        g.setStroke(Math.max(1, Ui.dp(this, 1.6f)), Color.parseColor("#B8E5E5EA"));
        return g;
    }

    private void syncDock() {
        for (int i = 0; i < TABS.length; i++) {
            boolean on = (i == current);
            tabIcons[i].setTint(on ? Ui.TEXT : Ui.TEXT2);
            GradientDrawable cbg = new GradientDrawable();
            cbg.setShape(GradientDrawable.OVAL);
            cbg.setColor(on ? Color.parseColor("#241C1C1E") : Color.TRANSPARENT);
            tabChips[i].setBackground(cbg);
        }
    }

    private void render() {
        final AppState s = AppState.get();
        // 页面代次递增：旧页挂的秒级刷新会在下一次 tick 时自动退出
        s.pageEpoch++;
        boolean glass = s.liquidGlass;
        int pageBg = glass ? Color.parseColor("#DDE7F2") : Ui.PAGE;
        root.setBackgroundColor(pageBg);
        dock.setBackground(dockBg(glass ? "#E6FFFFFF" : "#E6FFFFFF"));
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
