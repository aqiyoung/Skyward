//! TUN 设备接管（PoC-7：真实转发闭环）。
//!
//! Android 上由 `VpnService` 建立 TUN 并把 fd 传给内核。本模块做三件事：
//!
//! 1. 从 fd 读原始 IP 帧，按协议分流（TCP / UDP:53 / 其它）；
//! 2. TCP 交给 [`crate::tcpstack`] 的用户态栈，栈吐出的事件再驱动上游
//!    （SS 出站）拨号，回程数据重新封包写回 TUN；
//! 3. UDP:53 交给 [`crate::dnsrelay`]，经代理链路解析后封 UDP 包写回。
//!
//! 这是 "0.1.0.19 之前只读不写" 的终点：现在 tun 里的包真的会被转发出去，
//! 回来的字节也真的会被写回设备。
//!
//! 沙箱无 `/dev/net/tun`，设备读写只能在安卓真机经 VpnService 验证；
//! 帧解析、TCP 状态机、DNS 报文封装均有单元测试覆盖。

use crate::dnsrelay;
use crate::net;
use crate::outbound::{self, Protocol};
use crate::socks5::ProxyConfig;
use crate::ss::{master_key, read_chunk, ss_client_connect, SsTarget};
use crate::tcpstack::{Event, FlowKey, TcpStack};
use crate::udpstack::{FlowKey as UdpKey, Sink, UdpRelay};
use std::collections::HashMap;
use std::fs::File;
use std::io::{Read, Write};
use std::net::Ipv4Addr;
use std::os::fd::{FromRawFd, RawFd};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Duration;
use tokio::io::AsyncWriteExt;
use tokio::sync::mpsc::{unbounded_channel, UnboundedSender};

/// 四层协议类型与端口。
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum L4 {
    Tcp { src: u16, dst: u16 },
    Udp { src: u16, dst: u16 },
}

/// 解析出的 IPv4 数据包摘要。
#[derive(Debug, Clone)]
pub struct ParsedV4 {
    pub src_ip: Ipv4Addr,
    pub dst_ip: Ipv4Addr,
    pub proto: u8,
    pub l4: Option<L4>,
}

/// 解析一个 IPv4 数据包（含以太网偏移由调用方裁掉；此处只认裸 IP 帧）。
pub fn parse_ipv4(pkt: &[u8]) -> std::io::Result<ParsedV4> {
    if pkt.len() < 20 {
        return Err(std::io::Error::new(std::io::ErrorKind::InvalidData, "ipv4 too short"));
    }
    let ver_ihl = pkt[0];
    if ver_ihl >> 4 != 4 {
        return Err(std::io::Error::new(std::io::ErrorKind::InvalidData, "not ipv4"));
    }
    let ihl = (ver_ihl & 0x0f) as usize * 4;
    if ihl < 20 || pkt.len() < ihl {
        return Err(std::io::Error::new(std::io::ErrorKind::InvalidData, "bad ihl"));
    }
    let proto = pkt[9];
    let src_ip = Ipv4Addr::new(pkt[12], pkt[13], pkt[14], pkt[15]);
    let dst_ip = Ipv4Addr::new(pkt[16], pkt[17], pkt[18], pkt[19]);

    let l4 = match proto {
        6 => {
            // TCP
            if pkt.len() < ihl + 20 {
                return Err(std::io::Error::new(std::io::ErrorKind::InvalidData, "tcp too short"));
            }
            let src = u16::from_be_bytes([pkt[ihl], pkt[ihl + 1]]);
            let dst = u16::from_be_bytes([pkt[ihl + 2], pkt[ihl + 3]]);
            Some(L4::Tcp { src, dst })
        }
        17 => {
            // UDP
            if pkt.len() < ihl + 8 {
                return Err(std::io::Error::new(std::io::ErrorKind::InvalidData, "udp too short"));
            }
            let src = u16::from_be_bytes([pkt[ihl], pkt[ihl + 1]]);
            let dst = u16::from_be_bytes([pkt[ihl + 2], pkt[ihl + 3]]);
            Some(L4::Udp { src, dst })
        }
        _ => None,
    };
    Ok(ParsedV4 {
        src_ip,
        dst_ip,
        proto,
        l4,
    })
}

