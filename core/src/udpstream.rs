//! Trojan 的 UDP 通道（UDP ASSOCIATE）—— 补齐「Trojan 下 QUIC 全丢」这个缺口。
//!
//! Trojan 没有独立的 UDP 端口，UDP 是在一条 TCP（TLS）连接上复用出来的：
//!
//! ```text
//! 首包：hex(SHA224(pwd)) CRLF | 0x03 | ATYP ADDR PORT CRLF
//! 之后每个数据报（双向同构）：
//!   ATYP | ADDR | PORT | Length(2, BE) | CRLF | Payload
//! ```
//!
//! 一条连接绑定一个目标，所以本模块按四元组建会话、每会话一条 TCP。
//! 回程包带地址头，解析后校验目标一致再封 IPv4/UDP 写回 TUN。
//!
//! VLESS 的 UDP 不走这里：裸 VLESS 的 UDP over TCP 没有长度前缀，
//! 多个数据报会粘连、边界丢失；实践中要靠 XUDP/mux 才能正确分帧。
//! 那部分留到 Mux 模块一起做，当前 VLESS 下 UDP 仍只放行 DNS（走 TCP）。

use crate::outbound::{dial_trojan_udp, socks5_addr};
use crate::ss::SsTarget;
use crate::udpstack::{build_udp_packet, FlowKey, Sink};
use std::collections::HashMap;
use std::io;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use tokio::io::{AsyncRead, AsyncReadExt, AsyncWrite, AsyncWriteExt};
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender};

const IDLE_TIMEOUT: Duration = Duration::from_secs(90);
const WRITE_TICK: Duration = Duration::from_secs(15);
/// 单个数据报上限；UDP 在 IPv4 下理论最大 65507。
const MAX_DATAGRAM: usize = 65535;

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

struct Session {
    key: FlowKey,
    tx: UnboundedSender<Vec<u8>>,
    rx_total: AtomicU64,
    last_active: AtomicU64,
    closed: AtomicBool,
}

/// Trojan UDP 会话表。
pub struct StreamRelay {
    server: String,
    port: u16,
    password: String,
    tls: bool,
    sni: String,
    sink: Sink,
    table: Mutex<HashMap<FlowKey, Arc<Session>>>,
}

impl StreamRelay {
    pub fn new(
        server: String,
        port: u16,
        password: String,
        tls: bool,
        sni: String,
        sink: Sink,
    ) -> Arc<Self> {
        Arc::new(StreamRelay {
            server,
            port,
            password,
            tls,
            sni,
            sink,
            table: Mutex::new(HashMap::new()),
        })
    }

    pub fn flow_count(&self) -> usize {
        match self.table.lock() {
            Ok(g) => g.len(),
            Err(e) => e.into_inner().len(),
        }
    }

    pub fn rx_total(&self, key: &FlowKey) -> Option<u64> {
        let m = match self.table.lock() {
            Ok(g) => g,
            Err(e) => e.into_inner(),
        };
        m.get(key).map(|s| s.rx_total.load(Ordering::Relaxed))
    }

    /// 发送一个 UDP 载荷，返回发送前的回程计数（DNS 兜底判定用）。
    pub async fn send(self: &Arc<Self>, key: FlowKey, payload: &[u8]) -> io::Result<u64> {
        let sess = self.get_or_open(key).await?;
        let before = sess.rx_total.load(Ordering::Relaxed);
        sess.last_active.store(now_ms(), Ordering::Relaxed);
        sess.tx
            .send(payload.to_vec())
            .map_err(|_| io::Error::new(io::ErrorKind::BrokenPipe, "会话已关闭"))?;
        Ok(before)
    }

    async fn get_or_open(self: &Arc<Self>, key: FlowKey) -> io::Result<Arc<Session>> {
        {
            let m = match self.table.lock() {
                Ok(g) => g,
                Err(e) => e.into_inner(),
            };
            if let Some(s) = m.get(&key) {
                if !s.closed.load(Ordering::Relaxed) {
                    return Ok(s.clone());
                }
            }
        }

        // 建连放在锁外，避免一条慢连接卡住全表。
        let target = SsTarget {
            host: key.dst.to_string(),
            port: key.dport,
        };
        let stream = dial_trojan_udp(
            &self.server,
            self.port,
            &self.password,
            self.tls,
            &self.sni,
            &target,
        )
        .await?;

        let (tx, rx) = unbounded_channel();
        let sess = Arc::new(Session {
            key,
            tx,
            rx_total: AtomicU64::new(0),
            last_active: AtomicU64::new(now_ms()),
            closed: AtomicBool::new(false),
        });

        {
            let mut m = match self.table.lock() {
                Ok(g) => g,
                Err(e) => e.into_inner(),
            };
            if let Some(existing) = m.get(&key) {
                if !existing.closed.load(Ordering::Relaxed) {
                    return Ok(existing.clone());
                }
            }
            m.insert(key, sess.clone());
        }

        let me = self.clone();
        let s2 = sess.clone();
        tokio::spawn(async move {
            me.run(s2, stream, rx, target).await;
        });
        Ok(sess)
    }

