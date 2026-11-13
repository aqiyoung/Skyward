//! 宿主侧基准（非 Android）：同一份 engine 逻辑，用于在没有真机时
//! 先量出规则匹配/数据面吞吐与内存量级。
//! 用法：cargo run --release --example bench

use skyward_core::engine::Core;
use std::hint::black_box;

fn main() {
    println!("Skyward Rust core bench (host x86_64, same engine as Android)\n");

    let core = Core::new();
    println!("default rules: {}", core.rule_count());
    println!("rss(baseline): {:.2} MB", Core::rss_bytes() as f64 / 1048576.0);
    println!("logical bytes: {} B\n", core.logical_bytes());

    // 规则规模扫描
    for &n in &[9usize, 1_000, 10_000, 50_000] {
        core.load_rules(n);
        let iters = 200_000usize;
        let ms = core.bench_matches(iters);
        println!(
            "match: rules={:>6}  iters={}  {:>8.2} ms  {:>10.2} Mops/s  logical={} B",
            n,
            iters,
            ms,
            (iters as f64 / 1_000_000.0) / (ms / 1000.0),
            core.logical_bytes()
        );
    }

    // 数据面模拟（100万包 x 1500B = 1.5GB 逻辑流量）
    core.load_rules(1_000);
    let packets = 1_000_000usize;
    let size = 1500usize;
    let ms = core.bench_packets(packets, size);
    println!(
        "\npackets: {} x {} B = {:.2} MB  {:>8.2} ms  {:.2} Mpps  {:.2} GB/s",
        packets,
        size,
        (packets * size) as f64 / 1048576.0,
        ms,
        (packets as f64 / 1_000_000.0) / (ms / 1000.0),
        ((packets * size) as f64 / 1e9) / (ms / 1000.0)
    );
    println!("connections: {}", core.conn_count());
    println!("loopback bytes: {}", core.loopback_bytes());
    println!("rss(after): {:.2} MB", Core::rss_bytes() as f64 / 1048576.0);
    println!("logical bytes: {} B", core.logical_bytes());
    black_box(core.conn_count());
}
