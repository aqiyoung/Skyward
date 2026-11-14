//! 用户态最小 TCP 栈（PoC-7）。
//!
//! 为什么需要它：TUN 里拿到的是原始 IP 帧，客户端（手机上的 App）发起的是真实 TCP 连接。
//! 内核必须自己扮演"对端"：回 SYN-ACK、维护序列号、把 payload 交出去、把上游回来的数据
//! 重新封成 IP/TCP 包写回 TUN。目前只做被动打开（我们永远是接收 SYN 的一方），这与
//! 代理的实际角色一致。
//!
//! 刻意不做的（先让链路跑起来，后续按需补）：
//! - 不协商窗口缩放 / SACK / 时间戳：SYN-ACK 只发 20 字节裸头，对端会退回窗口 65535
//! - 不做乱序重排：非期望序号的段丢弃并回 ACK，让对端重传缺口
//! - 不做拥塞控制：我们基本只发 ACK 和上游回来的数据，靠固定窗口 + 重传兜底
//!
//! 设计上把状态机与 IO 彻底分离：`on_packet` 吃字节、吐字节，因此可以在单测里
//! 用一个"模拟客户端"把握手、收发、关闭全流程跑一遍，不依赖 TUN 设备。

use std::collections::HashMap;
use std::net::Ipv4Addr;
use std::time::{Duration, Instant};

pub const FIN: u8 = 0x01;
pub const SYN: u8 = 0x02;
pub const RST: u8 = 0x04;
pub const PSH: u8 = 0x08;
pub const ACK: u8 = 0x10;

/// 单个段的最大载荷。tun MTU 1500，留出 IP 20 + TCP 20 + 余量。
pub const MSS: usize = 1400;
/// 我们通告的接收窗口。不做缩放，固定 64K。
const WINDOW: u16 = 65535;
/// 未确认段多久重传。
const RTO: Duration = Duration::from_millis(300);
/// 同一段最多重传次数，超过即判定连接已死。
const MAX_RETRIES: u32 = 8;

/// 一条 TCP 流的四元组。`src` 是手机上 App 的地址，`dst` 是被访问的目标。
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
pub struct FlowKey {
    pub src: Ipv4Addr,
    pub sport: u16,
    pub dst: Ipv4Addr,
    pub dport: u16,
}

impl FlowKey {
    pub fn new(src: Ipv4Addr, sport: u16, dst: Ipv4Addr, dport: u16) -> Self {
        Self { src, sport, dst, dport }
    }

    /// 给日志/统计用的简短描述。
    pub fn describe(&self) -> String {
        format!("{}:{} -> {}:{}", self.src, self.sport, self.dst, self.dport)
    }
}

/// 解析出来的 TCP 段。
#[derive(Debug, Clone)]
pub struct Segment {
    pub key: FlowKey,
    pub seq: u32,
    pub ack: u32,
    pub flags: u8,
    pub payload: Vec<u8>,
}

