//! DNS 转发（PoC-7）：TUN 里截到的 UDP:53 查询，经代理链路送到上游解析。
//!
//! 为什么不用本地系统解析：设备一开 VPN，所有流量都进了 TUN，系统解析器发出的
//! UDP 包同样被吸进来，本机已经"没有网"了。域名解析必须也走代理，否则开 VPN
//! 之后没有任何域名能用，TCP 闭环再完整也没意义。
//!
//! 传输选 DNS over TCP：SS 的 TCP 通道已经跑通，只要在报文前加 2 字节长度前缀即可，
//! 不依赖服务器是否开启 UDP relay。代价是多一次建连，所以加了按查询内容的缓存
//! （TTL 固定 120s，够覆盖一次页面加载里的重复查询）。
//!
//! 后续会把这里换成 SS 的 UDP relay，省掉 TCP 建连开销；接口不变。

use crate::outbound::{self, Protocol};
use crate::socks5::ProxyConfig;
use crate::ss::{read_chunk, ss_client_connect, SsTarget};
use std::collections::HashMap;
use std::io;
use std::net::Ipv4Addr;
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};
use tokio::io::AsyncWriteExt;

/// 上游 DNS 服务器：走代理出去，所以用境外的公共解析。
const UPSTREAM_HOST: &str = "8.8.8.8";
const UPSTREAM_PORT: u16 = 53;
/// 缓存有效期。
const CACHE_TTL: Duration = Duration::from_secs(120);
/// 缓存条目上限，防止长时间运行无限增长。
const CACHE_MAX: usize = 512;

/// 解析出的 UDP 报文。
pub struct UdpDatagram {
    pub src: Ipv4Addr,
    pub sport: u16,
    pub dst: Ipv4Addr,
    pub dport: u16,
    pub payload: Vec<u8>,
}

/// 从原始 IPv4 帧里取 UDP（仅首片）。
pub fn parse_udp(pkt: &[u8]) -> Option<UdpDatagram> {
    if pkt.len() < 20 || pkt[0] >> 4 != 4 {
        return None;
    }
    let ihl = ((pkt[0] & 0x0f) as usize) * 4;
    if ihl < 20 || pkt.len() < ihl + 8 {
        return None;
    }
    if pkt[9] != 17 {
        return None;
    }
    if u16::from_be_bytes([pkt[6], pkt[7]]) & 0x1fff != 0 {
        return None;
    }
    let total_len = u16::from_be_bytes([pkt[2], pkt[3]]) as usize;
    let end = total_len.min(pkt.len());
    let udp = &pkt[ihl..end];
    if udp.len() < 8 {
        return None;
    }
    let ulen = u16::from_be_bytes([udp[4], udp[5]]) as usize;
    let ulen = ulen.min(udp.len());
    if ulen < 8 {
        return None;
    }
    Some(UdpDatagram {
        src: Ipv4Addr::new(pkt[12], pkt[13], pkt[14], pkt[15]),
        sport: u16::from_be_bytes([udp[0], udp[1]]),
        dst: Ipv4Addr::new(pkt[16], pkt[17], pkt[18], pkt[19]),
        dport: u16::from_be_bytes([udp[2], udp[3]]),
        payload: udp[8..ulen].to_vec(),
    })
}

/// 构造从 `src:53` 回到 `dst:sport` 的 UDP 应答包。
pub fn build_udp_reply(src: Ipv4Addr, dst: Ipv4Addr, sport: u16, dport: u16, payload: &[u8]) -> Vec<u8> {
    crate::udpstack::build_udp_packet(src, dst, sport, dport, payload)
}

fn cache() -> &'static Mutex<HashMap<Vec<u8>, (Vec<u8>, Instant)>> {
    static C: OnceLock<Mutex<HashMap<Vec<u8>, (Vec<u8>, Instant)>>> = OnceLock::new();
    C.get_or_init(|| Mutex::new(HashMap::new()))
}

/// 缓存键：去掉 DNS 报文头里的 2 字节 ID，其余（flags + question）相同即可复用。
fn cache_key(query: &[u8]) -> Vec<u8> {
    if query.len() < 12 {
        return query.to_vec();
    }
    query[2..].to_vec()
}

fn cache_get(key: &[u8]) -> Option<Vec<u8>> {
    let mut m = match cache().lock() {
        Ok(g) => g,
        Err(e) => e.into_inner(),
    };
    match m.get(key) {
        Some((resp, at)) if at.elapsed() < CACHE_TTL => Some(resp.clone()),
        Some(_) => {
            m.remove(key);
            None
        }
        None => None,
    }
}

fn cache_put(key: Vec<u8>, resp: Vec<u8>) {
    let mut m = match cache().lock() {
        Ok(g) => g,
        Err(e) => e.into_inner(),
    };
    if m.len() >= CACHE_MAX {
        m.clear();
    }
    m.insert(key, (resp, Instant::now()));
}