/// 内核从 TUN 读到的真实流量统计（区别于模拟会话）。
#[derive(Debug, Default, Clone, Copy)]
pub struct TunStats {
    pub bytes: u64,
    pub packets: u64,
    pub tcp: u64,
    pub udp: u64,
    /// 当前活跃连接数（TCP 栈视角）。
    pub conns: u64,
    /// 当前活跃 UDP 会话数（SS UDP relay 视角）。
    pub udp_flows: u64,
    /// 写回 tun 的字节数，用于确认闭环真的在工作。
    pub tx_bytes: u64,
}

/// 一条活跃连接的上游句柄。
struct Upstream {
    tx: UnboundedSender<Vec<u8>>,
    alive: Arc<AtomicBool>,
}

/// 服务端 UDP relay 是否可用。一旦确认不可用（DNS 查询 1.2s 无回程），
/// 后续 DNS 直接走 DNS-over-TCP，避免每个查询都白等一次超时。
/// 每次开启 TUN 时重置为 true。
static DNS_UDP_OK: AtomicBool = AtomicBool::new(true);

/// DNS 走 UDP relay 时的等待上限：超过即判定 UDP 不可用并回退 TCP。
const DNS_FALLBACK_WAIT: Duration = Duration::from_millis(1200);

/// 写一个完整的 IP 包回 TUN。
fn write_tun(w: &Arc<Mutex<File>>, pkt: &[u8], stats: &Arc<Mutex<TunStats>>) {
    let mut f = match w.lock() {
        Ok(f) => f,
        Err(e) => e.into_inner(),
    };
    if f.write_all(pkt).is_ok() {
        if let Ok(mut s) = stats.lock() {
            s.tx_bytes += pkt.len() as u64;
        }
    }
}

