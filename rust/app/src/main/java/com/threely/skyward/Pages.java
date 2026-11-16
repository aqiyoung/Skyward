package com.threely.skyward;

import android.content.Context;
import android.view.View;

/**
 * 页面入口门面。MainActivity 只认这五个方法，具体实现按页拆到 PageXxx。
 * 拆分本身不改任何布局参数——视觉与原单文件版本逐像素一致。
 */
public final class Pages {

    private Pages() {}

    public static View home(Context c, Runnable refresh) {
        return PageHome.home(c, refresh);
    }

    public static View proxies(Context c, Runnable refresh) {
        return PageProxies.proxies(c, refresh);
    }

    public static View rules(Context c, Runnable refresh) {
        return PageRules.rules(c, refresh);
    }

    public static View profiles(Context c, Runnable refresh) {
        return PageProfiles.profiles(c, refresh);
    }

    public static View mine(Context c, Runnable refresh) {
        return PageMine.mine(c, refresh);
    }
}
