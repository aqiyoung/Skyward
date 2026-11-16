//! 通用 UDP 转发（SS UDP relay）—— 补齐 TCP 之外的另一半数据面。
//!
//! 为什么必须做：QUIC（HTTP/3）、部分游戏、DNS、NTP、WebRTC 全走 UDP。
//! 只做 TCP 的客户端在真机上表现为「网页能开、视频卡死、部分 App 直接超时」。
//!
//! 报文格式（与 shadowsocks-rust 的 UDP relay 一致）：
//! `[salt(32)] || AEAD(subkey, nonce=0, [addr][payload])`，
//! 其中 `subkey = HKDF-SHA1(master, salt, "ss-subkey")`，每个报文独立加盐。
//!
//! 本模块按「源 IP:端口 + 目标 IP:端口」四元组维护会话，每个会话一个连到 SS
//! 服务器的 UDP socket，回程包解密后重新封装成 IPv4/UDP 帧写回 TUN。
//! 会话空闲 90s 自动回收（socket 关闭、任务退出、表项移除）。

use crate::ss::{open_udp, seal_udp, SsTarget};
use crate::tcpstack::checksum;
use std::collections::HashMap;
use std::io;
use std::net::Ipv4Addr;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use tokio::net::UdpSocket;

/// 空闲回收阈值。
const IDLE_TIMEOUT: Duration = Duration::from_secs(90);
/// 单次 recv 等待上限，用于周期性检查空闲。
const RECV_TICK: Duration = Duration::from_secs(15);
/// 单个 UDP 报文上限（IPv4 理论上限 65535）。
const MAX_DATAGRAM: usize = 65535;

/// 写回 TUN 的出口。由 `tun` 模块注入，避免本模块反向依赖 TUN 细节。
pub type Sink = Arc<dyn Fn(&[u8]) + Send + Sync + 'static>;

/// 一条 UDP 流的四元组。
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct FlowKey {
    pub src: Ipv4Addr,
    pub sport: u16,
    pub dst: Ipv4Addr,
    pub dport: u16,
}

impl FlowKey {
    pub fn new(src: Ipv4Addr, sport: u16, dst: Ipv4Addr, dport: u16) -> Self {
        FlowKey { src, sport, dst, dport }
    }
}

/// 构造 IPv4/UDP 数据包（含 IP 头校验和与 UDP 伪头校验和）。
pub fn build_udp_packet(
    src: Ipv4Addr,
    dst: Ipv4Addr,
    sport: u16,
    dport: u16,
    payload: &[u8],
) -> Vec<u8> {
    let udp_len = 8 + payload.len();
    let mut pkt = vec![0u8; 20 + udp_len];
    pkt[0] = 0x45; // ver4 / ihl5
    pkt[2..4].copy_from_slice(&((20 + udp_len) as u16).to_be_bytes());
    pkt[6..8].copy_from_slice(&0x4000u16.to_be_bytes()); // DF
    pkt[8] = 64; // TTL
    pkt[9] = 17; // UDP
    pkt[12..16].copy_from_slice(&src.octets());
    pkt[16..20].copy_from_slice(&dst.octets());
    let ip_sum = checksum(&[&pkt[..20]]);
    pkt[10..12].copy_from_slice(&ip_sum.to_be_bytes());

    let u = &mut pkt[20..];
    u[0..2].copy_from_slice(&sport.to_be_bytes());
    u[2..4].copy_from_slice(&dport.to_be_bytes());
    u[4..6].copy_from_slice(&(udp_len as u16).to_be_bytes());
    u[8..].copy_from_slice(payload);

    let s = src.octets();
    let d = dst.octets();
    let pseudo = [
        s[0], s[1], s[2], s[3], d[0], d[1], d[2], d[3], 0, 17,
        (udp_len >> 8) as u8, udp_len as u8,
    ];
    let sum = checksum(&[&pseudo, &pkt[20..]]);
    // 0 表示「未计算」，计算结果恰为 0 时按 RFC 768 写 0xFFFF
    let sum = if sum == 0 { 0xffff } else { sum };
    pkt[26..28].copy_from_slice(&sum.to_be_bytes());
    pkt
}

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

