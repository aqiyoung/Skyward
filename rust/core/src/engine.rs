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

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
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

// ============================ 代理节点（Clash 配置解析） ============================

#[derive(Clone)]
pub struct ProxyNode {
    pub name: String,
    pub ptype: String,
    pub server: String,
    pub port: u16,
    pub group: String,
    pub delay_ms: i32,
    pub secret: String,
    pub cipher: String,
    pub tls: bool,
    pub sni: String,
    pub transport: String,
    pub security: String,
    pub flow: String,
    pub insecure: bool,
}

impl ProxyNode {
    pub fn supported(&self) -> bool {
        if self.server.is_empty() || self.port == 0 || self.secret.is_empty() || self.insecure {
            return false;
        }
        match self.ptype.as_str() {
            "ss" => self.transport == "tcp" && self.cipher == "chacha20-ietf-poly1305",
            "trojan" => {
                self.tls
                    && self.transport == "tcp"
                    && (self.security.is_empty() || self.security == "tls")
            }
            "vless" => {
                self.transport == "tcp"
                    && self.flow.is_empty()
                    && matches!(self.security.as_str(), "" | "none" | "tls")
                    && crate::outbound::parse_uuid(&self.secret).is_ok()
            }
            _ => false,
        }
    }
}

/// 节点类型 → 稳定整型编码，供 Java 侧着色 / 徽标，避免跨语言传字符串类型。
pub fn node_type_code(t: &str) -> u8 {
    match t {
        "ss" => 0, "ssr" => 1, "vmess" => 2, "vless" => 3, "trojan" => 4,
        "hysteria" => 5, "hysteria2" => 6, "socks5" => 7, "http" => 8, "tuic" => 9,
        "wireguard" => 10, "snell" => 11, "shadowquic" => 12, "direct" => 13,
        _ => 99,
    }
}

struct NodeBuilder {
    name: String,
    ptype: String,
    server: String,
    port: u16,
    group: String,
    delay_ms: i32,
    secret: String,
    uuid: String,
    cipher: String,
    tls: bool,
    sni: String,
    transport: String,
    security: String,
    flow: String,
    insecure: bool,
}

impl NodeBuilder {
    fn new() -> Self {
        NodeBuilder {
            name: String::new(),
            ptype: String::new(),
            server: String::new(),
            port: 0,
            group: String::new(),
            delay_ms: -1,
            secret: String::new(),
            uuid: String::new(),
            cipher: String::new(),
            tls: false,
            sni: String::new(),
            transport: "tcp".into(),
            security: String::new(),
            flow: String::new(),
            insecure: false,
        }
    }
}

fn yaml_scalar(raw: &str) -> String {
    let value = raw.trim();
    if value.len() >= 2 {
        let first = value.as_bytes()[0];
        let last = value.as_bytes()[value.len() - 1];
        if (first == b'\'' && last == b'\'') || (first == b'"' && last == b'"') {
            let inner = &value[1..value.len() - 1];
            return if first == b'\'' {
                inner.replace("''", "'")
            } else {
                inner.replace("\\\"", "\"").replace("\\\\", "\\")
            };
        }
    }
    value.split_once(" #").map(|(v, _)| v.trim()).unwrap_or(value).to_string()
}

fn parse_bool(value: &str) -> bool {
    matches!(value.trim().to_ascii_lowercase().as_str(), "true" | "yes" | "on" | "1" | "tls")
}

fn parse_kv(line: &str, b: &mut NodeBuilder) {
    let Some((k, v)) = line.split_once(':') else { return };
    let key = k.trim().to_ascii_lowercase();
    let val = yaml_scalar(v);
    match key.as_str() {
        "name" => b.name = val,
        "type" => b.ptype = val.to_ascii_lowercase(),
        "server" => b.server = val,
        "port" => b.port = val.parse::<u16>().unwrap_or(0),
        "password" => b.secret = val,
        "uuid" => b.uuid = val,
        "cipher" => b.cipher = val.to_ascii_lowercase(),
        "tls" => b.tls = parse_bool(&val),
        "security" => {
            b.security = val.to_ascii_lowercase();
            b.tls = matches!(b.security.as_str(), "tls" | "reality");
        }
        "sni" | "servername" | "server-name" | "peer" => b.sni = val,
        "network" | "transport" => b.transport = val.to_ascii_lowercase(),
        "flow" => b.flow = val,
        "skip-cert-verify" | "allowinsecure" => b.insecure = parse_bool(&val),
        "plugin" if !val.is_empty() => b.transport = "plugin".into(),
        _ => {}
    }
}

