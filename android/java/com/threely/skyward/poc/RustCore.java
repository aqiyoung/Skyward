package com.threely.skyward.poc;

/**
 * Java 侧只做 JNI 声明。所有逻辑都在 Rust core（libskyward_core.so）。
 * 边界只走原始类型 int/long/double，零对象分配、零字符串跨语言拷贝。
 *
 * PoC-2 新增：会话真值（时长 / 上下行 / 包数由内核计算）、索引引擎对照、
 * 规则集重置。PoC-4 新增：按动作分桶会话汇总、规则枚举。
 * PoC-5 新增：真实 TCP 探针（tokio 数据面地基）。共 37 个导出符号。
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
    /** 按动作分桶会话汇总：dirBytes,dirPkts,dirConns,prxBytes,prxPkts,prxConns,rejBytes,rejPkts,rejConns */
    public static native String nativeSessionBreakdown();

    // ---- 规则枚举（PoC-4）----
    public static native String nativeRulePattern(int i);
    public static native int nativeRuleKind(int i);
    public static native int nativeRuleAction(int i);

    // ---- 订阅解析 / 代理节点 / 路由决策（PoC-3）----
    public static native int nativeLoadSampleConfig();
    public static native int nativeNodeCount();
    public static native String nativeNodeName(int i);
    public static native int nativeNodeType(int i);
    public static native String nativeNodeServer(int i);
    public static native int nativeNodePort(int i);
    public static native int nativeNodeDelay(int i);
    public static native String nativeNodeGroup(int i);
    /** 输入域名，返回打包命中结果。bit63=命中；bits16-46=规则序号；bits8-15=类型；bits0-7=动作。 */
    public static native long nativeDecide(String host);

    /** 真实 TCP 探针（PoC-5）：内核经 tokio 做 DNS 解析 + 建连 + 收发试探字节。
     *  返回 CSV：ok,ms,ip,tx,rx,err。与 session_tick 模拟计数不是一回事。 */
    public static native String nativeProbe(String host, int port, long timeoutMs);

    // ---- 真实代理入口 / TUN 接管（PoC-6：内核开始真转发）----

    /** 启动本地 SOCKS5 入口：port 本地端口、ssServer 远端 SS 地址、ssPort 远端端口、password。返回 1/0。 */
    public static native int nativeStartProxy(int port, String ssServer, int ssPort, String password,
                                              String protocol, boolean tls, String sni);
    /** 停止 SOCKS5 入口。返回 1/0。 */
    public static native int nativeStopProxy();
    /** 真实代理吞吐 CSV：tx,rx（字节）。区别于 nativeSessionBreakdown 的模拟会话。 */
    public static native String nativeProxyStats();
    /** 打开 TUN 接管：fd 由 VpnService 提供。返回 1/0。 */
    public static native int nativeOpenTun(int fd, String server, int port, String password,
                                           String protocol, boolean tls, String sni);
    /** 关闭 TUN 接管。返回 1/0。 */
    public static native int nativeCloseTun();
    /** TUN 真实流量统计 CSV：bytes,packets,tcp,udp。 */
    public static native String nativeTunStats();
}
