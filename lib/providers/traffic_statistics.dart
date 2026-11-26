import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/database/database.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/features/features.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/providers/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/traffic_statistics.g.dart';

/// How often live connections are snapshotted into the history table.
@Riverpod(keepAlive: true)
Duration trafficSampleInterval(Ref ref) => const Duration(seconds: 5);

/// How long history rows are kept before being pruned.
@Riverpod(keepAlive: true)
Duration trafficHistoryRetention(Ref ref) => const Duration(days: 90);

/// Domains blocked by the ad-block module in the last seven days, read from
/// the same native history the traffic card uses. The sampler below keeps it
/// fresh, so the dashboard card never shows a stale count.
@Riverpod(keepAlive: true)
Future<List<AdBlockHit>> adBlockHitList(Ref ref) async {
  ref.watch(trafficSamplerProvider);
  final now = DateTime.now();
  final rows = await database.nativeTrafficDao.between(
    now.subtract(const Duration(days: 7)),
    now,
  );
  return adBlockHits(rows);
}

@Riverpod(keepAlive: true)
bool nativeTrafficHistoryEnabled(Ref ref) => system.isAndroid;

@Riverpod(keepAlive: true)
class TrafficSampler extends _$TrafficSampler {
  Timer? _timer;
  final _pending = <String, TrackerInfo>{};
  Future<void>? _sampling;
  int _nativeRevision = 0;

  @override
  void build() {
    ref.listen(coreStatusProvider, (_, next) {
      if (next != CoreStatus.connected) _nativeRevision = 0;
      _sync();
    });
    ref.listen(appVisibleProvider, (_, visible) {
      _sync();
      if (visible) unawaited(sample());
    });
    ref.onDispose(_stop);
    _sync();
  }

  void _sync() {
    final active =
        ref.read(coreStatusProvider) == CoreStatus.connected &&
        (!ref.read(nativeTrafficHistoryEnabledProvider) ||
            ref.read(appVisibleProvider));
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
    if (ref.read(nativeTrafficHistoryEnabledProvider)) return;
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
    if (ref.read(nativeTrafficHistoryEnabledProvider)) {
      await _importNative(retention);
      return;
    }
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
      // adBlockHitListProvider reads nativeTrafficDao, which only _importNative
      // writes. Invalidating it here re-queries seven days of history every
      // five seconds for no new data -- a visible stutter on the UI isolate.
    }
  }

  Future<void> _importNative(Duration retention) async {
    try {
      final answer = await ref
          .read(coreHandlerProvider)
          .getTrafficHistory(_nativeRevision);
      if (answer == null) return;
      final rows = (answer['rows'] as List)
          .map((row) => Map<String, Object?>.from(row as Map))
          .toList();
      await database.nativeTrafficDao.importRows(
        rows,
        DateTime.now().subtract(retention),
      );
      _nativeRevision = (answer['revision'] as num).toInt();
      if (rows.isNotEmpty && ref.mounted) {
        ref.invalidate(trafficStatisticsProvider);
        ref.invalidate(appUsageProvider);
        ref.invalidate(adBlockHitListProvider);
      }
    } catch (error) {
      commonPrint.log(
        'Native traffic history sync failed: $error',
        logLevel: LogLevel.error,
      );
    }
  }
}

/// The first instant of the period that contains [date]: the day itself, the
/// Monday of its calendar week, or the first of its month.
///
/// The week is a calendar week, not a rolling seven days from the selected
/// day — the two drift apart the moment the reader looks at any day but
/// Monday.
DateTime startOfTrafficPeriod(TrafficPeriod period, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return switch (period) {
    TrafficPeriod.day => day,
    TrafficPeriod.week => day.subtract(
      Duration(days: day.weekday - DateTime.monday),
    ),
    TrafficPeriod.month => DateTime(date.year, date.month, 1),
  };
}

/// The range a statistics view currently shows: the start of the period.
@Riverpod(keepAlive: true)
class TrafficRange extends _$TrafficRange {
  @override
  DateTime build() => startOfTrafficPeriod(TrafficPeriod.day, DateTime.now());

  void set(DateTime value) => state = value;

  /// Re-anchor on a period change to *today's* period, not to the previous
  /// period's boundary. The state holds a period start, so a month's state is
  /// its first day; anchoring a new period on that made a week count from the
  /// Monday of the month's first day instead of the Monday of today.
  void setPeriod(TrafficPeriod period) {
    state = startOfTrafficPeriod(period, DateTime.now());
  }

  void shift(TrafficPeriod period, int amount) {
    final next = switch (period) {
      TrafficPeriod.day => state.add(Duration(days: amount)),
      TrafficPeriod.week => state.add(Duration(days: 7 * amount)),
      TrafficPeriod.month => DateTime(state.year, state.month + amount, 1),
    };
    state = startOfTrafficPeriod(period, next);
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
  final start0 = startOfTrafficPeriod(period, ref.watch(trafficRangeProvider));
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
  final native = await database.nativeTrafficDao.between(start, end);
  final result = await aggregateTrafficTask(
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
      for (final r in native.where((r) => !r.bucketId.startsWith('runtime/')))
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
      for (final r in native)
        for (final direction in [0, 1])
          (
            hour: DateTime.fromMillisecondsSinceEpoch(r.hour),
            direction: direction,
            proxied: r.node.isNotEmpty && r.node.toUpperCase() != 'DIRECT'
                ? 0
                : 1,
            bytes: direction == 0 ? r.download : r.upload,
          ),
    ],
    kind.index,
    connectionCounts: [
      for (final _ in records) 1,
      for (final r in native.where((r) => !r.bucketId.startsWith('runtime/')))
        r.connections,
    ],
  );
  return result.copyWith(
    runtimeMs: native.fold(0, (sum, row) => sum + row.runtimeMs),
    connectionCount:
        records.length + native.fold(0, (sum, row) => sum + row.connections),
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
  final native = await database.nativeTrafficDao.between(
    range.start,
    range.end,
  );
  return aggregateAppUsageTask(
    [
      for (final b in buckets)
        (process: b.process, direction: b.direction, bytes: b.bytes),
      for (final row in native.where(
        (r) => r.upload > 0 || r.download > 0,
      )) ...[
        (process: row.process, direction: 0, bytes: row.download),
        (process: row.process, direction: 1, bytes: row.upload),
      ],
    ],
    labels,
    currentAppLocalizations.unknown,
  );
}
