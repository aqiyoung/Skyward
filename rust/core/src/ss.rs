//! Shadowsocks AEAD 出站协议（PoC-6）。
//!
//! 这是内核第一次拥有真正的"转发肌肉"：用 AEAD 加密经真实 TCP 连远端
//! SS 服务器并收发字节——不再是内存模拟。
//!
//! 设计要点：
//! - 支持三种标准 AEAD：chacha20-ietf-poly1305 / aes-128-gcm / aes-256-gcm，
//!   AES 走 ring（硬件 AES 指令），ChaCha 沿用纯 Rust 实现。
//! - 主密钥 = OpenSSL EVP_BytesToKey(MD5)（SS 标准），每次连接随机 salt
//!   （长度 = 密钥长度）；会话子密钥 = HKDF-SHA1(master, salt, "ss-subkey")。
//! - 每个 chunk 结构：`seal([u16 length][payload])` → 输出 `[length_chunk(2+16)][payload_chunk(len+16)]`。
//! - nonce（12 字节）= 小端计数（shadowsocks 标准），收发各自独立计数。
//! - 双向代理以 `ss_proxy(plain, enc, sess)` 复用：enc 侧发用 tx、收用 rx。

use chacha20poly1305::aead::generic_array::GenericArray;
use chacha20poly1305::aead::Aead as ChaChaAead;
use chacha20poly1305::{ChaCha20Poly1305, KeyInit};
use hmac::{Hmac, Mac};
use ring::aead::{self as ring_aead, LessSafeKey, UnboundKey};
use sha1::Sha1;
use std::io;
use std::net::{Ipv4Addr, Ipv6Addr};
use std::sync::{Arc, OnceLock};
use tokio::io::{AsyncRead, AsyncReadExt, AsyncWrite, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio::sync::Mutex;

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

type HmacSha1 = Hmac<Sha1>;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum SsCipher {
    Chacha20IetfPoly1305,
    Aes128Gcm,
    Aes256Gcm,
}

impl SsCipher {
    pub fn parse(name: &str) -> Option<SsCipher> {
        match name.trim().to_ascii_lowercase().as_str() {
            "chacha20-ietf-poly1305" | "chacha20-poly1305" | "aead_chacha20_poly1305" => {
                Some(SsCipher::Chacha20IetfPoly1305)
            }
            "aes-128-gcm" | "aead_aes_128_gcm" => Some(SsCipher::Aes128Gcm),
            "aes-256-gcm" | "aead_aes_256_gcm" => Some(SsCipher::Aes256Gcm),
            _ => None,
        }
    }

    pub fn key_len(self) -> usize {
        match self {
            SsCipher::Aes128Gcm => 16,
            _ => 32,
        }
    }

    pub fn salt_len(self) -> usize {
        self.key_len()
    }

    pub fn name(self) -> &'static str {
        match self {
            SsCipher::Chacha20IetfPoly1305 => "chacha20-ietf-poly1305",
            SsCipher::Aes128Gcm => "aes-128-gcm",
            SsCipher::Aes256Gcm => "aes-256-gcm",
        }
    }
}