    /// 一条连接的生命周期：写循环与读循环并行，任一结束就整体收摊。
    async fn run(
        self: Arc<Self>,
        sess: Arc<Session>,
        stream: crate::outbound::BoxStream,
        rx: UnboundedReceiver<Vec<u8>>,
        target: SsTarget,
    ) {
        let (mut rd, mut wr) = tokio::io::split(stream);

        let up = Self::write_loop(&mut wr, rx, &sess, &target);
        let down = Self::read_loop(&mut rd, &sess, &self.sink, &sess.key);

        tokio::select! {
            _ = up => {}
            _ = down => {}
        }

        sess.closed.store(true, Ordering::Relaxed);
        let mut m = match self.table.lock() {
            Ok(g) => g,
            Err(e) => e.into_inner(),
        };
        m.remove(&sess.key);
    }

    /// 上行：从队列取载荷，按 `[addr][len][CRLF][payload]` 组帧写出。
    async fn write_loop(
        wr: &mut (impl AsyncWrite + Unpin),
        mut rx: UnboundedReceiver<Vec<u8>>,
        sess: &Session,
        target: &SsTarget,
    ) {
        let addr = socks5_addr(target);
        loop {
            let payload = match tokio::time::timeout(WRITE_TICK, rx.recv()).await {
                Ok(Some(p)) => p,
                Ok(None) => return, // 发送端全部 drop
                Err(_) => {
                    let idle =
                        now_ms().saturating_sub(sess.last_active.load(Ordering::Relaxed));
                    if idle >= IDLE_TIMEOUT.as_millis() as u64 {
                        return;
                    }
                    continue;
                }
            };
            if payload.len() > MAX_DATAGRAM {
                continue;
            }
            let mut frame = Vec::with_capacity(addr.len() + 4 + payload.len());
            frame.extend_from_slice(&addr);
            frame.extend_from_slice(&(payload.len() as u16).to_be_bytes());
            frame.extend_from_slice(b"\r\n");
            frame.extend_from_slice(&payload);
            if wr.write_all(&frame).await.is_err() {
                return;
            }
            if wr.flush().await.is_err() {
                return;
            }
        }
    }

    /// 下行：逐帧解析地址头与长度，校验目标后封包写回 TUN。
    async fn read_loop(
        rd: &mut (impl AsyncRead + Unpin),
        sess: &Session,
        sink: &Sink,
        key: &FlowKey,
    ) {
        loop {
            let (host, port) = match read_addr(rd).await {
                Ok(x) => x,
                Err(_) => return,
            };
            let mut lb = [0u8; 2];
            if rd.read_exact(&mut lb).await.is_err() {
                return;
            }
            let len = u16::from_be_bytes(lb) as usize;
            let mut crlf = [0u8; 2];
            if rd.read_exact(&mut crlf).await.is_err() {
                return;
            }
            // 规范要求这里是 CRLF；不是则说明流已错位，继续读只会越错越远。
            if &crlf != b"\r\n" {
                return;
            }
            let mut payload = vec![0u8; len];
            if rd.read_exact(&mut payload).await.is_err() {
                return;
            }

            // 只接受与请求目标一致的应答，避免服务器回错包串流。
            let same = port == key.dport
                && (host == key.dst.to_string() || host.is_empty());
            if !same {
                continue;
            }

            sess.rx_total.fetch_add(1, Ordering::Relaxed);
            sess.last_active.store(now_ms(), Ordering::Relaxed);
            let pkt = build_udp_packet(key.dst, key.src, key.dport, key.sport, &payload);
            sink(&pkt);
        }
    }
}

