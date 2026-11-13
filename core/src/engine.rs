//! Skyward Rust core engine - PoC 1
//!
//! 纯 std、零第三方依赖。这里承载所有可以下沉的逻辑：配置、规则引擎、
//! 连接状态表、数据面统计与内存读数。JNI 只是薄薄一层导出。
//!
//! 设计取向：无 GC、无运行时、无异步 executor 常驻，状态全部显式持有；
//! 用 Mutex<Vec<_>> 而不是每连接一个 task，避免运行时内存随连接数膨胀。

use std::collections::HashMap;
use std::hint::black_box;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Mutex;
use std::time::Instant;

pub const ACTION_DIRECT: u8 = 0;
pub const ACTION_PROXY: u8 = 1;
pub const ACTION_REJECT: u8 = 2;

pub const CORE_VERSION: i32 = 1;

/// 一组真实感的域名样本，供匹配吞吐基准使用。
pub static HOSTS: [&str; 12] = [
    "www.google.com",
    "github.com",
    "api.telegram.org",
    "www.bilibili.com",
    "cdn.jsdelivr.net",
    "ads.doubleclick.net",
    "www.qq.com",
    "cloudflare-dns.com",
    "tracker.example.org",
    "raw.githubusercontent.com",
    "localhost",
    "192.168.1.20",
];

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum RuleKind {
    DomainSuffix,
    DomainKeyword,
    IpCidr,
}

pub struct Rule {
    pub kind: RuleKind,
    pub pattern: String,
    pub action: u8,
}

pub struct Connection {
    pub bytes: u64,
    pub action: u8,
}

pub struct Core {
    rules: Mutex<Vec<Rule>>,
    connections: Mutex<HashMap<u64, Connection>>,
    next_id: AtomicU64,
    loopback_bytes: AtomicU64,
}

impl Core {
    pub fn new() -> Self {
        let rules = vec![
            Rule { kind: RuleKind::DomainSuffix, pattern: "google.com".into(), action: ACTION_PROXY },
            Rule { kind: RuleKind::DomainSuffix, pattern: "github.com".into(), action: ACTION_PROXY },
            Rule { kind: RuleKind::DomainSuffix, pattern: "telegram.org".into(), action: ACTION_PROXY },
            Rule { kind: RuleKind::DomainSuffix, pattern: "bilibili.com".into(), action: ACTION_DIRECT },
            Rule { kind: RuleKind::DomainSuffix, pattern: "qq.com".into(), action: ACTION_DIRECT },
            Rule { kind: RuleKind::DomainKeyword, pattern: "ads".into(), action: ACTION_REJECT },
            Rule { kind: RuleKind::DomainKeyword, pattern: "tracker".into(), action: ACTION_REJECT },
            Rule { kind: RuleKind::IpCidr, pattern: "192.168.0.0/16".into(), action: ACTION_DIRECT },
            Rule { kind: RuleKind::IpCidr, pattern: "10.0.0.0/8".into(), action: ACTION_DIRECT },
        ];
        Core {
            rules: Mutex::new(rules),
            connections: Mutex::new(HashMap::new()),
            next_id: AtomicU64::new(1),
            loopback_bytes: AtomicU64::new(0),
        }
    }

    /// 生成 count 条规则（基准用），返回实际条数。
    pub fn load_rules(&self, count: usize) -> usize {
        let mut rules = Vec::with_capacity(count);
        for i in 0..count {
            rules.push(Rule {
                kind: RuleKind::DomainSuffix,
                pattern: format!("node{:05}.example.net", i),
                action: (i % 3) as u8,
            });
        }
        *self.rules.lock().unwrap() = rules;
        count
    }

    pub fn rule_count(&self) -> usize {
        self.rules.lock().unwrap().len()
    }