/// RFC 1321 MD5（仅用于 EVP_BytesToKey，几十字节输入，无性能诉求）。
fn md5(parts: &[&[u8]]) -> [u8; 16] {
    const S: [u32; 64] = [
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
    ];
    const K: [u32; 64] = [
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
        0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
        0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
        0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
        0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
        0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
        0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
        0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
        0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
        0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
        0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
        0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
        0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
    ];
    let mut msg: Vec<u8> = parts.concat();
    let bits = (msg.len() as u64).wrapping_mul(8);
    msg.push(0x80);
    while msg.len() % 64 != 56 {
        msg.push(0);
    }
    msg.extend_from_slice(&bits.to_le_bytes());

    let (mut a0, mut b0, mut c0, mut d0) =
        (0x67452301u32, 0xefcdab89u32, 0x98badcfeu32, 0x10325476u32);
    for chunk in msg.chunks_exact(64) {
        let mut m = [0u32; 16];
        for (i, w) in m.iter_mut().enumerate() {
            *w = u32::from_le_bytes([
                chunk[4 * i],
                chunk[4 * i + 1],
                chunk[4 * i + 2],
                chunk[4 * i + 3],
            ]);
        }
        let (mut a, mut b, mut c, mut d) = (a0, b0, c0, d0);
        for i in 0..64 {
            let (f, g) = match i / 16 {
                0 => ((b & c) | (!b & d), i),
                1 => ((d & b) | (!d & c), (5 * i + 1) % 16),
                2 => (b ^ c ^ d, (3 * i + 5) % 16),
                _ => (c ^ (b | !d), (7 * i) % 16),
            };
            let tmp = d;
            d = c;
            c = b;
            b = b.wrapping_add(
                a.wrapping_add(f)
                    .wrapping_add(K[i])
                    .wrapping_add(m[g])
                    .rotate_left(S[i]),
            );
            a = tmp;
        }
        a0 = a0.wrapping_add(a);
        b0 = b0.wrapping_add(b);
        c0 = c0.wrapping_add(c);
        d0 = d0.wrapping_add(d);
    }
    let mut out = [0u8; 16];
    out[..4].copy_from_slice(&a0.to_le_bytes());
    out[4..8].copy_from_slice(&b0.to_le_bytes());
    out[8..12].copy_from_slice(&c0.to_le_bytes());
    out[12..].copy_from_slice(&d0.to_le_bytes());
    out
}

/// OpenSSL `EVP_BytesToKey`（MD5、无 salt）——Shadowsocks 标准的密码→主密钥派生。
pub fn evp_bytes_to_key(password: &[u8], key: &mut [u8]) {
    let mut last: Option<[u8; 16]> = None;
    let mut filled = 0usize;
    while filled < key.len() {
        let digest = match last {
            Some(prev) => md5(&[&prev, password]),
            None => md5(&[password]),
        };
        let take = (key.len() - filled).min(digest.len());
        key[filled..filled + take].copy_from_slice(&digest[..take]);
        filled += take;
        last = Some(digest);
    }
}

#[derive(Clone, Copy)]
pub struct SsKey {
    pub cipher: SsCipher,
    key: [u8; 32],
}

impl SsKey {
    pub fn derive(cipher: SsCipher, password: &str) -> SsKey {
        let mut key = [0u8; 32];
        evp_bytes_to_key(password.as_bytes(), &mut key[..cipher.key_len()]);
        SsKey { cipher, key }
    }

    pub fn material(&self) -> &[u8] {
        &self.key[..self.cipher.key_len()]
    }
}

/// 兼容旧调用点：默认 chacha20-ietf-poly1305 的主密钥。
pub fn master_key(password: &str) -> SsKey {
    SsKey::derive(SsCipher::Chacha20IetfPoly1305, password)
}

/// 子密钥 = `HKDF-SHA1(ikm = master, salt, info = "ss-subkey")`，长度 = 密钥长度；
/// 与规范有任何出入，真实服务端解第一个 chunk 即失败断开。
pub fn subkey(master: &SsKey, salt: &[u8]) -> Vec<u8> {
    let mut out = vec![0u8; master.cipher.key_len()];
    hkdf_sha1(master.material(), salt, &mut out);
    out
}

fn hkdf_sha1(ikm: &[u8], salt: &[u8], out: &mut [u8]) {
    let mut mac = <HmacSha1 as Mac>::new_from_slice(salt).expect("hkdf salt");
    mac.update(ikm);
    let prk = mac.finalize().into_bytes();

    let mut prev: Vec<u8> = Vec::new();
    let mut filled = 0usize;
    let mut counter: u8 = 1;
    while filled < out.len() {
        let mut m = <HmacSha1 as Mac>::new_from_slice(&prk).expect("hkdf prk");
        m.update(&prev);
        m.update(b"ss-subkey");
        m.update(&[counter]);
        prev = m.finalize().into_bytes().to_vec();
        let take = (out.len() - filled).min(prev.len());
        out[filled..filled + take].copy_from_slice(&prev[..take]);
        filled += take;
        counter = counter.wrapping_add(1);
    }
}

