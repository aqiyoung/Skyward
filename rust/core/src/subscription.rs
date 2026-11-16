use crate::outbound;
use std::io;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::time::Duration;

const MAX_BODY: usize = 5 * 1024 * 1024;
const MAX_HEADER: usize = 32 * 1024;
const REQUEST_TIMEOUT: Duration = Duration::from_secs(20);
const MAX_REDIRECTS: usize = 4;

#[derive(Clone)]
struct Url {
    secure: bool,
    host: String,
    authority: String,
    port: u16,
    path: String,
}

struct Response {
    status: u16,
    location: Option<String>,
    body: Vec<u8>,
}

pub async fn fetch_url(input: &str) -> io::Result<String> {
    let mut url = parse_url(input, None)?;
    for redirect in 0..=MAX_REDIRECTS {
        let response = tokio::time::timeout(REQUEST_TIMEOUT, request(&url))
            .await
            .map_err(|_| io::Error::new(io::ErrorKind::TimedOut, "订阅请求超时"))??;
        if (300..400).contains(&response.status) {
            let location = response.location.ok_or_else(|| {
                io::Error::new(io::ErrorKind::InvalidData, "订阅重定向缺少 Location")
            })?;
            if redirect == MAX_REDIRECTS {
                return Err(io::Error::new(io::ErrorKind::InvalidData, "订阅重定向过多"));
            }
            let redirected = parse_url(&location, Some(&url))?;
            if url.secure && !redirected.secure {
                return Err(io::Error::new(io::ErrorKind::InvalidInput, "拒绝 HTTPS 订阅降级到 HTTP"));
            }
            url = redirected;
            continue;
        }
        if !(200..300).contains(&response.status) {
            return Err(io::Error::new(
                io::ErrorKind::Other,
                format!("订阅服务器返回 HTTP {}", response.status),
            ));
        }
        let text = String::from_utf8(response.body)
            .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "订阅内容不是 UTF-8"))?;
        if text.trim().is_empty() {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "订阅内容为空"));
        }
        return Ok(text);
    }
    Err(io::Error::new(io::ErrorKind::InvalidData, "订阅重定向过多"))
}

async fn request(url: &Url) -> io::Result<Response> {
    let mut stream = outbound::dial_raw(&url.host, url.port, url.secure, &url.host).await?;
    let request = format!(
        "GET {} HTTP/1.1\r\nHost: {}\r\nUser-Agent: Skyward-Rust/1\r\nAccept: */*\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n",
        url.path, url.authority
    );
    stream.write_all(request.as_bytes()).await?;
    stream.flush().await?;

    let mut bytes = Vec::new();
    let mut buf = [0u8; 8192];
    loop {
        let n = match stream.read(&mut buf).await {
            Ok(n) => n,
            Err(error) if error.kind() == io::ErrorKind::UnexpectedEof && !bytes.is_empty() => break,
            Err(error) => return Err(error),
        };
        if n == 0 {
            break;
        }
        if bytes.len().saturating_add(n) > MAX_BODY + MAX_HEADER {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "订阅内容超过 5 MiB"));
        }
        bytes.extend_from_slice(&buf[..n]);
    }
    parse_response(&bytes)
}

fn parse_response(bytes: &[u8]) -> io::Result<Response> {
    let split = bytes
        .windows(4)
        .position(|w| w == b"\r\n\r\n")
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "HTTP 响应头不完整"))?;
    if split > MAX_HEADER {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "HTTP 响应头过大"));
    }
    let headers = std::str::from_utf8(&bytes[..split])
        .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "HTTP 响应头编码无效"))?;
    let mut lines = headers.split("\r\n");
    let status = lines
        .next()
        .and_then(|line| line.split_whitespace().nth(1))
        .and_then(|value| value.parse::<u16>().ok())
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "HTTP 状态行无效"))?;
    let mut chunked = false;
    let mut location = None;
    let mut content_length = None;
    let mut content_encoding = String::new();
    for line in lines {
        let Some((key, value)) = line.split_once(':') else { continue };
        match key.trim().to_ascii_lowercase().as_str() {
            "transfer-encoding" => {
                let encoding = value.trim().to_ascii_lowercase();
                if encoding != "chunked" {
                    return Err(io::Error::new(io::ErrorKind::InvalidData, "HTTP Transfer-Encoding 不受支持"));
                }
                chunked = true;
            }
            "content-length" => {
                let length = value.trim().parse::<usize>()
                    .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "HTTP Content-Length 无效"))?;
                if content_length.is_some_and(|previous| previous != length) {
                    return Err(io::Error::new(io::ErrorKind::InvalidData, "HTTP Content-Length 冲突"));
                }
                content_length = Some(length);
            }
            "location" => location = Some(value.trim().to_string()),
            "content-encoding" => content_encoding = value.trim().to_ascii_lowercase(),
            _ => {}
        }
    }
    if chunked && content_length.is_some() {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "HTTP 响应同时包含 Transfer-Encoding 和 Content-Length"));
    }
    if content_encoding != "" && content_encoding != "identity" {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "订阅服务器返回了不支持的压缩格式"));
    }
    let raw_body = &bytes[split + 4..];
    if content_length.is_some_and(|length| length > MAX_BODY) {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "订阅内容超过 5 MiB"));
    }
    let body = if chunked {
        decode_chunked(raw_body)?
    } else if let Some(length) = content_length {
        if raw_body.len() < length {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "订阅内容不完整"));
        }
        raw_body[..length].to_vec()
    } else {
        if raw_body.len() > MAX_BODY {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "订阅内容超过 5 MiB"));
        }
        raw_body.to_vec()
    };
    Ok(Response { status, location, body })
}