/// 状态机吐出的事件，交给 IO 层去驱动上游。
#[derive(Debug, Clone)]
pub enum Event {
    /// 握手完成，可以向上游拨号了。挂起的 payload 会随后以 `Data` 送达。
    Opened(FlowKey),
    /// 客户端发来数据。
    Data(FlowKey, Vec<u8>),
    /// 客户端关闭了发送方向。
    PeerFin(FlowKey),
    /// 连接异常结束（RST / 重传耗尽）。
    Aborted(FlowKey),
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum State {
    SynReceived,
    Established,
    /// 对端 FIN 已收到，我们在等自己的数据发完。
    PeerClosed,
}

/// 已发出但未被确认的段，用于重传。
struct Outstanding {
    seq: u32,
    flags: u8,
    payload: Vec<u8>,
    sent_at: Instant,
    retries: u32,
}

struct Conn {
    state: State,
    /// 我们下一个要发的序列号。
    snd_nxt: u32,
    /// 对端下一个期望的序列号（也就是我们要 ACK 的值）。
    rcv_nxt: u32,
    outstanding: Vec<Outstanding>,
}

impl Conn {
    fn new(isn: u32, peer_isn: u32) -> Self {
        Self {
            state: State::SynReceived,
            snd_nxt: isn.wrapping_add(1), // SYN 占一个序号
            rcv_nxt: peer_isn.wrapping_add(1),
            outstanding: Vec::new(),
        }
    }
}

/// 序列号比较（处理 2^32 回绕）。
fn seq_lt(a: u32, b: u32) -> bool {
    (a.wrapping_sub(b) as i32) < 0
}

fn seq_le(a: u32, b: u32) -> bool {
    a == b || seq_lt(a, b)
}

/// Internet checksum：16 位反码求和再取反。
pub fn checksum(parts: &[&[u8]]) -> u16 {
    let mut sum: u32 = 0;
    let mut odd: Option<u8> = None;
    for part in parts {
        let mut i = 0;
        if let Some(hi) = odd.take() {
            if !part.is_empty() {
                sum += u16::from_be_bytes([hi, part[0]]) as u32;
                i = 1;
            } else {
                odd = Some(hi);
                continue;
            }
        }
        while i + 1 < part.len() {
            sum += u16::from_be_bytes([part[i], part[i + 1]]) as u32;
            i += 2;
        }
        if i < part.len() {
            odd = Some(part[i]);
        }
    }
    if let Some(hi) = odd {
        sum += u16::from_be_bytes([hi, 0]) as u32;
    }
    while sum >> 16 != 0 {
        sum = (sum & 0xffff) + (sum >> 16);
    }
    !(sum as u16)
}

/// 从原始 IPv4 帧里取出一段 TCP。非 TCP、非 IPv4、分片（offset != 0）都返回 None。
pub fn parse_segment(pkt: &[u8]) -> Option<Segment> {
    if pkt.len() < 20 || pkt[0] >> 4 != 4 {
        return None;
    }
    let ihl = ((pkt[0] & 0x0f) as usize) * 4;
    if ihl < 20 || pkt.len() < ihl {
        return None;
    }
    if pkt[9] != 6 {
        return None;
    }
    // 分片偏移非 0 的后续分片没有 TCP 头，直接丢弃。
    let frag_off = u16::from_be_bytes([pkt[6], pkt[7]]) & 0x1fff;
    if frag_off != 0 {
        return None;
    }
    let total_len = u16::from_be_bytes([pkt[2], pkt[3]]) as usize;
    let end = total_len.min(pkt.len());
    if end < ihl + 20 {
        return None;
    }
    let tcp = &pkt[ihl..end];
    let sport = u16::from_be_bytes([tcp[0], tcp[1]]);
    let dport = u16::from_be_bytes([tcp[2], tcp[3]]);
    let seq = u32::from_be_bytes([tcp[4], tcp[5], tcp[6], tcp[7]]);
    let ack = u32::from_be_bytes([tcp[8], tcp[9], tcp[10], tcp[11]]);
    let data_off = ((tcp[12] >> 4) as usize) * 4;
    if data_off < 20 || tcp.len() < data_off {
        return None;
    }
    let flags = tcp[13];
    let payload = tcp[data_off..].to_vec();
    Some(Segment {
        key: FlowKey::new(
            Ipv4Addr::new(pkt[12], pkt[13], pkt[14], pkt[15]),
            sport,
            Ipv4Addr::new(pkt[16], pkt[17], pkt[18], pkt[19]),
            dport,
        ),
        seq,
        ack,
        flags,
        payload,
    })
}

/// 封一个回程包：源/目的与入站包相反（从目标回到手机）。
pub fn build_packet(key: &FlowKey, seq: u32, ack: u32, flags: u8, payload: &[u8]) -> Vec<u8> {
    let src = key.dst.octets();
    let dst = key.src.octets();
    let tcp_len = 20 + payload.len();
    let mut pkt = vec![0u8; 20 + tcp_len];

    // IPv4 头
    pkt[0] = 0x45;
    pkt[1] = 0;
    pkt[2..4].copy_from_slice(&((20 + tcp_len) as u16).to_be_bytes());
    pkt[4..6].copy_from_slice(&next_ip_id().to_be_bytes());
    pkt[6..8].copy_from_slice(&0x4000u16.to_be_bytes()); // DF
    pkt[8] = 64;
    pkt[9] = 6;
    pkt[12..16].copy_from_slice(&src);
    pkt[16..20].copy_from_slice(&dst);
    let ip_sum = checksum(&[&pkt[..20]]);
    pkt[10..12].copy_from_slice(&ip_sum.to_be_bytes());

    // TCP 头
    let t = &mut pkt[20..];
    t[0..2].copy_from_slice(&key.dport.to_be_bytes());
    t[2..4].copy_from_slice(&key.sport.to_be_bytes());
    t[4..8].copy_from_slice(&seq.to_be_bytes());
    t[8..12].copy_from_slice(&ack.to_be_bytes());
    t[12] = (20 / 4) << 4;
    t[13] = flags;
    t[14..16].copy_from_slice(&WINDOW.to_be_bytes());
    t[18..20].copy_from_slice(&0u16.to_be_bytes());
    t[20..].copy_from_slice(payload);

    // TCP 校验和（伪头 + 头 + 载荷）
    let pseudo = [
        src[0], src[1], src[2], src[3], dst[0], dst[1], dst[2], dst[3], 0, 6,
        (tcp_len >> 8) as u8, tcp_len as u8,
    ];
    let sum = checksum(&[&pseudo, &pkt[20..]]);
    pkt[20 + 16..20 + 18].copy_from_slice(&sum.to_be_bytes());
    pkt
}

fn next_ip_id() -> u16 {
    use std::sync::atomic::{AtomicU16, Ordering};
    static ID: AtomicU16 = AtomicU16::new(1);
    ID.fetch_add(1, Ordering::Relaxed)
}

/// TUN 侧 TCP 数据面。所有方法都在同一把锁下调用（IO 层持有可变引用）。
pub struct TcpStack {
    conns: HashMap<FlowKey, Conn>,
    isn: u32,
}

impl Default for TcpStack {
    fn default() -> Self {
        Self::new()
    }
}

impl TcpStack {
    pub fn new() -> Self {
        let seed = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.subsec_nanos() ^ d.as_secs() as u32)
            .unwrap_or(0x1234_5678);
        Self { conns: HashMap::new(), isn: seed }
    }