/// 生成一次连接的随机 salt（真实长度 = cipher.salt_len()，调用方取前缀）。
pub fn random_salt() -> [u8; 32] {
    let mut salt = [0u8; 32];
    let _ = getrandom::getrandom(&mut salt);
    salt
}

/// 统一的 AEAD 封装：ChaCha 走纯 Rust 实现，AES-GCM 走 ring。
enum AeadImpl {
    ChaCha(Box<ChaCha20Poly1305>),
    Ring(LessSafeKey),
}

impl AeadImpl {
    fn new(cipher: SsCipher, session_key: &[u8]) -> AeadImpl {
        match cipher {
            SsCipher::Chacha20IetfPoly1305 => AeadImpl::ChaCha(Box::new(
                ChaCha20Poly1305::new(GenericArray::from_slice(session_key)),
            )),
            SsCipher::Aes128Gcm => AeadImpl::Ring(LessSafeKey::new(
                UnboundKey::new(&ring_aead::AES_128_GCM, session_key).expect("aes128 key"),
            )),
            SsCipher::Aes256Gcm => AeadImpl::Ring(LessSafeKey::new(
                UnboundKey::new(&ring_aead::AES_256_GCM, session_key).expect("aes256 key"),
            )),
        }
    }

    fn seal(&self, nonce: &[u8; 12], plain: &[u8]) -> Vec<u8> {
        match self {
            AeadImpl::ChaCha(c) => c
                .encrypt(GenericArray::from_slice(nonce), plain)
                .expect("ss seal"),
            AeadImpl::Ring(k) => {
                let mut buf = plain.to_vec();
                let n = ring_aead::Nonce::assume_unique_for_key(*nonce);
                k.seal_in_place_append_tag(n, ring_aead::Aad::empty(), &mut buf)
                    .expect("ss seal");
                buf
            }
        }
    }

    fn open(&self, nonce: &[u8; 12], ct: &[u8]) -> io::Result<Vec<u8>> {
        match self {
            AeadImpl::ChaCha(c) => c
                .decrypt(GenericArray::from_slice(nonce), ct)
                .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "ss decrypt failed")),
            AeadImpl::Ring(k) => {
                let mut buf = ct.to_vec();
                let n = ring_aead::Nonce::assume_unique_for_key(*nonce);
                let plain_len = k
                    .open_in_place(n, ring_aead::Aad::empty(), &mut buf)
                    .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "ss decrypt failed"))?
                    .len();
                buf.truncate(plain_len);
                Ok(buf)
            }
        }
    }
}

/// 单个 SS 会话：持有子密钥与收发 nonce 计数。
pub struct SsSession {
    cipher: AeadImpl,
    tx: u64,
    rx: u64,
}

impl SsSession {
    /// 从主密钥 + 本次连接 salt 派生子密钥（HKDF-SHA1）。
    pub fn new(master: &SsKey, salt: &[u8]) -> Self {
        let skey = subkey(master, salt);
        SsSession {
            cipher: AeadImpl::new(master.cipher, &skey),
            tx: 0,
            rx: 0,
        }
    }

    /// SS nonce：12 字节小端计数（shadowsocks AEAD 标准）。
    #[inline]
    fn nonce(c: u64) -> [u8; 12] {
        let mut n = [0u8; 12];
        n[..8].copy_from_slice(&c.to_le_bytes());
        n
    }

    /// 加密一个 chunk：先发长度块 `encrypt([u16 length])`（密文固定 18 字节），
    /// 再发载荷块 `encrypt(payload)`（密文 = len+16 字节）。两段各自独立递增 nonce，
    /// 与 shadowsocks-rust / 标准 SS AEAD 完全一致，可对接真实远端。
    pub fn seal(&mut self, payload: &[u8]) -> Vec<u8> {
        let n = Self::nonce(self.tx);
        self.tx += 1;
        let len_frame = (payload.len() as u16).to_be_bytes();
        let mut out = self.cipher.seal(&n, len_frame.as_slice());
        let n2 = Self::nonce(self.tx);
        self.tx += 1;
        let payload_block = self.cipher.seal(&n2, payload);
        out.extend_from_slice(&payload_block);
        out
    }