/// 在独立 OS 线程里从 TUN fd 阻塞读取原始帧，驱动 TCP 栈与 DNS 转发，并把回程包写回设备。
/// 返回的统计句柄供 JNI 查询。设备读取本身只能在安卓真机（VpnService 提供 fd）验证。
pub fn run_tun_blocking(fd: RawFd, cfg: Arc<ProxyConfig>) -> Arc<Mutex<TunStats>> {
    let stats = Arc::new(Mutex::new(TunStats::default()));
    let s2 = stats.clone();

    std::thread::spawn(move || {
        // fd 由调用方保证是有效的 TUN 字符设备。读用一份、写用一份：
        // 单个 File 被读阻塞时无法写，必须 try_clone 出独立的 fd。
        let file = unsafe { File::from_raw_fd(fd) };
        let mut reader = match file.try_clone() {
            Ok(f) => f,
            Err(_) => return,
        };
        let writer = Arc::new(Mutex::new(file));
        let stack = Arc::new(Mutex::new(TcpStack::new()));
        let ups: Arc<Mutex<HashMap<FlowKey, Upstream>>> = Arc::new(Mutex::new(HashMap::new()));
        let master = master_key(&cfg.password);
        let rt = net::runtime();
        DNS_UDP_OK.store(true, Ordering::Relaxed);

        // UDP 全量转发：所有 UDP（含 DNS）先走 SS UDP relay。
        // 服务器未开 udp relay 时 DNS 会回退 TCP，见下面的分支。
        let sink: Sink = {
            let w = writer.clone();
            let s = s2.clone();
            Arc::new(move |pkt: &[u8]| write_tun(&w, pkt, &s))
        };
        let udp = UdpRelay::new(master, cfg.ss_server.clone(), cfg.ss_port, sink);

        // 重传定时器：每 100ms 推一次栈内的超时段。
        {
            let stack = stack.clone();
            let writer = writer.clone();
            let stats = s2.clone();
            std::thread::spawn(move || loop {
                std::thread::sleep(Duration::from_millis(100));
                let pkts = {
                    let mut st = match stack.lock() {
                        Ok(g) => g,
                        Err(e) => e.into_inner(),
                    };
                    st.tick()
                };
                for p in pkts {
                    write_tun(&writer, &p, &stats);
                }
            });
        }

        let mut buf = vec![0u8; 65536];
        loop {
            let n = match reader.read(&mut buf) {
                Ok(0) => break, // EOF：VPN 断开
                Ok(n) => n,
                Err(_) => break,
            };
            let pkt = &buf[..n];
            let parsed = match parse_ipv4(pkt) {
                Ok(p) => p,
                Err(_) => continue,
            };

            {
                let mut s = match s2.lock() {
                    Ok(g) => g,
                    Err(e) => e.into_inner(),
                };
                s.bytes += n as u64;
                s.packets += 1;
                match parsed.l4 {
                    Some(L4::Tcp { .. }) => s.tcp += 1,
                    Some(L4::Udp { .. }) => s.udp += 1,
                    None => {}
                }
            }

            match parsed.l4 {
                Some(L4::Tcp { .. }) => {
                    let (out, events) = {
                        let mut st = match stack.lock() {
                            Ok(g) => g,
                            Err(e) => e.into_inner(),
                        };
                        st.on_packet(pkt)
                    };
                    for p in out {
                        write_tun(&writer, &p, &s2);
                    }
                    for ev in events {
                        handle_event(ev, &rt, &stack, &writer, &ups, &cfg, &master, &s2);
                    }
                    if let Ok(mut s) = s2.lock() {
                        s.conns = stack
                            .lock()
                            .map(|g| g.conn_count() as u64)
                            .unwrap_or(0);
                    }
                }
                Some(L4::Udp { src, dst }) => {
                    // 抓出 UDP 载荷（非首片 / 非法长度直接丢）
                    let dg = match dnsrelay::parse_udp(pkt) {
                        Some(d) => d,
                        None => continue,
                    };
                    let key = UdpKey::new(parsed.src_ip, src, parsed.dst_ip, dst);
                    let payload = dg.payload;
                    let is_dns = dst == 53;

                    let relay = udp.clone();
                    let writer2 = writer.clone();
                    let stats2 = s2.clone();
                    let cfg2 = cfg.clone();
                    let client_ip = parsed.src_ip;
                    let client_port = src;
                    let dns_ip = parsed.dst_ip;

                    // Trojan / VLESS 还没有 UDP 通道：DNS 走 TCP，其余 UDP 丢弃
                    // （QUIC 会自动回退到 TCP，不会造成整站不可用）。
                    if cfg.protocol != Protocol::Shadowsocks {
                        if is_dns {
                            rt.spawn(async move {
                                dns_over_tcp(
                                    &cfg2, master, client_ip, client_port, dns_ip,
                                    &payload, &writer2, &stats2,
                                )
                                .await;
                            });
                        }
                        continue;
                    }

                    rt.spawn(async move {
                        // 已知服务端 UDP relay 不可用：DNS 直接走 TCP
                        if is_dns && !DNS_UDP_OK.load(Ordering::Relaxed) {
                            dns_over_tcp(
                                &cfg2, master, client_ip, client_port, dns_ip,
                                &payload, &writer2, &stats2,
                            )
                            .await;
                            return;
                        }

                        match relay.send(key, &payload).await {
                            Ok(before) if is_dns => {
                                // DNS 兜底：UDP 没回来就改用 DNS-over-TCP
                                tokio::time::sleep(DNS_FALLBACK_WAIT).await;
                                let after = relay.rx_total(&key).unwrap_or(before);
                                if after == before {
                                    DNS_UDP_OK.store(false, Ordering::Relaxed);
                                    dns_over_tcp(
                                        &cfg2, master, client_ip, client_port, dns_ip,
                                        &payload, &writer2, &stats2,
                                    )
                                    .await;
                                }
                            }
                            _ => {}
                        }
                    });

                    if let Ok(mut s) = s2.lock() {
                        s.udp_flows = udp.flow_count() as u64;
                    }
                }
                None => {
                    // 非 TCP/UDP（ICMP 等）本版不转发
                }
            }
        }

        // TUN 关闭：清掉所有上游句柄，让任务退出
        {
            let mut m = match ups.lock() {
                Ok(g) => g,
                Err(e) => e.into_inner(),
            };
            for (_, u) in m.drain() {
                u.alive.store(false, Ordering::Relaxed);
            }
        }
    });

    stats
}