    pub fn conn_count(&self) -> usize {
        self.conns.len()
    }

    fn next_isn(&mut self) -> u32 {
        // 递增即可，不需要密码学随机。
        self.isn = self.isn.wrapping_mul(1664525).wrapping_add(1013904223);
        self.isn
    }

    /// 处理一个入站 IP 包：返回要写回 TUN 的包，以及需要上游配合的事件。
    pub fn on_packet(&mut self, pkt: &[u8]) -> (Vec<Vec<u8>>, Vec<Event>) {
        let mut out = Vec::new();
        let mut events = Vec::new();
        let seg = match parse_segment(pkt) {
            Some(s) => s,
            None => return (out, events),
        };

        if seg.flags & RST != 0 {
            if self.conns.remove(&seg.key).is_some() {
                events.push(Event::Aborted(seg.key));
            }
            return (out, events);
        }

        if !self.conns.contains_key(&seg.key) {
            if seg.flags & SYN != 0 && seg.flags & ACK == 0 {
                // 新连接：我们扮演服务端
                let isn = self.next_isn();
                let mut conn = Conn::new(isn, seg.seq);
                let synack = build_packet(&seg.key, isn, seg.seq.wrapping_add(1), SYN | ACK, &[]);
                conn.outstanding.push(Outstanding {
                    seq: isn,
                    flags: SYN | ACK,
                    payload: Vec::new(),
                    sent_at: Instant::now(),
                    retries: 0,
                });
                out.push(synack);
                self.conns.insert(seg.key, conn);
            } else {
                // 没有这个连接：按 RFC 793 回 RST
                let ack = if seg.flags & ACK != 0 { seg.seq.wrapping_add(seg.payload.len() as u32) } else { 0 };
                let flags = if seg.flags & ACK != 0 { RST } else { RST | ACK };
                out.push(build_packet(&seg.key, ack, seg.seq.wrapping_add(seg.payload.len() as u32), flags, &[]));
            }
            return (out, events);
        }

        // 拿到锁外的事件，避免借用冲突
        let mut want_open = false;
        let mut drop_conn = false;

        {
            let conn = self.conns.get_mut(&seg.key).unwrap();

            // 1) ACK：清掉已确认的未决段，并推进握手状态
            if seg.flags & ACK != 0 {
                conn.outstanding.retain(|o| {
                    let seg_len = o.payload.len() as u32 + if o.flags & (SYN | FIN) != 0 { 1 } else { 0 };
                    let end = o.seq.wrapping_add(seg_len);
                    !seq_le(end, seg.ack)
                });
                if conn.state == State::SynReceived {
                    conn.state = State::Established;
                    want_open = true;
                }
            }

            // 2) 数据：只接受期望序号，其余回 ACK 让对端重传
            if !seg.payload.is_empty() {
                let n = seg.payload.len() as u32;
                if seg.seq == conn.rcv_nxt {
                    conn.rcv_nxt = conn.rcv_nxt.wrapping_add(n);
                    events.push(Event::Data(seg.key, seg.payload.clone()));
                }
                // 无论接受与否都回 ACK（重复段 / 乱序段让对端尽快重传缺口）
                out.push(build_packet(&seg.key, conn.snd_nxt, conn.rcv_nxt, ACK, &[]));
            }

            // 3) FIN
            if seg.flags & FIN != 0
                && seg.seq.wrapping_add(seg.payload.len() as u32) == conn.rcv_nxt
                && conn.state == State::Established
            {
                conn.rcv_nxt = conn.rcv_nxt.wrapping_add(1);
                let fin_ack = build_packet(&seg.key, conn.snd_nxt, conn.rcv_nxt, FIN | ACK, &[]);
                conn.outstanding.push(Outstanding {
                    seq: conn.snd_nxt,
                    flags: FIN | ACK,
                    payload: Vec::new(),
                    sent_at: Instant::now(),
                    retries: 0,
                });
                conn.snd_nxt = conn.snd_nxt.wrapping_add(1);
                conn.state = State::PeerClosed;
                out.push(fin_ack);
                events.push(Event::PeerFin(seg.key));
            }

            // 4) 已关闭且无未决段：可以回收
            if conn.state == State::PeerClosed && conn.outstanding.is_empty() {
                drop_conn = true;
            }
        }

        if want_open {
            events.push(Event::Opened(seg.key));
        }
        if drop_conn {
            self.conns.remove(&seg.key);
        }
        (out, events)
    }

