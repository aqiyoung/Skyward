import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/database/database.dart';
import 'package:skyward/enum/enum.dart';
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

/// Keeps the first-seen time of every connection we have persisted so an
/// upsert never moves a connection's start.
final trafficFirstSeen = <String, DateTime>{};

/// The last cumulative byte totals we sampled per connection, used to derive
/// the per-hour deltas the trend chart is built from.
final trafficLastBytes = <String, ({int up, int down})>{};

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
    final hour = DateTime(now.year, now.month, now.day, now.hour);
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

      // Derive the delta since the previous sample and add it to this hour.
      final last = trafficLastBytes[r.id];
      if (last != null) {
        final upDelta = r.upload - last.up;
        final downDelta = r.download - last.down;
        final node = r.chains.isEmpty ? '' : r.chains.last;
        final proxied = node.isNotEmpty && node.toUpperCase() != 'DIRECT';
        if (upDelta > 0 || downDelta > 0) {
          await _safeWrite(
            database.trafficHourlyDao.add(
              hour: hour,
              download: downDelta,
              upload: upDelta,
              proxied: proxied,
            ),
          );
          await _safeWrite(
            database.appTrafficHourlyDao.add(
              hour: hour,
              process: r.metadata.process,
              download: downDelta,
              upload: upDelta,
            ),
          );
        }
      }
      trafficLastBytes[r.id] = (up: r.upload, down: r.download);
    }
    await _recordClosed();
    final cutoff = now.subtract(ref.read(trafficHistoryRetentionProvider));
    await _safeWrite(() async {
      await database.trafficRecordsDao.pruneBefore(cutoff);
      await database.trafficHourlyDao.pruneBefore(cutoff);
      await database.appTrafficHourlyDao.pruneBefore(cutoff);
    }());
  }

  /// Persist connections that finished since the last sample. The core keeps
  /// their final accounting, so traffic from backgrounded or missed sampling
  /// still lands in history (and in the hourly buckets) instead of vanishing.
  Future<void> _recordClosed() async {
    final List<Map<String, Object?>> items;
    try {
      items = await ref.read(coreHandlerProvider).takeClosedConnections();
    } catch (_) {
      return; // best-effort, like the rest of history
    }
    for (final item in items) {
      final id = item['id'] as String?;
      if (id == null) continue;
      final endedMs =
          (item['endedAt'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch;
      final ended = DateTime.fromMillisecondsSinceEpoch(endedMs);
      final hour = DateTime(ended.year, ended.month, ended.day, ended.hour);
      final upload = (item['upload'] as num?)?.toInt() ?? 0;
      final download = (item['download'] as num?)?.toInt() ?? 0;
      final rawChains = item['chains'];
      final chains = [
        for (final c in rawChains is List ? rawChains : const <Object?>[])
          c.toString(),
      ];
      final node = chains.isEmpty ? '' : chains.last;
      final started = DateTime.fromMillisecondsSinceEpoch(
        (item['startedAt'] as num?)?.toInt() ?? endedMs,
      );
      await _safeWrite(
        database.trafficRecordsDao.upsert(
          TrafficRecord(
            connectionId: id,
            startedAt: started,
            endedAt: ended,
            host: (item['host'] as String?) ?? '',
            rule: (item['rule'] as String?) ?? '',
            rulePayload: (item['rulePayload'] as String?) ?? '',
            node: node,
            network: (item['network'] as String?) ?? '',
            upload: upload,
            download: download,
          ),
        ),
      );
      final last = trafficLastBytes[id];
      final upDelta = upload - (last?.up ?? 0);
      final downDelta = download - (last?.down ?? 0);
      if (upDelta > 0 || downDelta > 0) {
        final proxied = node.isNotEmpty && node.toUpperCase() != 'DIRECT';
        await _safeWrite(
          database.trafficHourlyDao.add(
            hour: hour,
            download: downDelta,
            upload: upDelta,
            proxied: proxied,
          ),
        );
        await _safeWrite(
          database.appTrafficHourlyDao.add(
            hour: hour,
            process: '',
            download: downDelta,
            upload: upDelta,
          ),
        );
      }
      trafficLastBytes[id] = (up: upload, down: download);
      trafficFirstSeen.putIfAbsent(id, () => started);
    }
  }

  Future<void> _safeWrite(Future<void> write) async {
    try {
      await write;
    } catch (_) {
      // History is best-effort; a failed sample must never break the UI.
    }
  }
}

/// Monday of the week containing [date]. Weeks run Monday-to-Sunday, so a
/// weekly view must snap the selected day back to the start of its week both
/// when querying history and when labelling the date strip.
DateTime weekStartOf(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
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
    TrafficPeriod.week => (
      weekStartOf(start0),
      weekStartOf(start0).add(const Duration(days: 7)),
    ),
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
  // Watch, not read: the installed-app list loads asynchronously and its
  // labels are what turn a package name into a readable app name.
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