/// DNS 回退通道：UDP relay 不可用时，用 DNS-over-TCP（2 字节长度前缀）经 SS 出去。
#[allow(clippy::too_many_arguments)]
async fn dns_over_tcp(
    cfg: &ProxyConfig,
    master: [u8; 32],
    client_ip: Ipv4Addr,
    client_port: u16,
    dns_ip: Ipv4Addr,
    query: &[u8],
    writer: &Arc<Mutex<File>>,
    stats: &Arc<Mutex<TunStats>>,
) {
    if let Ok(resp) = dnsrelay::resolve(cfg, &master, query).await {
        // 应答源地址必须是客户端查询的那个 DNS，否则系统解析器会丢弃
        let reply = dnsrelay::build_udp_reply(dns_ip, client_ip, 53, client_port, &resp);
        write_tun(writer, &reply, stats);
    }
}

/// 处理 TCP 栈吐出的事件。
#[allow(clippy::too_many_arguments)]
fn handle_event(
    ev: Event,
    rt: &'static tokio::runtime::Runtime,
    stack: &Arc<Mutex<TcpStack>>,
    writer: &Arc<Mutex<File>>,
    ups: &Arc<Mutex<HashMap<FlowKey, Upstream>>>,
    cfg: &Arc<ProxyConfig>,
    master: &[u8; 32],
    stats: &Arc<Mutex<TunStats>>,
) {
    match ev {
        Event::Opened(key) => {
            let (tx, rx) = unbounded_channel();
            let alive = Arc::new(AtomicBool::new(true));
            {
                let mut m = match ups.lock() {
                    Ok(g) => g,
                    Err(e) => e.into_inner(),
                };
                m.insert(key, Upstream { tx, alive: alive.clone() });
            }
            let stack = stack.clone();
            let writer = writer.clone();
            let stats = stats.clone();
            let cfg = cfg.clone();
            let master = *master;
            rt.spawn(async move {
                upstream_task(key, rx, alive, cfg, master, stack, writer, stats).await;
            });
        }
        Event::Data(key, data) => {
            let m = match ups.lock() {
                Ok(g) => g,
                Err(e) => e.into_inner(),
            };
            if let Some(u) = m.get(&key) {
                let _ = u.tx.send(data);
            }
        }
        Event::PeerFin(key) => {
            // drop sender，让上游写方向收尾
            let mut m = match ups.lock() {
                Ok(g) => g,
                Err(e) => e.into_inner(),
            };
            m.remove(&key);
        }
        Event::Aborted(key) => {
            let mut m = match ups.lock() {
                Ok(g) => g,
                Err(e) => e.into_inner(),
            };
            if let Some(u) = m.remove(&key) {
                u.alive.store(false, Ordering::Relaxed);
            }
        }
    }
}

/// 拨号失败时给客户端发 RST，避免应用侧一直等（表现为转圈直到超时）。
fn reset_conn(
    key: FlowKey,
    stack: &Arc<Mutex<TcpStack>>,
    writer: &Arc<Mutex<File>>,
    stats: &Arc<Mutex<TunStats>>,
) {
    let pkts = {
        let mut st = match stack.lock() {
            Ok(g) => g,
            Err(e) => e.into_inner(),
        };
        st.abort(&key)
    };
    for p in pkts {
        write_tun(writer, &p, stats);
    }
}