    /// 解密一个加密块（长度块或载荷块），返回其明文。长度解析由读取端负责。
    pub fn open(&mut self, ct: &[u8]) -> io::Result<Vec<u8>> {
        let n = Self::nonce(self.rx);
        self.rx += 1;
        self.cipher.open(&n, ct)
    }
}

/// 目标地址（SS 地址类型）。
#[derive(Debug, Clone)]
pub struct SsTarget {
    pub host: String,
    pub port: u16,
}

/// 构造 SS 请求头：`[atype][addr][port(2)]`。
pub(crate) fn build_header(target: &SsTarget) -> Vec<u8> {
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
pub(crate) fn parse_header(buf: &[u8]) -> io::Result<SsTarget> {
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

/// SS 地址头长度（用于从 UDP 明文里切出真实载荷）。
pub(crate) fn header_len(buf: &[u8]) -> io::Result<usize> {
    match buf.first().copied() {
        Some(1) => Ok(7),  // atype=1 → 1 + 4 + 2
        Some(4) => Ok(19), // atype=4 → 1 + 16 + 2
        Some(3) => {
            if buf.len() < 2 {
                return Err(io::Error::new(io::ErrorKind::InvalidData, "domain short"));
            }
            Ok(2 + buf[1] as usize + 2)
        }
        Some(t) => Err(io::Error::new(
            io::ErrorKind::InvalidData,
            format!("bad atype {t}"),
        )),
        None => Err(io::Error::new(io::ErrorKind::InvalidData, "empty header")),
    }
}

/// SS AEAD UDP 加密（shadowsocks UDP relay 的客户端封装）：
/// `[salt] || AEAD(subkey, nonce = 0, [addr][payload])`。
///
/// 与 TCP 的区别：UDP 每个报文独立加盐、nonce 恒为 0、只加密一段明文，
/// 不需要长度前缀的两段式结构。服务器未开启 udp 时该报文会被直接丢弃。
pub fn seal_udp(master: &SsKey, target: &SsTarget, payload: &[u8]) -> Vec<u8> {
    let salt_len = master.cipher.salt_len();
    let salt = random_salt();
    let salt = &salt[..salt_len];
    let skey = subkey(master, salt);
    let cipher = AeadImpl::new(master.cipher, &skey);

    let mut plain = build_header(target);
    plain.extend_from_slice(payload);

    let nonce = [0u8; 12];
    let ct = cipher.seal(&nonce, &plain);

    let mut out = Vec::with_capacity(salt_len + ct.len());
    out.extend_from_slice(salt);
    out.extend_from_slice(&ct);
    out
}

/// SS AEAD UDP 解密：返回（来源地址, 载荷）。来源地址是服务器回包时写入的目标，
/// 客户端应校验它与请求目标一致，避免串包。
pub fn open_udp(master: &SsKey, pkt: &[u8]) -> io::Result<(SsTarget, Vec<u8>)> {
    let salt_len = master.cipher.salt_len();
    if pkt.len() < salt_len + TAG_LEN {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "ss udp too short"));
    }
    let (salt, ct) = pkt.split_at(salt_len);
    let skey = subkey(master, salt);
    let cipher = AeadImpl::new(master.cipher, &skey);
    let nonce = [0u8; 12];
    let plain = cipher.open(&nonce, ct)?;

    let target = parse_header(&plain)?;
    let hlen = header_len(&plain)?;
    if plain.len() < hlen {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "ss udp header short"));
    }
    Ok((target, plain[hlen..].to_vec()))
}

