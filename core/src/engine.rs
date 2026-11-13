//! Skyward Rust core engine - PoC 2
//!
//! 纯 std、零第三方依赖。承载所有可以下沉的逻辑：配置、规则引擎、
//! 连接状态表、会话统计、数据面模拟与内存读数。JNI 只是薄薄一层导出。
//!
//! 设计取向：无 GC、无运行时、无异步 executor 常驻，状态全部显式持有；
//! 用 Mutex<HashMap<_>> 而不是每连接一个 task，避免运行时内存随连接数膨胀。
//!
//! PoC-2 相对 PoC-1 的关键修正：
//!   PoC-1 的 match_host 对每条规则做 O(n) 线性扫描，规则从 9 条涨到 5 万条时
//!   吞吐从 50.03 Mops/s 塌到 0.02 Mops/s。这里改为三类索引：
//!     - DOMAIN-SUFFIX：反转标签 trie，查询 O(标签数)，与规则总数无关；
//!     - DOMAIN-KEYWORD：按首字节分桶，避免全量 contains；
//!     - IP-CIDR：按前缀长度分桶 + 桶内排序二分，实现最长前缀匹配。
//!   命中优先级仍按「规则原始序号最小者」，与逐条首次命中语义一致。
//!   线性实现保留为 bench_matches_linear()，用于同机对照，不参与线上查询。
//!
//! 另新增会话状态：连接时长 / 上下行字节 / 包数 / 连接表全部由内核计算，
//! 不再由 UI 写死常量。数据面仍是内存模拟（不接管真实 tun），装机不会断网。

use std::collections::HashMap;
use std::hint::black_box;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Mutex;
use std::time::Instant;

pub const ACTION_DIRECT: u8 = 0;
pub const ACTION_PROXY: u8 = 1;
pub const ACTION_REJECT: u8 = 2;

pub const CORE_VERSION: i32 = 2;

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

// ============================ 规则索引 ============================

/// 反转域名 trie 的节点。action 带规则序号，用于保持「按序首次命中」语义。
struct SuffixNode {
    action: Option<(usize, u8)>,
    children: HashMap<String, SuffixNode>,
}

impl SuffixNode {
    fn new() -> Self {
        SuffixNode { action: None, children: HashMap::new() }
    }
}

pub struct RuleIndex {
    suffix: SuffixNode,
    /// 关键词按首字节分桶：(pattern, 规则序号, action)
    keywords: HashMap<u8, Vec<(String, usize, u8)>>,
    /// 下标 = 前缀长度 0..=32，值为 (网络号, 规则序号, action)，按网络号排序
    cidrs: Vec<Vec<(u32, usize, u8)>>,
    /// 非空前缀长度，按从长到短排列，查询时只遍历这些桶
    cidr_prefixes: Vec<usize>,
    raw_count: usize,
    suffix_nodes: usize,
    label_bytes: usize,
    pattern_bytes: usize,
}

fn parse_ipv4(s: &str) -> Option<u32> {
    let mut acc: u32 = 0;
    let mut parts = 0;
    for seg in s.split('.') {
        let v: u32 = seg.parse().ok()?;
        if v > 255 {
            return None;
        }
        acc = (acc << 8) | v;
        parts += 1;
    }
    if parts == 4 { Some(acc) } else { None }
}

fn prefix_mask(p: usize) -> u32 {
    if p == 0 {
        0
    } else if p >= 32 {
        !0u32
    } else {
        !0u32 << (32 - p)
    }
}

fn parse_cidr(s: &str) -> Option<(u32, usize)> {
    let mut it = s.split('/');
    let ip = parse_ipv4(it.next()?)?;
    let p: usize = it.next()?.parse().ok()?;
    if p > 32 {
        return None;
    }
    Some((ip & prefix_mask(p), p))
}

