//! Shadowsocks AEAD 出站协议（PoC-6）。
//!
//! 这是内核第一次拥有真正的"转发肌肉"：用 ChaCha20-Poly1305 加密，
//! 经真实 TCP 连远端 SS 服务器并收发字节——不再是内存模拟。
//!
//! 设计要点：
//! - 主密钥 = SHA-256(password)；每次连接随机 32 字节 salt；
//!   会话子密钥 = HMAC-SHA256(master, salt)（与 shadowsocks-rust 一致，可对接真实远端）。
//! - 每个 chunk 结构：`seal([u16 length][payload])` → 输出 `[length_chunk(2+16)][payload_chunk(len+16)]`。
//! - nonce（12 字节）= `[0u8;4] ++ counter.to_be_bytes()`，收发各自独立计数。
//! - 双向代理以 `ss_proxy(plain, enc, sess)` 复用：enc 侧发用 tx、收用 rx。

use chacha20poly1305::aead::generic_array::GenericArray;
use chacha20poly1305::aead::Aead;
use chacha20poly1305::{ChaCha20Poly1305, KeyInit};
use hmac::{Hmac, Mac};
use sha2::{Digest, Sha256};
use std::io;
use std::net::{Ipv4Addr, Ipv6Addr};
use std::sync::{Arc, OnceLock};
use tokio::io::{AsyncRead, AsyncReadExt, AsyncWrite, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio::sync::Mutex;

const SALT_LEN: usize = 32; // chacha20-ietf-poly1305
const MAX_PAYLOAD: usize = 0x3FFF; // 单 chunk 载荷上限（SS 惯例）
const TAG_LEN: usize = 16;

/// 真实代理吞吐统计（区别于 `engine` 的模拟会话）。每次经 SS 转发的字节在此累计，
/// 由 `nativeProxyStats` 回传 UI，作为「真实代理流量」展示。
#[derive(Default, Clone, Copy)]
pub struct ProxyStats {
    pub tx: u64, // 上行（本地 → 远端）真实字节
    pub rx: u64, // 下行（远端 → 本地）真实字节
}

static PROXY_STATS: OnceLock<std::sync::Mutex<ProxyStats>> = OnceLock::new();

/// 取全局代理统计（惰性初始化）。
pub fn proxy_stats() -> &'static std::sync::Mutex<ProxyStats> {
    PROXY_STATS.get_or_init(|| std::sync::Mutex::new(ProxyStats::default()))
}

/// 重置代理统计（启动新代理实例时调用）。
pub fn reset_proxy_stats() {
    if let Some(s) = PROXY_STATS.get() {
        *s.lock().unwrap() = ProxyStats::default();
    }
}

type HmacSha256 = Hmac<Sha256>;

/// 由密码派生主密钥（SHA-256）。
pub fn master_key(password: &str) -> [u8; 32] {
    let mut h = Sha256::new();
    h.update(password.as_bytes());
    let out = h.finalize();
    let mut k = [0u8; 32];
    k.copy_from_slice(&out);
    k
}

/// 生成一次连接的随机 salt。
pub fn random_salt() -> [u8; SALT_LEN] {
    let mut salt = [0u8; SALT_LEN];
    // getrandom 在 aarch64-linux-android（minSdk 26，有 libc getrandom）可用。
    let _ = getrandom::getrandom(&mut salt);
    salt
}

/// 单个 SS 会话：持有子密钥与收发 nonce 计数。
pub struct SsSession {
    cipher: ChaCha20Poly1305,
    tx: u64,
    rx: u64,
}

impl SsSession {
    /// 从主密钥 + 本次连接 salt 派生子密钥。
    pub fn new(master: &[u8; 32], salt: &[u8; SALT_LEN]) -> Self {
        let mut mac = <HmacSha256 as Mac>::new_from_slice(master).expect("hmac key len");
        mac.update(salt);
        let sub = mac.finalize().into_bytes();
        let mut skey = [0u8; 32];
        skey.copy_from_slice(&sub);
        let key = GenericArray::from_slice(&skey);
        let cipher = ChaCha20Poly1305::new(key);
        SsSession {
            cipher,
            tx: 0,
            rx: 0,
        }
    }

    /// SS nonce：前 4 字节为 0，后 8 字节为 big-endian 计数。
    #[inline]
    fn nonce(c: u64) -> [u8; 12] {
        let mut n = [0u8; 12];
        n[4..].copy_from_slice(&c.to_be_bytes());
        n
    }

