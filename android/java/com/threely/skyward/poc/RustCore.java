package com.threely.skyward.poc;

/**
 * Java 侧只做 JNI 声明。所有逻辑都在 Rust core（libskyward_core.so）。
 * 边界只走原始类型 int/long/double，零对象分配、零字符串跨语言拷贝。
 */
public final class RustCore {
    static {
        System.loadLibrary("skyward_core");
    }

    private RustCore() {}

    public static native int nativeVersion();
    public static native long nativeInitNs();
    public static native int nativeLoadRules(int count);
    public static native int nativeRuleCount();
    public static native double nativeBenchMatches(int iterations);
    public static native double nativeBenchPackets(int packets, int size);
    public static native long nativeRssBytes();
    public static native long nativeLogicalBytes();
    public static native long nativeOpenConn(int action);
    public static native int nativeCloseConn(long id);
    public static native int nativeConnCount();
    public static native long nativeLoopbackBytes();
}