fn decode_chunked(input: &[u8]) -> io::Result<Vec<u8>> {
    let mut out = Vec::new();
    let mut at = 0;
    loop {
        let line_end = input[at..]
            .windows(2)
            .position(|w| w == b"\r\n")
            .map(|n| at + n)
            .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "HTTP chunk 长度无效"))?;
        let size_text = std::str::from_utf8(&input[at..line_end])
            .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "HTTP chunk 长度无效"))?;
        let size = usize::from_str_radix(size_text.split(';').next().unwrap_or("").trim(), 16)
            .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "HTTP chunk 长度无效"))?;
        at = line_end + 2;
        if size == 0 {
            loop {
                let trailer_end = input[at..]
                    .windows(2)
                    .position(|window| window == b"\r\n")
                    .map(|offset| at + offset)
                    .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "HTTP chunk trailers 不完整"))?;
                if trailer_end == at {
                    return Ok(out);
                }
                at = trailer_end + 2;
            }
        }
        let end = at.checked_add(size).and_then(|value| value.checked_add(2));
        if out.len().saturating_add(size) > MAX_BODY || end.is_none_or(|end| input.len() < end) {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "HTTP chunk 内容不完整或过大"));
        }
        out.extend_from_slice(&input[at..at + size]);
        at += size;
        if &input[at..at + 2] != b"\r\n" {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "HTTP chunk 分隔符无效"));
        }
        at += 2;
    }
}

fn normalize_uri_path(path: &str) -> String {
    let (raw_path, query) = path.split_once('?').unwrap_or((path, ""));
    let trailing_slash = raw_path.ends_with('/') || raw_path.ends_with("/.") || raw_path.ends_with("/..");
    let mut segments = Vec::new();
    for segment in raw_path.split('/') {
        match segment {
            "" | "." => {}
            ".." => { let _ = segments.pop(); }
            _ => segments.push(segment),
        }
    }
    let mut normalized = format!("/{}", segments.join("/"));
    if trailing_slash && !normalized.ends_with('/') {
        normalized.push('/');
    }
    if !query.is_empty() {
        normalized.push('?');
        normalized.push_str(query);
    }
    normalized
}

