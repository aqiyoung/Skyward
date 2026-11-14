//! Skyward Rust core - JNI 边界层（PoC 2）
//!
//! 全部用 C ABI 手工导出，不依赖 jni crate：Java 侧只传/收原始类型
//! (int/long/double)，因此不需要构造 Java 对象，边界零分配。
//! 所有真实逻辑在 engine.rs；这里只做 OnceLock 单例与数值转换。
//!
//! PoC-2 新增会话类接口：连接时长 / 上下行字节 / 包数由内核计算并累加，
//! 界面不再写死演示常量。另有索引/线性双引擎对照接口供工具页基准使用。

pub mod dnsrelay;
pub mod engine;
pub mod net;
pub mod socks5;
pub mod ss;
pub mod tcpstack;
pub mod tun;

use engine::{Core, CORE_VERSION, RuleKind};
use socks5::{run_socks5, ProxyConfig};
use std::ffi::{c_char, c_void, CStr, CString};
use std::os::fd::RawFd;
use std::sync::OnceLock;
use std::time::Instant;
use std::sync::Mutex as StdMutex;
use tokio::task::JoinHandle;
use tun::{run_tun_blocking, TunStats};

// JNI 原始类型别名（与 jni.h 一致）。
#[allow(non_camel_case_types)]
type jint = i32;
#[allow(non_camel_case_types)]
type jlong = i64;
#[allow(non_camel_case_types)]
type jdouble = f64;

// JNIEnv* / jclass 在本层不使用，声明为不透明指针占位。
// 注意：jclass 是 jobject 指针，必须按指针传递，不能按值，否则破坏 JNI 调用约定。
#[allow(non_camel_case_types)]
type JNIEnv = c_void;
#[allow(non_camel_case_types)]
type jclass = c_void;
#[allow(non_camel_case_types)]
type jclassRef = *mut jclass;

// JNI 函数表（仅取用到的槽位）。C 侧 JNIEnv* 即 `struct JNINativeInterface**`，
// 故先解一次引用得到 iface 指针，再经函数表调用。偏移由 NDK jni.h 实测：
// NewStringUTF=1336(÷8=167) / GetStringUTFChars=1352 / ReleaseStringUTFChars=1360。
// 这样回传 / 读取字符串时无需引入 jni crate，保持零三方依赖。
#[repr(C)]
#[allow(non_snake_case)]
struct JNINativeInterface {
    _pad: [usize; 167],
    NewStringUTF:
        Option<unsafe extern "system" fn(*mut c_void, *const c_char) -> *mut c_void>,
    _p1: usize, // GetStringUTFLength
    GetStringUTFChars:
        Option<unsafe extern "system" fn(*mut c_void, *mut c_void, *mut u8) -> *const c_char>,
    ReleaseStringUTFChars:
        Option<unsafe extern "system" fn(*mut c_void, *mut c_void, *const c_char)>,
}

#[inline]
unsafe fn iface(env: *mut JNIEnv) -> *mut JNINativeInterface {
    *(env as *mut *mut JNINativeInterface)
}

/// Rust String → Java jstring（零拷贝 CString 经 NewStringUTF）。
fn new_jstring(env: *mut JNIEnv, s: &str) -> *mut c_void {
    let c = CString::new(s).unwrap_or_else(|_| CString::new("").unwrap());
    let i = unsafe { iface(env) };
    let f = unsafe { (*i).NewStringUTF }.expect("NewStringUTF missing");
    unsafe { f(env as *mut c_void, c.as_ptr()) }
}

/// Java jstring → Rust String（GetStringUTFChars / ReleaseStringUTFChars 配对）。
fn read_jstring(env: *mut JNIEnv, js: *mut c_void) -> String {
    if js.is_null() {
        return String::new();
    }
    let i = unsafe { iface(env) };
    let get = unsafe { (*i).GetStringUTFChars }.expect("GetStringUTFChars missing");
    let cstr = unsafe { get(env as *mut c_void, js, std::ptr::null_mut()) };
    if cstr.is_null() {
        return String::new();
    }
    let s = unsafe { CStr::from_ptr(cstr) }.to_string_lossy().into_owned();
    let rel = unsafe { (*i).ReleaseStringUTFChars }.expect("ReleaseStringUTFChars missing");
    unsafe { rel(env as *mut c_void, js, cstr) };
    s
}

