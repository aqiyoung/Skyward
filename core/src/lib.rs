//! Skyward Rust core - JNI 边界层（PoC 2）
//!
//! 全部用 C ABI 手工导出，不依赖 jni crate：Java 侧只传/收原始类型
//! (int/long/double)，因此不需要构造 Java 对象，边界零分配。
//! 所有真实逻辑在 engine.rs；这里只做 OnceLock 单例与数值转换。
//!
//! PoC-2 新增会话类接口：连接时长 / 上下行字节 / 包数由内核计算并累加，
//! 界面不再写死演示常量。另有索引/线性双引擎对照接口供工具页基准使用。

pub mod engine;

use engine::{Core, CORE_VERSION};
use std::ffi::c_void;
use std::sync::OnceLock;
use std::time::Instant;

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
