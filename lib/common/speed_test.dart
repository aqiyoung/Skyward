import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// The three stages of a run. They execute latency first, then download,
/// then upload, whatever order a caller's set lists them in.
enum SpeedPhase { latency, download, upload }

/// One finished measurement. Speeds are in megabits per second, delay in
/// milliseconds. A stage the chosen provider does not offer reads as null,
/// and the byte counts are what actually crossed the wire.
class SpeedResult {
  const SpeedResult({
    required this.service,
    this.downloadMbps,
    this.uploadMbps,
    this.latencyMs,
    this.jitterMs,
    this.downloadBytes = 0,
    this.uploadBytes = 0,
    this.elapsedMs = 0,
  });

  final String service;
  final double? downloadMbps;
  final double? uploadMbps;
  final int? latencyMs;

  /// Variation between ping samples, in milliseconds. Lower is steadier.
  final int? jitterMs;
  final int downloadBytes;
  final int uploadBytes;
  final int elapsedMs;
}

/// A set of endpoints from one provider. Only [download] is required; a
/// provider that cannot measure upload or latency simply leaves those null,
/// and the page shows a dash there. New providers are added to
/// [speedTestEndpoints] and need no other change.
class SpeedTestEndpoint {
  const SpeedTestEndpoint({
    required this.name,
    required this.download,
    this.upload,
    this.ping,
    this.downloadBytes = 25 * 1024 * 1024,
    this.uploadBytes = 8 * 1024 * 1024,
  });

  final String name;
  final Uri Function(int bytes) download;
  final Uri? upload;
  final Uri? ping;

  /// Size of one download request. A stage re-requests until its time or
  /// byte budget runs out, so this is a chunk size, not the test size.
  final int downloadBytes;
  final int uploadBytes;
}

final speedTestCloudflare = SpeedTestEndpoint(
  name: 'Cloudflare',
  download: (bytes) =>
      Uri.https('speed.cloudflare.com', '/__down', {'bytes': '$bytes'}),
  upload: Uri.https('speed.cloudflare.com', '/__up'),
  ping: Uri.https('speed.cloudflare.com', '/__down', {'bytes': '0'}),
);

final speedTestOvh = SpeedTestEndpoint(
  name: 'OVH',
  download: (bytes) =>
      Uri.https('proof.ovh.net', '/files/${bytes ~/ (1024 * 1024)}Mb.dat'),
  // proof.ovh.net only publishes whole-megabyte files (1, 10, 100, ...);
  // asking it for a split size such as 2Mb.dat answers 404.
  downloadBytes: 10 * 1024 * 1024,
);

final speedTestHetzner = SpeedTestEndpoint(
  name: 'Hetzner',
  download: (bytes) =>
      Uri.https('speed.hetzner.de', '/${bytes ~/ (1024 * 1024)}MB.bin'),
  // The smallest file speed.hetzner.de publishes is 100MB.bin; a stage
  // streams it and stops at its deadline rather than finishing it.
  downloadBytes: 100 * 1024 * 1024,
);

/// A user-supplied endpoint. The URL must accept a `bytes` query parameter
/// (Cloudflare-style) or a `{bytes}` placeholder in the path.
SpeedTestEndpoint customSpeedTestEndpoint(String url) {
  final trimmed = url.trim();
  final uri = Uri.parse(trimmed);
  final hasPlaceholder = trimmed.contains('{bytes}');
  Uri build(int bytes) {
    if (hasPlaceholder) {
      return Uri.parse(trimmed.replaceAll('{bytes}', '$bytes'));
    }
    final query = Map<String, String>.from(uri.queryParameters)
      ..['bytes'] = '$bytes';
    return uri.replace(queryParameters: query);
  }

  return SpeedTestEndpoint(name: 'Custom', download: build);
}

/// The providers the speed test can use; only Cloudflare offers the full
/// latency + download + upload set, so it is the only one offered.
final speedTestEndpoints = <SpeedTestEndpoint>[speedTestCloudflare];

/// Cumulative byte counter with timestamped samples, so a stage's score can
/// be taken over its steady stretch instead of a whole-run average that
/// mixes in connection setup and slow start.
class _Meter {
  final _samples = <(int, int)>[];
  int bytes = 0;

  void add(int count, int elapsedUs) {
    bytes += count;
    if (_samples.isEmpty || elapsedUs - _samples.last.$1 >= 50000) {
      _samples.add((elapsedUs, bytes));
    }
  }

  void finish(int elapsedUs) => _samples.add((elapsedUs, bytes));

  int _bytesAt(int elapsedUs) {
    if (_samples.isEmpty) return 0;
    if (elapsedUs <= _samples.first.$1) return _samples.first.$2;
    for (var i = 1; i < _samples.length; i++) {
      final (t1, b1) = _samples[i];
      if (t1 >= elapsedUs) {
        final (t0, b0) = _samples[i - 1];
        if (t1 == t0) return b1;
        return b0 + (b1 - b0) * (elapsedUs - t0) ~/ (t1 - t0);
      }
    }
    return _samples.last.$2;
  }

