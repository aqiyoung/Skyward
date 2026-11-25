import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:skyward/common/common.dart';

/// Thrown when a downloaded update fails its digest or length check. ReClash
/// calls this UpdateDownloadVerificationException; the name is kept short.
class UpdateDownloadVerificationException implements Exception {
  const UpdateDownloadVerificationException(this.message);
  final String message;

  @override
  String toString() => 'UpdateDownloadVerificationException: $message';
}

/// The identity of a partial download, persisted so a resumed transfer can be
/// matched against the exact same asset. Schema version 1 matches ReClash.
class _ResumeMetadata {
  const _ResumeMetadata({
    required this.url,
    required this.sha256,
    required this.size,
    this.total,
    this.etag,
    this.lastModified,
  });

  final String url;
  final String sha256;
  final int? size;
  final int? total;
  final String? etag;
  final String? lastModified;

  String? get validator => etag ?? lastModified;

  _ResumeMetadata withResponse({int? total, String? etag, String? lastModified}) =>
      _ResumeMetadata(
        url: url,
        sha256: sha256,
        size: size,
        total: total ?? this.total,
        etag: etag ?? this.etag,
        lastModified: lastModified ?? this.lastModified,
      );

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'url': url,
    'sha256': sha256,
    'size': size,
    'total': total,
    'etag': etag,
    'lastModified': lastModified,
  };

  factory _ResumeMetadata.fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['schemaVersion'] != 1) {
      throw const FormatException('Invalid update resume metadata');
    }
    final url = value['url'];
    final sha256 = value['sha256'];
    final size = value['size'];
    if (url is! String ||
        sha256 is! String ||
        !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(sha256) ||
        (size != null && (size is! int || size <= 0))) {
      throw const FormatException('Invalid update resume metadata identity');
    }
    return _ResumeMetadata(
      url: url,
      sha256: sha256,
      size: size,
      total: value['total'] is int ? value['total'] as int : null,
      etag: value['etag'] is String ? value['etag'] as String : null,
      lastModified: value['lastModified'] is String
          ? value['lastModified'] as String
          : null,
    );
  }
}

class _ContentRange {
  const _ContentRange(this.start, this.end, this.total);
  final int start;
  final int end;
  final int total;
  int get length => end - start + 1;

  static _ContentRange? parse(String? header) {
    final match = RegExp(r'^bytes (\d+)-(\d+)/(\d+)$').firstMatch(header ?? '');
    if (match == null) return null;
    final start = int.tryParse(match.group(1)!);
    final end = int.tryParse(match.group(2)!);
    final total = int.tryParse(match.group(3)!);
    if (start == null || end == null || total == null || start > end || end >= total) {
      return null;
    }
    return _ContentRange(start, end, total);
  }
}

/// Streams one update asset to [target], resuming a partial file when the
/// metadata still matches, and verifying length + SHA-256 before publishing.
/// The result is a ready-to-install file in the app-private update directory,
/// which is what the native verifier insists on.
class UpdateFileTransfer {
  UpdateFileTransfer({
    required this.dio,
    required this.uri,
    required this.target,
    required this.cancelToken,
    required this.onProgress,
    required this.expectedSha256,
    required this.expectedSize,
  });

  final Dio dio;
  final Uri uri;
  final File target;
  final CancelToken cancelToken;
  final void Function(int received, int total) onProgress;
  final String expectedSha256;
  final int? expectedSize;

  static const _timeout = Duration(minutes: 10);

  late final File _partial = File('${target.path}.tmp');
  late final File _metadataFile = File('${target.path}.tmp.json');
  late _ResumeMetadata _metadata;
  CancelToken? _networkToken;
  Timer? _idleTimer;
  bool _timedOut = false;
  bool _rangeRestarted = false;
  int _received = 0;

