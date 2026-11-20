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

@Riverpod(keepAlive: true)
class TrafficSampler extends _$TrafficSampler {
  Timer? _timer;
  final _pending = <String, TrackerInfo>{};
  Future<void>? _sampling;

  @override
  void build() {
    ref.listen(coreStatusProvider, (_, _) => _sync());
    ref.listen(appVisibleProvider, (_, _) => unawaited(sample()));
    ref.onDispose(_stop);
    _sync();
  }

  void _sync() {
    final active = ref.read(coreStatusProvider) == CoreStatus.connected;
    if (active) {
      _start();
    } else {
      _stop();
      if (_pending.isNotEmpty) unawaited(sample());
    }
  }

  void _start() {
    if (_timer != null) return;
    _timer = Timer.periodic(
      ref.read(trafficSampleIntervalProvider),
      (_) => unawaited(sample()),
    );
    unawaited(sample());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void capture(Iterable<TrackerInfo> requests) {
    for (final request in requests) {
      final previous = _pending[request.id];
      _pending[request.id] = previous == null
          ? request
          : request.copyWith(
              upload: request.upload > previous.upload
                  ? request.upload
                  : previous.upload,
              download: request.download > previous.download
                  ? request.download
                  : previous.download,
            );
    }
  }

  Future<void> sample() {
    if (_sampling != null) return _sampling!;
    final retention = ref.read(trafficHistoryRetentionProvider);
    capture(ref.read(requestsProvider).list);
    final requests = _pending.values.toList();
    _pending.clear();
    return _sampling = _persist(requests, retention).whenComplete(() {
      _sampling = null;
    });
  }

  Future<void> _persist(List<TrackerInfo> requests, Duration retention) async {
    final now = DateTime.now();
    final hour = DateTime(now.year, now.month, now.day, now.hour);
    var changed = false;
    for (final r in requests) {
      try {
        changed =
            await database.trafficRecordsDao.recordSample(
              record: TrafficRecord(
                connectionId: r.id,
                startedAt: r.start,
                endedAt: now,
                host: r.metadata.host,
                rule: r.rule,
                rulePayload: r.rulePayload,
                node: r.chains.isEmpty ? '' : r.chains.last,
                network: r.metadata.network,
                upload: r.upload,
                download: r.download,
              ),
              process: r.metadata.process,
              hour: hour,
            ) ||
            changed;
      } catch (error) {
        capture([r]);
        commonPrint.log(
          'Traffic history write failed: $error',
          logLevel: LogLevel.error,
        );
      }
    }
    final cutoff = now.subtract(retention);
    try {
      await database.trafficRecordsDao.pruneBefore(cutoff);
      await database.trafficHourlyDao.pruneBefore(cutoff);
      await database.appTrafficHourlyDao.pruneBefore(cutoff);
    } catch (error) {
      commonPrint.log(
        'Traffic history pruning failed: $error',
        logLevel: LogLevel.error,
      );
    }
    if (changed && ref.mounted) {
      ref.invalidate(trafficStatisticsProvider);
      ref.invalidate(appUsageProvider);
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
  final hours = await database.trafficHourlyDao.between(start, end);
  return aggregateTrafficTask(
    [
      for (final r in records)
        (
          host: r.host,
          rule: r.rule,
          rulePayload: r.rulePayload,
          node: r.node,
          upload: r.upload,
          download: r.download,
        ),
    ],
    [
      for (final h in hours)
        (
          hour: DateTime.fromMillisecondsSinceEpoch(h.hour),
          direction: h.direction,
          proxied: h.proxied,
          bytes: h.bytes,
        ),
    ],
    kind.index,
  );
}

/// The inclusive range an app-usage period covers. "近7天" is a rolling window
/// (unlike TrafficPeriod.week which is anchored to the selected date).
({DateTime start, DateTime end}) appUsageRange(AppUsagePeriod period) {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  return switch (period) {
    AppUsagePeriod.today => (
      start: DateTime(now.year, now.month, now.day),
      end: tomorrow,
    ),
    AppUsagePeriod.last7Days => (
      start: DateTime(now.year, now.month, now.day - 6),
      end: tomorrow,
    ),
    AppUsagePeriod.thisMonth => (
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 1),
    ),
    // History is retained for a bounded window; this covers all of it.
    AppUsagePeriod.total => (start: DateTime(2000), end: tomorrow),
  };
}

/// Per-app traffic for one usage period, with installed-app labels resolved.
@Riverpod(keepAlive: true)
Future<AppUsage> appUsage(Ref ref, AppUsagePeriod period) async {
  ref.watch(trafficSamplerProvider);
  final packages = ref.watch(packagesProvider);
  final range = appUsageRange(period);
  final buckets = await database.appTrafficHourlyDao.between(
    range.start,
    range.end,
  );
  final labels = {for (final p in packages) p.packageName: p.label};
  return aggregateAppUsageTask(
    [
      for (final b in buckets)
        (process: b.process, direction: b.direction, bytes: b.bytes),
    ],
    labels,
    currentAppLocalizations.unknown,
  );
}