/// SS 客户端：连远端服务器、发送 salt + 加密头，返回（加密流, 会话）。
/// 之后调用 [`ss_proxy`] 把本地明文连接与加密流双向打通。
pub async fn ss_client_connect(
    master: &SsKey,
    server: &str,
    server_port: u16,
    target: &SsTarget,
) -> io::Result<(TcpStream, Arc<Mutex<SsSession>>)> {
    let mut stream = TcpStream::connect((server, server_port)).await?;
    let salt = random_salt();
    let salt = &salt[..master.cipher.salt_len()];
    stream.write_all(salt).await?;
    let mut sess = SsSession::new(master, salt);
    let header = build_header(target);
    let sealed = sess.seal(&header);
    stream.write_all(&sealed).await?;
    // 冲刷，避免对端读不全。
    stream.flush().await?;
    Ok((stream, Arc::new(Mutex::new(sess))))
}

/// 从加密流读一个完整 chunk：先读 18 字节长度块解密得长度，再读 `len+16` 字节载荷块解密得 payload。
pub(crate) async fn read_chunk<R>(r: &mut R, sess: &Arc<Mutex<SsSession>>) -> io::Result<Vec<u8>>
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
    master: &SsKey,
) -> io::Result<(TcpStream, Arc<Mutex<SsSession>>, SsTarget)> {
    let mut salt = vec![0u8; master.cipher.salt_len()];
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

    fn hex(bytes: &[u8]) -> String {
        bytes.iter().map(|b| format!("{b:02x}")).collect()
    }

    #[test]
    fn evp_bytes_to_key_matches_openssl_vectors() {
        // 向量由 Python hashlib.md5 独立计算，钉死 MD5 + EVP_BytesToKey 实现。
        let mut k16 = [0u8; 16];
        evp_bytes_to_key(b"", &mut k16);
        assert_eq!(hex(&k16), "d41d8cd98f00b204e9800998ecf8427e");
        evp_bytes_to_key(b"test-password", &mut k16);
        assert_eq!(hex(&k16), "dfb450efddbb5387197c84460623675b");
        let mut k32 = [0u8; 32];
        evp_bytes_to_key(b"test-password", &mut k32);
        assert_eq!(
            hex(&k32),
            "dfb450efddbb5387197c84460623675b69f2cebcd8ef520a3dfddef7c3d540b2"
        );
        evp_bytes_to_key(b"secret", &mut k32);
        assert_eq!(
            hex(&k32),
            "5ebe2294ecd0e0f08eab7690d2a6ee6926ae5cc854e36b6bdfca366848dea6bb"
        );
        let long = vec![b'a'; 100];
        evp_bytes_to_key(&long, &mut k32);
        assert_eq!(
            hex(&k32),
            "36a92cc94a9e0fa21f625f8bfb007adf1c2e3353e40401402b1b0a7bf3e33ae8"
        );
        let mut k24 = [0u8; 24];
        evp_bytes_to_key(b"test-password", &mut k24);
        assert_eq!(hex(&k24), "dfb450efddbb5387197c84460623675b69f2cebcd8ef520a");
    }

    #[test]
    fn cipher_parse_aliases_and_lengths() {
        assert_eq!(
            SsCipher::parse("CHACHA20-IETF-POLY1305"),
            Some(SsCipher::Chacha20IetfPoly1305)
        );
        assert_eq!(SsCipher::parse("chacha20-poly1305"), Some(SsCipher::Chacha20IetfPoly1305));
        assert_eq!(SsCipher::parse("aes-128-gcm"), Some(SsCipher::Aes128Gcm));
        assert_eq!(SsCipher::parse("AEAD_AES_256_GCM"), Some(SsCipher::Aes256Gcm));
        assert_eq!(SsCipher::parse("rc4-md5"), None);
        assert_eq!(SsCipher::Aes128Gcm.key_len(), 16);
        assert_eq!(SsCipher::Aes128Gcm.salt_len(), 16);
        assert_eq!(SsCipher::Aes256Gcm.key_len(), 32);
        assert_eq!(SsCipher::Chacha20IetfPoly1305.salt_len(), 32);
    }

    #[test]
    fn subkey_matches_hkdf_sha1_vectors() {
        // 独立向量（Python hashlib/hmac 按 RFC 5869 计算）钉死派生算法。
        let mk = SsKey::derive(SsCipher::Chacha20IetfPoly1305, "test-password");
        let salt: [u8; 32] = core::array::from_fn(|i| i as u8);
        let sk = subkey(&mk, &salt);
        assert_eq!(
            hex(&sk),
            "7b6ca12d45ef79467432717aaa6a6ae6e1dd046a505fb2ebaaac602210919595"
        );
        let mk16 = SsKey::derive(SsCipher::Aes128Gcm, "test-password");
        let salt16: [u8; 16] = core::array::from_fn(|i| i as u8);
        let sk16 = subkey(&mk16, &salt16);
        assert_eq!(hex(&sk16), "780f000955954fb33743812b1002261b");
    }

    #[test]
    fn seal_open_roundtrip_all_ciphers() {
        for cipher in [
            SsCipher::Chacha20IetfPoly1305,
            SsCipher::Aes128Gcm,
            SsCipher::Aes256Gcm,
        ] {
            let mk = SsKey::derive(cipher, "test-password");
            let salt = random_salt();
            let salt = &salt[..cipher.salt_len()];
            let mut a = SsSession::new(&mk, salt);
            let mut b = SsSession::new(&mk, salt);
            let samples = [
                b"".to_vec(),
                b"hello world".to_vec(),
                vec![0u8; 2000],
                (0..16383u16).map(|x| x as u8).collect::<Vec<u8>>(),
            ];
            for s in &samples {
                let sealed = a.seal(s);
                assert!(sealed.len() >= 18, "sealed too short");
                let len_block = &sealed[..18];
                let h = b.open(len_block).expect("open len");
                let plen = u16::from_be_bytes([h[0], h[1]]) as usize;
                assert_eq!(plen, s.len());
                let payload_block = &sealed[18..18 + plen + TAG_LEN];
                let payload = b.open(payload_block).expect("open payload");
                assert_eq!(&payload, s, "cipher {:?}", cipher);
            }
        }
    }

    #[test]
    fn tampered_ciphertext_rejected_all_ciphers() {
        for cipher in [
            SsCipher::Chacha20IetfPoly1305,
            SsCipher::Aes128Gcm,
            SsCipher::Aes256Gcm,
        ] {
            let mk = SsKey::derive(cipher, "k");
            let salt = random_salt();
            let salt = &salt[..cipher.salt_len()];
            let mut a = SsSession::new(&mk, salt);
            let mut b = SsSession::new(&mk, salt);
            let mut sealed = a.seal(b"payload");
            sealed[3] ^= 0xff;
            assert!(b.open(&sealed[..18]).is_err(), "cipher {:?}", cipher);
        }
    }

    #[test]
    fn udp_seal_open_roundtrip_all_ciphers() {
        for cipher in [
            SsCipher::Chacha20IetfPoly1305,
            SsCipher::Aes128Gcm,
            SsCipher::Aes256Gcm,
        ] {
            let mk = SsKey::derive(cipher, "udp-pass");
            let t = SsTarget { host: "1.2.3.4".into(), port: 53 };
            let sealed = seal_udp(&mk, &t, b"payload-bytes");
            assert_eq!(sealed.len(), cipher.salt_len() + 7 + 13 + TAG_LEN);
            let (got_t, got_p) = open_udp(&mk, &sealed).expect("open udp");
            assert_eq!(got_t.host, "1.2.3.4");
            assert_eq!(got_t.port, 53);
            assert_eq!(got_p, b"payload-bytes");
            let mut bad = sealed.clone();
            let last = bad.len() - 1;
            bad[last] ^= 0xff;
            assert!(open_udp(&mk, &bad).is_err());
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
        // 回环目标 echo server；AES-256-GCM 走与真实服务器一致的全链路。
        let echo = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let echo_addr = echo.local_addr().unwrap();
        let mk = SsKey::derive(SsCipher::Aes256Gcm, "e2e-secret");

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
