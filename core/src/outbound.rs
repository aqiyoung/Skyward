//! 出站协议适配层（PoC-9）：Shadowsocks 之外补上 Trojan 与 VLESS 的 TCP 出站。
//!
//! 为什么先做这两个、而不是 VMess：Trojan 与 VLESS 的握手都是「明文头 + 裸字节流」，
//! 头里只有密码哈希 / UUID 和地址，协议本身不加密，安全性完全由外层 TLS 提供。
//! 也就是说两个协议共用同一套 TLS 通道实现，工作量接近一个；VMess 要自己做
//! KDF、时间戳、AEAD 分块，是另一个量级，放在下一块。
//!
//! 报文格式（与各自服务端实现一致）：
//!
//! Trojan：
//! ```text
//! hex(SHA224(password)) CRLF
//! CMD(0x01) ATYP ADDR PORT(2) CRLF
//! <payload...>
//! ```
//!
//! VLESS：
//! ```text
//! VER(0) UUID(16) OPTLEN(0) CMD(1=TCP) PORT(2) ATYP ADDR
//! <payload...>
//! ```
//!
//! 注意两者地址字段顺序不同：Trojan 是 `ATYP ADDR PORT`（与 SS 相同），
//! VLESS 是 `PORT ATYP ADDR`。写反了服务端会直接断开，且很难从日志看出来。

use crate::ss::SsTarget;
use sha2::{Digest, Sha224};
use std::io;
use std::net::{Ipv4Addr, Ipv6Addr};
use std::sync::Arc;
use tokio::io::{AsyncRead, AsyncWrite, AsyncWriteExt};
use tokio::net::TcpStream;

/// 出站协议。
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Protocol {
    Shadowsocks,
    Trojan,
    Vless,
}

impl Protocol {
    /// 从配置字符串解析；未知值一律按 Shadowsocks 处理，保持向后兼容。
    pub fn parse(s: &str) -> Protocol {
        match s.trim().to_ascii_lowercase().as_str() {
            "trojan" => Protocol::Trojan,
            "vless" => Protocol::Vless,
            _ => Protocol::Shadowsocks,
        }
    }

    pub fn as_str(&self) -> &'static str {
        match self {
            Protocol::Shadowsocks => "shadowsocks",
            Protocol::Trojan => "trojan",
            Protocol::Vless => "vless",
        }
    }

    /// 该协议是否必须（或默认）走 TLS。
    pub fn wants_tls(&self) -> bool {
        !matches!(self, Protocol::Shadowsocks)
    }
}

/// 既读又写的流。Rust 的 trait object 只允许一个非 auto trait，故先合成一个。
pub trait AsyncStream: AsyncRead + AsyncWrite {}
impl<T: AsyncRead + AsyncWrite> AsyncStream for T {}

/// 统一的加密流类型：TLS 流与裸 TCP 流都能装箱成它。
pub type BoxStream = Box<dyn AsyncStream + Unpin + Send>;

/// TLS 包装：用 webpki 根证书校验服务端，SNI 取配置里的 sni（空则用服务器地址）。
async fn tls_wrap(stream: TcpStream, sni: &str) -> io::Result<BoxStream> {
    use rustls::pki_types::ServerName;

    let mut roots = rustls::RootCertStore::empty();
    roots.extend(webpki_roots::TLS_SERVER_ROOTS.iter().cloned());
    let config = rustls::ClientConfig::builder()
        .with_root_certificates(roots)
        .with_no_client_auth();

    let name = ServerName::try_from(sni.to_string())
        .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "bad sni"))?;
    let connector = tokio_rustls::TlsConnector::from(Arc::new(config));
    let tls = connector.connect(name, stream).await?;
    Ok(Box::new(tls))
}

/// 解析 VLESS 的 UUID：允许带连字符，必须恰好 32 个十六进制字符。
pub fn parse_uuid(s: &str) -> io::Result<[u8; 16]> {
    let hex: Vec<u8> = s
        .chars()
        .filter(|c| *c != '-')
        .map(|c| c as u8)
        .collect();
    if hex.len() != 32 {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "uuid 必须是 32 个十六进制字符",
        ));
    }
    let mut out = [0u8; 16];
    for i in 0..16 {
        let s = std::str::from_utf8(&hex[i * 2..i * 2 + 2])
            .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "uuid 非 ASCII"))?;
        out[i] = u8::from_str_radix(s, 16)
            .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "uuid 含非十六进制字符"))?;
    }
    Ok(out)
}

