import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:path/path.dart';
import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/state.dart';
import 'package:skyward/common/secure_client.dart';
import 'package:skyward/common/subscription.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

class Request {
  late final Dio dio;
  late final Dio _clashDio;
  String? userAgent;

  ProviderReader? _read;

  void attach(ProviderReader read) {
    _read = read;
  }

  Request() {
    dio = Dio(BaseOptions(headers: {'User-Agent': browserUa}));
    _clashDio = Dio();
    _clashDio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = (Uri uri) {
          client.userAgent = globalState.ua;
          final read = _read;
          if (read == null) {
            return 'DIRECT';
          }
          return SkywardHttpOverrides.findProxyForReader(read, uri);
        };
        return client;
      },
    );
  }

  Future<Response<T>> _download<T>(String url, ResponseType responseType) {
    final target = downloadTarget(url);
    final cancelToken = CancelToken();
    return _clashDio
        .getUri<T>(
          target.uri,
          options: Options(responseType: responseType, headers: target.headers),
          cancelToken: cancelToken,
        )
        .timeout(
          downloadTimeoutDuration,
          onTimeout: () {
            cancelToken.cancel();
            throw DioException.receiveTimeout(
              timeout: downloadTimeoutDuration,
              requestOptions: RequestOptions(path: url),
            );
          },
        );
  }

  Future<Response<Uint8List>> getFileResponseForUrl(String url) async {
    try {
      return await _download<Uint8List>(url, ResponseType.bytes);
    } catch (e) {
      commonPrint.log(
        'getFileResponseForUrl error ${compactError(e)}',
        logLevel: LogLevel.warning,
      );
      rethrow;
    }
  }

  Future<Response<String>> getTextResponseForUrl(String url) async {
    try {
      return await _download<String>(url, ResponseType.plain);
    } catch (e) {
      commonPrint.log(
        'getTextResponseForUrl error ${compactError(e)}',
        logLevel: LogLevel.warning,
      );
      rethrow;
    }
  }

  /// Null when this build is current; throws when GitHub cannot be asked.
  ///
  /// The check looks at the whole releases list, not just the latest
  /// release, so a newer beta or preview is found just as a newer stable
  /// is -- the latest-release endpoint only ever answers with a stable.
  /// A preview is Android-only, so it is skipped on desktop, where it has
  /// no package to install.
  ///
  /// The list carries each release's notes, where the shared build number
  /// lives, and that number is what lets a preview learn that a newer beta or
  /// stable exists. When the list cannot be read (the API quota is spent, the
  /// device is offline), this falls back first to the last list it cached while
  /// the API was reachable -- which still carries the numbers -- and only then
  /// to the latest stable alone. Without the cache a preview would be told
  /// there is no update, because the release-page redirect the last fallback
  /// follows names a tag and nothing more.
  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await HttpOverrides.runWithHttpOverrides(
        () => dio.get<List<dynamic>>(
          'https://api.github.com/repos/$repository/releases?per_page=30',
          options: Options(responseType: ResponseType.json),
        ),
        DirectOverrides(),
      );
      final releases = response.data ?? const <dynamic>[];
      await _cacheReleases(releases);
      return newestOfferableRelease(
        _platformCandidates(releases),
        installedVersion: globalState.packageInfo.displayVersion,
      );
    } on DioException catch (error) {
      commonPrint.log(
        'releases list failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
    }
    // The list could not be read. Reuse the last list we cached while the API
    // was reachable so a preview can still be offered a newer beta or stable by
    // build number, instead of being told there is nothing.
    final cached = await _readCachedReleases();
    if (cached.isNotEmpty) {
      final offer = newestOfferableRelease(
        _platformCandidates(cached),
        installedVersion: globalState.packageInfo.displayVersion,
      );
      if (offer != null) return offer;
    }
    final release = await latestRelease();
    final remoteVersion = release['tag_name'] as String;
    final version = globalState.packageInfo.displayVersion;
    final hasUpdate = shouldOfferUpdate(
      remoteVersion: releaseVersionOf(remoteVersion, release['name'] as String?),
      remoteBuildNumber: releaseBuildNumber(release['body']),
      installedVersion: version,
    );
    return hasUpdate ? release : null;
  }

  /// The release page redirect still answers once the hourly API quota is spent.
  @visibleForTesting
  Future<Map<String, dynamic>> latestRelease() async {
    try {
      final response = await HttpOverrides.runWithHttpOverrides(
        () => dio.get<Map<String, dynamic>>(
          'https://api.github.com/repos/$repository/releases/latest',
          options: Options(responseType: ResponseType.json),
        ),
        DirectOverrides(),
      );
      return response.data!;
    } on DioException catch (error) {
      commonPrint.log(
        'latest release API failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
    }
    final response = await HttpOverrides.runWithHttpOverrides(
      () => dio.get<void>(
        'https://github.com/$repository/releases/latest',
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
      ),
      DirectOverrides(),
    );
    final location = response.headers.value(HttpHeaders.locationHeader);
    final segments = Uri.tryParse(location ?? '')?.pathSegments ?? const [];
    final tagIndex = segments.indexOf('tag') + 1;
    if (tagIndex == 0 || tagIndex >= segments.length) {
      throw FormatException('No release tag in the redirect', location);
    }
    return {'tag_name': segments[tagIndex]};
  }

  /// The release list most recently fetched while the GitHub API was reachable.
  /// When the list cannot be read -- the hourly anonymous quota spent, or the
  /// device offline -- [checkForUpdate] reads this so a preview build can still
  /// find the shared build number in each release's notes and learn that a
  /// newer beta or stable exists. Without it the only fallback is the
  /// release-page redirect, which names a tag and nothing more, so a preview
  /// would wrongly hear that it has no update to take.
  static const _releasesCacheFileName = 'releases_cache.json';

  Future<File> _releasesCacheFile() async {
    return File(join(await appPath.homeDirPath, _releasesCacheFileName));
  }

  Future<void> _cacheReleases(List<dynamic> releases) async {
    try {
      await (await _releasesCacheFile()).safeWriteAsString(jsonEncode(releases));
    } catch (error) {
      commonPrint.log(
        'cache releases failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
    }
  }

  Future<List<dynamic>> _readCachedReleases() async {
    try {
      final file = await _releasesCacheFile();
      if (!await file.exists()) return const [];
      final content = await file.readAsString();
      if (content.isEmpty) return const [];
      final data = jsonDecode(content);
      return data is List ? data : const [];
    } catch (error) {
      commonPrint.log(
        'read cached releases failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      return const [];
    }
  }

  /// Drops the Android-only preview releases where they have no package to
  /// install -- on desktop -- and keeps everything else across every channel.
  List<dynamic> _platformCandidates(List<dynamic> releases) {
    if (!system.isDesktop) return releases;
    return releases.where((release) {
      final tag = release is Map ? release['tag_name'] : null;
      return tag is! String || !tag.startsWith('preview-');
    }).toList();
  }
}

final request = Request();

/// Some subscription servers send a gzip or zlib body without saying so in
/// Content-Encoding, which is the only signal dart:io decompresses on.
Uint8List decompressUnlabeled(Uint8List bytes) {
  final codec = switch (bytes) {
    [0x1f, 0x8b, ...] => gzip,
    [0x78, final flags, ...] when (0x78 << 8 | flags) % 31 == 0 => zlib,
    _ => null,
  };
  Uint8List decompressed = bytes;
  if (codec != null) {
    try {
      decompressed = Uint8List.fromList(codec.decode(bytes));
    } on FormatException {
      decompressed = bytes;
    }
  }
  // Convert plain-text proxy link subscriptions to Clash YAML
  try {
    final text = utf8.decode(decompressed);
    if (looksLikeProxyLinks(text)) {
      final yaml = convertToClashConfig(text);
      return Uint8List.fromList(utf8.encode(yaml));
    }
    // Try base64
    final decoded = tryBase64Decode(text);
    if (decoded != null) {
      final yaml = convertToClashConfig(decoded);
      return Uint8List.fromList(utf8.encode(yaml));
    }
  } catch (_) {
    // Not text, return as-is
  }
  return decompressed;
}

/// dart:io turns [Uri.userInfo] into Basic credentials still percent-encoded.
@visibleForTesting
({Uri uri, Map<String, Object> headers}) downloadTarget(String url) {
  final uri = url.webUri ?? Uri.parse(url);
  if (uri.userInfo.isEmpty) {
    return (uri: uri, headers: const {});
  }
  final credentials = uri.userInfo.split(':').map(_decodeUserInfo).join(':');
  return (
    uri: uri.replace(userInfo: ''),
    headers: {
      HttpHeaders.authorizationHeader:
          'Basic ${base64.encode(utf8.encode(credentials))}',
    },
  );
}

String _decodeUserInfo(String value) {
  try {
    return Uri.decodeComponent(value);
  } on ArgumentError {
    return value;
  }
}

String? getFileNameForDisposition(String? disposition) {
  if (disposition == null) return null;
  final parseValue = HeaderValue.parse(disposition);
  final parameters = parseValue.parameters;
  final fileNamePointKey = parameters.keys.firstWhere(
    (key) => key == 'filename*',
    orElse: () => '',
  );
  if (fileNamePointKey.isNotEmpty) {
    final res = parameters[fileNamePointKey]?.split("''") ?? [];
    if (res.length >= 2) {
      return Uri.decodeComponent(res[1]);
    }
  }
  final fileNameKey = parameters.keys.firstWhere(
    (key) => key == 'filename',
    orElse: () => '',
  );
  if (fileNameKey.isEmpty) return null;
  return parameters[fileNameKey];
}