  Future<void> run() async {
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(expectedSha256)) {
      throw const UpdateDownloadVerificationException('Invalid pinned SHA-256');
    }
    if (expectedSize != null && expectedSize! <= 0) {
      throw const UpdateDownloadVerificationException('Invalid pinned size');
    }
    _armIdleTimer();
    unawaited(cancelToken.whenCancel.then((e) => _networkToken?.cancel(e)));
    try {
      _metadata = _ResumeMetadata(
        url: uri.toString(),
        sha256: expectedSha256.toLowerCase(),
        size: expectedSize,
      );
      await _restorePartial();
      while (true) {
        try {
          while (!await _receiveResponse()) {
            _ensureActive();
          }
          _ensureActive();
          await _publish();
          return;
        } on UpdateDownloadVerificationException {
          if (_rangeRestarted) rethrow;
          _rangeRestarted = true;
          await _discardPartial();
          _metadata = _ResumeMetadata(
            url: uri.toString(),
            sha256: expectedSha256.toLowerCase(),
            size: expectedSize,
          );
        }
      }
    } catch (error) {
      await _discardPartial();
      _ensureActive();
      rethrow;
    } finally {
      _idleTimer?.cancel();
      _networkToken?.cancel();
      _networkToken = null;
    }
  }

  void _armIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_timeout, () {
      _timedOut = true;
      _networkToken?.cancel('Update download timed out');
    });
  }

  Future<void> _restorePartial() async {
    if (await _partial.exists() && await _metadataFile.exists()) {
      try {
        if (await _metadataFile.length() > 16384) {
          throw const FormatException('metadata too large');
        }
        final saved = _ResumeMetadata.fromJson(jsonDecode(await _metadataFile.readAsString()));
        final length = await _partial.length();
        final total = saved.total ?? saved.size;
        if (saved.url == _metadata.url &&
            saved.sha256 == _metadata.sha256 &&
            saved.size == _metadata.size &&
            (total == null || length <= total)) {
          _metadata = saved;
          _received = length;
          return;
        }
      } on Object {
        // A partial without the exact asset identity is never resumed.
      }
    }
    await _discardPartial();
  }

  Future<bool> _receiveResponse() async {
    _ensureActive();
    final networkToken = CancelToken();
    _networkToken = networkToken;
    final offset = _received;
    final validator = _metadata.validator;
    ResponseBody? body;
    var consumed = false;
    try {
      final response = await dio.getUri<ResponseBody>(
        uri,
        cancelToken: networkToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            HttpHeaders.acceptEncodingHeader: 'identity',
            if (offset > 0) HttpHeaders.rangeHeader: 'bytes=$offset-',
            if (offset > 0 && validator != null) HttpHeaders.ifRangeHeader: validator,
          },
          validateStatus: (_) => true,
        ),
      );
      body = response.data;
      final status = response.statusCode;
      if (status == HttpStatus.requestedRangeNotSatisfiable) {
        if (expectedSize != null && offset == expectedSize) {
          _metadata = _metadata.withResponse(total: expectedSize);
          return true;
        }
        if (_rangeRestarted) {
          throw const UpdateDownloadVerificationException('Server rejected the update range');
        }
        _rangeRestarted = true;
        await _discardPartial();
        _metadata = _ResumeMetadata(url: uri.toString(), sha256: expectedSha256.toLowerCase(), size: expectedSize);
        return false;
      }
      if (status != HttpStatus.ok && status != HttpStatus.partialContent) {
        throw DioException.badResponse(
          statusCode: status ?? 0,
          requestOptions: response.requestOptions,
          response: response,
        );
      }
      final encoding = response.headers.value(HttpHeaders.contentEncodingHeader);
      if (encoding != null && encoding.toLowerCase() != 'identity') {
        throw const UpdateDownloadVerificationException('Encoded update ranges are not supported');
      }
      final rawLength = response.headers.value(HttpHeaders.contentLengthHeader);
      final length = rawLength == null ? null : int.tryParse(rawLength);
      if (rawLength != null && (length == null || length < 0)) {
        throw const UpdateDownloadVerificationException('Invalid Content-Length');
      }
      final range = status == HttpStatus.partialContent
          ? _ContentRange.parse(response.headers.value(HttpHeaders.contentRangeHeader))
          : null;
      if (status == HttpStatus.partialContent &&
          (range == null || range.start != offset || (length != null && length != range.length))) {
        throw const UpdateDownloadVerificationException('Invalid Content-Range');
      }
      final total = range?.total ?? length ?? expectedSize;
      if (expectedSize != null && total != null && total != expectedSize) {
        throw const UpdateDownloadVerificationException('Update length does not match the release');
      }
      if (status == HttpStatus.ok) {
        await _safeDelete(_partial);
        _received = 0;
        _metadata = _ResumeMetadata(url: uri.toString(), sha256: expectedSha256.toLowerCase(), size: expectedSize);
      }
      if (body == null) {
        throw const UpdateDownloadVerificationException('The update response has no body');
      }
      final segmentLength = range?.length ?? length;
      final startedAt = _received;
      await _partial.parent.create(recursive: true);
      final file = await _partial.open(mode: _received > 0 ? FileMode.append : FileMode.write);
      try {
        onProgress(_received, total ?? -1);
        consumed = true;
        await for (final chunk in body.stream) {
          _ensureActive();
          final next = _received + chunk.length;
          if ((total != null && next > total) ||
              (segmentLength != null && next - startedAt > segmentLength)) {
            throw const UpdateDownloadVerificationException('The update body exceeds its declared length');
          }
          await file.writeFrom(chunk);
          _received = next;
          _armIdleTimer();
          onProgress(_received, total ?? -1);
        }
      } finally {
        try {
          await file.flush();
        } finally {
          await file.close();
        }
      }
      _ensureActive();
      if (segmentLength != null && _received - startedAt != segmentLength) {
        throw const HttpException('The update download ended before its declared length');
      }
      if (total != null && _received < total) {
        if (range != null && _received > startedAt) return false;
        throw const HttpException('The update download is incomplete');
      }
      return true;
    } finally {
      if (body != null && !consumed) {
        await body.stream.listen(null, onError: (Object error) {}).cancel();
      }
      networkToken.cancel();
      if (identical(_networkToken, networkToken)) _networkToken = null;
    }
  }

  Future<void> _publish() async {
    if (!await _partial.exists() || await _partial.length() != _received || _received == 0) {
      throw const UpdateDownloadVerificationException('The update download produced an invalid file');
    }
    if (expectedSize != null && _received != expectedSize) {
      throw const UpdateDownloadVerificationException('The update file length is invalid');
    }
    if (await _fileSha256(_partial) != expectedSha256.toLowerCase()) {
      throw const UpdateDownloadVerificationException('The update SHA-256 does not match the release');
    }
    _ensureActive();
    await _safeDelete(target);
    await _partial.rename(target.path);
    await _safeDelete(_metadataFile);
    onProgress(_received, _received);
  }

  Future<void> _discardPartial() async {
    await _safeDelete(_partial);
    await _safeDelete(_metadataFile);
    _received = 0;
  }

  void _ensureActive() {
    if (_timedOut) throw TimeoutException('Update download timed out', _timeout);
    if (cancelToken.cancelError case final error?) throw error;
  }
}

Future<void> _safeDelete(File file) async {
  if (await file.exists()) {
    await file.delete();
  }
}

Future<String> _fileSha256(File file) async {
  // A digest over the whole file. The native verifier re-checks it anyway,
  // so a one-shot read is acceptable here and keeps the API simple.
  return sha256.convert(await file.readAsBytes()).toString();
}