/// 把查询报文送上游（DNS over TCP，经当前出站协议），返回应答报文。
///
/// 走 TCP 而不是 UDP 的原因：DNS over TCP 只需在报文前加 2 字节长度前缀，
/// 任何出站协议（SS / Trojan / VLESS）都能承载，不依赖服务端是否开 UDP relay。
pub async fn resolve(cfg: &ProxyConfig, master: &[u8; 32], query: &[u8]) -> io::Result<Vec<u8>> {
    let key = cache_key(query);
    if let Some(mut hit) = cache_get(&key) {
        // 复用缓存时把 ID 改回本次查询的
        if hit.len() >= 2 && query.len() >= 2 {
            hit[0] = query[0];
            hit[1] = query[1];
        }
        return Ok(hit);
    }

    let target = SsTarget { host: UPSTREAM_HOST.to_string(), port: UPSTREAM_PORT };
    let mut framed = Vec::with_capacity(query.len() + 2);
    framed.extend_from_slice(&(query.len() as u16).to_be_bytes());
    framed.extend_from_slice(query);

    let resp = if cfg.protocol == Protocol::Shadowsocks {
        let (mut enc, sess) = ss_client_connect(master, &cfg.ss_server, cfg.ss_port, &target).await?;
        let chunk = {
            let mut s = sess.lock().await;
            s.seal(&framed)
        };
        enc.write_all(&chunk).await?;
        enc.flush().await?;

        let mut buf: Vec<u8> = Vec::new();
        // 先凑够 2 字节长度
        while buf.len() < 2 {
            let p = read_chunk(&mut enc, &sess).await?;
            if p.is_empty() {
                return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "dns eof"));
            }
            buf.extend_from_slice(&p);
        }
        let want = u16::from_be_bytes([buf[0], buf[1]]) as usize;
        while buf.len() < 2 + want {
            let p = read_chunk(&mut enc, &sess).await?;
            if p.is_empty() {
                return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "dns short"));
            }
            buf.extend_from_slice(&p);
        }
        buf[2..2 + want].to_vec()
    } else {
        // Trojan / VLESS：握手头之后就是裸字节流，直接按长度前缀读写
        let mut st = outbound::dial(
            cfg.protocol,
            &cfg.ss_server,
            cfg.ss_port,
            &cfg.password,
            cfg.tls,
            &cfg.sni,
            &target,
        )
        .await?;
        st.write_all(&framed).await?;
        st.flush().await?;
        read_framed(&mut st).await?
    };

    cache_put(key, resp.clone());
    Ok(resp)
}

/// 从流里读一条 DNS over TCP 报文（2 字节长度前缀 + 报文）。
async fn read_framed<R>(r: &mut R) -> io::Result<Vec<u8>>
where
    R: tokio::io::AsyncRead + Unpin,
{
    use tokio::io::AsyncReadExt;
    let mut len = [0u8; 2];
    r.read_exact(&mut len).await?;
    let want = u16::from_be_bytes(len) as usize;
    let mut buf = vec![0u8; want];
    r.read_exact(&mut buf).await?;
    Ok(buf)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::tcpstack::checksum;

    fn sample_query() -> Vec<u8> {
        // 一个最小的 A 查询：id=0x1234, flags=0x0100, qd=1,
        // example.com type A class IN
        let mut q = vec![0x12, 0x34, 0x01, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0];
        for label in ["example", "com"] {
            q.push(label.len() as u8);
            q.extend_from_slice(label.as_bytes());
        }
        q.push(0);
        q.extend_from_slice(&1u16.to_be_bytes()); // type A
        q.extend_from_slice(&1u16.to_be_bytes()); // class IN
        q
    }

    #[test]
    fn parse_udp_roundtrip() {
        let q = sample_query();
        let pkt = build_udp_reply(
            Ipv4Addr::new(8, 8, 8, 8),
            Ipv4Addr::new(10, 10, 10, 2),
            53,
            40123,
            &q,
        );
        // 校验和必须自洽
        assert_eq!(checksum(&[&pkt[..20]]), 0);
        let s = Ipv4Addr::new(8, 8, 8, 8).octets();
        let d = Ipv4Addr::new(10, 10, 10, 2).octets();
        let ulen = pkt.len() - 20;
        let pseudo = [s[0], s[1], s[2], s[3], d[0], d[1], d[2], d[3], 0, 17,
            (ulen >> 8) as u8, ulen as u8];
        assert_eq!(checksum(&[&pseudo, &pkt[20..]]), 0);

        let parsed = parse_udp(&pkt).expect("应能解出 UDP");
        assert_eq!(parsed.sport, 53);
        assert_eq!(parsed.dport, 40123);
        assert_eq!(parsed.payload, q);
    }

    #[test]
    fn cache_key_ignores_id() {
        let mut a = sample_query();
        let mut b = sample_query();
        b[0] = 0xab;
        b[1] = 0xcd;
        assert_eq!(cache_key(&a), cache_key(&b));
        // 问题不同则键不同
        a.push(0xff);
        assert_ne!(cache_key(&a), cache_key(&b));
    }

    #[test]
    fn cache_hit_rewrites_id() {
        let q1 = sample_query();
        let mut resp = q1.clone();
        resp[2] = 0x81; // QR=1
        let key = cache_key(&q1);
        cache_put(key.clone(), resp);
        let got = cache_get(&key).expect("应命中");
        assert_eq!(got.len(), q1.len());
    }
}