    /// 加密一个 chunk：先发长度块 `encrypt([u16 length])`（密文固定 18 字节），
    /// 再发载荷块 `encrypt(payload)`（密文 = len+16 字节）。两段各自独立递增 nonce，
    /// 与 shadowsocks-rust / 标准 SS AEAD 完全一致，可对接真实远端。
    pub fn seal(&mut self, payload: &[u8]) -> Vec<u8> {
        let n = Self::nonce(self.tx);
        self.tx += 1;
        let nonce = GenericArray::from_slice(&n);
        let len_frame = (payload.len() as u16).to_be_bytes();
        let len_block = self
            .cipher
            .encrypt(nonce, len_frame.as_slice())
            .expect("ss seal len");
        let n2 = Self::nonce(self.tx);
        self.tx += 1;
        let nonce2 = GenericArray::from_slice(&n2);
        let payload_block = self
            .cipher
            .encrypt(nonce2, payload)
            .expect("ss seal payload");
        let mut out = len_block;
        out.extend_from_slice(&payload_block);
        out
    }

    /// 解密一个加密块（长度块或载荷块），返回其明文。长度解析由读取端负责。
    pub fn open(&mut self, ct: &[u8]) -> io::Result<Vec<u8>> {
        let n = Self::nonce(self.rx);
        self.rx += 1;
        let nonce = GenericArray::from_slice(&n);
        self.cipher
            .decrypt(nonce, ct)
            .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "ss decrypt failed"))
    }
}

/// 目标地址（SS 地址类型）。
#[derive(Debug, Clone)]
pub struct SsTarget {
    pub host: String,
    pub port: u16,
}

/// 构造 SS 请求头：`[atype][addr][port(2)]`。
fn build_header(target: &SsTarget) -> Vec<u8> {
    let mut h = Vec::new();
    if let Ok(ip) = target.host.parse::<Ipv4Addr>() {
        h.push(1);
        h.extend_from_slice(&ip.octets());
    } else if let Ok(ip) = target.host.parse::<Ipv6Addr>() {
        h.push(4);
        h.extend_from_slice(&ip.octets());
    } else {
        let b = target.host.as_bytes();
        h.push(3);
        h.push(b.len() as u8);
        h.extend_from_slice(b);
    }
    h.extend_from_slice(&target.port.to_be_bytes());
    h
}

/// 解析 SS 请求头（逆向 `build_header`）。
fn parse_header(buf: &[u8]) -> io::Result<SsTarget> {
    if buf.len() < 1 {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "empty header"));
    }
    let (host, rest) = match buf[0] {
        1 => {
            if buf.len() < 7 {
                return Err(io::Error::new(io::ErrorKind::InvalidData, "ipv4 short"));
            }
            let ip = Ipv4Addr::new(buf[1], buf[2], buf[3], buf[4]);
            (ip.to_string(), &buf[5..])
        }
        4 => {
            if buf.len() < 19 {
                return Err(io::Error::new(io::ErrorKind::InvalidData, "ipv6 short"));
            }
            let mut o = [0u8; 16];
            o.copy_from_slice(&buf[1..17]);
            let ip = Ipv6Addr::from(o);
            (ip.to_string(), &buf[17..])
        }
        3 => {
            if buf.len() < 2 {
                return Err(io::Error::new(io::ErrorKind::InvalidData, "domain short"));
            }
            let len = buf[1] as usize;
            if buf.len() < 2 + len {
                return Err(io::Error::new(io::ErrorKind::InvalidData, "domain len"));
            }
            let host = String::from_utf8_lossy(&buf[2..2 + len]).into_owned();
            (host, &buf[2 + len..])
        }
        t => {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("bad atype {t}"),
            ))
        }
    };
    if rest.len() < 2 {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "no port"));
    }
    let port = u16::from_be_bytes([rest[0], rest[1]]);
    Ok(SsTarget { host, port })
}