pub fn parse_clash_proxies(text: &str) -> Vec<ProxyNode> {
    let mut nodes = Vec::new();
    let mut in_proxies = false;
    let mut proxies_indent = 0;
    let mut item_indent = None;
    let mut current = None;
    for raw in text.lines() {
        let indent = raw.len() - raw.trim_start().len();
        let line = raw.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        if !line.starts_with('-') && line.contains(':') {
            let key = line.split(':').next().unwrap_or("").trim();
            if key == "proxies" {
                in_proxies = true;
                proxies_indent = indent;
                item_indent = None;
                if let Some(builder) = current.take() {
                    flush(&mut nodes, builder);
                }
                continue;
            }
            if indent <= proxies_indent {
                in_proxies = false;
                if let Some(builder) = current.take() {
                    flush(&mut nodes, builder);
                }
                continue;
            }
        }
        if !in_proxies {
            continue;
        }
        if let Some(rest) = line.strip_prefix("- ") {
            if item_indent.is_some_and(|expected| indent != expected) {
                continue;
            }
            item_indent.get_or_insert(indent);
            if let Some(builder) = current.take() {
                flush(&mut nodes, builder);
            }
            let mut builder = NodeBuilder::new();
            parse_kv(rest, &mut builder);
            current = Some(builder);
        } else if line == "-" {
            if item_indent.is_some_and(|expected| indent != expected) {
                continue;
            }
            item_indent.get_or_insert(indent);
            if let Some(builder) = current.take() {
                flush(&mut nodes, builder);
            }
            current = Some(NodeBuilder::new());
        } else if indent > proxies_indent {
            if let Some(builder) = current.as_mut() {
                parse_kv(line, builder);
            }
        }
    }
    if let Some(builder) = current {
        flush(&mut nodes, builder);
    }
    nodes
}

fn flush(out: &mut Vec<ProxyNode>, b: NodeBuilder) {
    if b.name.is_empty() || b.ptype.is_empty() {
        return;
    }
    let secret = if b.ptype == "vless" && !b.uuid.is_empty() { b.uuid } else { b.secret };
    let tls = if b.ptype == "trojan" {
        true
    } else if b.security.is_empty() {
        b.tls
    } else {
        matches!(b.security.as_str(), "tls" | "reality")
    };
    out.push(ProxyNode {
        name: b.name,
        ptype: b.ptype,
        server: b.server,
        port: b.port,
        group: b.group,
        delay_ms: b.delay_ms,
        secret,
        cipher: b.cipher,
        tls,
        sni: b.sni,
        transport: b.transport,
        security: b.security,
        flow: b.flow,
        insecure: b.insecure,
    });
}