impl RuleIndex {
    fn build(rules: &[Rule]) -> Self {
        let mut idx = RuleIndex {
            suffix: SuffixNode::new(),
            keywords: HashMap::new(),
            cidrs: (0..=32).map(|_| Vec::new()).collect(),
            cidr_prefixes: Vec::new(),
            raw_count: rules.len(),
            suffix_nodes: 1, // root
            label_bytes: 0,
            pattern_bytes: 0,
        };
        let mut nodes_added = 0usize;
        let mut label_added = 0usize;

        for (order, r) in rules.iter().enumerate() {
            idx.pattern_bytes += r.pattern.len();
            match r.kind {
                RuleKind::DomainSuffix => {
                    let labels: Vec<&str> = r
                        .pattern
                        .split('.')
                        .filter(|x| !x.is_empty())
                        .collect();
                    let mut node = &mut idx.suffix;
                    for label in labels.iter().rev() {
                        if !node.children.contains_key(*label) {
                            nodes_added += 1;
                            label_added += label.len();
                            node.children.insert((*label).to_string(), SuffixNode::new());
                        }
                        node = node.children.get_mut(*label).unwrap();
                    }
                    if node.action.is_none() {
                        node.action = Some((order, r.action));
                    }
                }
                RuleKind::DomainKeyword => {
                    let key = *r.pattern.as_bytes().first().unwrap_or(&0);
                    idx.keywords
                        .entry(key)
                        .or_default()
                        .push((r.pattern.clone(), order, r.action));
                }
                RuleKind::IpCidr => {
                    if let Some((net, p)) = parse_cidr(&r.pattern) {
                        idx.cidrs[p].push((net, order, r.action));
                    }
                }
            }
        }
        idx.suffix_nodes += nodes_added;
        idx.label_bytes += label_added;
        for bucket in idx.cidrs.iter_mut() {
            bucket.sort_by_key(|e| e.0);
        }
        let prefixes: Vec<usize> = (0..=32)
            .rev()
            .filter(|&p| !idx.cidrs[p].is_empty())
            .collect();
        idx.cidr_prefixes = prefixes;
        idx
    }

    /// 索引化查询：与规则条数基本无关，返回 action。
    fn lookup(&self, host: &str) -> u8 {
        let mut best: (usize, u8) = (usize::MAX, ACTION_DIRECT);

        // 1) 反转域名 trie：O(标签数)。沿路记录序号最小的命中，保持原始优先级。
        // 用 rsplit 直接从最右标签往左走，避免 split().collect() 的堆分配。
        let mut node = &self.suffix;
        for label in host.rsplit('.') {
            match node.children.get(label) {
                Some(child) => {
                    if let Some(cand) = child.action {
                        if cand.0 < best.0 {
                            best = cand;
                        }
                    }
                    node = child;
                }
                None => break,
            }
        }

        // 2) 关键词：按首字节分桶，只比对同桶候选，不再全量 contains。
        if !self.keywords.is_empty() {
            let bytes = host.as_bytes();
            for (i, _) in host.char_indices() {
                if let Some(cands) = self.keywords.get(&bytes[i]) {
                    for (pat, order, action) in cands {
                        if *order < best.0 && host[i..].starts_with(pat.as_str()) {
                            best = (*order, *action);
                        }
                    }
                }
            }
        }

        // 3) IP-CIDR：只遍历非空前缀桶（从长到短），桶内二分，实现最长前缀匹配。
        if let Some(ip) = parse_ipv4(host) {
            for &p in &self.cidr_prefixes {
                let net = ip & prefix_mask(p);
                if let Ok(pos) = self.cidrs[p].binary_search_by_key(&net, |e| e.0) {
                    let e = self.cidrs[p][pos];
                    if e.1 < best.0 {
                        best = (e.1, e.2);
                    }
                }
            }
        }
        best.1
    }

    /// 逻辑状态占用估算（规则真源 + 索引结构），不是进程 RSS。
    fn memory_bytes(&self) -> u64 {
        let trie = self.suffix_nodes * std::mem::size_of::<SuffixNode>() + self.label_bytes;
        let kw: usize = self
            .keywords
            .values()
            .map(|v| {
                v.iter()
                    .map(|(s, _, _)| std::mem::size_of::<(String, usize, u8)>() + s.len())
                    .sum::<usize>()
            })
            .sum();
        let cidr: usize = self
            .cidrs
            .iter()
            .map(|b| b.len() * std::mem::size_of::<(u32, usize, u8)>())
            .sum();
        (self.raw_count * std::mem::size_of::<Rule>()
            + self.pattern_bytes
            + trie
            + kw
            + cidr) as u64
    }
}

