//! 数据面地基（PoC-5）：基于 tokio 的真实 socket 基础。
//!
//! 这是把内核从「模拟会话」推向「真能收发字节」的第一步。
//! 目前提供真实 TCP 探针（系统 DNS 解析 + 建连 + 收发试探字节），
//! 后续 tun 设备、出站协议、DNS 分流均构建于此运行时之上。
//!
//! 设计约束：release 用 `panic = "abort"`，故异步路径内**不允许任何会 panic 的
//! 调用**（无 `.unwrap()`/`.expect()`），全部用 `Result` / `match` 收口，避免
//! 单个任务 panic 拖垮整个 App 进程。

use std::sync::OnceLock;
use std::time::{Duration, Instant};

use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio::runtime::{Builder, Runtime};

static RUNTIME: OnceLock<Runtime> = OnceLock::new();

/// 拿到全局异步运行时（惰性创建，2 个 worker 线程）。
/// 后续所有协议 / tun 任务都用同一个事件循环派生，保证全内核共用一个 reactor。
pub fn runtime() -> &'static Runtime {
    RUNTIME.get_or_init(|| {
        Builder::new_multi_thread()
            .worker_threads(2)
            .enable_all()
            .build()
            .expect("tokio runtime init failed")
    })
}

/// 真实 TCP 探针结果。
pub struct Probe {
    pub ok: bool,
    pub ms: u64,
    pub ip: String,
    pub tx: u64,
    pub rx: u64,
    pub err: String,
}

/// 真实对外 TCP 探测：先走系统 DNS（getaddrinfo）解析，再建连，
/// 最后做最小收发试探。所有 I/O 都是真实 socket，不是模拟。
/// 返回结构化结果，调用方负责格式化。
pub async fn tcp_probe(host: &str, port: u16, timeout_ms: u64) -> Probe {
    let to = Duration::from_millis(timeout_ms.max(200));

    // 1) 真实 DNS 解析（系统解析器，非写死常量）。
    let addrs = match tokio::time::timeout(to, tokio::net::lookup_host((host, port))).await {
        Ok(Ok(a)) => a,
        Ok(Err(e)) => {
            return Probe { ok: false, ms: 0, ip: String::new(), tx: 0, rx: 0, err: format!("dns:{e}") };
        }
        Err(_) => {
            return Probe { ok: false, ms: 0, ip: String::new(), tx: 0, rx: 0, err: "dns timeout".into() };
        }
    };
    let target = match addrs.into_iter().next() {
        Some(a) => a,
        None => {
            return Probe { ok: false, ms: 0, ip: String::new(), tx: 0, rx: 0, err: "no address".into() };
        }
    };
    let ip = target.ip().to_string();

    // 2) 真实建连并计时。
    let start = Instant::now();
    let mut stream = match tokio::time::timeout(to, TcpStream::connect(target)).await {
        Ok(Ok(s)) => s,
        Ok(Err(e)) => {
            return Probe {
                ok: false,
                ms: start.elapsed().as_millis() as u64,
                ip,
                tx: 0,
                rx: 0,
                err: format!("connect:{e}"),
            };
        }
        Err(_) => {
            return Probe {
                ok: false,
                ms: start.elapsed().as_millis() as u64,
                ip,
                tx: 0,
                rx: 0,
                err: "connect timeout".into(),
            };
        }
    };
    let ms = start.elapsed().as_millis() as u64;

    // 3) 最小收发试探（真实字节进出内核 socket）。
    //    对 80 端口发一个真实 HTTP 请求以拿到响应；其它端口发 16 字节中性试探。
    let payload: Vec<u8> = if port == 80 {
        format!("GET / HTTP/1.0\r\nHost: {host}\r\n\r\n").into_bytes()
    } else {
        vec![0u8; 16]
    };
    let read_to = if port == 80 {
        Duration::from_millis(1200)
    } else {
        Duration::from_millis(600)
    };
    let mut tx = 0u64;
    let mut rx = 0u64;
    if tokio::time::timeout(to, stream.write_all(&payload))
        .await
        .is_ok_and(|r| r.is_ok())
    {
        tx = payload.len() as u64;
        let mut buf = [0u8; 512];
        if let Ok(Ok(n)) = tokio::time::timeout(read_to, stream.read(&mut buf)).await {
            rx = n as u64;
        }
    }
    let _ = stream.shutdown().await;
    Probe { ok: true, ms, ip, tx, rx, err: String::new() }
}

impl Probe {
    /// CSV：ok,ms,ip,tx,rx,err（供 JNI 直接回传，零对象分配）。
    pub fn to_csv(&self) -> String {
        format!(
            "{},{},{},{},{},{}",
            if self.ok { 1 } else { 0 },
            self.ms,
            self.ip,
            self.tx,
            self.rx,
            self.err
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn real_tcp_connect_to_example_com() {
        let rt = Builder::new_current_thread().enable_all().build().unwrap();
        let p = rt.block_on(tcp_probe("example.com", 80, 5000));
        assert!(p.ok, "应成功连到 example.com:80，err={}", p.err);
        assert!(!p.ip.is_empty(), "应解析出 IP");
        assert!(p.rx > 0, "应收到 HTTP 响应字节，rx={}", p.rx);
    }
}