/// 单个 UDP 会话：一个连到 SS 服务器的 socket + 回程统计。
pub struct Session {
    key: FlowKey,
    sock: Arc<UdpSocket>,
    /// 累计收到的回程报文数，供 DNS 兜底判定「本次查询有没有回来」。
    rx_total: AtomicU64,
    last_active: AtomicU64,
}

impl Session {
    pub fn rx_total(&self) -> u64 {
        self.rx_total.load(Ordering::Relaxed)
    }
}

/// UDP 会话表 + 转发器。
pub struct UdpRelay {
    master: [u8; 32],
    server: String,
    server_port: u16,
    sink: Sink,
    table: Mutex<HashMap<FlowKey, Arc<Session>>>,
}

impl UdpRelay {
    pub fn new(master: [u8; 32], server: String, server_port: u16, sink: Sink) -> Arc<Self> {
        Arc::new(UdpRelay {
            master,
            server,
            server_port,
            sink,
            table: Mutex::new(HashMap::new()),
        })
    }

    /// 当前活跃会话数（界面上用于确认 UDP 真的在跑）。
    pub fn flow_count(&self) -> usize {
        match self.table.lock() {
            Ok(g) => g.len(),
            Err(e) => e.into_inner().len(),
        }
    }

    /// 某条流的回程计数快照。
    pub fn rx_total(&self, key: &FlowKey) -> Option<u64> {
        let m = match self.table.lock() {
            Ok(g) => g,
            Err(e) => e.into_inner(),
        };
        m.get(key).map(|s| s.rx_total())
    }

    /// 发送一个 UDP 载荷。返回发送前的回程计数（DNS 兜底用）。
    pub async fn send(self: &Arc<Self>, key: FlowKey, payload: &[u8]) -> io::Result<u64> {
        let sess = match self.get_or_open(key).await {
            Ok(s) => s,
            Err(e) => return Err(e),
        };
        let before = sess.rx_total();
        sess.last_active.store(now_ms(), Ordering::Relaxed);

        let target = SsTarget {
            host: key.dst.to_string(),
            port: key.dport,
        };
        let sealed = seal_udp(&self.master, &target, payload);
        sess.sock.send(&sealed).await?;
        Ok(before)
    }

    /// 取已有会话，没有就新建并挂上回程任务。
    async fn get_or_open(self: &Arc<Self>, key: FlowKey) -> io::Result<Arc<Session>> {
        {
            let m = match self.table.lock() {
                Ok(g) => g,
                Err(e) => e.into_inner(),
            };
            if let Some(s) = m.get(&key) {
                return Ok(s.clone());
            }
        }

        // 不持锁建连，避免阻塞其它流。
        let sock = UdpSocket::bind("0.0.0.0:0").await?;
        sock.connect((self.server.as_str(), self.server_port)).await?;
        let sess = Arc::new(Session {
            key,
            sock: Arc::new(sock),
            rx_total: AtomicU64::new(0),
            last_active: AtomicU64::new(now_ms()),
        });

        {
            let mut m = match self.table.lock() {
                Ok(g) => g,
                Err(e) => e.into_inner(),
            };
            // 并发建连时可能已被别的任务插入，保留先到的那个。
            if let Some(existing) = m.get(&key) {
                return Ok(existing.clone());
            }
            m.insert(key, sess.clone());
        }

        let me = self.clone();
        let s2 = sess.clone();
        tokio::spawn(async move {
            me.recv_loop(s2).await;
            let mut m = match me.table.lock() {
                Ok(g) => g,
                Err(e) => e.into_inner(),
            };
            m.remove(&key);
        });
        Ok(sess)
    }

