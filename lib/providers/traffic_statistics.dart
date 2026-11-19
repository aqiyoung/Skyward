import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/database/database.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/app.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/traffic_statistics.g.dart';

/// How often live connections are snapshotted into the history table.
@Riverpod(keepAlive: true)
Duration trafficSampleInterval(Ref ref) => const Duration(seconds: 5);

/// How long history rows are kept before being pruned.
@Riverpod(keepAlive: true)
Duration trafficHistoryRetention(Ref ref) => const Duration(days: 90);

/// Keeps the first-seen time of every connection we have persisted so an
/// upsert never moves a connection's start.
final trafficFirstSeen = <String, DateTime>{};

/// Periodically persists the live connection list so the statistics page has
/// history. Runs only while the core is connected and the app is visible.
@Riverpod(keepAlive: true)
class TrafficSampler extends _$TrafficSampler {
  Timer? _timer;

  @override
  void build() {
    ref.listen(coreStatusProvider, (_, _) => _sync());
    ref.listen(appVisibleProvider, (_, _) => _sync());
    ref.onDispose(_stop);
    _sync();
  }

  void _sync() {
    final active =
        ref.read(coreStatusProvider) == CoreStatus.connected &&
        ref.read(appVisibleProvider);
    if (active) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    if (_timer != null) return;
    _timer = Timer.periodic(
      ref.read(trafficSampleIntervalProvider),
      (_) => _sample(),
    );
    _sample();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _sample() async {
    final now = DateTime.now();
    final requests = ref.read(requestsProvider);
    for (final r in requests.list) {
      final started = trafficFirstSeen.putIfAbsent(r.id, () => now);
      await _safeWrite(
        database.trafficRecordsDao.upsert(
          TrafficRecord(
            connectionId: r.id,
            startedAt: started,
            endedAt: now,
            host: r.metadata.host,
            rule: r.rule,
            rulePayload: r.rulePayload,
            node: r.chains.isEmpty ? '' : r.chains.last,
            network: r.metadata.network,
            upload: r.upload,
            download: r.download,
          ),
        ),
      );
    }
    final cutoff = now.subtract(ref.read(trafficHistoryRetentionProvider));
    await _safeWrite(() async {
      await database.trafficRecordsDao.pruneBefore(cutoff);
    }());
  }

  Future<void> _safeWrite(Future<void> write) async {
    try {
      await write;
    } catch (_) {
      // History is best-effort; a failed sample must never break the UI.
    }
  }
}

/// The range a statistics view currently shows: the start of the period.
@Riverpod(keepAlive: true)
class TrafficRange extends _$TrafficRange {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void set(DateTime value) => state = value;

  void shift(TrafficPeriod period, int amount) {
    state = switch (period) {
      TrafficPeriod.day => state.add(Duration(days: amount)),
      TrafficPeriod.week => state.add(Duration(days: 7 * amount)),
      TrafficPeriod.month => DateTime(state.year, state.month + amount, 1),
    };
  }
}

/// Loads history for the selected period and aggregates it off-isolate.
@Riverpod(keepAlive: true)
Future<TrafficStatistics> trafficStatistics(
  Ref ref,
  TrafficPeriod period,
  TrafficRankKind kind,
) async {
  // Keep the sampler alive for as long as statistics are being read.
  ref.watch(trafficSamplerProvider);
  final start0 = ref.watch(trafficRangeProvider);
  final (start, end) = switch (period) {
    TrafficPeriod.day => (start0, start0.add(const Duration(days: 1))),
    TrafficPeriod.week => (start0, start0.add(const Duration(days: 7))),
    TrafficPeriod.month => (
      DateTime(start0.year, start0.month, 1),
      DateTime(start0.year, start0.month + 1, 1),
    ),
  };
  final records = await database.trafficRecordsDao.between(start, end);
  return aggregateTrafficTask([
    for (final r in records)
      (
        host: r.host,
        rule: r.rule,
        rulePayload: r.rulePayload,
        node: r.node,
        upload: r.upload,
        download: r.download,
      ),
  ], kind.index);
}
