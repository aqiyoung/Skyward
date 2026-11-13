package com.threely.skyward.poc;

/**
 * Java 侧只做 JNI 声明。所有逻辑都在 Rust core（libskyward_core.so）。
 * 边界只走原始类型 int/long/double，零对象分配、零字符串跨语言拷贝。
 *
 * PoC-2 新增：会话真值（时长 / 上下行 / 包数由内核计算）、索引引擎对照、
 * 规则集重置。共 23 个导出符号。
 */
public final class RustCore {
    static {
        System.loadLibrary("skyward_core");
    }

    private RustCore() {}

    // ---- 内核 / 规则 ----
    public static native int nativeVersion();
    public static native long nativeInitNs();
    public static native int nativeLoadRules(int count);
    public static native int nativeResetRules();
    public static native int nativeRuleCount();
    public static native int nativeIndexNodes();

    // ---- 基准 ----
    public static native double nativeBenchMatches(int iterations);
    public static native double nativeBenchMatchesLinear(int iterations);
    public static native double nativeBenchPackets(int packets, int size);

    // ---- 内存 / 连接表 ----
    public static native long nativeRssBytes();
    public static native long nativeLogicalBytes();
    public static native long nativeOpenConn(int action);
    public static native int nativeCloseConn(long id);
    public static native int nativeConnCount();
    public static native long nativeLoopbackBytes();

    // ---- 会话真值（PoC-2）----
    public static native int nativeSessionStart(long nowMs, long seedUp, long seedDown);
    public static native int nativeSessionStop();
    public static native int nativeSessionRunning();
    public static native long nativeSessionTick(int packets, int size);
    public static native long nativeSessionUptimeSec(long nowMs);
    public static native long nativeSessionUpBytes();
    public static native long nativeSessionDownBytes();
    public static native long nativeSessionPackets();
}
