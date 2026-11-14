//! 本地 SOCKS5 入口（PoC-6）。
//!
//! 内核监听 TCP 端口（默认 1080），解析 SOCKS5 握手与 CONNECT 请求，
//! 把目标交给 SS 出站协议并双向打通。这样外部 App / 浏览器把代理指向本机端口，
//! 流量即经真实 SS 链路转发——这是内核第一次具备"真实代理入口"。

use crate::ss::{master_key, ss_client_connect, ss_proxy, SsTarget};
use std::io;
use std::net::{Ipv4Addr, Ipv6Addr};
use std::sync::Arc;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};

/// 代理配置：远端 SS 服务器与密码。
#[derive(Clone)]
pub struct ProxyConfig {
    pub ss_server: String,
    pub ss_port: u16,
    pub password: String,
}

/// 启动 SOCKS5 监听循环（在 tokio runtime 上 spawn）。
pub async fn run_socks5(port: u16, cfg: Arc<ProxyConfig>) -> io::Result<()> {
    let listener = TcpListener::bind(("0.0.0.0", port)).await?;
    loop {
        let (conn, _peer) = listener.accept().await?;
        let cfg = cfg.clone();
        tokio::spawn(async move {
            if let Err(e) = handle_conn(conn, &cfg).await {
                // 连接级错误只记录，不影响监听循环。
                eprintln!("socks5 conn err: {e}");
            }
        });
    }
}

/// 处理单条 SOCKS5 连接：握手 → CONNECT → 经 SS 双向代理。
async fn handle_conn(mut conn: TcpStream, cfg: &ProxyConfig) -> io::Result<()> {
    // 1) 方法协商：VER NMETHODS METHODS...
    let mut hdr = [0u8; 2];
    conn.read_exact(&mut hdr).await?;
    if hdr[0] != 5 {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "socks5 bad ver"));
    }
    let nmethods = hdr[1] as usize;
    let mut methods = vec![0u8; nmethods];
    conn.read_exact(&mut methods).await?;
    // 仅支持无认证（0x00）。
    conn.write_all(&[0x05, 0x00]).await?;

    // 2) 请求：VER CMD RSV ATYP DST.ADDR DST.PORT
    let mut rhdr = [0u8; 4];
    conn.read_exact(&mut rhdr).await?;
    if rhdr[0] != 5 || rhdr[1] != 1 {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "socks5 only CONNECT"));
    }
    let atype = rhdr[3];
    let host = match atype {
        1 => {
            let mut a = [0u8; 4];
            conn.read_exact(&mut a).await?;
            Ipv4Addr::from(a).to_string()
        }
        4 => {
            let mut a = [0u8; 16];
            conn.read_exact(&mut a).await?;
            Ipv6Addr::from(a).to_string()
        }
        3 => {
            let mut l = [0u8; 1];
            conn.read_exact(&mut l).await?;
            let mut d = vec![0u8; l[0] as usize];
            conn.read_exact(&mut d).await?;
            String::from_utf8_lossy(&d).into_owned()
        }
        t => {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("socks5 bad atype {t}"),
            ))
        }
    };
    let mut port_b = [0u8; 2];
    conn.read_exact(&mut port_b).await?;
    let port = u16::from_be_bytes(port_b);

    // 3) 回复 success（绑定地址占位为 0.0.0.0:0）。
    conn.write_all(&[0x05, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0])
        .await?;

    // 4) 经 SS 连远端目标并双向代理。
    let master = master_key(&cfg.password);
    let target = SsTarget { host, port };
    let (ss_stream, sess) = ss_client_connect(&master, &cfg.ss_server, cfg.ss_port, &target).await?;
    ss_proxy(conn, ss_stream, sess).await;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::io::{AsyncReadExt, AsyncWriteExt};
    use tokio::net::TcpStream as ClientStream;

    /// 一个最小 SOCKS5 客户端：无认证握手 + CONNECT（IPv4 目标）。
    async fn socks5_connect(
        server: &str,
        port: u16,
        dst_ip: Ipv4Addr,
        dst_port: u16,
    ) -> io::Result<ClientStream> {
        let mut s = ClientStream::connect((server, port)).await?;
        s.write_all(&[0x05, 0x01, 0x00]).await?;
        let mut m = [0u8; 2];
        s.read_exact(&mut m).await?;
        assert_eq!(m, [0x05, 0x00]);
        let mut req = vec![0x05u8, 0x01, 0x00, 0x01];
        req.extend_from_slice(&dst_ip.octets());
        req.extend_from_slice(&dst_port.to_be_bytes());
        s.write_all(&req).await?;
        let mut rep = [0u8; 10];
        s.read_exact(&mut rep).await?;
        assert_eq!(rep[0], 5);
        assert_eq!(rep[1], 0); // success
        Ok(s)
    }

    #[tokio::test(flavor = "multi_thread")]
    async fn socks5_to_ss_e2e() {
        let mk = master_key("proxy-secret");

        // echo 目标
        let echo = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let echo_addr = echo.local_addr().unwrap();
        tokio::spawn(async move {
            let (mut s, _) = echo.accept().await.unwrap();
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

        // SS server
        let ss = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let ss_addr = ss.local_addr().unwrap();
        tokio::spawn(async move {
            loop {
                let (enc, _) = match ss.accept().await {
                    Ok(x) => x,
                    Err(_) => break,
                };
                tokio::spawn(async move {
                    let (enc, sess, target) =
                        match crate::ss::ss_server_accept(enc, &mk).await {
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

        // SOCKS5 server
        let cfg = Arc::new(ProxyConfig {
            ss_server: "127.0.0.1".into(),
            ss_port: ss_addr.port(),
            password: "proxy-secret".into(),
        });
        let socks_port = {
            let l = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
            l.local_addr().unwrap().port()
        };
        tokio::spawn(run_socks5(socks_port, cfg));

        // SOCKS5 client 经代理连 echo 目标并收发。
        // run_socks5 在后台 spawn，绑定完成时间与本线程存在竞争，故做有限重试。
        let mut c = None;
        for _ in 0..100 {
            match socks5_connect(
                "127.0.0.1",
                socks_port,
                echo_addr.ip().to_string().parse().unwrap(),
                echo_addr.port(),
            )
            .await
            {
                Ok(s) => {
                    c = Some(s);
                    break;
                }
                Err(_) => tokio::time::sleep(std::time::Duration::from_millis(10)).await,
            }
        }
        let mut c = c.expect("socks5 connect 多次重试仍失败");
        let send = b"via-socks5-and-ss";
        c.write_all(send).await.unwrap();
        let mut rx = [0u8; 64];
        let n = tokio::time::timeout(std::time::Duration::from_secs(5), c.read(&mut rx))
            .await
            .expect("socks5 read timed out")
            .unwrap();
        assert_eq!(&rx[..n], send);
    }
}