  /// Megabits per second between two points of the run. Bits per
  /// microsecond is numerically megabits per second.
  double rateMbps(int fromUs, int toUs) {
    if (toUs <= fromUs) return 0;
    return (_bytesAt(toUs) - _bytesAt(fromUs)) * 8 / (toUs - fromUs);
  }
}

/// Downloads and uploads measured byte streams through the app's proxy and
/// reports the throughput. The proxy finder is injected so this stays pure
/// Dart and can be exercised without a Flutter binding.
///
/// Each transfer stage is time-boxed rather than fixed-size: connections
/// re-request chunks until the stage's deadline or byte cap, and the score
/// is the rate over the steady stretch after the first second, so a fast
/// link is not scored mostly on handshakes and a slow one does not run on
/// for half a minute.
class SpeedTestService {
  SpeedTestService({
    required String Function(Uri url) findProxy,
    HttpClient Function()? clientFactory,
    SpeedTestEndpoint? endpoint,
    Duration stageDuration = const Duration(seconds: 10),
  }) : _findProxy = findProxy,
       _clientFactory = clientFactory ?? HttpClient.new,
       endpoint = endpoint ?? speedTestCloudflare,
       _stageDuration = stageDuration;

  final String Function(Uri url) _findProxy;
  final HttpClient Function() _clientFactory;
  final SpeedTestEndpoint endpoint;
  final Duration _stageDuration;

  static const _downloadConnections = 4;
  static const _uploadConnections = 3;
  static const _downloadCap = 250 * 1024 * 1024;
  static const _uploadCap = 120 * 1024 * 1024;
  static const _capFloor = Duration(seconds: 3);
  static const _settleUs = 1000000;

  final _clients = <HttpClient>[];
  bool _stopped = false;

  HttpClient _client() {
    final client = _clientFactory();
    client.findProxy = _findProxy;
    _clients.add(client);
    return client;
  }

  /// Aborts any in-flight transfer without waiting for it to finish.
  void clientClose() {
    _stopped = true;
    for (final client in _clients) {
      client.close(force: true);
    }
    _clients.clear();
  }

  /// Runs the requested [phases] (all of them by default) in latency,
  /// download, upload order. [onProgress] receives the live throughput of
  /// the transfer stage in progress, in megabits per second.
  Future<SpeedResult> run({
    void Function(SpeedPhase phase, double mbps)? onProgress,
    Set<SpeedPhase>? phases,
  }) async {
    final wanted = phases ?? SpeedPhase.values.toSet();
    final sw = Stopwatch()..start();
    _stopped = false;
    try {
      (int, int)? latency;
      if (wanted.contains(SpeedPhase.latency) && endpoint.ping != null) {
        onProgress?.call(SpeedPhase.latency, 0);
        latency = await _latency();
      }
      double? downloadMbps;
      var downloadBytes = 0;
      if (wanted.contains(SpeedPhase.download)) {
        final stage = await _download(onProgress);
        downloadMbps = stage.$1;
        downloadBytes = stage.$2;
      }
      double? uploadMbps;
      var uploadBytes = 0;
      if (wanted.contains(SpeedPhase.upload) && endpoint.upload != null) {
        final stage = await _upload(onProgress);
        uploadMbps = stage.$1;
        uploadBytes = stage.$2;
      }
      return SpeedResult(
        service: endpoint.name,
        downloadMbps: downloadMbps,
        uploadMbps: uploadMbps,
        latencyMs: latency?.$1,
        jitterMs: latency?.$2,
        downloadBytes: downloadBytes,
        uploadBytes: uploadBytes,
        elapsedMs: sw.elapsedMilliseconds,
      );
    } finally {
      clientClose();
    }
  }

  /// Median round trip on one warm connection, plus jitter as the mean
  /// absolute difference between consecutive samples. The first sample pays
  /// for DNS, TCP, TLS and the proxy handshake and is discarded; measuring
  /// on fresh connections would score the handshake, not the latency.
  Future<(int, int)> _latency() async {
    const samples = 10;
    final client = _client();
    final times = <int>[];
    for (var i = 0; i < samples; i++) {
      final sw = Stopwatch()..start();
      final request = await client.getUrl(endpoint.ping!);
      final response = await request.close();
      await response.drain();
      sw.stop();
      times.add(sw.elapsedMicroseconds ~/ 1000);
    }
    final warm = times.skip(1).toList();
    if (warm.isEmpty) return (0, 0);
    final sorted = [...warm]..sort();
    final median = sorted[sorted.length ~/ 2];
    var variation = 0;
    for (var i = 1; i < warm.length; i++) {
      variation += (warm[i] - warm[i - 1]).abs();
    }
    final jitter = warm.length > 1 ? variation / (warm.length - 1) : 0.0;
    return (median, jitter.round());
  }