/// Trojan / VLESS 的上游搬运：协议头已由 `outbound::dial` 写掉，这里只搬字节。
async fn plain_upstream(
    key: FlowKey,
    stream: crate::outbound::BoxStream,
    mut rx: tokio::sync::mpsc::UnboundedReceiver<Vec<u8>>,
    alive: Arc<AtomicBool>,
    stack: Arc<Mutex<TcpStack>>,
    writer: Arc<Mutex<File>>,
    stats: Arc<Mutex<TunStats>>,
) {
    use tokio::io::AsyncReadExt;

    let (mut r, mut w) = tokio::io::split(stream);

    // 下行：出站流 → 栈 → TUN
    {
        let stack = stack.clone();
        let writer = writer.clone();
        let stats = stats.clone();
        tokio::spawn(async move {
            let mut buf = vec![0u8; 16384];
            loop {
                match r.read(&mut buf).await {
                    Ok(0) => break,
                    Ok(n) => {
                        let pkts = {
                            let mut st = match stack.lock() {
                                Ok(g) => g,
                                Err(e) => e.into_inner(),
                            };
                            st.on_upstream(&key, &buf[..n])
                        };
                        for p in pkts {
                            write_tun(&writer, &p, &stats);
                        }
                    }
                    Err(_) => break,
                }
            }
            // 对端关闭：让栈把 FIN 补上
            let pkts = {
                let mut st = match stack.lock() {
                    Ok(g) => g,
                    Err(e) => e.into_inner(),
                };
                st.on_upstream_closed(&key)
            };
            for p in pkts {
                write_tun(&writer, &p, &stats);
            }
        });
    }

    // 上行：TUN → 出站流
    while let Some(data) = rx.recv().await {
        if !alive.load(Ordering::Relaxed) {
            break;
        }
        if w.write_all(&data).await.is_err() {
            break;
        }
    }
    let _ = w.shutdown().await;
}