    /// 规则匹配：命中返回 action，未命中 DIRECT。
    pub fn match_host(&self, host: &str) -> u8 {
        let rules = self.rules.lock().unwrap();
        for r in rules.iter() {
            let hit = match r.kind {
                RuleKind::DomainSuffix => {
                    host == r.pattern
                        || (host.len() > r.pattern.len()
                            && host.ends_with(&r.pattern)
                            && host.as_bytes()[host.len() - r.pattern.len() - 1] == b'.')
                }
                RuleKind::DomainKeyword => host.contains(&r.pattern),
                RuleKind::IpCidr => {
                    // PoC 阶段用前缀近似；正式内核换成压缩前缀树。
                    let prefix = r.pattern.split('/').next().unwrap_or("");
                    host.starts_with(prefix)
                }
            };
            if hit {
                return r.action;
            }
        }
        ACTION_DIRECT
    }

    /// 规则匹配吞吐基准，返回耗时毫秒。
    pub fn bench_matches(&self, iterations: usize) -> f64 {
        let start = Instant::now();
        let mut acc = 0u64;
        for i in 0..iterations {
            acc += self.match_host(HOSTS[i % HOSTS.len()]) as u64;
        }
        black_box(acc);
        start.elapsed().as_secs_f64() * 1000.0
    }

    /// 模拟数据面：逐包查规则 + 更新连接表 + 统计字节，返回耗时毫秒。
    /// 不接管真实 tun，装机后不会断网；真实 tun2socks 留到阶段 2。
    pub fn bench_packets(&self, packets: usize, size: usize) -> f64 {
        let start = Instant::now();
        let mut acc = 0u64;
        for i in 0..packets {
            let host = HOSTS[i % HOSTS.len()];
            let action = self.match_host(host);
            let id = (i % 64) as u64;
            if let Ok(mut conns) = self.connections.lock() {
                let c = conns.entry(id).or_insert(Connection { bytes: 0, action });
                c.bytes += size as u64;
            }
            acc += action as u64 + size as u64;
        }
        black_box(acc);
        self.loopback_bytes
            .fetch_add((packets * size) as u64, Ordering::Relaxed);
        start.elapsed().as_secs_f64() * 1000.0
    }

    pub fn open_conn(&self, action: u8) -> u64 {
        let id = self.next_id.fetch_add(1, Ordering::Relaxed);
        self.connections
            .lock()
            .unwrap()
            .insert(id, Connection { bytes: 0, action });
        id
    }

    pub fn close_conn(&self, id: u64) -> bool {
        self.connections.lock().unwrap().remove(&id).is_some()
    }

    pub fn conn_count(&self) -> usize {
        self.connections.lock().unwrap().len()
    }

    pub fn loopback_bytes(&self) -> u64 {
        self.loopback_bytes.load(Ordering::Relaxed)
    }

    /// 逻辑状态占用的估算字节数（规则 + 连接表），不是进程 RSS。
    pub fn logical_bytes(&self) -> u64 {
        let rules = self.rules.lock().unwrap();
        let conns = self.connections.lock().unwrap();
        let rule_bytes: usize = rules
            .iter()
            .map(|r| std::mem::size_of::<Rule>() + r.pattern.len())
            .sum();
        let conn_bytes = conns.len() * (std::mem::size_of::<Connection>() + 16);
        (rule_bytes + conn_bytes) as u64
    }

    /// 进程 RSS（VmRSS），用于和 Go 内核的常驻内存做量级对比。
    pub fn rss_bytes() -> u64 {
        let Ok(status) = std::fs::read_to_string("/proc/self/status") else {
            return 0;
        };
        for line in status.lines() {
            if let Some(rest) = line.strip_prefix("VmRSS:") {
                if let Some(kb) = rest
                    .split_whitespace()
                    .next()
                    .and_then(|v| v.parse::<u64>().ok())
                {
                    return kb * 1024;
                }
            }
        }
        0
    }
}

impl Default for Core {
    fn default() -> Self {
        Self::new()
    }
}