fn parse_url(input: &str, base: Option<&Url>) -> io::Result<Url> {
    let input = input.trim();
    if input.is_empty() || input.bytes().any(|b| b == b'\r' || b == b'\n') {
        return Err(io::Error::new(io::ErrorKind::InvalidInput, "订阅 URL 无效"));
    }
    if let Some(base) = base {
        if input.starts_with("//") {
            return parse_url(&format!("{}:{}", if base.secure { "https" } else { "http" }, input), None);
        }
        if !input.contains("://") {
            let scheme = if base.secure { "https" } else { "http" };
            let absolute = if input.starts_with('/') {
                format!("{scheme}://{}{}", base.authority, normalize_uri_path(input))
            } else if input.starts_with('?') {
                let path = base.path.split('?').next().unwrap_or("/");
                format!("{scheme}://{}{}{}", base.authority, path, input)
            } else {
                let base_path = base.path.split('?').next().unwrap_or("/");
                let parent = base_path.rsplit_once('/').map(|(head, _)| head).unwrap_or("");
                let merged = normalize_uri_path(&format!("{parent}/{input}"));
                format!("{scheme}://{}{merged}", base.authority)
            };
            return parse_url(&absolute, None);
        }
    }

    let (scheme, rest) = input
        .split_once("://")
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "订阅 URL 必须以 http:// 或 https:// 开头"))?;
    let secure = match scheme.to_ascii_lowercase().as_str() {
        "https" => true,
        "http" => false,
        _ => return Err(io::Error::new(io::ErrorKind::InvalidInput, "仅支持 HTTP 或 HTTPS 订阅 URL")),
    };
    let rest = rest.split('#').next().unwrap_or("");
    let boundary = rest.find(|c| c == '/' || c == '?').unwrap_or(rest.len());
    let authority = &rest[..boundary];
    if authority.is_empty() || authority.contains('@') {
        return Err(io::Error::new(io::ErrorKind::InvalidInput, "订阅 URL 主机无效"));
    }
    let tail = &rest[boundary..];
    let path = if tail.is_empty() {
        "/".to_string()
    } else if tail.starts_with('?') {
        format!("/{tail}")
    } else {
        tail.to_string()
    };
    if path.bytes().any(|b| b.is_ascii_control()) {
        return Err(io::Error::new(io::ErrorKind::InvalidInput, "订阅 URL 路径无效"));
    }

    let (host, port) = if let Some(bracketed) = authority.strip_prefix('[') {
        let close = bracketed
            .find(']')
            .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "IPv6 主机地址无效"))?;
        let host = &bracketed[..close];
        let after = &bracketed[close + 1..];
        let port = if after.is_empty() {
            if secure { 443 } else { 80 }
        } else {
            after.strip_prefix(':')
                .and_then(|s| s.parse::<u16>().ok())
                .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "订阅 URL 端口无效"))?
        };
        (host.to_string(), port)
    } else if let Some((host, raw_port)) = authority.rsplit_once(':') {
        if host.contains(':') {
            return Err(io::Error::new(io::ErrorKind::InvalidInput, "IPv6 主机地址需使用方括号"));
        }
        let port = raw_port
            .parse::<u16>()
            .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "订阅 URL 端口无效"))?;
        (host.to_string(), port)
    } else {
        (authority.to_string(), if secure { 443 } else { 80 })
    };
    if host.is_empty() || port == 0 || host.bytes().any(|b| b.is_ascii_whitespace()) {
        return Err(io::Error::new(io::ErrorKind::InvalidInput, "订阅 URL 主机无效"));
    }
    let default_port = if secure { 443 } else { 80 };
    let host_header = if port == default_port {
        if host.contains(':') { format!("[{host}]") } else { host.clone() }
    } else if host.contains(':') {
        format!("[{host}]:{port}")
    } else {
        format!("{host}:{port}")
    };
    Ok(Url { secure, host, authority: host_header, port, path })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_https_and_relative_redirects() {
        let base = parse_url("https://example.com/sub/list?token=x", None).unwrap();
        assert_eq!(base.path, "/sub/list?token=x");
        assert_eq!(parse_url("../next", Some(&base)).unwrap().path, "/next");
        assert_eq!(parse_url("?next=1", Some(&base)).unwrap().path, "/sub/list?next=1");
        assert!(parse_url("ftp://example.com/list", None).is_err());
    }

    #[test]
    fn decodes_chunked_responses() {
        assert_eq!(decode_chunked(b"4\r\ntest\r\n0\r\n\r\n").unwrap().as_slice(), b"test");
        assert_eq!(decode_chunked(b"1\r\na\r\n0\r\nX-Test: ok\r\n\r\n").unwrap().as_slice(), b"a");
        assert!(decode_chunked(b"4\r\ntest\r\n0\r\n").is_err());
        assert!(decode_chunked(b"bad").is_err());
    }

    #[test]
    fn validates_content_length_and_status() {
        let response = parse_response(b"HTTP/1.1 200 OK\r\nContent-Length: 4\r\n\r\ntest").unwrap();
        assert_eq!(response.status, 200);
        assert_eq!(response.body.as_slice(), b"test");
        assert!(parse_response(b"HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\ntest").is_err());
        assert!(parse_response(b"HTTP/1.1 200 OK\r\nContent-Length: nope\r\n\r\ntest").is_err());
        assert!(parse_response(b"HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\nContent-Length: 4\r\n\r\n").is_err());
        assert!(parse_response(b"HTTP/1.1 200 OK\r\nContent-Encoding: gzip\r\n\r\n").is_err());
    }
}