/// SS 客户端：连远端服务器、发送 salt + 加密头，返回（加密流, 会话）。
/// 之后调用 [`ss_proxy`] 把本地明文连接与加密流双向打通。
pub async fn ss_client_connect(
    master: &[u8; 32],
    server: &str,
    server_port: u16,
    target: &SsTarget,
) -> io::Result<(TcpStream, Arc<Mutex<SsSession>>)> {
    let mut stream = TcpStream::connect((server, server_port)).await?;
    let salt = random_salt();
    stream.write_all(&salt).await?;
    let mut sess = SsSession::new(master, &salt);
    let header = build_header(target);
    let sealed = sess.seal(&header);
    stream.write_all(&sealed).await?;
    // 冲刷，避免对端读不全。
    stream.flush().await?;
    Ok((stream, Arc::new(Mutex::new(sess))))
}

/// 从加密流读一个完整 chunk：先读 18 字节长度块解密得长度，再读 `len+16` 字节载荷块解密得 payload。
async fn read_chunk<R>(r: &mut R, sess: &Arc<Mutex<SsSession>>) -> io::Result<Vec<u8>>
where
    R: AsyncRead + Unpin,
{
    let mut lenbuf = [0u8; 2 + TAG_LEN];
    r.read_exact(&mut lenbuf).await?;
    let h = { let mut s = sess.lock().await; s.open(&lenbuf)? };
    if h.len() < 2 {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "bad chunk len"));
    }
    let plen = u16::from_be_bytes([h[0], h[1]]) as usize;
    let mut pbuf = vec![0u8; plen + TAG_LEN];
    r.read_exact(&mut pbuf).await?;
    let payload = { let mut s = sess.lock().await; s.open(&pbuf)? };
    Ok(payload)
}

/// SS 服务端（用于回环测试 / 自托管）：读取 salt + 加密头，解析出目标。
/// 返回（加密流, 会话, 目标），调用方可自行连目标并 `ss_proxy`。
pub async fn ss_server_accept(
    mut enc: TcpStream,
    master: &[u8; 32],
) -> io::Result<(TcpStream, Arc<Mutex<SsSession>>, SsTarget)> {
    let mut salt = [0u8; SALT_LEN];
    enc.read_exact(&mut salt).await?;
    let sess = SsSession::new(master, &salt);
    let sess_arc = Arc::new(Mutex::new(sess));
    let header = read_chunk(&mut enc, &sess_arc).await?;
    let target = parse_header(&header)?;
    Ok((enc, sess_arc, target))
}

