import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// The three stages of a run, in the order they happen.
enum SpeedPhase { download, upload, latency }

/// One finished measurement. Speeds are in megabits per second, delay in
/// milliseconds. A stage the chosen provider does not offer reads as null.
class SpeedResult {
  const SpeedResult({
    required this.service,
    this.downloadMbps,
    this.uploadMbps,
    this.latencyMs,
    this.jitterMs,
    this.downloadBytes = 0,
    this.uploadBytes = 0,
  });

  final String service;
  final double? downloadMbps;
  final double? uploadMbps;
  final int? latencyMs;

  /// Variation between ping samples, in milliseconds. Lower is steadier.
  final int? jitterMs;
  final int downloadBytes;
  final int uploadBytes;
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
    this.downloadBytes = 20 * 1024 * 1024,
    this.uploadBytes = 8 * 1024 * 1024,
  });

  final String name;
  final Uri Function(int bytes) download;
  final Uri? upload;
  final Uri? ping;
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
  downloadBytes: 10 * 1024 * 1024,
);

/// The providers offered in the page picker, in display order.
final speedTestEndpoints = <SpeedTestEndpoint>[
  speedTestCloudflare,
  speedTestOvh,
];

/// Downloads and uploads measured byte streams through the app's proxy and
/// reports the throughput. The proxy finder is injected so this stays pure
/// Dart and can be exercised without a Flutter binding.
class SpeedTestService {
  SpeedTestService({
    required String Function(Uri url) findProxy,
    HttpClient Function()? clientFactory,
    SpeedTestEndpoint? endpoint,
  }) : _findProxy = findProxy,
       _clientFactory = clientFactory ?? HttpClient.new,
       endpoint = endpoint ?? speedTestCloudflare;

  final String Function(Uri url) _findProxy;
  final HttpClient Function() _clientFactory;
  final SpeedTestEndpoint endpoint;

  HttpClient _client() {
    final client = _clientFactory();
    client.findProxy = _findProxy;
    return client;
  }

  /// Runs all three stages. [onProgress] receives the live throughput of the
  /// stage in progress (megabits per second); the stage's final number is the
  /// average across its whole transfer.
  Future<SpeedResult> run({
    void Function(SpeedPhase phase, double mbps)? onProgress,
  }) async {
    try {
      final downloadMbps = await _download(onProgress);
      final uploadMbps = endpoint.upload != null
          ? await _upload(onProgress)
          : null;
      final latency = endpoint.ping != null ? await _latency() : null;
      return SpeedResult(
        service: endpoint.name,
        downloadMbps: downloadMbps,
        uploadMbps: uploadMbps,
        latencyMs: latency?.$1,
        jitterMs: latency?.$2,
        downloadBytes: endpoint.downloadBytes,
        uploadBytes: endpoint.upload != null ? endpoint.uploadBytes : 0,
      );
    } finally {
      clientClose();
    }
  }

  /// Aborts any in-flight transfer without waiting for it to finish.
  void clientClose() {
    for (final client in _clients) {
      client.close(force: true);
    }
    _clients.clear();
  }

  final _clients = <HttpClient>[];

  HttpClient _trackedClient() {
    final client = _client();
    _clients.add(client);
    return client;
  }

  /// Keeps a short rolling window so the live figure tracks the current
  /// bandwidth instead of a lifetime average that hides speed changes.
  /// Final score is the mean of the steady samples, skipping ramp-up.
  static const _reportEveryMs = 200;
  static const _windowMs = 1000;
  static const _settleMs = 500;

  double _mbps(int bytes, int microseconds) =>
      bytes * 8 / microseconds; // bits/µs == Mbit/s

  /// Parallel connections, like a real speed test. A single TCP stream is
  /// capped by its congestion window on high-latency proxy paths; several at
  /// once fill the pipe and give a number comparable to other speed tests.
  static const _downloadConnections = 4;