/// PoC-1 的线性实现，仅用于同机对照基准，不参与线上查询。
fn linear_match(rules: &[Rule], host: &str) -> u8 {
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

fn default_rules() -> Vec<Rule> {
    vec![
        Rule { kind: RuleKind::DomainSuffix, pattern: "google.com".into(), action: ACTION_PROXY },
        Rule { kind: RuleKind::DomainSuffix, pattern: "github.com".into(), action: ACTION_PROXY },
        Rule { kind: RuleKind::DomainSuffix, pattern: "telegram.org".into(), action: ACTION_PROXY },
        Rule { kind: RuleKind::DomainSuffix, pattern: "bilibili.com".into(), action: ACTION_DIRECT },
        Rule { kind: RuleKind::DomainSuffix, pattern: "qq.com".into(), action: ACTION_DIRECT },
        Rule { kind: RuleKind::DomainKeyword, pattern: "ads".into(), action: ACTION_REJECT },
        Rule { kind: RuleKind::DomainKeyword, pattern: "tracker".into(), action: ACTION_REJECT },
        Rule { kind: RuleKind::IpCidr, pattern: "192.168.0.0/16".into(), action: ACTION_DIRECT },
        Rule { kind: RuleKind::IpCidr, pattern: "10.0.0.0/8".into(), action: ACTION_DIRECT },
    ]
}

// ============================ 会话状态 ============================

pub struct Session {
    running: AtomicBool,
    start_ms: AtomicU64,
    up_bytes: AtomicU64,
    down_bytes: AtomicU64,
    packets: AtomicU64,
}

impl Session {
    fn new() -> Self {
        Session {
            running: AtomicBool::new(false),
            start_ms: AtomicU64::new(0),
            up_bytes: AtomicU64::new(0),
            down_bytes: AtomicU64::new(0),
            packets: AtomicU64::new(0),
        }
    }

    /// 启动或恢复会话；seed_up / seed_down 来自上次落盘，保证重启后读数连续。
    fn start(&self, now_ms: u64, seed_up: u64, seed_down: u64) {
        self.start_ms.store(now_ms, Ordering::Relaxed);
        self.up_bytes.store(seed_up, Ordering::Relaxed);
        self.down_bytes.store(seed_down, Ordering::Relaxed);
        self.packets.store(0, Ordering::Relaxed);
        self.running.store(true, Ordering::Relaxed);
    }

    fn stop(&self) {
        self.running.store(false, Ordering::Relaxed);
    }

    fn running(&self) -> bool {
        self.running.load(Ordering::Relaxed)
    }

    fn uptime_sec(&self, now_ms: u64) -> u64 {
        if !self.running() {
            return 0;
        }
        now_ms.saturating_sub(self.start_ms.load(Ordering::Relaxed)) / 1000
    }

    fn up(&self) -> u64 { self.up_bytes.load(Ordering::Relaxed) }
    fn down(&self) -> u64 { self.down_bytes.load(Ordering::Relaxed) }
    fn packets(&self) -> u64 { self.packets.load(Ordering::Relaxed) }
}

// ============================ Core ============================

pub struct Core {
    /// 规则真源（仅线性对照基准与内存估算使用）
    rules: Mutex<Vec<Rule>>,
    /// 线上查询走的索引
    index: Mutex<RuleIndex>,
    connections: Mutex<HashMap<u64, Connection>>,
    next_id: AtomicU64,
    loopback_bytes: AtomicU64,
    session: Session,
}

impl Core {
    pub fn new() -> Self {
        let rules = default_rules();
        let index = RuleIndex::build(&rules);
        Core {
            rules: Mutex::new(rules),
            index: Mutex::new(index),
            connections: Mutex::new(HashMap::new()),
            next_id: AtomicU64::new(1),
            loopback_bytes: AtomicU64::new(0),
            session: Session::new(),
        }
    }

    /// 生成 count 条规则（基准用），重建索引，返回实际条数。
    pub fn load_rules(&self, count: usize) -> usize {
        let mut new_rules = Vec::with_capacity(count);
        for i in 0..count {
            new_rules.push(Rule {
                kind: RuleKind::DomainSuffix,
                pattern: format!("node{:05}.example.net", i),
                action: (i % 3) as u8,
            });
        }
        let new_index = RuleIndex::build(&new_rules);
        let mut rv = self.rules.lock().unwrap();
        let mut ix = self.index.lock().unwrap();
        *rv = new_rules;
        *ix = new_index;
        count
    }

    /// 基准跑完后恢复默认规则集，避免首页「规则条数」被基准污染。
    pub fn reset_rules(&self) -> usize {
        let new_rules = default_rules();
        let n = new_rules.len();
        let new_index = RuleIndex::build(&new_rules);
        let mut rv = self.rules.lock().unwrap();
        let mut ix = self.index.lock().unwrap();
        *rv = new_rules;
        *ix = new_index;
        n
    }

    pub fn rule_count(&self) -> usize {
        self.rules.lock().unwrap().len()
    }

    pub fn index_nodes(&self) -> usize {
        self.index.lock().unwrap().suffix_nodes
    }

    /// 规则匹配：命中返回 action，未命中 DIRECT。（索引版）
    pub fn match_host(&self, host: &str) -> u8 {
        self.index.lock().unwrap().lookup(host)
    }

    /// 线性实现查询，供基准做语义一致性校验（确认索引化没改变命中结果）。
    pub fn match_host_linear(&self, host: &str) -> u8 {
        linear_match(self.rules.lock().unwrap().as_slice(), host)
    }

    /// 索引引擎匹配吞吐基准，返回耗时毫秒。
    pub fn bench_matches(&self, iterations: usize) -> f64 {
        let ix = self.index.lock().unwrap();
        let start = Instant::now();
        let mut acc = 0u64;
        for i in 0..iterations {
            acc += ix.lookup(HOSTS[i % HOSTS.len()]) as u64;
        }
        black_box(acc);
        start.elapsed().as_secs_f64() * 1000.0
    }

    /// 线性引擎对照基准（PoC-1 实现），返回耗时毫秒。
    pub fn bench_matches_linear(&self, iterations: usize) -> f64 {
        let rv = self.rules.lock().unwrap();
        let start = Instant::now();
        let mut acc = 0u64;
        for i in 0..iterations {
            acc += linear_match(rv.as_slice(), HOSTS[i % HOSTS.len()]) as u64;
        }
        black_box(acc);
        start.elapsed().as_secs_f64() * 1000.0
    }

    /// 模拟数据面：逐包查规则 + 更新连接表 + 统计字节，返回耗时毫秒。
    /// 不接管真实 tun，装机后不会断网；真实 tun2socks 留到阶段 2。
    pub fn bench_packets(&self, packets: usize, size: usize) -> f64 {
        let ix = self.index.lock().unwrap();
        let mut conns = self.connections.lock().unwrap();
        let start = Instant::now();
        let mut acc = 0u64;
        for i in 0..packets {
            let host = HOSTS[i % HOSTS.len()];
            let action = ix.lookup(host);
            let id = (i % 64) as u64;
            let c = conns.entry(id).or_insert(Connection { bytes: 0, action });
            c.bytes += size as u64;
            acc += action as u64 + size as u64;
        }
        black_box(acc);
        drop(conns);
        self.loopback_bytes
            .fetch_add((packets * size) as u64, Ordering::Relaxed);
        start.elapsed().as_secs_f64() * 1000.0
    }

    /// 会话 tick：连接状态下跑一小段模拟数据面，累加上下行字节 / 包数 / 连接表。
    /// UI 每秒调一次，界面上的时长与流量因此是内核真值，不是写死常量。
    pub fn session_tick(&self, packets: usize, size: usize) -> u64 {
        if !self.session.running() {
            return 0;
        }
        let ix = self.index.lock().unwrap();
        let mut conns = self.connections.lock().unwrap();
        let mut acc = 0u64;
        for i in 0..packets {
            let host = HOSTS[i % HOSTS.len()];
            let action = ix.lookup(host);
            let id = (i % 64) as u64;
            let c = conns.entry(id).or_insert(Connection { bytes: 0, action });
            c.bytes += size as u64;
            acc += size as u64;
        }
        black_box(acc);
        drop(conns);
        let up = acc / 3;
        let down = acc - up;
        self.session.up_bytes.fetch_add(up, Ordering::Relaxed);
        self.session.down_bytes.fetch_add(down, Ordering::Relaxed);
        self.session.packets.fetch_add(packets as u64, Ordering::Relaxed);
        self.loopback_bytes.fetch_add(acc, Ordering::Relaxed);
        acc
    }

    pub fn session_start(&self, now_ms: u64, seed_up: u64, seed_down: u64) {
        self.session.start(now_ms, seed_up, seed_down);
    }
    pub fn session_stop(&self) { self.session.stop(); }
    pub fn session_running(&self) -> bool { self.session.running() }
    pub fn session_uptime_sec(&self, now_ms: u64) -> u64 { self.session.uptime_sec(now_ms) }
    pub fn session_up(&self) -> u64 { self.session.up() }
    pub fn session_down(&self) -> u64 { self.session.down() }
    pub fn session_packets(&self) -> u64 { self.session.packets() }

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

    /// 逻辑状态占用估算（规则真源 + 索引 + 连接表），不是进程 RSS。
    pub fn logical_bytes(&self) -> u64 {
        let ix = self.index.lock().unwrap();
        let conns = self.connections.lock().unwrap();
        ix.memory_bytes()
            + (conns.len() * (std::mem::size_of::<Connection>() + 16)) as u64
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