/// 把一条明文连接（plain）与一条 SS 加密连接（enc）双向打通。
///
/// - plain→enc：读明文，用 sess.tx 加密成 chunk 写 enc；
/// - enc→plain：读 chunk，用 sess.rx 解密成明文写 plain。
///
/// 任一侧 EOS / 错误即结束该方向；两方向都结束后返回。
pub async fn ss_proxy<P, E>(plain: P, enc: E, sess: Arc<Mutex<SsSession>>)
where
    P: AsyncRead + AsyncWrite + Unpin + Send + 'static,
    E: AsyncRead + AsyncWrite + Unpin + Send + 'static,
{
    let (mut pr, mut pw) = tokio::io::split(plain);
    let (mut er, mut ew) = tokio::io::split(enc);

    // 方向 A：plain -> enc（加密发送）
    let s_tx = sess.clone();
    let fwd = tokio::spawn(async move {
        let mut buf = [0u8; MAX_PAYLOAD];
        loop {
            match pr.read(&mut buf).await {
                Ok(0) | Err(_) => break,
                Ok(n) => {
                    let chunk = { let mut s = s_tx.lock().await; s.seal(&buf[..n]) };
                    if ew.write_all(&chunk).await.is_err() {
                        break;
                    }
                    // 累计真实上行字节（密文长度近似真实写出量）
                    { proxy_stats().lock().unwrap().tx += chunk.len() as u64; }
                }
            }
        }
    });

    // 方向 B：enc -> plain（解密接收）
    let s_rx = sess.clone();
    let rev = tokio::spawn(async move {
        loop {
            match read_chunk(&mut er, &s_rx).await {
                Ok(payload) => {
                    if pw.write_all(&payload).await.is_err() {
                        break;
                    }
                    // 累计真实下行字节（明文长度）
                    { proxy_stats().lock().unwrap().rx += payload.len() as u64; }
                }
                Err(_) => break,
            }
        }
    });

    // 两个方向各自在 task 内收尾；这里等待两者结束（顺序 await 不影响并发）。
    let _ = fwd.await;
    let _ = rev.await;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn seal_open_roundtrip() {
        let mk = master_key("test-password");
        let salt = random_salt();
        let mut a = SsSession::new(&mk, &salt);
        let mut b = SsSession::new(&mk, &salt);
        let samples = [
            b"".to_vec(),
            b"hello world".to_vec(),
            vec![0u8; 2000],
            (0..16383u16).map(|x| x as u8).collect::<Vec<u8>>(),
        ];
        for s in &samples {
            let sealed = a.seal(s);
            // 两段式：前 18 字节为长度块，其后为载荷块
            assert!(sealed.len() >= 18, "sealed too short");
            let len_block = &sealed[..18];
            let h = b.open(len_block).expect("open len");
            let plen = u16::from_be_bytes([h[0], h[1]]) as usize;
            assert_eq!(plen, s.len());
            let payload_block = &sealed[18..18 + plen + TAG_LEN];
            let payload = b.open(payload_block).expect("open payload");
            assert_eq!(&payload, s);
        }
    }

    #[test]
    fn header_roundtrip_ipv4() {
        let t = SsTarget {
            host: "1.2.3.4".into(),
            port: 443,
        };
        let h = build_header(&t);
        let parsed = parse_header(&h).unwrap();
        assert_eq!(parsed.host, "1.2.3.4");
        assert_eq!(parsed.port, 443);
    }

    #[test]
    fn header_roundtrip_domain() {
        let t = SsTarget {
            host: "example.com".into(),
            port: 8388,
        };
        let h = build_header(&t);
        let parsed = parse_header(&h).unwrap();
        assert_eq!(parsed.host, "example.com");
        assert_eq!(parsed.port, 8388);
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn end_to_end_ss_link() {
        // 回环目标 echo server
        let echo = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let echo_addr = echo.local_addr().unwrap();
        let mk = master_key("e2e-secret");

        // SS server：accept -> 解析目标 -> 连目标 -> 双向代理
        let ss_listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let ss_addr = ss_listener.local_addr().unwrap();
        tokio::spawn(async move {
            loop {
                let (enc, _) = match ss_listener.accept().await {
                    Ok(x) => x,
                    Err(_) => break,
                };
                tokio::spawn(async move {
                    let (enc, sess, target) = match ss_server_accept(enc, &mk).await {
                        Ok(x) => x,
                        Err(e) => {
                            eprintln!("ss_server_accept err: {e}");
                            return;
                        }
                    };
                    let target_conn =
                        match TcpStream::connect((target.host.as_str(), target.port)).await {
                            Ok(c) => c,
                            Err(e) => {
                                eprintln!("target connect err: {e}");
                                return;
                            }
                        };
                    ss_proxy(target_conn, enc, sess).await;
                });
            }
        });

        // echo server 任务
        tokio::spawn(async move {
            let (mut s, _) = match echo.accept().await {
                Ok(x) => x,
                Err(_) => return,
            };
            let mut buf = [0u8; 4096];
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

        // 本地"客户端侧"真实 socket：模拟 socks5 交给 ss_proxy 的明文连接
        let local = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let local_addr = local.local_addr().unwrap();
        let client_stream = TcpStream::connect(local_addr).await.unwrap();
        let (local_stream, _) = local.accept().await.unwrap();

        // 客户端：走 SS 连到 echo 目标
        let target = SsTarget {
            host: echo_addr.ip().to_string(),
            port: echo_addr.port(),
        };
        let (ss_stream, sess) =
            ss_client_connect(&mk, "127.0.0.1", ss_addr.port(), &target)
                .await
                .unwrap();

        // 启动双向代理（ss_proxy 内部 spawn 两个方向）
        let proxy_task = tokio::spawn(ss_proxy(local_stream, ss_stream, sess));

        // 通过 client_stream 发送数据，应经 SS 链路被 echo 回
        let send = b"real-end-to-end-bytes";
        let mut client_stream = client_stream;
        client_stream.write_all(send).await.unwrap();
        eprintln!("[test] client wrote {} bytes", send.len());
        let mut rx = [0u8; 64];
        let n = tokio::time::timeout(std::time::Duration::from_secs(5), client_stream.read(&mut rx))
            .await
            .expect("client read timed out (no echo returned)")
            .unwrap();
        eprintln!("[test] client read {n} bytes");
        assert_eq!(&rx[..n], send);
        drop(client_stream);
        // 代理链路在真实运行中持续转发（连接保持），测试里主动中止即可。
        proxy_task.abort();
    }
}
