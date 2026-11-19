package com.follow.clash.core.mobile;

/**
 * Hand-written replacement for the gomobile-generated Mobile class.
 * Native methods are implemented by the Rust core (src/jni.rs). Signatures
 * match what Core.kt calls so the App needs no changes to its bridge layer.
 */
public final class Mobile {
    static {
        System.loadLibrary("skyward_core");
        // Register the JavaVM so native threads can deliver callbacks (events,
        // logs) to the App. The host does not call this explicitly.
        initVm();
    }

    /** Register the JavaVM so native threads can deliver callbacks. */
    public static native void initVm();

    public static native void forceGC();
    public static native void updateDns(String dns);
    public static native void resetNetwork();

    public static native boolean startTun(
            int fd, TunHandler handler, String stack, String address, String dns, String options);

    public static native void invokeMethod(String data, ResultHandler handler);
    public static native void setEventListener(ResultHandler handler);
    public static native void quickSetup(String initParams, String setupParams, ResultHandler handler);

    public static native void stopTun();
    public static native void startListener();
    public static native void stopListener();

    public static native String getTraffic(boolean onlyStatisticsProxy);
    public static native String getTotalTraffic(boolean onlyStatisticsProxy);
}
