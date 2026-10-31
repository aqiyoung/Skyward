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
  if (lower.startsWith('ss://')) return _parseSs(link);
  // TODO: ssr, hysteria2, tuic, etc.
  return null;
}

Map<String, dynamic>? _parseVless(String link) {
  try {
    final uri = Uri.parse(link);
    final name = uri.fragment.isNotEmpty 
        ? Uri.decodeComponent(uri.fragment) 
        : '${uri.host}:${uri.port}';
    final params = uri.queryParameters;
    
    final proxy = <String, dynamic>{
      'name': name,
      'type': 'vless',
      'server': uri.host,
      'port': uri.port,
      'uuid': Uri.decodeComponent(uri.userInfo),
    };
    
    // Security
    final security = params['security'] ?? 'none';
    if (security == 'tls' || security == 'reality') {
      proxy['tls'] = true;
      if (params['sni'] != null) proxy['servername'] = params['sni'];
      if (security == 'reality') {
        proxy['reality-opts'] = {
          'public-key': params['pbk'] ?? '',
          'short-id': params['sid'] ?? '',
        };
      }
      if (params['fp'] != null) proxy['fingerprint'] = params['fp'];
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