  Future<(double, int)> _download(
    void Function(SpeedPhase, double)? onProgress,
  ) async {
    final meter = _Meter();
    final sw = Stopwatch()..start();
    final stageClients = <HttpClient>[];
    var aborted = false;
    Object? firstError;
    var lastReportUs = 0;

    void report() {
      if (onProgress == null) return;
      final now = sw.elapsedMicroseconds;
      if (now - lastReportUs < 200000) return;
      lastReportUs = now;
      final from = math.max(0, now - 1000000);
      onProgress(SpeedPhase.download, meter.rateMbps(from, now));
    }

    Future<void> pull() async {
      final client = _client();
      stageClients.add(client);
      try {
        while (!aborted &&
            !_stopped &&
            sw.elapsed < _stageDuration &&
            (meter.bytes < _downloadCap || sw.elapsed < _capFloor)) {
          final request = await client.getUrl(
            endpoint.download(endpoint.downloadBytes),
          );
          final response = await request.close();
          if (response.statusCode != HttpStatus.ok) {
            await response.drain();
            throw SpeedTestException(
              'download failed with status ${response.statusCode}',
            );
          }
          await for (final chunk in response) {
            meter.add(chunk.length, sw.elapsedMicroseconds);
            report();
          }
        }
      } catch (e) {
        // The deadline abort closes the stage's clients mid-stream; that
        // error is the expected end of the stage, not a failure.
        if (!aborted && !_stopped) firstError ??= e;
      }
    }

    final abort = Timer(_stageDuration, () {
      aborted = true;
      for (final client in stageClients) {
        client.close(force: true);
      }
    });
    await Future.wait(List.generate(_downloadConnections, (_) => pull()));
    abort.cancel();
    sw.stop();
    meter.finish(sw.elapsedMicroseconds);
    if (_stopped) throw const SpeedTestException('test stopped');
    if (meter.bytes == 0) {
      throw firstError is SpeedTestException
          ? firstError as SpeedTestException
          : const SpeedTestException('download produced no data');
    }
    final elapsedUs = sw.elapsedMicroseconds;
    final settleUs = math.min(_settleUs, elapsedUs ~/ 4);
    return (meter.rateMbps(settleUs, elapsedUs), meter.bytes);
  }

  Future<(double, int)> _upload(
    void Function(SpeedPhase, double)? onProgress,
  ) async {
    final meter = _Meter();
    final sw = Stopwatch()..start();
    final stageClients = <HttpClient>[];
    var aborted = false;
    Object? firstError;
    var lastReportUs = 0;
    const chunkSize = 64 * 1024;
    final chunk = Uint8List(chunkSize);

    void report() {
      if (onProgress == null) return;
      final now = sw.elapsedMicroseconds;
      if (now - lastReportUs < 200000) return;
      lastReportUs = now;
      final from = math.max(0, now - 1000000);
      onProgress(SpeedPhase.upload, meter.rateMbps(from, now));
    }

    // flush() completes rarely under backpressure, so a timer reports the
    // rate on a wider window between flushes.
    final progressTimer = Timer.periodic(const Duration(milliseconds: 200), (
      _,
    ) {
      if (onProgress == null) return;
      final now = sw.elapsedMicroseconds;
      final from = math.max(0, now - 2000000);
      onProgress(SpeedPhase.upload, meter.rateMbps(from, now));
    });

    Future<void> push() async {
      final client = _client();
      stageClients.add(client);
      try {
        while (!aborted &&
            !_stopped &&
            sw.elapsed < _stageDuration &&
            (meter.bytes < _uploadCap || sw.elapsed < _capFloor)) {
          final request = await client.postUrl(endpoint.upload!);
          request.contentLength = endpoint.uploadBytes;
          var sent = 0;
          // flush pushes each chunk onto the socket instead of letting it
          // sit in Dart's buffer; over the stage's steady stretch the score
          // is the wire rate, not the buffer's acceptance rate.
          while (sent < endpoint.uploadBytes && !aborted) {
            final size = math.min(chunkSize, endpoint.uploadBytes - sent);
            request.add(Uint8List.sublistView(chunk, 0, size));
            await request.flush();
            sent += size;
            meter.add(size, sw.elapsedMicroseconds);
            report();
          }
          final response = await request.close();
          await response.drain();
        }
      } catch (e) {
        if (!aborted && !_stopped) firstError ??= e;
      }
    }

    final abort = Timer(_stageDuration, () {
      aborted = true;
      for (final client in stageClients) {
        client.close(force: true);
      }
    });
    await Future.wait(List.generate(_uploadConnections, (_) => push()));
    progressTimer.cancel();
    abort.cancel();
    sw.stop();
    meter.finish(sw.elapsedMicroseconds);
    if (_stopped) throw const SpeedTestException('test stopped');
    if (meter.bytes == 0) {
      throw firstError is SpeedTestException
          ? firstError as SpeedTestException
          : const SpeedTestException('upload produced no data');
    }
    final elapsedUs = sw.elapsedMicroseconds;
    final settleUs = math.min(_settleUs, elapsedUs ~/ 4);
    return (meter.rateMbps(settleUs, elapsedUs), meter.bytes);
  }
}

class SpeedTestException implements Exception {
  const SpeedTestException(this.message);

  final String message;

  @override
  String toString() => 'SpeedTestException: $message';
}
