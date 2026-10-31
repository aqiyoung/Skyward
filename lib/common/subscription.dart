// Converts plain-text proxy link subscriptions to Clash YAML config.
// Supports vless://, vmess://, trojan://, ss://, ssr://, hysteria2:// etc.

import 'dart:convert';

/// Proxy link schemes we recognize.
const _proxySchemes = [
  'vless://',
  'vmess://',
  'trojan://',
  'ss://',
  'ssr://',
  'hysteria2://',
  'hysteria://',
  'tuic://',
  'socks5://',
  'http://',
];

/// Returns true if [text] looks like it contains proxy links (not YAML).
bool looksLikeProxyLinks(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  // Already a Clash config?
  if (trimmed.contains('proxies:') || trimmed.contains('mixed-port:')) {
    return false;
  }
  // Check for proxy link schemes
  final lower = trimmed.toLowerCase();
  return _proxySchemes.any((s) => lower.contains(s));
}

/// Tries to base64-decode [text]. Returns null if not valid base64
/// or if decoded content doesn't look like proxy links.
String? tryBase64Decode(String text) {
  final trimmed = text.trim().replaceAll(RegExp(r'\s+'), '');
  if (trimmed.isEmpty) return null;
  try {
    // Add padding if needed
    var padded = trimmed;
    while (padded.length % 4 != 0) {
      padded += '=';
    }
    final decoded = utf8.decode(base64.decode(padded));
    if (looksLikeProxyLinks(decoded)) {
      return decoded;
    }
  } catch (_) {}
  return null;
}

/// Converts subscription [content] to a Clash YAML config.
/// If content is already YAML, returns it unchanged.
/// If content is base64-encoded proxy links, decodes first.
/// If content is plain-text proxy links, generates a Clash config.
String convertToClashConfig(String content) {
  var text = content.trim();
  if (text.isEmpty) return content;

  // Already YAML?
  if (!looksLikeProxyLinks(text)) {
    // Try base64
    final decoded = tryBase64Decode(text);
    if (decoded != null) {
      text = decoded;
    } else {
      return content; // Not proxy links, return as-is
    }
  }

  // Parse proxy links
  final proxies = <Map<String, dynamic>>[];
  final names = <String>[];
  
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final proxy = _parseProxyLink(trimmed);
    if (proxy != null) {
      proxies.add(proxy);
      names.add(proxy['name'] as String);
    }
  }

  if (proxies.isEmpty) return content;

  // Generate Clash YAML
  final buffer = StringBuffer();
  buffer.writeln('proxies:');
  for (final p in proxies) {
    buffer.writeln('  - ${_mapToYaml(p, 4)}');
  }
  buffer.writeln('proxy-groups:');
  buffer.writeln('  - name: PROXY');
  buffer.writeln('    type: select');
  buffer.writeln('    proxies:');
  for (final n in names) {
    buffer.writeln('      - ${_yamlString(n)}');
  }
  buffer.writeln('rules:');
  buffer.writeln('  - MATCH,PROXY');
  
  return buffer.toString();
}

/// Parses a single proxy link into a Clash proxy map.
/// Returns null if the link format is not recognized.
Map<String, dynamic>? _parseProxyLink(String link) {
  final lower = link.toLowerCase();
  if (lower.startsWith('vless://')) return _parseVless(link);
  if (lower.startsWith('vmess://')) return _parseVmess(link);
  if (lower.startsWith('trojan://')) return _parseTrojan(link);
  if (lower.startsWith('ssr://')) return _parseSsr(link);
  if (lower.startsWith('ss://')) return _parseSs(link);
  if (lower.startsWith('hysteria2://')) return _parseHysteria2(link);
  if (lower.startsWith('hysteria://')) return _parseHysteria(link);
  if (lower.startsWith('tuic://')) return _parseTuic(link);
  if (lower.startsWith('socks5://')) return _parseSocks5(link);
  if (lower.startsWith('http://')) return _parseHttp(link);
  return null;
}