/// 读一个 `ATYP ADDR PORT` 地址块，返回 `(host, port)`。
async fn read_addr(rd: &mut (impl AsyncRead + Unpin)) -> io::Result<(String, u16)> {
    let mut atyp = [0u8; 1];
    rd.read_exact(&mut atyp).await?;
    let host = match atyp[0] {
        0x01 => {
            let mut b = [0u8; 4];
            rd.read_exact(&mut b).await?;
            std::net::Ipv4Addr::from(b).to_string()
        }
        0x04 => {
            let mut b = [0u8; 16];
            rd.read_exact(&mut b).await?;
            std::net::Ipv6Addr::from(b).to_string()
        }
        0x03 => {
            let mut l = [0u8; 1];
            rd.read_exact(&mut l).await?;
            let mut b = vec![0u8; l[0] as usize];
            rd.read_exact(&mut b).await?;
            String::from_utf8_lossy(&b).to_string()
        }
        _ => return Err(io::Error::new(io::ErrorKind::InvalidData, "未知 ATYP")),
    };
    let mut p = [0u8; 2];
    rd.read_exact(&mut p).await?;
    Ok((host, u16::from_be_bytes(p)))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::net::Ipv4Addr;
    use std::sync::Mutex as StdMutex;
    use tokio::net::{TcpListener, UdpSocket};

    /// 自建极简 Trojan UDP 服务端：认 0x03 头 → 收帧 → 转发 UDP → 回帧。
    /// 覆盖三段接缝：首包解析、逐包分帧、回程封包。
    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn trojan_udp_roundtrip() {
        // UDP echo
        let echo = UdpSocket::bind("127.0.0.1:0").await.unwrap();
        let echo_port = echo.local_addr().unwrap().port();
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

        let srv = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let srv_port = srv.local_addr().unwrap().port();
        tokio::spawn(async move {
            loop {
                let (mut c, _) = match srv.accept().await {
                    Ok(x) => x,
                    Err(_) => break,
                };
                tokio::spawn(async move {
                    // 头：56 hex + CRLF + cmd
                    let mut hdr = [0u8; 58];
                    if c.read_exact(&mut hdr).await.is_err() {
                        return;
                    }
                    let mut cmd = [0u8; 1];
                    if c.read_exact(&mut cmd).await.is_err() || cmd[0] != 0x03 {
                        return;
                    }
                    // 首包的地址块 + CRLF（这里只读掉，不用）
                    let _ = read_addr(&mut c).await;
                    let mut crlf = [0u8; 2];
                    if c.read_exact(&mut crlf).await.is_err() {
                        return;
                    }

                    let up = UdpSocket::bind("127.0.0.1:0").await.unwrap();
                    let up = Arc::new(up);
                    let up2 = up.clone();
                    let (mut r, mut w) = tokio::io::split(c);

                    // 回程：UDP → 帧 → TCP
                    tokio::spawn(async move {
                        let mut b = [0u8; 2048];
                        loop {
                            let (n, _) = match up2.recv_from(&mut b).await {
                                Ok(x) => x,
                                Err(_) => break,
                            };
                            let payload = &b[..n];
                            let mut frame = Vec::new();
                            frame.push(0x01);
                            frame.extend_from_slice(&[127, 0, 0, 1]);
                            frame.extend_from_slice(&echo_port.to_be_bytes());
                            frame.extend_from_slice(&(payload.len() as u16).to_be_bytes());
                            frame.extend_from_slice(b"\r\n");
                            frame.extend_from_slice(payload);
                            if w.write_all(&frame).await.is_err() {
                                break;
                            }
                            let _ = w.flush().await;
                        }
                    });

                    // 上行：帧 → UDP
                    loop {
                        let (host, port) = match read_addr(&mut r).await {
                            Ok(x) => x,
                            Err(_) => return,
                        };
                        let mut lb = [0u8; 2];
                        if r.read_exact(&mut lb).await.is_err() {
                            return;
                        }
                        let len = u16::from_be_bytes(lb) as usize;
                        let mut crlf = [0u8; 2];
                        if r.read_exact(&mut crlf).await.is_err() {
                            return;
                        }
                        let mut payload = vec![0u8; len];
                        if r.read_exact(&mut payload).await.is_err() {
                            return;
                        }
                        let dst = format!("{host}:{port}");
                        let _ = up.send_to(&payload, dst.as_str()).await;
                    }
                });
            }
        });

        let got: Arc<StdMutex<Vec<Vec<u8>>>> = Arc::new(StdMutex::new(Vec::new()));
        let sink_hold = got.clone();
        let sink: Sink = Arc::new(move |pkt: &[u8]| {
            sink_hold.lock().unwrap().push(pkt.to_vec());
        });

        let relay = StreamRelay::new(
            "127.0.0.1".into(),
            srv_port,
            "trojan-pass".into(),
            false,
            String::new(),
            sink,
        );
        let key = FlowKey::new(
            Ipv4Addr::new(10, 10, 10, 2),
            52000,
            Ipv4Addr::new(127, 0, 0, 1),
            echo_port,
        );

        relay.send(key, b"hello-trojan-udp").await.expect("发送应成功");

        let mut waited = 0;
        while got.lock().unwrap().is_empty() && waited < 3000 {
            tokio::time::sleep(Duration::from_millis(20)).await;
            waited += 20;
        }
        let frames = got.lock().unwrap().clone();
        assert_eq!(frames.len(), 1, "应收到一个回程包");
        let f = &frames[0];
        assert_eq!(u16::from_be_bytes([f[20], f[21]]), echo_port);
        assert_eq!(u16::from_be_bytes([f[22], f[23]]), 52000);
        assert_eq!(&f[28..], b"pdu-najort-olleh", "echo 应被反转后回来");
        assert_eq!(relay.flow_count(), 1);
        assert!(relay.rx_total(&key).unwrap() >= 1);
    }

    #[tokio::test]
    async fn read_addr_handles_domain() {
        let mut buf: &[u8] = &[0x03, 11, b'e', b'x', b'a', b'm', b'p', b'l', b'e', b'.', b'c', b'o', b'm', 0x01, 0xbb];
        let (h, p) = read_addr(&mut buf).await.unwrap();
        assert_eq!(h, "example.com");
        assert_eq!(p, 443);
    }
}