/// Trojan 请求头：56 字节密码哈希 + CRLF + 命令/地址 + CRLF。
pub fn trojan_header(password: &str, target: &SsTarget) -> Vec<u8> {
    trojan_header_cmd(password, target, 0x01)
}

/// 同 `trojan_header`，但命令字节可指定：0x01 = CONNECT，0x03 = UDP ASSOCIATE。
pub fn trojan_header_cmd(password: &str, target: &SsTarget, cmd: u8) -> Vec<u8> {
    let mut h = Sha224::new();
    h.update(password.as_bytes());
    let digest = h.finalize();
    let mut out = Vec::with_capacity(56 + 2 + 1 + 1 + 18 + 2 + 2);
    for b in digest.iter() {
        out.extend_from_slice(format!("{b:02x}").as_bytes());
    }
    out.extend_from_slice(b"\r\n");
    out.push(cmd);
    out.extend_from_slice(&addr_field(target));
    out.extend_from_slice(&target.port.to_be_bytes());
    out.extend_from_slice(b"\r\n");
    out
}

/// `ATYP + ADDR + PORT`（SOCKS5 地址块，Trojan 的 UDP 包逐包都要带）。
pub fn socks5_addr(target: &SsTarget) -> Vec<u8> {
    let mut out = addr_field(target);
    out.extend_from_slice(&target.port.to_be_bytes());
    out
}

/// VLESS 请求头：版本 + UUID + 无选项 + TCP 命令 + 端口 + 地址。
pub fn vless_header(uuid: &[u8; 16], target: &SsTarget) -> Vec<u8> {
    let mut out = Vec::with_capacity(1 + 16 + 1 + 1 + 2 + 18);
    out.push(0); // 版本
    out.extend_from_slice(uuid);
    out.push(0); // 选项长度
    out.push(1); // 命令：TCP
    out.extend_from_slice(&target.port.to_be_bytes());
    out.extend_from_slice(&addr_field(target));
    out
}

/// `ATYP + ADDR`（不含端口），Trojan 与 VLESS 共用。
fn addr_field(target: &SsTarget) -> Vec<u8> {
    let mut out = Vec::new();
    if let Ok(ip) = target.host.parse::<Ipv4Addr>() {
        out.push(1);
        out.extend_from_slice(&ip.octets());
    } else if let Ok(ip) = target.host.parse::<Ipv6Addr>() {
        out.push(4);
        out.extend_from_slice(&ip.octets());
    } else {
        let b = target.host.as_bytes();
        out.push(3);
        out.push(b.len().min(255) as u8);
        out.extend_from_slice(&b[..b.len().min(255)]);
    }
    out
}

/// 只建连（含 TLS），不写任何协议头。给 UDP over TCP 这类「头要自己拼」的场景用。
pub async fn dial_raw(
    server: &str,
    port: u16,
    tls: bool,
    sni: &str,
) -> io::Result<BoxStream> {
    let tcp = tokio::time::timeout(
        std::time::Duration::from_secs(10),
        TcpStream::connect((server, port)),
    )
    .await
    .map_err(|_| io::Error::new(io::ErrorKind::TimedOut, "连接超时"))??;

    if tls {
        let name = if sni.is_empty() { server } else { sni };
        tls_wrap(tcp, name).await
    } else {
        Ok(Box::new(tcp))
    }
}

/// 拨号并写入协议头，返回可以直接搬运字节的流。
///
/// `tls` 为 false 时走裸 TCP（VLESS 在 80 端口或 CDN 回源场景下会用到）。
pub async fn dial(
    protocol: Protocol,
    server: &str,
    port: u16,
    secret: &str,
    tls: bool,
    sni: &str,
    target: &SsTarget,
) -> io::Result<BoxStream> {
    let mut stream = dial_raw(server, port, tls, sni).await?;

    let header = match protocol {
        Protocol::Trojan => trojan_header(secret, target),
        Protocol::Vless => vless_header(&parse_uuid(secret)?, target),
        Protocol::Shadowsocks => {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "Shadowsocks 走独立链路",
            ))
        }
    };
    stream.write_all(&header).await?;
    stream.flush().await?;
    Ok(stream)
}

