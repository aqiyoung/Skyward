//! 宿主侧基准（非 Android）：同一份 engine 逻辑，用于在没有真机时
//! 先量出规则匹配/数据面吞吐与内存量级，并验证 PoC-2 索引化修正。
//! 用法：cargo run --release --example bench

use skyward_core::engine::{Core, HOSTS};
use std::hint::black_box;

fn main() {
    println!("Skyward Rust core bench (host x86_64, same engine as Android)\n");

    let core = Core::new();
    println!("core version    : {}", skyward_core::engine::CORE_VERSION);
    println!("default rules   : {}", core.rule_count());
    println!("trie nodes      : {}", core.index_nodes());
    println!("rss(baseline)   : {:.2} MB", Core::rss_bytes() as f64 / 1048576.0);
    println!("logical bytes   : {} B\n", core.logical_bytes());

    // ---- 语义一致性：索引化不能改变命中结果 ----
    let mut ok = 0;
    for &h in HOSTS.iter() {
        if core.match_host(h) == core.match_host_linear(h) {
            ok += 1;
        } else {
            println!("MISMATCH {} indexed={} linear={}",
                     h, core.match_host(h), core.match_host_linear(h));
        }
    }
    println!("== 语义一致性（默认规则）==\nmatched {}/{} hosts identical\n", ok, HOSTS.len());

    // ---- 索引 vs 线性吞吐对照 ----
    println!("== 规则引擎：索引化 vs 线性扫描（同一份规则，同一批 host）==");
    println!("{:>8} {:>12} {:>12} | {:>12} {:>12}",
             "rules", "idx(ms)", "idx Mops/s", "lin(ms)", "lin Mops/s");
    // 线性档刻意用较小迭代数：PoC-1 实测 5 万规则时吞吐仅 0.02 Mops/s
    for &(n, idx_iters, lin_iters) in
        &[(9usize, 200_000usize, 200_000usize),
          (1_000,   200_000,      50_000),
          (10_000,  200_000,       5_000),
          (50_000,  200_000,       2_000)] {
        core.load_rules(n);
        let ims = core.bench_matches(idx_iters);
        let lms = core.bench_matches_linear(lin_iters);
        let imops = (idx_iters as f64 / 1e6) / (ims / 1000.0);
        let lmops = (lin_iters as f64 / 1e6) / (lms / 1000.0);
        println!("{:>8} {:>12.2} {:>12.2} | {:>12.2} {:>12.2}   (lin iters={})",
                 n, ims, imops, lms, lmops, lin_iters);
    }
    println!("\n索引引擎吞吐随规则数基本持平；线性引擎按 O(n) 塌方（PoC-1 的缺陷）。\n");

    // ---- 数据面 ----
    core.load_rules(1_000);
    let packets = 1_000_000usize;
    let size = 1500usize;
    let ms = core.bench_packets(packets, size);
    println!("== 数据面（内存模拟，不接管 tun）==");
    println!("{} x {} B = {:.2} MB  {:>8.2} ms  {:.2} Mpps  {:.2} GB/s",
             packets, size,
             (packets * size) as f64 / 1048576.0,
             ms,
             (packets as f64 / 1e6) / (ms / 1000.0),
             ((packets * size) as f64 / 1e9) / (ms / 1000.0));
    println!("connections: {}  loopback bytes: {}", core.conn_count(), core.loopback_bytes());

    // ---- 会话真值（PoC-2 新增） ----
    core.reset_rules();
    let t0 = 1_700_000_000_000u64;
    core.session_start(t0, 0, 0);
    for _ in 0..5 { core.session_tick(200, 1500); }
    println!("\n== 会话真值 ==");
    println!("running={} uptime={} s up={} B down={} B packets={} conns={}",
             core.session_running(), core.session_uptime_sec(t0 + 5_000),
             core.session_up(), core.session_down(),
             core.session_packets(), core.conn_count());
    core.session_stop();

    println!("\nrss(after): {:.2} MB", Core::rss_bytes() as f64 / 1048576.0);
    println!("logical bytes: {} B", core.logical_bytes());
    println!("trie nodes: {}", core.index_nodes());
    black_box(core.conn_count());
}