fn percent_decode(value: &str, plus_as_space: bool) -> String {
    let bytes = value.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() {
            if let Ok(hex) = std::str::from_utf8(&bytes[i + 1..i + 3]) {
                if let Ok(byte) = u8::from_str_radix(hex, 16) {
                    out.push(byte);
                    i += 3;
                    continue;
                }
            }
        }
        out.push(if plus_as_space && bytes[i] == b'+' { b' ' } else { bytes[i] });
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

fn decode_base64(value: &str) -> Option<Vec<u8>> {
    let mut out = Vec::with_capacity(value.len() * 3 / 4);
    let mut bits = 0u32;
    let mut count = 0u32;
    for byte in value.bytes() {
        if byte.is_ascii_whitespace() {
            continue;
        }
        if byte == b'=' {
            break;
        }
        let digit = match byte {
            b'A'..=b'Z' => byte - b'A',
            b'a'..=b'z' => byte - b'a' + 26,
            b'0'..=b'9' => byte - b'0' + 52,
            b'+' | b'-' => 62,
            b'/' | b'_' => 63,
            _ => return None,
        };
        bits = (bits << 6) | digit as u32;
        count += 6;
        if count >= 8 {
            count -= 8;
            out.push(((bits >> count) & 0xff) as u8);
        }
    }
    (!out.is_empty()).then_some(out)
}

fn parse_host_port(value: &str) -> Result<(String, u16), String> {
    if let Some(rest) = value.strip_prefix('[') {
        let end = rest.find(']').ok_or_else(|| "IPv6 地址格式无效".to_string())?;
        let host = rest[..end].to_string();
        let port = rest[end + 1..]
            .strip_prefix(':')
            .ok_or_else(|| "节点端口缺失".to_string())?
            .parse::<u16>()
            .map_err(|_| "节点端口无效".to_string())?;
        if host.is_empty() || port == 0 {
            return Err("节点地址或端口无效".into());
        }
        return Ok((host, port));
    }
    let (host, raw_port) = value.rsplit_once(':').ok_or_else(|| "节点端口缺失".to_string())?;
    let port = raw_port.parse::<u16>().map_err(|_| "节点端口无效".to_string())?;
    if host.is_empty() || host.contains(':') || port == 0 {
        return Err("节点地址或端口无效".into());
    }
    Ok((host.to_string(), port))
}

fn query_map(query: &str) -> HashMap<String, String> {
    query.split('&').filter_map(|pair| {
        let (key, value) = pair.split_once('=').unwrap_or((pair, ""));
        if key.is_empty() { None } else {
            Some((percent_decode(key, true).to_ascii_lowercase(), percent_decode(value, true)))
        }
    }).collect()
}

fn uri_node(name: String, ptype: &str, host: String, port: u16, secret: String) -> ProxyNode {
    ProxyNode {
        name: if name.is_empty() { format!("{host}:{port}") } else { name },
        ptype: ptype.into(),
        server: host,
        port,
        group: String::new(),
        delay_ms: -1,
        secret,
        cipher: "chacha20-ietf-poly1305".into(),
        tls: false,
        sni: String::new(),
        transport: "tcp".into(),
        security: String::new(),
        flow: String::new(),
        insecure: false,
    }
}

fn json_value(json: &str, key: &str) -> Option<String> {
    let needle = format!("\"{key}\"");
    let tail = json.split_once(&needle)?.1.trim_start().strip_prefix(':')?.trim_start();
    if let Some(quoted) = tail.strip_prefix('"') {
        let mut value = String::new();
        let mut chars = quoted.chars();
        while let Some(ch) = chars.next() {
            match ch {
                '"' => return Some(value),
                '\\' => match chars.next()? {
                    '"' => value.push('"'),
                    '\\' => value.push('\\'),
                    '/' => value.push('/'),
                    'b' => value.push('\u{0008}'),
                    'f' => value.push('\u{000c}'),
                    'n' => value.push('\n'),
                    'r' => value.push('\r'),
                    't' => value.push('\t'),
                    'u' => {
                        let hex: String = chars.by_ref().take(4).collect();
                        let code = u16::from_str_radix(&hex, 16).ok()?;
                        value.push(char::from_u32(code as u32)?);
                    }
                    _ => return None,
                },
                _ => value.push(ch),
            }
        }
        return None;
    }
    let end = tail.find(|ch| ch == ',' || ch == '}' || ch == ']')?;
    let value = tail[..end].trim();
    (!value.is_empty() && value != "null").then(|| value.to_string())
}

fn parse_proxy_uri(input: &str) -> Result<Option<ProxyNode>, String> {
    let Some((scheme, rest)) = input.split_once("://") else { return Ok(None) };
    let scheme = scheme.to_ascii_lowercase();
    if !matches!(scheme.as_str(), "ss" | "trojan" | "vless" | "vmess") {
        return Ok(None);
    }
    let (without_name, raw_name) = rest.split_once('#').unwrap_or((rest, ""));
    let name = percent_decode(raw_name, false);
    let (authority, raw_query) = without_name.split_once('?').unwrap_or((without_name, ""));
    let query = query_map(raw_query);
    match scheme.as_str() {
        "vmess" => {
            let json = decode_base64(authority)
                .and_then(|bytes| String::from_utf8(bytes).ok())
                .ok_or_else(|| "VMess URI 编码无效".to_string())?;
            let host = json_value(&json, "add").ok_or_else(|| "VMess URI 缺少服务器地址".to_string())?;
            let port = json_value(&json, "port")
                .and_then(|value| value.parse::<u16>().ok())
                .filter(|port| *port > 0)
                .ok_or_else(|| "VMess URI 端口无效".to_string())?;
            let secret = json_value(&json, "id").unwrap_or_default();
            let label = if name.is_empty() { json_value(&json, "ps").unwrap_or_default() } else { name };
            let mut node = uri_node(label, "vmess", host, port, secret);
            node.transport = json_value(&json, "net").unwrap_or_else(|| "tcp".into()).to_ascii_lowercase();
            node.tls = json_value(&json, "tls").is_some_and(|value| value == "tls" || value == "1");
            node.sni = json_value(&json, "sni").unwrap_or_default();
            node.cipher = json_value(&json, "scy").unwrap_or_default();
            Ok(Some(node))
        }
        "ss" => {
            let (userinfo, host_port) = if let Some((user, host)) = authority.rsplit_once('@') {
                (percent_decode(user, false), host.to_string())
            } else {
                let decoded = decode_base64(authority)
                    .and_then(|bytes| String::from_utf8(bytes).ok())
                    .ok_or_else(|| "Shadowsocks URI 编码无效".to_string())?;
                let (user, host) = decoded.rsplit_once('@').ok_or_else(|| "Shadowsocks URI 缺少服务器地址".to_string())?;
                (user.to_string(), host.to_string())
            };
            let userinfo = decode_base64(&userinfo)
                .and_then(|bytes| String::from_utf8(bytes).ok())
                .unwrap_or(userinfo);
            let (cipher, secret) = userinfo.split_once(':').ok_or_else(|| "Shadowsocks URI 缺少加密方法或密码".to_string())?;
            let (host, port) = parse_host_port(&host_port)?;
            let mut node = uri_node(name, "ss", host, port, percent_decode(secret, false));
            node.cipher = cipher.to_ascii_lowercase();
            if query.get("plugin").is_some_and(|value| !value.is_empty()) {
                node.transport = "plugin".into();
            }
            Ok(Some(node))
        }
        "trojan" | "vless" => {
            let (user, host_port) = authority.rsplit_once('@').ok_or_else(|| "代理 URI 缺少凭据或服务器地址".to_string())?;
            let (host, port) = parse_host_port(host_port)?;
            let mut node = uri_node(name, &scheme, host, port, percent_decode(user, false));
            let transport = query.get("type").cloned().unwrap_or_else(|| "tcp".into()).to_ascii_lowercase();
            node.transport = transport;
            node.sni = query.get("sni").or_else(|| query.get("peer")).cloned().unwrap_or_default();
            node.flow = query.get("flow").cloned().unwrap_or_default();
            node.insecure = query.get("allowinsecure").is_some_and(|value| parse_bool(value));
            node.security = query.get("security").cloned().unwrap_or_default().to_ascii_lowercase();
            node.tls = if scheme == "trojan" {
                node.security != "none"
            } else {
                matches!(node.security.as_str(), "tls" | "reality")
            };
            Ok(Some(node))
        }
        _ => Ok(None),
    }
}

fn decode_subscription(text: &str) -> String {
    let trimmed = text.trim().trim_start_matches('\u{feff}');
    if let Some(decoded) = decode_base64(trimmed).and_then(|bytes| String::from_utf8(bytes).ok()) {
        if decoded.contains("proxies:") || decoded.lines().any(|line| line.contains("://")) {
            return decoded;
        }
    }
    trimmed.to_string()
}

pub fn parse_config(text: &str) -> Result<Vec<ProxyNode>, String> {
    if text.trim().is_empty() {
        return Err("配置内容为空".into());
    }
    if text.len() > 5 * 1024 * 1024 {
        return Err("配置内容超过 5 MiB".into());
    }
    let decoded = decode_subscription(text);
    let nodes = if decoded.lines().any(|line| line.trim_start().starts_with("proxies:")) {
        parse_clash_proxies(&decoded)
    } else {
        let mut nodes = Vec::new();
        for line in decoded.lines().map(str::trim).filter(|line| !line.is_empty() && !line.starts_with('#')) {
            if let Some(node) = parse_proxy_uri(line)? {
                nodes.push(node);
            }
        }
        nodes
    };
    if nodes.is_empty() {
        return Err("没有找到可识别的代理节点".into());
    }
    Ok(nodes)
}

/// 测试夹具：一份 Clash/Mihomo 风格配置，地址和凭据均为虚构，不作为可用订阅展示。
pub const SAMPLE_CONFIG: &str = r#"
proxies:
  - name: "HK · 专线 01"
    type: ss
    server: 103.45.12.7
    port: 8388
    cipher: chacha20-ietf-poly1305
    password: "sample-ss-pass-001"
  - name: "Tokyo · BGP 02"
    type: trojan
    server: 45.76.88.19
    port: 443
    password: "sample-trojan-pass-002"
    sni: hk.example.com
  - name: "Singapore · IEPL 03"
    type: vmess
    server: 194.233.10.5
    port: 10086
    uuid: "b0c4f1a2-3d5e-4f6a-8b9c-0d1e2f3a4b5c"
    alterId: 0
    cipher: auto
  - name: "US-West · 04"
    type: vless
    server: 162.159.192.4
    port: 443
    uuid: "c1d2e3f4-a5b6-4c7d-8e9f-0a1b2c3d4e5f"
    flow: xtls-rprx-vision
  - name: "HK · CN2 05"
    type: hysteria2
    server: 103.45.12.33
    port: 8443
    password: "sample-hy2-pass-005"
  - name: "Taiwan · 06"
    type: tuic
    server: 211.23.88.10
    port: 10443
    uuid: "d2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a"
    password: "sample-tuic-pass-006"
  - name: "London · 07"
    type: socks5
    server: 185.12.4.9
    port: 1080
    username: "user07"
    password: "pass07"
  - name: "DIRECT 直连"
    type: direct
    server: localhost
    port: 0
"#;

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

    /// 索引化查询：返回命中的 (规则序号, 动作, 类型)，未命中 None。
    /// 保持「按序首次命中」语义——沿路记录序号最小的命中。
    fn lookup_detail(&self, host: &str) -> Option<(usize, u8, RuleKind)> {
        let mut best_order: usize = usize::MAX;
        let mut best_action: u8 = ACTION_DIRECT;
        let mut best_kind: RuleKind = RuleKind::DomainSuffix;

        // 1) 反转域名 trie：O(标签数)。沿路记录序号最小的命中，保持原始优先级。
        // 用 rsplit 直接从最右标签往左走，避免 split().collect() 的堆分配。
        let mut node = &self.suffix;
        for label in host.rsplit('.') {
            match node.children.get(label) {
                Some(child) => {
                    if let Some(cand) = child.action {
                        if cand.0 < best_order {
                            best_order = cand.0;
                            best_action = cand.1;
                            best_kind = RuleKind::DomainSuffix;
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
                        if *order < best_order && host[i..].starts_with(pat.as_str()) {
                            best_order = *order;
                            best_action = *action;
                            best_kind = RuleKind::DomainKeyword;
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
                    if e.1 < best_order {
                        best_order = e.1;
                        best_action = e.2;
                        best_kind = RuleKind::IpCidr;
                    }
                }
            }
        }

        if best_order == usize::MAX {
            None
        } else {
            Some((best_order, best_action, best_kind))
        }
    }

    /// 索引化查询：返回 action；未命中 DIRECT。
    fn lookup(&self, host: &str) -> u8 {
        self.lookup_detail(host).map(|x| x.1).unwrap_or(ACTION_DIRECT)
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
    /// 按动作分桶的累计：直连 / 代理 / 拒绝 各自的字节与包数。
    dir_bytes: AtomicU64,
    dir_pkts: AtomicU64,
    prx_bytes: AtomicU64,
    prx_pkts: AtomicU64,
    rej_bytes: AtomicU64,
    rej_pkts: AtomicU64,
}

impl Session {
    fn new() -> Self {
        Session {
            running: AtomicBool::new(false),
            start_ms: AtomicU64::new(0),
            up_bytes: AtomicU64::new(0),
            down_bytes: AtomicU64::new(0),
            packets: AtomicU64::new(0),
            dir_bytes: AtomicU64::new(0),
            dir_pkts: AtomicU64::new(0),
            prx_bytes: AtomicU64::new(0),
            prx_pkts: AtomicU64::new(0),
            rej_bytes: AtomicU64::new(0),
            rej_pkts: AtomicU64::new(0),
        }
    }

    /// 启动或恢复会话；seed_up / seed_down 来自上次落盘，保证重启后读数连续。
    /// 分桶累计一并清零，避免跨会话污染。
    fn start(&self, now_ms: u64, seed_up: u64, seed_down: u64) {
        self.start_ms.store(now_ms, Ordering::Relaxed);
        self.up_bytes.store(seed_up, Ordering::Relaxed);
        self.down_bytes.store(seed_down, Ordering::Relaxed);
        self.packets.store(0, Ordering::Relaxed);
        self.dir_bytes.store(0, Ordering::Relaxed);
        self.dir_pkts.store(0, Ordering::Relaxed);
        self.prx_bytes.store(0, Ordering::Relaxed);
        self.prx_pkts.store(0, Ordering::Relaxed);
        self.rej_bytes.store(0, Ordering::Relaxed);
        self.rej_pkts.store(0, Ordering::Relaxed);
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
    nodes: Mutex<Vec<ProxyNode>>,
    last_error: Mutex<String>,
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
            nodes: Mutex::new(Vec::new()),
            last_error: Mutex::new(String::new()),
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

    /// 规则 #i 的匹配模式串（域名 / 关键词 / CIDR 文本）。
    pub fn rule_pattern(&self, i: usize) -> String {
        self.rules.lock().unwrap().get(i).map(|r| r.pattern.clone()).unwrap_or_default()
    }

    /// 规则 #i 的类型：0=DOMAIN-SUFFIX / 1=DOMAIN-KEYWORD / 2=IP-CIDR。
    pub fn rule_kind_code(&self, i: usize) -> u8 {
        self.rules.lock().unwrap().get(i).map(|r| match r.kind {
            RuleKind::DomainSuffix => 0,
            RuleKind::DomainKeyword => 1,
            RuleKind::IpCidr => 2,
        }).unwrap_or(0)
    }

    /// 规则 #i 的动作：0=DIRECT / 1=PROXY / 2=REJECT。
    pub fn rule_action(&self, i: usize) -> u8 {
        self.rules.lock().unwrap().get(i).map(|r| r.action).unwrap_or(0)
    }

    /// 规则 #i 在规则集中的原始序号（即其插入顺序）。
    pub fn rule_order(&self, i: usize) -> usize {
        i
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

    /// Loads a test fixture for the native parser test hook.
    pub fn load_sample_config(&self) -> usize {
        self.parse_text_config(SAMPLE_CONFIG).unwrap_or(0)
    }

    pub fn parse_text_config(&self, text: &str) -> Result<usize, String> {
        match parse_config(text) {
            Ok(nodes) => {
                let count = nodes.len();
                *self.nodes.lock().unwrap() = nodes;
                *self.last_error.lock().unwrap() = String::new();
                Ok(count)
            }
            Err(error) => {
                *self.last_error.lock().unwrap() = error.clone();
                Err(error)
            }
        }
    }

    pub fn set_last_error(&self, error: String) {
        *self.last_error.lock().unwrap() = error;
    }

    pub fn last_error(&self) -> String {
        self.last_error.lock().unwrap().clone()
    }

    pub fn node_count(&self) -> usize {
        self.nodes.lock().unwrap().len()
    }

    pub fn node_name(&self, i: usize) -> String {
        self.nodes
            .lock()
            .unwrap()
            .get(i)
            .map(|n| n.name.clone())
            .unwrap_or_default()
    }

    pub fn node_type(&self, i: usize) -> String {
        self.nodes
            .lock()
            .unwrap()
            .get(i)
            .map(|n| n.ptype.clone())
            .unwrap_or_default()
    }

    pub fn node_secret(&self, i: usize) -> String {
        self.nodes.lock().unwrap().get(i).map(|n| n.secret.clone()).unwrap_or_default()
    }

    pub fn node_cipher(&self, i: usize) -> String {
        self.nodes.lock().unwrap().get(i).map(|n| n.cipher.clone()).unwrap_or_default()
    }

    pub fn node_tls(&self, i: usize) -> bool {
        self.nodes.lock().unwrap().get(i).is_some_and(|n| n.tls)
    }

    pub fn node_sni(&self, i: usize) -> String {
        self.nodes.lock().unwrap().get(i).map(|n| n.sni.clone()).unwrap_or_default()
    }

    pub fn node_supported(&self, i: usize) -> bool {
        self.nodes.lock().unwrap().get(i).is_some_and(ProxyNode::supported)
    }

    pub fn node_type_code(&self, i: usize) -> u8 {
        self.nodes
            .lock()
            .unwrap()
            .get(i)
            .map(|n| node_type_code(&n.ptype))
            .unwrap_or(99)
    }

    pub fn node_server(&self, i: usize) -> String {
        self.nodes
            .lock()
            .unwrap()
            .get(i)
            .map(|n| n.server.clone())
            .unwrap_or_default()
    }

    pub fn node_port(&self, i: usize) -> u16 {
        self.nodes.lock().unwrap().get(i).map(|n| n.port).unwrap_or(0)
    }

    pub fn node_delay(&self, i: usize) -> i32 {
        self.nodes
            .lock()
            .unwrap()
            .get(i)
            .map(|n| n.delay_ms)
            .unwrap_or(-1)
    }

    pub fn node_group(&self, i: usize) -> String {
        self.nodes
            .lock()
            .unwrap()
            .get(i)
            .map(|n| n.group.clone())
            .unwrap_or_default()
    }

    /// 路由决策：返回命中规则 (序号, 动作, 类型)，未命中 None。
    pub fn decide(&self, host: &str) -> Option<(usize, u8, RuleKind)> {
        self.index.lock().unwrap().lookup_detail(host)
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

    /// 会话 tick：连接状态下跑一小段模拟数据面，累加上下行字节 / 包数 / 连接表，
    /// 并同步按动作（直连 / 代理 / 拒绝）分桶累计，供首页「流量分配」展示。
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
            // 按动作分桶：字节（上行 1/3、下行 2/3，沿用既有语义）与包数分别累加
            let up = (size as u64) / 3;
            let down = (size as u64) - up;
            match action {
                ACTION_DIRECT => {
                    self.session.dir_bytes.fetch_add(up + down, Ordering::Relaxed);
                    self.session.dir_pkts.fetch_add(1, Ordering::Relaxed);
                }
                ACTION_PROXY => {
                    self.session.prx_bytes.fetch_add(up + down, Ordering::Relaxed);
                    self.session.prx_pkts.fetch_add(1, Ordering::Relaxed);
                }
                _ => {
                    self.session.rej_bytes.fetch_add(up + down, Ordering::Relaxed);
                    self.session.rej_pkts.fetch_add(1, Ordering::Relaxed);
                }
            }
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

    /// 按动作统计当前活动连接数（连接表最多 64 条，扫描成本可忽略）。
    pub fn conn_count_by_action(&self, action: u8) -> usize {
        self.connections.lock().unwrap().values().filter(|c| c.action == action).count()
    }

    /// 会话按动作分桶汇总：逗号分隔
    /// dirBytes,dirPkts,dirConns,prxBytes,prxPkts,prxConns,rejBytes,rejPkts,rejConns
    pub fn session_breakdown(&self) -> String {
        let s = &self.session;
        format!(
            "{},{},{},{},{},{},{},{},{}",
            s.dir_bytes.load(Ordering::Relaxed),
            s.dir_pkts.load(Ordering::Relaxed),
            self.conn_count_by_action(ACTION_DIRECT),
            s.prx_bytes.load(Ordering::Relaxed),
            s.prx_pkts.load(Ordering::Relaxed),
            self.conn_count_by_action(ACTION_PROXY),
            s.rej_bytes.load(Ordering::Relaxed),
            s.rej_pkts.load(Ordering::Relaxed),
            self.conn_count_by_action(ACTION_REJECT),
        )
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_sample_config_node_count_and_fields() {
        let nodes = parse_clash_proxies(SAMPLE_CONFIG);
        assert_eq!(nodes.len(), 8);
        assert_eq!(nodes[0].name, "HK · 专线 01");
        assert_eq!(nodes[0].ptype, "ss");
        assert_eq!(nodes[0].server, "103.45.12.7");
        assert_eq!(nodes[0].port, 8388);
        assert_eq!(nodes[0].secret, "sample-ss-pass-001");
        assert!(nodes[0].supported());
        assert_eq!(nodes[7].ptype, "direct");
        assert_eq!(nodes[7].port, 0);
    }

    #[test]
    fn parses_clash_credentials_and_tls_metadata() {
        let text = "proxies:\n  - name: hk\n    type: ss\n    server: edge.example\n    port: 8388\n    cipher: chacha20-ietf-poly1305\n    password: secret\n  - name: tls\n    type: trojan\n    server: edge.example\n    port: 443\n    password: pass\n    sni: cdn.example\n  - name: uuid\n    type: vless\n    server: edge.example\n    port: 443\n    uuid: b831381d-6324-4d53-ad4f-8cda48b30811\n    tls: true\n";
        let nodes = parse_config(text).unwrap();
        assert_eq!(nodes.len(), 3);
        assert!(nodes[0].supported());
        assert_eq!(nodes[0].secret, "secret");
        assert_eq!(nodes[1].sni, "cdn.example");
        assert!(nodes[1].tls);
        assert!(nodes[2].supported());
        assert!(nodes[2].tls);

        let unsupported = parse_config("proxies:\n  - name: missing-cipher\n    type: ss\n    server: edge.example\n    port: 8388\n    password: secret\n    plugin-opts:\n      headers:\n        - X-Test: value\n  - name: unknown-security\n    type: vless\n    server: edge.example\n    port: 443\n    uuid: b831381d-6324-4d53-ad4f-8cda48b30811\n    security: xtls\n").unwrap();
        assert_eq!(unsupported.len(), 2);
        assert!(!unsupported[0].supported());
        assert!(!unsupported[1].supported());
    }

    #[test]
    fn parses_supported_proxy_uri_schemes_and_subscription_base64() {
        let text = "ss://chacha20-ietf-poly1305:secret@example.com:8388#HK\ntrojan://password@example.com:443?sni=edge.example.com#Tokyo\nvless://b831381d-6324-4d53-ad4f-8cda48b30811@example.com:443?security=tls&type=tcp&sni=cdn.example.com#US";
        let nodes = parse_config(text).unwrap();
        assert_eq!(nodes.len(), 3);
        assert!(nodes[0].supported());
        assert_eq!(nodes[0].secret, "secret");
        assert!(nodes[1].supported());
        assert_eq!(nodes[1].sni, "edge.example.com");
        assert!(nodes[2].supported());
        assert_eq!(nodes[2].secret, "b831381d-6324-4d53-ad4f-8cda48b30811");
        let encoded = "ss://YWVzLTI1Ni1nY206cGFzcw==@example.com:8388#legacy";
        let legacy = parse_config(encoded).unwrap();
        assert_eq!(legacy[0].cipher, "aes-256-gcm");
        assert_eq!(legacy[0].secret, "pass");
        assert!(!legacy[0].supported());
        let vmess = "vmess://eyJ2IjoiMiIsInBzIjoiSmFwYW4iLCJhZGQiOiJleGFtcGxlLmNvbSIsInBvcnQiOiI0NDMiLCJpZCI6ImI4MzEzODFkLTYzMjQtNGQ1My1hZDRmLThjZGE0OGIzMDgxMSIsIm5ldCI6InRjcCIsInRscyI6InRscyIsInNjeSI6ImF1dG8ifQ==";
        let parsed = parse_config(vmess).unwrap();
        assert_eq!(parsed[0].name, "Japan");
        assert_eq!(parsed[0].server, "example.com");
        assert_eq!(parsed[0].ptype, "vmess");
        assert!(!parsed[0].supported());
        let encoded_list = "dHJvamFuOi8vcGFzc3dvcmRAZXhhbXBsZS5jb206NDQzI1Rlc3QK";
        let decoded_list = parse_config(encoded_list).unwrap();
        assert_eq!(decoded_list[0].name, "Test");
        assert_eq!(decoded_list[0].secret, "password");
    }

    #[test]
    fn rule_enumeration_matches_default_rules() {
        let c = Core::new();
        assert_eq!(c.rule_count(), 9);
        // google.com -> DOMAIN-SUFFIX(0) / PROXY(1)
        assert_eq!(c.rule_pattern(0), "google.com");
        assert_eq!(c.rule_kind_code(0), 0);
        assert_eq!(c.rule_action(0), ACTION_PROXY);
        // 192.168.0.0/16 -> IP-CIDR(2) / DIRECT(0)
        assert_eq!(c.rule_kind_code(7), 2);
        assert_eq!(c.rule_action(7), ACTION_DIRECT);
        // ads keyword -> REJECT(2)
        assert_eq!(c.rule_pattern(5), "ads");
        assert_eq!(c.rule_action(5), ACTION_REJECT);
    }

    #[test]
    fn session_tick_buckets_by_action() {
        let c = Core::new();
        c.session_start(0, 0, 0);
        c.session_tick(200, 1500);
        let b = c.session_breakdown();
        let v: Vec<&str> = b.split(',').collect();
        assert_eq!(v.len(), 9);
        // 三桶包数之和 = 200（每条包恰好归入一个动作）
        let pkts: u64 = v[1].parse::<u64>().unwrap()
            + v[4].parse::<u64>().unwrap()
            + v[7].parse::<u64>().unwrap();
        assert_eq!(pkts, 200);
        // 三桶字节之和 > 0
        let total: u64 = v[0].parse::<u64>().unwrap()
            + v[3].parse::<u64>().unwrap()
            + v[6].parse::<u64>().unwrap();
        assert!(total > 0);
        // 会话总字节应与分桶合计一致
        assert_eq!(c.session_up() + c.session_down(), total);
    }

    #[test]
    fn decide_returns_expected_rule_for_known_host() {
        let rules = default_rules();
        let idx = RuleIndex::build(&rules);
        // google.com 命中 DOMAIN-SUFFIX google.com -> PROXY(1)
        let d = idx.lookup_detail("www.google.com").expect("should match");
        assert_eq!(d.1, ACTION_PROXY);
        assert_eq!(d.2, RuleKind::DomainSuffix);
        // 未知域名不命中
        assert!(idx.lookup_detail("example.invalid").is_none());
        // IP-CIDR 命中 192.168.x
        let d2 = idx.lookup_detail("192.168.5.5").expect("cidr match");
        assert_eq!(d2.1, ACTION_DIRECT);
        assert_eq!(d2.2, RuleKind::IpCidr);
    }
}