/// Trojan 的 UDP ASSOCIATE 拨号：连上后写 `hash CRLF 0x03 ATYP ADDR PORT CRLF`。
///
/// 之后这条 TCP 流上跑的是逐包帧 `[ATYP][ADDR][PORT][len(2)][CRLF][payload]`，
/// 一个连接对应一个目标，回程包同样带地址头。
pub async fn dial_trojan_udp(
    server: &str,
    port: u16,
    password: &str,
    tls: bool,
    sni: &str,
    target: &SsTarget,
) -> io::Result<BoxStream> {
    let mut stream = dial_raw(server, port, tls, sni).await?;
    let header = trojan_header_cmd(password, target, 0x03);
    stream.write_all(&header).await?;
    stream.flush().await?;
    Ok(stream)
}

/// 把本地明文连接与出站流双向打通（Trojan / VLESS 的负载是裸字节流，
/// 不需要像 SS 那样逐块加解密）。
///
/// 一个方向读到 EOF 时必须 shutdown 另一侧的写半边，否则对端会一直等，
/// 表现为「网页加载完了但不结束」。
pub async fn proxy_plain<A, B>(local: A, remote: B) -> io::Result<()>
where
    A: AsyncRead + AsyncWrite + Unpin + Send + 'static,
    B: AsyncRead + AsyncWrite + Unpin + Send + 'static,
{
    let (mut lr, mut lw) = tokio::io::split(local);
    let (mut rr, mut rw) = tokio::io::split(remote);

    let up = async {
        let r = tokio::io::copy(&mut lr, &mut rw).await;
        let _ = rw.shutdown().await;
        r
    };
    let down = async {
        let r = tokio::io::copy(&mut rr, &mut lw).await;
        let _ = lw.shutdown().await;
        r
    };
    let (a, b) = tokio::join!(up, down);
    a?;
    b?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn trojan_header_layout() {
        let t = SsTarget { host: "example.com".into(), port: 443 };
        let h = trojan_header("p@ssw0rd", &t);
        // 56 字节 hex + CRLF
        assert_eq!(h.len(), 76);
        assert!(h[..56].iter().all(|b| b.is_ascii_hexdigit()));
        assert_eq!(&h[56..58], b"\r\n");
        assert_eq!(h[58], 0x01, "CONNECT");
        assert_eq!(h[59], 0x03, "域名类型");
        assert_eq!(h[60] as usize, "example.com".len());
        assert_eq!(&h[61..72], b"example.com");
        assert_eq!(u16::from_be_bytes([h[72], h[73]]), 443);
        assert_eq!(&h[74..76], b"\r\n");
    }

    #[test]
    fn trojan_password_hash_is_sha224_hex() {
        // SHA224("password") 的十六进制，独立可校验
        let t = SsTarget { host: "1.2.3.4".into(), port: 80 };
        let h = trojan_header("password", &t);
        let hex = String::from_utf8_lossy(&h[..56]).to_string();
        assert_eq!(
            hex,
            "d63dc919e201d7bc4c825630d2cf25fdc93d4b2f0d46706d29038d01",
            "Trojan 密码必须是 SHA224 的十六进制小写"
        );
        assert_eq!(h[59], 0x01, "IPv4 类型");
        assert_eq!(&h[60..64], &[1, 2, 3, 4]);
        assert_eq!(u16::from_be_bytes([h[64], h[65]]), 80);
    }

    #[test]
    fn vless_header_port_before_addr() {
        let uuid = parse_uuid("b831381d-6324-4d53-ad4f-8cda48b30811").unwrap();
        let t = SsTarget { host: "9.9.9.9".into(), port: 8443 };
        let h = vless_header(&uuid, &t);
        assert_eq!(h[0], 0, "版本");
        assert_eq!(&h[1..17], &uuid);
        assert_eq!(h[17], 0, "optlen");
        assert_eq!(h[18], 1, "cmd=TCP");
        assert_eq!(u16::from_be_bytes([h[19], h[20]]), 8443, "端口在地址之前");
        assert_eq!(h[21], 1, "IPv4");
        assert_eq!(&h[22..26], &[9, 9, 9, 9]);
        assert_eq!(h.len(), 26);
    }

    #[test]
    fn uuid_parsing() {
        let a = parse_uuid("b831381d-6324-4d53-ad4f-8cda48b30811").unwrap();
        let b = parse_uuid("b831381d63244d53ad4f8cda48b30811").unwrap();
        assert_eq!(a, b);
        assert_eq!(a[0], 0xb8);
        assert_eq!(a[15], 0x11);
        assert!(parse_uuid("b831381d-6324").is_err());
        assert!(parse_uuid("zz31381d63244d53ad4f8cda48b30811").is_err());
    }

    #[test]
    fn protocol_parse_defaults_to_ss() {
        assert_eq!(Protocol::parse("Trojan"), Protocol::Trojan);
        assert_eq!(Protocol::parse("vless"), Protocol::Vless);
        assert_eq!(Protocol::parse(""), Protocol::Shadowsocks);
        assert_eq!(Protocol::parse("vmess"), Protocol::Shadowsocks);
        assert!(Protocol::Trojan.wants_tls());
        assert!(!Protocol::Shadowsocks.wants_tls());
    }

    /// VLESS 明文端到端：客户端握手 → 自建服务端解析头 → 连 echo → 双向转发。
    /// 覆盖最容易写错的一处：VLESS 的「端口在地址之前」。
    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn vless_plain_end_to_end() {
        use std::time::Duration;
        use tokio::io::AsyncReadExt;
        use tokio::net::TcpListener;

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
                    let mut b = [0u8; 1024];
                    loop {
                        match s.read(&mut b).await {
                            Ok(0) | Err(_) => break,
                            Ok(n) => {
                                if s.write_all(&b[..n]).await.is_err() {
                                    break;
                                }
                            }
                        }
                    }
                });
            }
        });

        // 极简 VLESS 服务端：只认 TCP 命令 + IPv4 目标
        let srv = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let srv_port = srv.local_addr().unwrap().port();
        tokio::spawn(async move {
            loop {
                let (mut c, _) = match srv.accept().await {
                    Ok(x) => x,
                    Err(_) => break,
                };
                tokio::spawn(async move {
                    let mut hdr = [0u8; 21]; // ver + uuid + optlen + cmd + port
                    if c.read_exact(&mut hdr).await.is_err() {
                        return;
                    }
                    if hdr[18] != 1 {
                        return; // 只支持 TCP
                    }
                    let dport = u16::from_be_bytes([hdr[19], hdr[20]]);
                    let mut at = [0u8; 1];
                    if c.read_exact(&mut at).await.is_err() || at[0] != 1 {
                        return;
                    }
                    let mut a = [0u8; 4];
                    if c.read_exact(&mut a).await.is_err() {
                        return;
                    }
                    let host = std::net::Ipv4Addr::from(a).to_string();
                    let mut up = match TcpStream::connect((host.as_str(), dport)).await {
                        Ok(s) => s,
                        Err(_) => return,
                    };
                    let _ = tokio::io::copy_bidirectional(&mut c, &mut up).await;
                });
            }
        });

        let target = SsTarget { host: "127.0.0.1".into(), port: echo_port };
        let mut st = dial(
            Protocol::Vless,
            "127.0.0.1",
            srv_port,
            "b831381d-6324-4d53-ad4f-8cda48b30811",
            false,
            "",
            &target,
        )
        .await
        .expect("VLESS 拨号应成功");

        st.write_all(b"vless-e2e").await.unwrap();
        st.flush().await.unwrap();
        let mut buf = [0u8; 32];
        let n = tokio::time::timeout(Duration::from_secs(5), st.read(&mut buf))
            .await
            .expect("读回超时")
            .unwrap();
        assert_eq!(&buf[..n], b"vless-e2e");
    }

    /// 真机外的 TLS 冒烟：验证 rustls + webpki 根证书链在当前构建里可用。
    /// 依赖外网，默认不跑（`cargo test -- --ignored` 手动触发）。
    #[tokio::test]
    #[ignore = "需要外网"]
    async fn real_tls_handshake() {
        let tcp = TcpStream::connect(("www.cloudflare.com", 443))
            .await
            .expect("TCP 连接失败");
        let stream = tls_wrap(tcp, "www.cloudflare.com")
            .await
            .expect("TLS 握手失败（证书链或 SNI 有问题）");
        drop(stream);
    }
}
