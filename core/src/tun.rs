//! TUN 设备接管（PoC-6）。
//!
//! 这是"接管设备层流量"的入口。Android 上由 `VpnService` 建立 TUN 并把 fd 传给内核；
//! 内核从 fd 读出原始 IP 帧，解析 IPv4 / TCP / UDP 头做分流与真实统计。
//!
//! 注意：沙箱无 `/dev/net/tun`，"设备读取"只能在安卓真机经 VpnService 验证；
//! 本文件的 `parse_ipv4` 帧解析为纯逻辑，可由单元测试真验证。

use std::io;
use std::fs::File;
use std::net::Ipv4Addr;
use std::os::fd::{FromRawFd, RawFd};
use std::sync::{Arc, Mutex};

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
pub fn parse_ipv4(pkt: &[u8]) -> io::Result<ParsedV4> {
    if pkt.len() < 20 {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "ipv4 too short"));
    }
    let ver_ihl = pkt[0];
    if ver_ihl >> 4 != 4 {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "not ipv4"));
    }
    let ihl = (ver_ihl & 0x0f) as usize * 4;
    if ihl < 20 || pkt.len() < ihl {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "bad ihl"));
    }
    let proto = pkt[9];
    let src_ip = Ipv4Addr::new(pkt[12], pkt[13], pkt[14], pkt[15]);
    let dst_ip = Ipv4Addr::new(pkt[16], pkt[17], pkt[18], pkt[19]);

    let l4 = match proto {
        6 => {
            // TCP
            if pkt.len() < ihl + 20 {
                return Err(io::Error::new(io::ErrorKind::InvalidData, "tcp too short"));
            }
            let src = u16::from_be_bytes([pkt[ihl], pkt[ihl + 1]]);
            let dst = u16::from_be_bytes([pkt[ihl + 2], pkt[ihl + 3]]);
            Some(L4::Tcp { src, dst })
        }
        17 => {
            // UDP
            if pkt.len() < ihl + 8 {
                return Err(io::Error::new(io::ErrorKind::InvalidData, "udp too short"));
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
}

/// 在独立 OS 线程里从 TUN fd 阻塞读取原始帧、解析并累计真实统计。
/// 返回的统计句柄供 JNI 查询。设备读取本身只能在安卓真机（VpnService 提供 fd）验证。
pub fn run_tun_blocking(fd: RawFd) -> Arc<Mutex<TunStats>> {
    let stats = Arc::new(Mutex::new(TunStats::default()));
    let s2 = stats.clone();
    std::thread::spawn(move || {
        // fd 由调用方保证是有效的 TUN 字符设备；File 接管所有权，drop 时关闭。
        let mut file = unsafe { File::from_raw_fd(fd) };
        let mut buf = vec![0u8; 65536];
        use std::io::Read;
        loop {
            match file.read(&mut buf) {
                Ok(0) => break, // EOF：对端关闭（如 VPN 断开）
                Ok(n) => {
                    if let Ok(p) = parse_ipv4(&buf[..n]) {
                        let mut s = s2.lock().unwrap();
                        s.bytes += n as u64;
                        s.packets += 1;
                        match p.l4 {
                            Some(L4::Tcp { .. }) => s.tcp += 1,
                            Some(L4::Udp { .. }) => s.udp += 1,
                            None => {}
                        }
                    }
                }
                Err(_) => break,
            }
        }
    });
    stats
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

    #[test]
    fn reject_non_ipv4_and_short() {
        assert!(parse_ipv4(&[0u8; 10]).is_err());
        let mut p = vec![0u8; 20];
        p[0] = 0x65; // ver6
        assert!(parse_ipv4(&p).is_err());
    }
}