  Future<double> _download(
    void Function(SpeedPhase, double)? onProgress,
  ) async {
    final perConnection = endpoint.downloadBytes ~/ _downloadConnections;
    final sw = Stopwatch();
    var received = 0;
    var lastReportMs = 0;
    var lastWindowBytes = 0;
    var lastWindowMs = 0;
    final steady = <double>[];

    Future<void> pull() async {
      final client = _trackedClient();
      final request = await client.getUrl(endpoint.download(perConnection));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain();
        throw SpeedTestException(
          'download failed with status ${response.statusCode}',
        );
      }
      await for (final chunk in response) {
        received += chunk.length;
        final ms = sw.elapsedMilliseconds;
        final us = sw.elapsedMicroseconds;
        if (us <= 0) continue;
        if (ms - lastWindowMs >= _windowMs) {
          final windowBytes = received - lastWindowBytes;
          final windowUs = (ms - lastWindowMs) * 1000;
          if (windowUs > 0 && ms >= _settleMs) {
            steady.add(_mbps(windowBytes, windowUs));
          }
          lastWindowBytes = received;
          lastWindowMs = ms;
        }
        if (onProgress != null && ms - lastReportMs >= _reportEveryMs && ms > 0) {
          final windowBytes = received - lastWindowBytes;
          final windowUs = ms - lastWindowMs;
          final live = windowUs > 0
              ? _mbps(windowBytes, windowUs * 1000)
              : _mbps(received, us);
          onProgress(SpeedPhase.download, live);
          lastReportMs = ms;
        }
      }
    }

    sw.start();
    await Future.wait(List.generate(_downloadConnections, (_) => pull()));
    sw.stop();
    if (received == 0 || sw.elapsedMicroseconds == 0) {
      throw const SpeedTestException('download produced no data');
    }
    if (steady.isNotEmpty) {
      steady.sort();
      return steady[steady.length ~/ 2];
    }
    return _mbps(received, sw.elapsedMicroseconds);
  }

  Future<double> _upload(void Function(SpeedPhase, double)? onProgress) async {
    final client = _trackedClient();
    final request = await client.postUrl(endpoint.upload!);
    request.contentLength = endpoint.uploadBytes;
    // 256 KB chunks, flushed to the socket one at a time. request.add alone
    // only fills Dart's buffer, so its timing said nothing about the network;
    // flush pushes each chunk out and makes the progress real and visible.
    const chunkSize = 256 * 1024;
    final chunk = Uint8List(chunkSize);
    final sw = Stopwatch()..start();
    var sent = 0;
    var lastReportMs = 0;
    var lastWindowBytes = 0;
    var lastWindowMs = 0;
    final steady = <double>[];
    while (sent < endpoint.uploadBytes) {
      final size = math.min(chunkSize, endpoint.uploadBytes - sent);
      request.add(Uint8List.sublistView(chunk, 0, size));
      await request.flush();
      sent += size;
      final ms = sw.elapsedMilliseconds;
      final us = sw.elapsedMicroseconds;
      if (us <= 0) continue;
      if (ms - lastWindowMs >= _windowMs) {
        final windowBytes = sent - lastWindowBytes;
        final windowUs = (ms - lastWindowMs) * 1000;
        if (windowUs > 0 && ms >= _settleMs) {
          steady.add(_mbps(windowBytes, windowUs));
        }
        lastWindowBytes = sent;
        lastWindowMs = ms;
      }
      if (onProgress != null && ms - lastReportMs >= _reportEveryMs && ms > 0) {
        final windowBytes = sent - lastWindowBytes;
        final windowUs = ms - lastWindowMs;
        final live = windowUs > 0
            ? _mbps(windowBytes, windowUs * 1000)
            : _mbps(sent, us);
        onProgress(SpeedPhase.upload, live);
        lastReportMs = ms;
      }
    }
    final response = await request.close();
    await response.drain();
    sw.stop();
    if (sent == 0 || sw.elapsedMicroseconds == 0) {
      throw const SpeedTestException('upload produced no data');
    }
    if (steady.isNotEmpty) {
      steady.sort();
      return steady[steady.length ~/ 2];
    }
    return _mbps(sent, sw.elapsedMicroseconds);
  }

  /// Returns (average ping, jitter) in milliseconds. Jitter is the mean
  /// absolute difference between consecutive samples, the usual network
  /// measure of latency variation.
  Future<(int, int)> _latency() async {
    const samples = 8;
    final times = <int>[];
    for (var i = 0; i < samples; i++) {
      final client = _trackedClient();
      final sw = Stopwatch()..start();
      final request = await client.getUrl(endpoint.ping!);
      final response = await request.close();
      await response.drain();
      sw.stop();
      times.add(sw.elapsedMilliseconds);
    }
    if (times.isEmpty) return (0, 0);
    final average = times.reduce((a, b) => a + b) / times.length;
    var variation = 0;
    for (var i = 1; i < times.length; i++) {
      variation += (times[i] - times[i - 1]).abs();
    }
    final jitter = variation / (times.length - 1);
    return (average.round(), jitter.round());
  }
}

class SpeedTestException implements Exception {
  const SpeedTestException(this.message);

  final String message;

  @override
  String toString() => 'SpeedTestException: $message';
}