    /// 上游回来了数据：切片、封包、记入未决队列。
    pub fn on_upstream(&mut self, key: &FlowKey, data: &[u8]) -> Vec<Vec<u8>> {
        let mut out = Vec::new();
        let conn = match self.conns.get_mut(key) {
            Some(c) => c,
            None => return out,
        };
        for chunk in data.chunks(MSS) {
            let seq = conn.snd_nxt;
            let pkt = build_packet(key, seq, conn.rcv_nxt, ACK | PSH, chunk);
            conn.outstanding.push(Outstanding {
                seq,
                flags: ACK | PSH,
                payload: chunk.to_vec(),
                sent_at: Instant::now(),
                retries: 0,
            });
            conn.snd_nxt = conn.snd_nxt.wrapping_add(chunk.len() as u32);
            out.push(pkt);
        }
        out
    }

    /// 上游关闭：发 FIN，并等待对端确认。
    pub fn on_upstream_closed(&mut self, key: &FlowKey) -> Vec<Vec<u8>> {
        let mut out = Vec::new();
        if let Some(conn) = self.conns.get_mut(key) {
            if conn.state == State::PeerClosed {
                // 双向都关了
                return out;
            }
            let fin = build_packet(key, conn.snd_nxt, conn.rcv_nxt, FIN | ACK, &[]);
            conn.outstanding.push(Outstanding {
                seq: conn.snd_nxt,
                flags: FIN | ACK,
                payload: Vec::new(),
                sent_at: Instant::now(),
                retries: 0,
            });
            conn.snd_nxt = conn.snd_nxt.wrapping_add(1);
            out.push(fin);
        }
        out
    }

    /// 上游拨号失败：给客户端一个 RST，避免它一直等。
    pub fn abort(&mut self, key: &FlowKey) -> Vec<Vec<u8>> {
        let mut out = Vec::new();
        if let Some(conn) = self.conns.remove(key) {
            out.push(build_packet(key, conn.snd_nxt, conn.rcv_nxt, RST | ACK, &[]));
        }
        out
    }