/// 单条连接的上游任务：按协议拨号 → 双向搬运。
#[allow(clippy::too_many_arguments)]
async fn upstream_task(
    key: FlowKey,
    mut rx: tokio::sync::mpsc::UnboundedReceiver<Vec<u8>>,
    alive: Arc<AtomicBool>,
    cfg: Arc<ProxyConfig>,
    master: [u8; 32],
    stack: Arc<Mutex<TcpStack>>,
    writer: Arc<Mutex<File>>,
    stats: Arc<Mutex<TunStats>>,
) {
    let target = SsTarget { host: key.dst.to_string(), port: key.dport };

    // Trojan / VLESS：握手头写完后是裸字节流，不需要逐块加解密。
    if cfg.protocol != Protocol::Shadowsocks {
        let stream = match outbound::dial(
            cfg.protocol,
            &cfg.ss_server,
            cfg.ss_port,
            &cfg.password,
            cfg.tls,
            &cfg.sni,
            &target,
        )
        .await
        {
            Ok(s) => s,
            Err(e) => {
                eprintln!("[outbound] {} 拨号失败: {e}", cfg.protocol.as_str());
                reset_conn(key, &stack, &writer, &stats);
                return;
            }
        };
        plain_upstream(key, stream, rx, alive, stack, writer, stats).await;
        return;
    }

    let (enc, sess) = match ss_client_connect(&master, &cfg.ss_server, cfg.ss_port, &target).await {
        Ok(x) => x,
        Err(_) => {
            // 拨号失败：给客户端 RST，别让它干等
            reset_conn(key, &stack, &writer, &stats);
            return;
        }
    };

    let (mut r, mut w) = tokio::io::split(enc);

    // 下行：SS → TUN
    {
        let stack = stack.clone();
        let writer = writer.clone();
        let stats = stats.clone();
        let sess = sess.clone();
        tokio::spawn(async move {
            loop {
                match read_chunk(&mut r, &sess).await {
                    Ok(data) => {
                        if data.is_empty() {
                            continue;
                        }
                        let pkts = {
                            let mut st = match stack.lock() {
                                Ok(g) => g,
                                Err(e) => e.into_inner(),
                            };
                            st.on_upstream(&key, &data)
                        };
                        for p in pkts {
                            write_tun(&writer, &p, &stats);
                        }
                    }
                    Err(_) => {
                        let pkts = {
                            let mut st = match stack.lock() {
                                Ok(g) => g,
                                Err(e) => e.into_inner(),
                            };
                            st.on_upstream_closed(&key)
                        };
                        for p in pkts {
                            write_tun(&writer, &p, &stats);
                        }
                        break;
                    }
                }
            }
        });
    }

    // 上行：TUN → SS
    while let Some(data) = rx.recv().await {
        if !alive.load(Ordering::Relaxed) {
            break;
        }
        let chunk = {
            let mut s = sess.lock().await;
            s.seal(&data)
        };
        if w.write_all(&chunk).await.is_err() {
            break;
        }
    }
    let _ = w.shutdown().await;
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_tcp(src: Ipv4Addr, dst: Ipv4Addr, sport: u16, dport: u16) -> Vec<u8> {
        let mut p = vec![0u8; 40];
        p[0] = 0x45; // ver4 ihl5
        p[9] = 6; // TCP
        p[12..16].copy_from_slice(&src.octets());
        p[16..20].copy_from_slice(&dst.octets());
        p[20..22].copy_from_slice(&sport.to_be_bytes());
        p[22..24].copy_from_slice(&dport.to_be_bytes());
        p
    }

    #[test]
    fn parse_tcp() {
        let pkt = make_tcp(
            Ipv4Addr::new(10, 0, 0, 2),
            Ipv4Addr::new(93, 184, 216, 34),
            51234,
            443,
        );
        let p = parse_ipv4(&pkt).unwrap();
        assert_eq!(p.src_ip, Ipv4Addr::new(10, 0, 0, 2));
        assert_eq!(p.dst_ip, Ipv4Addr::new(93, 184, 216, 34));
        assert_eq!(p.proto, 6);
        assert_eq!(p.l4, Some(L4::Tcp { src: 51234, dst: 443 }));
    }

    #[test]
    fn parse_udp() {
        let mut p = vec![0u8; 28];
        p[0] = 0x45;
        p[9] = 17; // UDP
        p[12..16].copy_from_slice(&[192, 168, 1, 5]);
        p[16..20].copy_from_slice(&[8, 8, 8, 8]);
        p[20..22].copy_from_slice(&5353u16.to_be_bytes()); // DNS
        p[22..24].copy_from_slice(&53u16.to_be_bytes());
        let parsed = parse_ipv4(&p).unwrap();
        assert_eq!(parsed.proto, 17);
        assert_eq!(parsed.l4, Some(L4::Udp { src: 5353, dst: 53 }));
    }

    /// 端到端：模拟客户端 SYN → 栈回 SYN-ACK → 上行经真实 SS 链路到 echo 目标
    /// → 下行回到栈 → 封包写回。这条测试覆盖「TUN 侧 TCP ↔ SS 出站」的接缝。
    #[tokio::test(flavor = "multi_thread")]
    async fn tun_tcp_flow_reaches_upstream_and_back() {
        use crate::ss::{master_key, ss_proxy, ss_server_accept, SsTarget};
        use tokio::io::{AsyncReadExt, AsyncWriteExt};
        use tokio::net::{TcpListener, TcpStream};

        let mk = master_key("tun-test");

        // echo 目标
        let echo = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let echo_port = echo.local_addr().unwrap().port();
        tokio::spawn(async move {
            loop {
                let (mut s, _) = match echo.accept().await {
                    Ok(x) => x,
                    Err(_) => break,
                };
                tokio::spawn(async move {
                    let mut buf = [0u8; 1024];
                    loop {
                        match s.read(&mut buf).await {
                            Ok(0) | Err(_) => break,
                            Ok(n) => {
                                if s.write_all(&buf[..n]).await.is_err() {
                                    break;
                                }
                            }
                        }
                    }
                });
            }
        });

        // SS 服务端
        let ss = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let ss_port = ss.local_addr().unwrap().port();
        tokio::spawn(async move {
            loop {
                let (enc, _) = match ss.accept().await {
                    Ok(x) => x,
                    Err(_) => break,
                };
                tokio::spawn(async move {
                    let (enc, sess, target) = match ss_server_accept(enc, &mk).await {
                        Ok(x) => x,
                        Err(_) => return,
                    };
                    let tc = match TcpStream::connect((target.host.as_str(), target.port)).await {
                        Ok(c) => c,
                        Err(_) => return,
                    };
                    ss_proxy(tc, enc, sess).await;
                });
            }
        });

        // 客户端侧：SYN / ACK / 数据
        let key = FlowKey::new(Ipv4Addr::new(10, 10, 10, 2), 51000, Ipv4Addr::new(127, 0, 0, 1), echo_port);
        let rev = FlowKey::new(key.dst, key.dport, key.src, key.sport);

        let mut stack = TcpStack::new();
        let syn = crate::tcpstack::build_packet(&rev, 1000, 0, crate::tcpstack::SYN, &[]);
        let (out, ev) = stack.on_packet(&syn);
        assert_eq!(out.len(), 1, "应回 SYN-ACK");
        assert!(ev.is_empty());
        let seg = crate::tcpstack::parse_segment(&out[0]).unwrap();
        assert_eq!(seg.flags & crate::tcpstack::SYN, crate::tcpstack::SYN);
        let our_isn = seg.seq;

        let ack = crate::tcpstack::build_packet(
            &rev, 1001, our_isn.wrapping_add(1), crate::tcpstack::ACK, &[]);
        let (_, ev) = stack.on_packet(&ack);
        assert!(matches!(ev[0], Event::Opened(_)), "握手后应通知上游拨号");

        // 上游拨号（真实的 SS 客户端 → SS 服务端 → echo）
        let (mut enc, sess) = ss_client_connect(
            &mk, "127.0.0.1", ss_port, &SsTarget { host: "127.0.0.1".into(), port: echo_port })
            .await
            .expect("SS 拨号应成功");

        // 上行：客户端数据 → 栈提取 → 加密发出
        let data_seg = crate::tcpstack::build_packet(
            &rev, 1001, our_isn.wrapping_add(1), crate::tcpstack::ACK | crate::tcpstack::PSH, b"ping-through-tun");
        let (ack_out, ev) = stack.on_packet(&data_seg);
        assert_eq!(ack_out.len(), 1, "应回 ACK");
        match &ev[0] {
            Event::Data(_, d) => assert_eq!(d, b"ping-through-tun"),
            other => panic!("期望 Data，得到 {other:?}"),
        }
        let chunk = { sess.lock().await.seal(b"ping-through-tun") };
        enc.write_all(&chunk).await.unwrap();
        enc.flush().await.unwrap();

        // 下行：echo 回来 → 解密 → 栈封包
        let echoed = tokio::time::timeout(
            std::time::Duration::from_secs(5),
            read_chunk(&mut enc, &sess),
        )
        .await
        .expect("下行超时")
        .expect("下行解密失败");
        assert_eq!(echoed, b"ping-through-tun", "echo 应原样回来");

        let back = stack.on_upstream(&key, &echoed);
        assert_eq!(back.len(), 1);
        let seg = crate::tcpstack::parse_segment(&back[0]).unwrap();
        assert_eq!(seg.payload, b"ping-through-tun");
        assert_eq!(seg.key.dport, 51000, "回程包应发回客户端端口");
        assert_eq!(seg.flags & crate::tcpstack::PSH, crate::tcpstack::PSH);
    }

    #[test]
    fn reject_non_ipv4_and_short() {
        assert!(parse_ipv4(&[0u8; 10]).is_err());
        let mut p = vec![0u8; 20];
        p[0] = 0x65; // ver6
        assert!(parse_ipv4(&p).is_err());
    }
}