static CORE: OnceLock<Core> = OnceLock::new();
static INIT_NS: OnceLock<u128> = OnceLock::new();

fn core() -> &'static Core {
    let t = Instant::now();
    let c = CORE.get_or_init(Core::new);
    INIT_NS.get_or_init(|| t.elapsed().as_nanos());
    c
}

/// 内核版本（整数）。PoC-2 = 2。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeVersion(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jint {
    let _ = core();
    CORE_VERSION
}

/// 首次初始化耗时（纳秒），衡量冷启动开销。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeInitNs(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jlong {
    let _ = core();
    INIT_NS.get().copied().unwrap_or(0) as jlong
}

/// 载入 count 条规则，返回实际条数。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeLoadRules(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    count: jint,
) -> jint {
    core().load_rules(count.max(0) as usize) as jint
}

/// 恢复默认规则集（基准跑完后调用，避免污染首页读数）。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeResetRules(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jint {
    core().reset_rules() as jint
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeRuleCount(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jint {
    core().rule_count() as jint
}

/// 反转域名 trie 的节点数，用于展示索引规模。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeIndexNodes(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jint {
    core().index_nodes() as jint
}

/// 索引引擎匹配吞吐基准，返回耗时毫秒。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeBenchMatches(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    iterations: jint,
) -> jdouble {
    core().bench_matches(iterations.max(0) as usize)
}

/// 线性引擎对照基准（PoC-1 实现），返回耗时毫秒。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeBenchMatchesLinear(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    iterations: jint,
) -> jdouble {
    core().bench_matches_linear(iterations.max(0) as usize)
}

/// 模拟数据面吞吐基准，返回耗时毫秒。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeBenchPackets(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    packets: jint,
    size: jint,
) -> jdouble {
    core().bench_packets(packets.max(0) as usize, size.max(0) as usize)
}

/// 进程 RSS（字节）。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeRssBytes(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jlong {
    Core::rss_bytes() as jlong
}