    /// 回程循环：解密 → 校验来源 → 封包 → 写回 TUN。
    async fn recv_loop(&self, sess: Arc<Session>) {
        let mut buf = vec![0u8; MAX_DATAGRAM];
        loop {
            match tokio::time::timeout(RECV_TICK, sess.sock.recv(&mut buf)).await {
                Ok(Ok(n)) => {
                    sess.last_active.store(now_ms(), Ordering::Relaxed);
                    let (target, payload) = match open_udp(&self.master, &buf[..n]) {
                        Ok(x) => x,
                        Err(_) => continue, // 非本会话的包 / 被中间设备改写，丢弃
                    };
                    // 只接受与请求目标一致的应答，避免服务器回错包串流。
                    if target.port != sess.key.dport || target.host != sess.key.dst.to_string() {
                        continue;
                    }
                    sess.rx_total.fetch_add(1, Ordering::Relaxed);
                    // 回程方向：源 = 目标服务器，目的 = 客户端
                    let pkt = build_udp_packet(
                        sess.key.dst,
                        sess.key.src,
                        sess.key.dport,
                        sess.key.sport,
                        &payload,
                    );
                    (self.sink)(&pkt);
                }
                Ok(Err(_)) => break, // socket 出错，回收
                Err(_) => {
                    // 空闲超时：超过阈值就结束，让表项被清理
                    let idle = now_ms().saturating_sub(sess.last_active.load(Ordering::Relaxed));
                    if idle >= IDLE_TIMEOUT.as_millis() as u64 {
                        break;
                    }
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn build_packet_checksums_valid() {
        let pkt = build_udp_packet(
            Ipv4Addr::new(140, 82, 121, 4),
            Ipv4Addr::new(10, 10, 10, 2),
            443,
            51000,
            b"quic-initial",
        );
        assert_eq!(checksum(&[&pkt[..20]]), 0, "IP 头校验和应自洽");
        let s = Ipv4Addr::new(140, 82, 121, 4).octets();
        let d = Ipv4Addr::new(10, 10, 10, 2).octets();
        let ulen = pkt.len() - 20;
        let pseudo = [
            s[0], s[1], s[2], s[3], d[0], d[1], d[2], d[3], 0, 17,
            (ulen >> 8) as u8, ulen as u8,
        ];
        assert_eq!(checksum(&[&pseudo, &pkt[20..]]), 0, "UDP 校验和应自洽");
        assert_eq!(&pkt[28..], b"quic-initial");
    }

    /// 端到端：TUN 侧 UDP → SS UDP relay（自建服务端）→ echo → 回程封包。
    /// 覆盖「加密上行 / 解密下行 / 组包」三段接缝。
    #[tokio::test(flavor = "multi_thread", worker_threads = 4)]
    async fn udp_flow_roundtrip_through_ss_relay() {
        use crate::ss::{master_key, open_udp, seal_udp};
        use std::net::SocketAddr;
        use std::sync::Mutex as StdMutex;

        let mk = master_key("udp-test");

        // 目标：UDP echo（把内容反转，便于确认确实是端到端回来的）
        let echo = UdpSocket::bind("127.0.0.1:0").await.unwrap();
        let echo_addr = echo.local_addr().unwrap();
        tokio::spawn(async move {
            let mut b = [0u8; 2048];
            loop {
                let (n, from) = match echo.recv_from(&mut b).await {
                    Ok(x) => x,
                    Err(_) => break,
                };
                let mut out = b[..n].to_vec();
                out.reverse();
                let _ = echo.send_to(&out, from).await;
            }
        });

        // SS UDP 服务端（单流简化版）：解密请求 → 发往目标；
        // 目标回包 → 用「请求里的原始地址」做地址头加密 → 发回客户端。
        let relay = Arc::new(UdpSocket::bind("127.0.0.1:0").await.unwrap());
        let relay_port = relay.local_addr().unwrap().port();
        let upstream = Arc::new(UdpSocket::bind("127.0.0.1:0").await.unwrap());
        let last_client: Arc<StdMutex<Option<SocketAddr>>> = Arc::new(StdMutex::new(None));
        let last_target: Arc<StdMutex<Option<SsTarget>>> = Arc::new(StdMutex::new(None));

        {
            let (r, u, lc, lt) = (relay.clone(), upstream.clone(), last_client.clone(), last_target.clone());
            tokio::spawn(async move {
                let mut b = [0u8; 4096];
                loop {
                    let (n, from) = match r.recv_from(&mut b).await {
                        Ok(x) => x,
                        Err(_) => break,
                    };
                    let (target, payload) = match open_udp(&mk, &b[..n]) {
                        Ok(x) => x,
                        Err(_) => continue,
                    };
                    let to: SocketAddr = format!("{}:{}", target.host, target.port)
                        .parse()
                        .expect("目标地址合法");
                    *lc.lock().unwrap() = Some(from);
                    *lt.lock().unwrap() = Some(target);
                    let _ = u.send_to(&payload, to).await;
                }
            });
        }
        {
            let (r, u, lc, lt) = (relay.clone(), upstream.clone(), last_client.clone(), last_target.clone());
            tokio::spawn(async move {
                let mut b = [0u8; 4096];
                loop {
                    let (n, _) = match u.recv_from(&mut b).await {
                        Ok(x) => x,
                        Err(_) => break,
                    };
                    let client = *lc.lock().unwrap();
                    let target = lt.lock().unwrap().clone();
                    if let (Some(c), Some(t)) = (client, target) {
                        let sealed = seal_udp(&mk, &t, &b[..n]);
                        let _ = r.send_to(&sealed, c).await;
                    }
                }
            });
        }

        let got: Arc<StdMutex<Vec<Vec<u8>>>> = Arc::new(StdMutex::new(Vec::new()));
        let sink_hold = got.clone();
        let sink: Sink = Arc::new(move |pkt: &[u8]| {
            sink_hold.lock().unwrap().push(pkt.to_vec());
        });

        let key = FlowKey::new(
            Ipv4Addr::new(10, 10, 10, 2),
            51000,
            Ipv4Addr::new(127, 0, 0, 1),
            echo_addr.port(),
        );
        let r = UdpRelay::new(mk, "127.0.0.1".into(), relay_port, sink);

        r.send(key, b"hello-udp").await.expect("发送应成功");

        // 轮询等待回程（回环链路，通常 <50ms）
        let mut waited = 0;
        while got.lock().unwrap().is_empty() && waited < 3000 {
            tokio::time::sleep(Duration::from_millis(20)).await;
            waited += 20;
        }
        let frames = got.lock().unwrap().clone();
        assert_eq!(frames.len(), 1, "应收到一个回程包");
        let f = &frames[0];
        // 源端口 = 目标端口，目的端口 = 客户端端口
        assert_eq!(u16::from_be_bytes([f[20], f[21]]), echo_addr.port());
        assert_eq!(u16::from_be_bytes([f[22], f[23]]), 51000);
        assert_eq!(&f[28..], b"pdu-olleh", "echo 应被反转后回来");
    }

    #[test]
    fn udp_seal_open_roundtrip() {
        use crate::ss::{master_key, open_udp, seal_udp, SsTarget};
        let mk = master_key("roundtrip");
        let t = SsTarget { host: "1.2.3.4".into(), port: 53 };
        let sealed = seal_udp(&mk, &t, b"payload-bytes");
        let (got_t, got_p) = open_udp(&mk, &sealed).expect("应能解开");
        assert_eq!(got_t.host, "1.2.3.4");
        assert_eq!(got_t.port, 53);
        assert_eq!(got_p, b"payload-bytes");
        // 篡改一个字节必须被拒
        let mut bad = sealed.clone();
        bad[40] ^= 0xff;
        assert!(open_udp(&mk, &bad).is_err());
    }
}