    /// 定时驱动：重传超时段，重传次数耗尽则判死。
    pub fn tick(&mut self) -> Vec<Vec<u8>> {
        let now = Instant::now();
        let mut out = Vec::new();
        let mut dead = Vec::new();
        for (key, conn) in self.conns.iter_mut() {
            for o in conn.outstanding.iter_mut() {
                if now.saturating_duration_since(o.sent_at) < RTO {
                    continue;
                }
                if o.retries >= MAX_RETRIES {
                    dead.push(*key);
                    break;
                }
                o.retries += 1;
                o.sent_at = now;
                out.push(build_packet(key, o.seq, conn.rcv_nxt, o.flags, &o.payload));
            }
        }
        for k in dead {
            self.conns.remove(&k);
        }
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const CLIENT: Ipv4Addr = Ipv4Addr::new(10, 10, 10, 2);
    const TARGET: Ipv4Addr = Ipv4Addr::new(93, 184, 216, 34);

    /// 模拟手机侧客户端发出的段（源=CLIENT，目的=TARGET）。
    fn client_packet(key: &FlowKey, seq: u32, ack: u32, flags: u8, payload: &[u8]) -> Vec<u8> {
        // 复用 build_packet，但方向反过来：把 key 反过来构造
        let rev = FlowKey::new(key.dst, key.dport, key.src, key.sport);
        build_packet(&rev, seq, ack, flags, payload)
    }

    fn key() -> FlowKey {
        FlowKey::new(CLIENT, 51000, TARGET, 80)
    }

    /// 从回程包里读出 TCP 头字段，供断言。
    fn parse_out(pkt: &[u8]) -> (u16, u16, u32, u32, u8, Vec<u8>) {
        let seg = parse_segment(pkt).expect("回程包应可解析");
        (seg.key.sport, seg.key.dport, seg.seq, seg.ack, seg.flags, seg.payload)
    }

    #[test]
    fn checksum_matches_known_ipv4_header() {
        // RFC 1071 例子：一个已算好校验和的 IPv4 头，整体再算应为 0
        let mut hdr = vec![
            0x45, 0x00, 0x00, 0x3c, 0x1c, 0x46, 0x40, 0x00, 0x40, 0x06, 0x00, 0x00, 0xac, 0x10,
            0x0a, 0x63, 0xac, 0x10, 0x0a, 0x0c,
        ];
        let s = checksum(&[&hdr]);
        hdr[10..12].copy_from_slice(&s.to_be_bytes());
        assert_eq!(checksum(&[&hdr]), 0, "填好校验和后整体应为 0");
    }

    #[test]
    fn build_packet_has_valid_ip_and_tcp_checksums() {
        let k = key();
        let pkt = build_packet(&k, 1000, 2000, ACK | PSH, b"hello");
        // IP 头校验和：整体求和应为 0
        assert_eq!(checksum(&[&pkt[..20]]), 0);
        // TCP 校验和：伪头 + 段整体求和应为 0
        let src = k.dst.octets();
        let dst = k.src.octets();
        let tcp_len = pkt.len() - 20;
        let pseudo = [
            src[0], src[1], src[2], src[3], dst[0], dst[1], dst[2], dst[3], 0, 6,
            (tcp_len >> 8) as u8, tcp_len as u8,
        ];
        assert_eq!(checksum(&[&pseudo, &pkt[20..]]), 0);
        assert_eq!(&pkt[20 + 20..], b"hello");
    }

    #[test]
    fn handshake_then_data_then_fin() {
        let k = key();
        let mut st = TcpStack::new();

        // 1) 客户端 SYN
        let (out, ev) = st.on_packet(&client_packet(&k, 100, 0, SYN, &[]));
        assert_eq!(out.len(), 1);
        let (sp, dp, seq, ack, flags, _) = parse_out(&out[0]);
        assert_eq!(sp, 80);
        assert_eq!(dp, 51000);
        assert_eq!(ack, 101, "SYN-ACK 应确认 client_seq+1");
        assert_eq!(flags, SYN | ACK);
        assert!(ev.is_empty(), "握手未完成前不应报 Opened");
        let our_isn = seq;

        // 2) 客户端 ACK，握手完成
        let (out, ev) = st.on_packet(&client_packet(&k, 101, our_isn.wrapping_add(1), ACK, &[]));
        assert!(out.is_empty());
        assert!(matches!(ev[0], Event::Opened(_)));
        assert_eq!(st.conn_count(), 1);

        // 3) 客户端发数据
        let (out, ev) = st.on_packet(&client_packet(&k, 101, our_isn.wrapping_add(1), ACK | PSH, b"GET /"));
        assert_eq!(out.len(), 1);
        let (_, _, _, ack, flags, _) = parse_out(&out[0]);
        assert_eq!(flags & ACK, ACK);
        assert_eq!(ack, 106, "应确认 101+5");
        match &ev[0] {
            Event::Data(_, d) => assert_eq!(d, b"GET /"),
            other => panic!("期望 Data，得到 {other:?}"),
        }

        // 4) 上游回数据
        let out = st.on_upstream(&k, b"HTTP/1.1 200 OK\r\n\r\n");
        assert_eq!(out.len(), 1);
        let (_, _, seq, ack, flags, payload) = parse_out(&out[0]);
        assert_eq!(seq, our_isn.wrapping_add(1), "发送序号应从 ISN+1 起");
        assert_eq!(ack, 106);
        assert_eq!(flags & PSH, PSH);
        assert_eq!(payload, b"HTTP/1.1 200 OK\r\n\r\n");

        // 5) 客户端 FIN
        let (out, ev) = st.on_packet(&client_packet(&k, 106, our_isn.wrapping_add(1), FIN | ACK, &[]));
        assert_eq!(out.len(), 1);
        let (_, _, _, ack, flags, _) = parse_out(&out[0]);
        assert_eq!(flags & FIN, FIN);
        assert_eq!(ack, 107);
        assert!(matches!(ev[0], Event::PeerFin(_)));
    }

    #[test]
    fn duplicate_data_is_acked_but_not_delivered_twice() {
        let k = key();
        let mut st = TcpStack::new();
        let (out, _) = st.on_packet(&client_packet(&k, 100, 0, SYN, &[]));
        let our_isn = parse_out(&out[0]).2;
        st.on_packet(&client_packet(&k, 101, our_isn.wrapping_add(1), ACK, &[]));

        let (_, ev) = st.on_packet(&client_packet(&k, 101, 0, ACK | PSH, b"abc"));
        assert_eq!(ev.len(), 1);
        let (out, ev) = st.on_packet(&client_packet(&k, 101, 0, ACK | PSH, b"abc"));
        assert!(ev.is_empty(), "重复段不应再次投递");
        assert_eq!(out.len(), 1, "但必须回 ACK");
        assert_eq!(parse_out(&out[0]).3, 104);
    }

    #[test]
    fn out_of_order_is_dropped_and_acked() {
        let k = key();
        let mut st = TcpStack::new();
        let (out, _) = st.on_packet(&client_packet(&k, 100, 0, SYN, &[]));
        let our_isn = parse_out(&out[0]).2;
        st.on_packet(&client_packet(&k, 101, our_isn.wrapping_add(1), ACK, &[]));

        // 跳号：期望 101，来了 105
        let (out, ev) = st.on_packet(&client_packet(&k, 105, 0, ACK | PSH, b"zzzz"));
        assert!(ev.is_empty(), "乱序不应投递");
        assert_eq!(parse_out(&out[0]).3, 101, "ACK 应停在缺口处");
    }

    #[test]
    fn retransmits_unacked_segment() {
        let k = key();
        let mut st = TcpStack::new();
        let (out, _) = st.on_packet(&client_packet(&k, 100, 0, SYN, &[]));
        let our_isn = parse_out(&out[0]).2;
        st.on_packet(&client_packet(&k, 101, our_isn.wrapping_add(1), ACK, &[]));

        st.on_upstream(&k, b"payload");
        // 立刻 tick 不应该重传
        assert!(st.tick().is_empty());
        // 推进时间：RTO 之后应重传一次
        std::thread::sleep(RTO + Duration::from_millis(50));
        let again = st.tick();
        assert_eq!(again.len(), 1, "超时后应重传");
        assert_eq!(parse_out(&again[0]).5, b"payload");

        // 收到 ACK 后不再重传
        let ack = our_isn.wrapping_add(1).wrapping_add(7);
        st.on_packet(&client_packet(&k, 101, ack, ACK, &[]));
        std::thread::sleep(RTO + Duration::from_millis(50));
        assert!(st.tick().is_empty(), "已确认的段不应再重传");
    }

    #[test]
    fn rst_removes_connection() {
        let k = key();
        let mut st = TcpStack::new();
        let (out, _) = st.on_packet(&client_packet(&k, 100, 0, SYN, &[]));
        let our_isn = parse_out(&out[0]).2;
        st.on_packet(&client_packet(&k, 101, our_isn.wrapping_add(1), ACK, &[]));
        assert_eq!(st.conn_count(), 1);
        let (_, ev) = st.on_packet(&client_packet(&k, 101, 0, RST, &[]));
        assert_eq!(st.conn_count(), 0);
        assert!(matches!(ev[0], Event::Aborted(_)));
    }

    #[test]
    fn unknown_flow_gets_rst() {
        let k = key();
        let mut st = TcpStack::new();
        let (out, _) = st.on_packet(&client_packet(&k, 500, 0, ACK | PSH, b"x"));
        assert_eq!(out.len(), 1);
        assert_eq!(parse_out(&out[0]).4 & RST, RST);
    }

    #[test]
    fn ip_fragment_with_offset_is_ignored() {
        let k = key();
        let mut pkt = client_packet(&k, 100, 0, SYN, &[]);
        // 设置分片偏移 185（非首片）
        pkt[6..8].copy_from_slice(&(185u16).to_be_bytes());
        assert!(parse_segment(&pkt).is_none());
    }
}