/// 逻辑状态占用（规则真源 + 索引 + 连接表，字节）。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeLogicalBytes(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jlong {
    core().logical_bytes() as jlong
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeOpenConn(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    action: jint,
) -> jlong {
    core().open_conn(action as u8) as jlong
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeCloseConn(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    id: jlong,
) -> jint {
    if core().close_conn(id as u64) { 1 } else { 0 }
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeConnCount(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jint {
    core().conn_count() as jint
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeLoopbackBytes(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jlong {
    core().loopback_bytes() as jlong
}

// ---------------- 会话真值（PoC-2 新增） ----------------

/// 启动 / 恢复会话。now_ms 由 Java 传 System.currentTimeMillis()，
/// seed_up / seed_down 是上次落盘的累计字节，保证重启后读数连续。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeSessionStart(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    now_ms: jlong,
    seed_up: jlong,
    seed_down: jlong,
) -> jint {
    core().session_start(
        now_ms.max(0) as u64,
        seed_up.max(0) as u64,
        seed_down.max(0) as u64,
    );
    1
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeSessionStop(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jint {
    core().session_stop();
    1
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeSessionRunning(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jint {
    if core().session_running() { 1 } else { 0 }
}

/// 跑一小段模拟数据面并累加会话计数，返回本次处理字节数。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeSessionTick(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    packets: jint,
    size: jint,
) -> jlong {
    core().session_tick(packets.max(0) as usize, size.max(0) as usize) as jlong
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeSessionUptimeSec(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    now_ms: jlong,
) -> jlong {
    core().session_uptime_sec(now_ms.max(0) as u64) as jlong
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeSessionUpBytes(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jlong {
    core().session_up() as jlong
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeSessionDownBytes(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jlong {
    core().session_down() as jlong
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeSessionPackets(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jlong {
    core().session_packets() as jlong
}

/// 会话按动作分桶汇总（内核真值）：dirBytes,dirPkts,dirConns,prxBytes,prxPkts,prxConns,
/// rejBytes,rejPkts,rejConns。逗号分隔一次返回，首页「流量分配」每秒取一次。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeSessionBreakdown(
    env: *mut JNIEnv,
    _cls: jclassRef,
) -> *mut c_void {
    new_jstring(env, &core().session_breakdown())
}

// ---------------- 订阅解析 / 代理节点 / 路由决策（PoC-3） ----------------

/// 载入内置示例订阅（Clash 风格），解析真实节点，返回节点数。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeLoadSampleConfig(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jint {
    core().load_sample_config() as jint
}

/// 已解析节点数（0 = 尚未载入配置，UI 回退演示数据）。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeNodeCount(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jint {
    core().node_count() as jint
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeNodeName(
    env: *mut JNIEnv,
    _cls: jclassRef,
    i: jint,
) -> *mut c_void {
    new_jstring(env, &core().node_name(i.max(0) as usize))
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeNodeType(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    i: jint,
) -> jint {
    core().node_type_code(i.max(0) as usize) as jint
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeNodeServer(
    env: *mut JNIEnv,
    _cls: jclassRef,
    i: jint,
) -> *mut c_void {
    new_jstring(env, &core().node_server(i.max(0) as usize))
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeNodePort(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    i: jint,
) -> jint {
    core().node_port(i.max(0) as usize) as jint
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeNodeDelay(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    i: jint,
) -> jint {
    core().node_delay(i.max(0) as usize) as jint
}

#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeNodeGroup(
    env: *mut JNIEnv,
    _cls: jclassRef,
    i: jint,
) -> *mut c_void {
    new_jstring(env, &core().node_group(i.max(0) as usize))
}

/// 路由决策：输入域名，返回打包的命中结果。
/// 位布局：bit63=matched, bits16-46=规则序号, bits8-15=类型(0 suffix/1 keyword/2 cidr),
/// bits0-7=动作(0 直连/1 代理/2 拒绝)。未命中返回 0。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeDecide(
    env: *mut JNIEnv,
    _cls: jclassRef,
    host: *mut c_void,
) -> jlong {
    let h = read_jstring(env, host);
    match core().decide(&h) {
        Some((order, action, kind)) => {
            let k: u64 = match kind {
                RuleKind::DomainSuffix => 0,
                RuleKind::DomainKeyword => 1,
                RuleKind::IpCidr => 2,
            };
            (((1u64) << 63)
                | ((order as u64 & 0x7FFF_FFFF) << 16)
                | ((k & 0xFF) << 8)
                | (action as u64 & 0xFF)) as jlong
        }
        None => 0,
    }
}

// ---------------- 规则总览（PoC-4：首页内核化 + 规则页） ----------------

/// 规则 #i 的匹配模式串（域名 / 关键词 / CIDR 文本）。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeRulePattern(
    env: *mut JNIEnv,
    _cls: jclassRef,
    i: jint,
) -> *mut c_void {
    new_jstring(env, &core().rule_pattern(i.max(0) as usize))
}

/// 规则 #i 的类型：0=DOMAIN-SUFFIX / 1=DOMAIN-KEYWORD / 2=IP-CIDR。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeRuleKind(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    i: jint,
) -> jint {
    core().rule_kind_code(i.max(0) as usize) as jint
}

/// 规则 #i 的动作：0=DIRECT / 1=PROXY / 2=REJECT。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeRuleAction(
    _env: *mut JNIEnv,
    _cls: jclassRef,
    i: jint,
) -> jint {
    core().rule_action(i.max(0) as usize) as jint
}

// ---------------- 数据面地基（PoC-5：tokio 真实 socket） ----------------

/// 真实 TCP 探针：内核经 tokio 运行时做 DNS 解析 + 建连 + 收发试探字节，
/// 返回 CSV：ok,ms,ip,tx,rx,err。这是内核「真能收发字节」的第一步，
/// 与首页 / 代理页里由 session_tick 模拟出来的流量计数不是一回事。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeProbe(
    env: *mut JNIEnv,
    _cls: jclassRef,
    host: *mut c_void,
    port: jint,
    timeout_ms: jlong,
) -> *mut c_void {
    let h = read_jstring(env, host);
    let p = port.max(0) as u16;
    let t = timeout_ms.max(500) as u64;
    let rt = net::runtime();
    let probe = rt.block_on(net::tcp_probe(&h, p, t));
    new_jstring(env, &probe.to_csv())
}

// ---------------- 真实代理入口 / TUN 接管（PoC-6：内核开始真转发） ----------------

/// SOCKS5 监听任务句柄（用于 stop）。
static PROXY_TASK: OnceLock<StdMutex<Option<JoinHandle<()>>>> = OnceLock::new();
fn proxy_task() -> &'static StdMutex<Option<JoinHandle<()>>> {
    PROXY_TASK.get_or_init(|| StdMutex::new(None))
}

/// TUN 真实流量统计句柄（VpnService 提供 fd 后由 `run_tun_blocking` 返回）。
static TUN_STATS: OnceLock<StdMutex<Option<std::sync::Arc<StdMutex<TunStats>>>>> = OnceLock::new();
fn tun_stats() -> &'static StdMutex<Option<std::sync::Arc<StdMutex<TunStats>>>> {
    TUN_STATS.get_or_init(|| StdMutex::new(None))
}

/// 启动本地 SOCKS5 入口（默认 1080），把目标经 SS 出站协议转发到远端。
/// 参数：port 本地监听端口、ssServer 远端 SS 地址、ssPort 远端 SS 端口、password。
/// 返回 1=已启动 / 0=参数无效。内核自此具备「真实代理入口」，外部 App 可把代理指向本机。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeStartProxy(
    env: *mut JNIEnv,
    _cls: jclassRef,
    port: jint,
    ss_server: *mut c_void,
    ss_port: jint,
    password: *mut c_void,
) -> jint {
    if port <= 0 || ss_port <= 0 {
        return 0;
    }
    let server = read_jstring(env, ss_server);
    let pwd = read_jstring(env, password);
    let cfg = std::sync::Arc::new(ProxyConfig {
        ss_server: server,
        ss_port: ss_port as u16,
        password: pwd,
    });
    let rt = net::runtime();
    let handle = rt.spawn(async move {
        let _ = run_socks5(port as u16, cfg).await;
    });
    *proxy_task().lock().unwrap() = Some(handle);
    ss::reset_proxy_stats();
    1
}

/// 停止 SOCKS5 入口。返回 1=已停止 / 0=本就未运行。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeStopProxy(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jint {
    if let Some(h) = proxy_task().lock().unwrap().take() {
        h.abort();
        1
    } else {
        0
    }
}

/// 真实代理吞吐统计 CSV：tx,rx（字节）。区别于 `nativeSessionBreakdown` 的模拟会话。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeProxyStats(
    env: *mut JNIEnv,
    _cls: jclassRef,
) -> *mut c_void {
    let s = ss::proxy_stats().lock().unwrap();
    new_jstring(env, &format!("{},{}", s.tx, s.rx))
}

/// 打开 TUN 接管：Android `VpnService` 建立 tun 后将 fd 传给内核，内核在独立线程里
/// 读取原始 IP 帧、解析并累计真实流量。返回 1=已开启 / 0=fd 无效。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeOpenTun(
    env: *mut JNIEnv,
    _cls: jclassRef,
    fd: jint,
    ss_server: *mut c_void,
    ss_port: jint,
    password: *mut c_void,
) -> jint {
    if fd <= 0 {
        return 0;
    }
    let server = read_jstring(env, ss_server);
    let pwd = read_jstring(env, password);
    let cfg = std::sync::Arc::new(ProxyConfig {
        ss_server: server,
        ss_port: ss_port.max(1) as u16,
        password: pwd,
    });
    let stats = run_tun_blocking(fd as RawFd, cfg);
    *tun_stats().lock().unwrap() = Some(stats);
    1
}

/// 关闭 TUN 接管（关闭 fd，读取线程自然退出）。返回 1=已关闭 / 0=本就未开启。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeCloseTun(
    _env: *mut JNIEnv,
    _cls: jclassRef,
) -> jint {
    if tun_stats().lock().unwrap().take().is_some() {
        1
    } else {
        0
    }
}

/// TUN 真实流量统计 CSV：bytes,packets,tcp,udp。
#[no_mangle]
pub extern "C" fn Java_com_threely_skyward_poc_RustCore_nativeTunStats(
    env: *mut JNIEnv,
    _cls: jclassRef,
) -> *mut c_void {
    if let Some(s) = tun_stats().lock().unwrap().as_ref() {
        let s = s.lock().unwrap();
        new_jstring(
            env,
            &format!(
                "{},{},{},{},{},{}",
                s.bytes, s.packets, s.tcp, s.udp, s.tx_bytes, s.conns
            ),
        )
    } else {
        new_jstring(env, "0,0,0,0,0,0")
    }
}
