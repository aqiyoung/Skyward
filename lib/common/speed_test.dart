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
    this.downloadBytes = 0,
    this.uploadBytes = 0,
  });

  final String service;
  final double? downloadMbps;
  final double? uploadMbps;
  final int? latencyMs;
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
    this.downloadBytes = 10 * 1024 * 1024,
    this.uploadBytes = 2 * 1024 * 1024,
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
      final latencyMs = endpoint.ping != null ? await _latency() : null;
      return SpeedResult(
        service: endpoint.name,
        downloadMbps: downloadMbps,
        uploadMbps: uploadMbps,
        latencyMs: latencyMs,
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

  Future<double> _download(
    void Function(SpeedPhase, double)? onProgress,
  ) async {
    final client = _trackedClient();
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
    final sw = Stopwatch()..start();
    var received = 0;
    var lastReport = 0;
    await for (final chunk in response) {
      received += chunk.length;
      final ms = sw.elapsedMilliseconds;
      if (onProgress != null && ms - lastReport >= 200 && ms > 0) {
        onProgress(SpeedPhase.download, received * 8 / ms / 1000);
        lastReport = ms;
      }
    }
    sw.stop();
    if (received == 0 || sw.elapsedMicroseconds == 0) {
      throw const SpeedTestException('download produced no data');
    }
    // bits / microseconds is already megabits per second (1e6 bits per
    // megabit cancels 1e6 microseconds per second). Multiplying by 1e6
    // here would report a phone connection in terabits.
    return received * 8 / sw.elapsedMicroseconds;
  }

  Future<double> _upload(void Function(SpeedPhase, double)? onProgress) async {
    final client = _trackedClient();
    final request = await client.postUrl(endpoint.upload!);
    request.contentLength = endpoint.uploadBytes;
    const chunkSize = 64 * 1024;
    final chunk = Uint8List(chunkSize);
    final sw = Stopwatch()..start();
    var sent = 0;
    var lastReport = 0;
    while (sent < endpoint.uploadBytes) {
      final size = math.min(chunkSize, endpoint.uploadBytes - sent);
      request.add(Uint8List.sublistView(chunk, 0, size));
      sent += size;
      final ms = sw.elapsedMilliseconds;
      if (onProgress != null && ms - lastReport >= 200 && ms > 0) {
        onProgress(SpeedPhase.upload, sent * 8 / ms / 1000);
        lastReport = ms;
      }
    }
    final response = await request.close();
    await response.drain();
    sw.stop();
    if (sw.elapsedMicroseconds == 0) {
      throw const SpeedTestException('upload finished too fast to measure');
    }
    return sent * 8 / sw.elapsedMicroseconds;
  }

  Future<int> _latency() async {
    const samples = 3;
    var total = 0;
    for (var i = 0; i < samples; i++) {
      final client = _trackedClient();
      final sw = Stopwatch()..start();
      final request = await client.getUrl(endpoint.ping!);
      final response = await request.close();
      await response.drain();
      sw.stop();
      total += sw.elapsedMilliseconds;
    }
    return (total / samples).round();
  }
}

class SpeedTestException implements Exception {
  const SpeedTestException(this.message);

  final String message;

  @override
  String toString() => 'SpeedTestException: $message';
}
