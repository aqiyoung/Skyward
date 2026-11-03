import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'package:skyward/enum/enum.dart';
import 'print.dart';
import 'protocol.dart';
import 'string.dart';

String? profileUrlFromQrCodes(Iterable<String?> values) {
  for (final value in values) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      continue;
    }
    if (text.isUrl || text.isShareLink) {
      return text;
    }
    final uri = Uri.tryParse(text);
    if (uri == null || !protocolSchemes.contains(uri.scheme)) {
      continue;
    }
    final url = _installConfigUrl(uri);
    if (url != null && url.isUrl) {
      return url;
    }
  }
  return null;
}

String? _installConfigUrl(Uri uri) {
  if (uri.host != 'install-config') {
    return null;
  }
  final url = uri.queryParameters['url']?.trim();
  if (url == null || url.isEmpty) {
    return null;
  }
  // SSRF / abuse guard: only fetch over public http/https, and never at
  // loopback, link-local (e.g. cloud metadata 169.254.169.254) or private
  // addresses. A web page or other app could otherwise make Skyward probe the
  // device or internal services through this deep link. Hostnames are allowed
  // (their resolved address cannot be checked statically here).
  if (!_isSafeInstallUrl(url)) {
    commonPrint.log(
      'rejected unsafe install-config url',
      logLevel: LogLevel.warning,
    );
    return null;
  }
  return url;
}

bool _isSafeInstallUrl(String url) {
  final parsed = Uri.tryParse(url);
  if (parsed == null ||
      (parsed.scheme != 'http' && parsed.scheme != 'https') ||
      parsed.host.isEmpty) {
    return false;
  }
  final address = InternetAddress.tryParse(parsed.host);
  if (address != null && _isUnsafeAddress(address)) {
    return false;
  }
  return true;
}

/// Rejects loopback, link-local (incl. cloud metadata 169.254.169.254) and
/// RFC1918 private addresses. [InternetAddress] has no `isPrivate` getter on
/// this Dart version, so the private ranges are checked manually.
bool _isUnsafeAddress(InternetAddress address) {
  if (address.isLoopback || address.isLinkLocal) return true;
  if (address.type == InternetAddressType.IPv4) {
    final b = address.rawAddress;
    if (b.length >= 2) {
      final a = b[0];
      if (a == 10) return true;
      if (a == 172 && b[1] >= 16 && b[1] <= 31) return true;
      if (a == 192 && b[1] == 168) return true;
    }
  }
  return false;
}

class LinkManager {
  static LinkManager? _instance;
  StreamSubscription? subscription;
  Uri? _pendingUri;

  LinkManager._internal();

  @visibleForTesting
  Stream<Uri> Function() uriLinkStream = () => AppLinks().uriLinkStream;

  /// Linux argv: the gtk plugin hooks GApplication too late to see it.
  void seedInitialLink(List<String> args) {
    for (final arg in args) {
      final uri = Uri.tryParse(arg);
      if (uri != null && protocolSchemes.contains(uri.scheme)) {
        _pendingUri = uri;
        return;
      }
    }
  }

  Future<void> initAppLinksListen(
    Function(String url) installConfigCallBack,
  ) async {
    destroy();
    subscription = uriLinkStream().listen((uri) {
      _handle(uri, installConfigCallBack);
    });
    final pending = _pendingUri;
    _pendingUri = null;
    if (pending != null) {
      _handle(pending, installConfigCallBack);
    }
  }

  void _handle(Uri uri, Function(String url) installConfigCallBack) {
    // The uri can carry a subscription link with a token in `url`: never
    // log it whole, the log can be exported and shared.
    final logged = uri.replace(queryParameters: {
      for (final entry in uri.queryParameters.entries)
        entry.key: entry.key == 'url' ? '<redacted>' : entry.value,
    });
    commonPrint.log('onAppLink: $logged');
    final url = _installConfigUrl(uri);
    if (url != null) {
      installConfigCallBack(url);
    }
  }

  void destroy() {
    if (subscription != null) {
      subscription?.cancel();
      subscription = null;
    }
  }

  factory LinkManager() {
    _instance ??= LinkManager._internal();
    return _instance!;
  }
}

final linkManager = LinkManager();