Map<String, dynamic>? _parseVless(String link) {
  try {
    final uri = Uri.parse(link);
    final params = uri.queryParameters;
    
    // userInfo may be base64-encoded "uuid@host:port" or "method:uuid@host:port"
    // or plain "uuid". Try to decode.
    String userInfo = Uri.decodeComponent(uri.userInfo);
    String host = uri.host;
    int port = uri.port;
    try {
      // Try base64 decode (for links like vless://base64(uuid@host:port)?...)
      var padded = userInfo;
      // Only try if it looks like base64 (no @ : . characters typical in plain)
      if (!userInfo.contains('@') && RegExp(r'^[A-Za-z0-9+/=_-]+$').hasMatch(userInfo)) {
        while (padded.length % 4 != 0) padded += '=';
        final decoded = utf8.decode(base64.decode(padded));
        if (decoded.contains('@')) {
          // Format: [method:]uuid@host:port
          final atIdx = decoded.lastIndexOf('@');
          final uuidPart = decoded.substring(0, atIdx);
          final hostPort = decoded.substring(atIdx + 1);
          // uuidPart may be "uuid" or "method:uuid"
          final colonIdx = uuidPart.indexOf(':');
          userInfo = colonIdx != -1 ? uuidPart.substring(colonIdx + 1) : uuidPart;
          final hpColon = hostPort.lastIndexOf(':');
          if (hpColon != -1) {
            host = hostPort.substring(0, hpColon);
            port = int.tryParse(hostPort.substring(hpColon + 1)) ?? port;
          } else {
            host = hostPort;
          }
        }
      }
    } catch (_) {
      // Not base64, use as-is
    }
    // userInfo may still be "method:uuid", extract uuid
    String uuid = userInfo;
    final colonIdx = userInfo.indexOf(':');
    if (colonIdx != -1 && !userInfo.contains('@')) {
      // Could be "auto:uuid" format
      final possibleUuid = userInfo.substring(colonIdx + 1);
      if (possibleUuid.contains('-')) {
        uuid = possibleUuid;
      }
    }
    
    // Name from remarks param or fragment
    String name;
    if (params['remarks'] != null) {
      name = params['remarks']!;
    } else if (uri.fragment.isNotEmpty) {
      name = Uri.decodeComponent(uri.fragment);
    } else {
      name = '$host:$port';
    }
    
    final proxy = <String, dynamic>{
      'name': name,
      'type': 'vless',
      'server': host,
      'port': port,
      'uuid': uuid,
    };
    
    // Security: support security=tls/reality, tls=1, and xtls/pbk indicators
    final security = params['security'] ?? 'none';
    final tlsParam = params['tls'];
    final hasTls = security == 'tls' || tlsParam == '1' || tlsParam == 'true';
    // Reality indicated by security=reality, or pbk (public key), or xtls param
    final isReality = security == 'reality' || 
        params['pbk'] != null || 
        params['xtls'] != null;
    
    if (hasTls || isReality) {
      proxy['tls'] = true;
      // servername from sni or peer param
      final sni = params['sni'] ?? params['peer'];
      if (sni != null) proxy['servername'] = sni;
      if (isReality) {
        proxy['reality-opts'] = {
          'public-key': params['pbk'] ?? '',
          'short-id': params['sid'] ?? '',
        };
      }
      final fp = params['fp'] ?? params['fingerprint'];
      if (fp != null) proxy['fingerprint'] = fp;
      if (params['alpn'] != null) {
        proxy['alpn'] = params['alpn']!.split(',');
      }
    }
    
    // Transport
    final type = params['type'] ?? 'tcp';
    if (type != 'tcp') {
      proxy['network'] = type;
      if (type == 'ws') {
        final wsOpts = <String, dynamic>{};
        if (params['path'] != null) wsOpts['path'] = params['path'];
        if (params['host'] != null) {
          wsOpts['headers'] = {'Host': params['host']};
        }
        if (wsOpts.isNotEmpty) proxy['ws-opts'] = wsOpts;
      } else if (type == 'grpc') {
        proxy['grpc-opts'] = {
          'grpc-service-name': params['serviceName'] ?? '',
        };
      }
    }
    
    // UDP and TFO
    if (params['udp'] == '1' || params['udp'] == 'true') {
      proxy['udp'] = true;
    }
    if (params['tfo'] == '1' || params['tfo'] == 'true') {
      proxy['tfo'] = true;
    }
    
    return proxy;
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _parseVmess(String link) {
  try {
    // vmess:// is base64-encoded JSON
    final b64 = link.substring('vmess://'.length);
    var padded = b64;
    while (padded.length % 4 != 0) padded += '=';
    final json = jsonDecode(utf8.decode(base64.decode(padded)));
    
    return {
      'name': json['ps'] ?? '${json['add']}:${json['port']}',
      'type': 'vmess',
      'server': json['add'],
      'port': int.tryParse(json['port'].toString()) ?? 443,
      'uuid': json['id'],
      'alterId': int.tryParse(json['aid'].toString()) ?? 0,
      'cipher': json['scy'] ?? 'auto',
      'tls': json['tls'] == 'tls',
      if (json['sni'] != null) 'servername': json['sni'],
      if (json['net'] != null && json['net'] != 'tcp') 'network': json['net'],
    };
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _parseTrojan(String link) {
  try {
    final uri = Uri.parse(link);
    final name = uri.fragment.isNotEmpty
        ? Uri.decodeComponent(uri.fragment)
        : '${uri.host}:${uri.port}';
    final params = uri.queryParameters;
    
    return {
      'name': name,
      'type': 'trojan',
      'server': uri.host,
      'port': uri.port,
      'password': Uri.decodeComponent(uri.userInfo),
      if (params['sni'] != null) 'sni': params['sni'],
    };
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _parseSs(String link) {
  // ss:// parsing is complex (multiple formats), basic support
  try {
    // ss://method:password@host:port#name  OR  ss://base64#name
    if (link.contains('@')) {
      final uri = Uri.parse(link);
      final name = uri.fragment.isNotEmpty
          ? Uri.decodeComponent(uri.fragment)
          : '${uri.host}:${uri.port}';
      final userInfo = Uri.decodeComponent(uri.userInfo);
      final parts = userInfo.split(':');
      if (parts.length >= 2) {
        return {
          'name': name,
          'type': 'ss',
          'server': uri.host,
          'port': uri.port,
          'cipher': parts[0],
          'password': parts.sublist(1).join(':'),
        };
      }
    }
  } catch (_) {}
  return null;
}


Map<String, dynamic>? _parseSsr(String link) {
  // ssr://base64(host:port:protocol:method:obfs:base64pass/?obfsparam=...&protoparam=...&remarks=...&group=...)
  try {
    var b64 = link.substring('ssr://'.length);
    // Remove fragment if present
    final hashIdx = b64.indexOf('#');
    if (hashIdx != -1) b64 = b64.substring(0, hashIdx);
    var padded = b64;
    while (padded.length % 4 != 0) padded += '=';
    final decoded = utf8.decode(base64.decode(padded));
    // format: host:port:protocol:method:obfs:base64pass/?params
    final mainParts = decoded.split('/?');
    final parts = mainParts[0].split(':');
    if (parts.length < 6) return null;
    final host = parts[0];
    final port = int.tryParse(parts[1]) ?? 443;
    final protocol = parts[2];
    final method = parts[3];
    final obfs = parts[4];
    var password = parts[5];
    try {
      var pp = password;
      while (pp.length % 4 != 0) pp += '=';
      password = utf8.decode(base64.decode(pp));
    } catch (_) {}
    String name = '$host:$port';
    String? obfsParam;
    String? protocolParam;
    String? group;
    if (mainParts.length > 1) {
      final params = Uri.splitQueryString(mainParts[1]);
      if (params['remarks'] != null) {
        var r = params['remarks']!;
        while (r.length % 4 != 0) r += '=';
        try { name = utf8.decode(base64.decode(r)); } catch (_) {}
      }
      if (params['obfsparam'] != null) {
        var o = params['obfsparam']!;
        while (o.length % 4 != 0) o += '=';
        try { obfsParam = utf8.decode(base64.decode(o)); } catch (_) {}
      }
      if (params['protoparam'] != null) {
        var p = params['protoparam']!;
        while (p.length % 4 != 0) p += '=';
        try { protocolParam = utf8.decode(base64.decode(p)); } catch (_) {}
      }
      if (params['group'] != null) {
        var g = params['group']!;
        while (g.length % 4 != 0) g += '=';
        try { group = utf8.decode(base64.decode(g)); } catch (_) {}
      }
    }
    return {
      'name': name,
      'type': 'ssr',
      'server': host,
      'port': port,
      'cipher': method,
      'password': password,
      'protocol': protocol,
      'obfs': obfs,
      if (obfsParam != null && obfsParam.isNotEmpty) 'obfs-param': obfsParam,
      if (protocolParam != null && protocolParam.isNotEmpty) 'protocol-param': protocolParam,
      if (group != null && group.isNotEmpty) 'group': group,
    };
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _parseHysteria2(String link) {
  // hysteria2://password@host:port?query#name
  try {
    final uri = Uri.parse(link);
    final name = uri.fragment.isNotEmpty
        ? Uri.decodeComponent(uri.fragment)
        : '${uri.host}:${uri.port}';
    final params = uri.queryParameters;
    return {
      'name': name,
      'type': 'hysteria2',
      'server': uri.host,
      'port': uri.port != 0 ? uri.port : 443,
      'password': Uri.decodeComponent(uri.userInfo),
      if (params['sni'] != null) 'sni': params['sni'],
      if (params['insecure'] == '1') 'skip-cert-verify': true,
      if (params['obfs'] != null) 'obfs': params['obfs'],
      if (params['obfs-password'] != null) 'obfs-password': params['obfs-password'],
    };
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _parseHysteria(String link) {
  // hysteria://host:port?protocol=udp&auth=...&upmbps=...&downmbps=...#name
  try {
    final uri = Uri.parse(link);
    final name = uri.fragment.isNotEmpty
        ? Uri.decodeComponent(uri.fragment)
        : '${uri.host}:${uri.port}';
    final params = uri.queryParameters;
    return {
      'name': name,
      'type': 'hysteria',
      'server': uri.host,
      'port': uri.port != 0 ? uri.port : 443,
      if (params['auth'] != null) 'auth-str': params['auth'],
      if (params['protocol'] != null) 'protocol': params['protocol'],
      if (params['upmbps'] != null) 'up': params['upmbps'],
      if (params['downmbps'] != null) 'down': params['downmbps'],
      if (params['sni'] != null) 'sni': params['sni'],
      if (params['insecure'] == '1') 'skip-cert-verify': true,
      if (params['obfs'] != null) 'obfs': params['obfs'],
    };
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _parseTuic(String link) {
  // tuic://uuid:password@host:port?congestion_controller=...&alpn=h3&sni=...#name
  try {
    final uri = Uri.parse(link);
    final name = uri.fragment.isNotEmpty
        ? Uri.decodeComponent(uri.fragment)
        : '${uri.host}:${uri.port}';
    final params = uri.queryParameters;
    final userInfo = Uri.decodeComponent(uri.userInfo);
    final parts = userInfo.split(':');
    return {
      'name': name,
      'type': 'tuic',
      'server': uri.host,
      'port': uri.port != 0 ? uri.port : 443,
      'uuid': parts[0],
      'password': parts.length > 1 ? parts.sublist(1).join(':') : '',
      if (params['sni'] != null) 'sni': params['sni'],
      if (params['alpn'] != null) 'alpn': params['alpn']!.split(','),
      if (params['congestion_controller'] != null)
        'congestion-controller': params['congestion_controller'],
      if (params['disable_sni'] == '1') 'disable-sni': true,
    };
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _parseSocks5(String link) {
  // socks5://user:pass@host:port#name
  try {
    final uri = Uri.parse(link);
    final name = uri.fragment.isNotEmpty
        ? Uri.decodeComponent(uri.fragment)
        : '${uri.host}:${uri.port}';
    final userInfo = Uri.decodeComponent(uri.userInfo);
    final parts = userInfo.split(':');
    return {
      'name': name,
      'type': 'socks5',
      'server': uri.host,
      'port': uri.port != 0 ? uri.port : 1080,
      if (parts.isNotEmpty && parts[0].isNotEmpty) 'username': parts[0],
      if (parts.length > 1) 'password': parts.sublist(1).join(':'),
    };
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _parseHttp(String link) {
  // http://user:pass@host:port#name
  try {
    final uri = Uri.parse(link);
    final name = uri.fragment.isNotEmpty
        ? Uri.decodeComponent(uri.fragment)
        : '${uri.host}:${uri.port}';
    final userInfo = Uri.decodeComponent(uri.userInfo);
    final parts = userInfo.split(':');
    return {
      'name': name,
      'type': 'http',
      'server': uri.host,
      'port': uri.port != 0 ? uri.port : 8080,
      if (parts.isNotEmpty && parts[0].isNotEmpty) 'username': parts[0],
      if (parts.length > 1) 'password': parts.sublist(1).join(':'),
    };
  } catch (_) {
    return null;
  }
}

String _yamlString(String s) {
  if (s.contains(':') || s.contains('#') || s.contains('"')) {
    return '"${s.replaceAll('"', '\\"')}"';
  }
  return s;
}

String _mapToYaml(Map<String, dynamic> map, int indent) {
  final buffer = StringBuffer();
  final pad = ' ' * indent;
  var first = true;
  for (final entry in map.entries) {
    if (!first) buffer.write('\n$pad');
    first = false;
    buffer.write('${entry.key}: ${_valueToYaml(entry.value, indent)}');
  }
  return buffer.toString();
}

String _valueToYaml(dynamic value, int indent) {
  if (value is String) return _yamlString(value);
  if (value is bool || value is num) return value.toString();
  if (value is List) {
    if (value.isEmpty) return '[]';
    final pad = ' ' * (indent + 2);
    return '\n$pad- ${value.map((e) => _valueToYaml(e, indent + 2)).join('\n$pad- ')}';
  }
  if (value is Map) {
    final pad = ' ' * (indent + 2);
    final entries = value.entries.map((e) => '$pad${e.key}: ${_valueToYaml(e.value, indent + 2)}');
    return '\n${entries.join('\n')}';
  }
  return value.toString();
}
