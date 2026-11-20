import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:flutter/foundation.dart';

/// A connection reduced to the fields the aggregator needs. Plain types keep
/// it cheap to send to the isolate.
typedef TrafficSample = ({
  String host,
  String rule,
  String rulePayload,
  String node,
  int upload,
  int download,
});

/// One hourly bucket reduced to plain types for the isolate.
typedef TrafficHourSample = ({
  DateTime hour,
  int direction,
  int proxied,
  int bytes,
});

/// Aggregates connection samples and hourly deltas off the UI isolate.
/// [kind] is the TrafficRankKind index.
Future<TrafficStatistics> aggregateTrafficTask(
  List<TrafficSample> samples,
  List<TrafficHourSample> hours,
  int kind, {
  List<int>? connectionCounts,
}) => compute<_AggregateArgs, TrafficStatistics>(
  _aggregate,
  _AggregateArgs(samples, hours, kind, connectionCounts),
);

class _AggregateArgs {
  const _AggregateArgs(
    this.samples,
    this.hours,
    this.kind,
    this.connectionCounts,
  );

  final List<TrafficSample> samples;
  final List<TrafficHourSample> hours;
  final int kind;
  final List<int>? connectionCounts;
}

TrafficStatistics _aggregate(_AggregateArgs args) {
  var totalUp = 0;
  var totalDown = 0;
  var proxyBytes = 0;
  var directBytes = 0;
  final ranks = <String, ({int up, int down, int hits})>{};
  final ruleHits = <String, ({int up, int down, int hits})>{};
  final byHour = <int, ({int up, int down})>{};

  String keyOf(TrafficSample s) => switch (TrafficRankKind.values[args.kind]) {
    TrafficRankKind.domain => s.host.isNotEmpty ? s.host : s.rulePayload,
    TrafficRankKind.rule => s.rule.isNotEmpty ? s.rule : 'MATCH',
    TrafficRankKind.node => s.node.isNotEmpty ? s.node : 'DIRECT',
    TrafficRankKind.config => s.rule,
  };

  for (var index = 0; index < args.samples.length; index++) {
    final s = args.samples[index];
    final connections = args.connectionCounts?[index] ?? 1;
    final key = keyOf(s);
    ranks[key] = (
      up: (ranks[key]?.up ?? 0) + s.upload,
      down: (ranks[key]?.down ?? 0) + s.download,
      hits: (ranks[key]?.hits ?? 0) + connections,
    );
    final ruleKey = s.rule.isNotEmpty ? s.rule : 'MATCH';
    ruleHits[ruleKey] = (
      up: (ruleHits[ruleKey]?.up ?? 0) + s.upload,
      down: (ruleHits[ruleKey]?.down ?? 0) + s.download,
      hits: (ruleHits[ruleKey]?.hits ?? 0) + connections,
    );
  }

  for (final h in args.hours) {
    if (h.direction == 1) {
      totalUp += h.bytes;
    } else {
      totalDown += h.bytes;
    }
    if (h.proxied == 0) {
      proxyBytes += h.bytes;
    } else {
      directBytes += h.bytes;
    }
    final key = h.hour.millisecondsSinceEpoch;
    final bucket = byHour[key] ?? (up: 0, down: 0);
    byHour[key] = h.direction == 1
        ? (up: bucket.up + h.bytes, down: bucket.down)
        : (up: bucket.up, down: bucket.down + h.bytes);
  }

  // Each ranking is a share of its own sum, so the two sources (per-connection
  // records for ranks, hourly deltas for totals) never cross as numerator and
  // denominator -- mixing them made percentages exceed 100%.
  final rankTotal = ranks.values.fold<int>(0, (sum, v) => sum + v.up + v.down);
  final hitTotal = ruleHits.values.fold<int>(
    0,
    (sum, v) => sum + v.up + v.down,
  );

  double rankShare(int up, int down) =>
      rankTotal == 0 ? 0.0 : (up + down) / rankTotal;
  double hitShare(int up, int down) =>
      hitTotal == 0 ? 0.0 : (up + down) / hitTotal;

  final ranking =
      ranks.entries
          .map(
            (e) => TrafficRankItem(
              key: e.key,
              upload: e.value.up,
              download: e.value.down,
              percent: rankShare(e.value.up, e.value.down),
            ),
          )
          .toList()
        ..sort(
          (a, b) => (b.upload + b.download).compareTo(a.upload + a.download),
        );

  final hits =
      ruleHits.entries
          .map(
            (e) => RuleHit(
              key: e.key,
              hits: e.value.hits,
              upload: e.value.up,
              download: e.value.down,
              percent: hitShare(e.value.up, e.value.down),
            ),
          )
          .toList()
        ..sort(
          (a, b) => (b.upload + b.download).compareTo(a.upload + a.download),
        );

  final trend =
      byHour.entries
          .map(
            (e) => TrafficHourPoint(
              hour: DateTime.fromMillisecondsSinceEpoch(e.key),
              download: e.value.down,
              upload: e.value.up,
            ),
          )
          .toList()
        ..sort((a, b) => a.hour.compareTo(b.hour));

  return TrafficStatistics(
    totalUpload: totalUp,
    totalDownload: totalDown,
    connectionCount:
        args.connectionCounts?.fold<int>(0, (sum, count) => sum + count) ??
        args.samples.length,
    proxyBytes: proxyBytes,
    directBytes: directBytes,
    ruleHits: hits,
    ranking: ranking,
    trend: trend,
  );
}

/// One per-app hourly bucket, plain for the isolate.
typedef AppHourSample = ({String process, int direction, int bytes});

/// Aggregates per-app hourly deltas into sorted app traffic. [labels] maps a
/// package name to its installed-app label; unknown packages fall back to the
/// package name. Built off-isolate so the map stays plain and sendable.
Future<AppUsage> aggregateAppUsageTask(
  List<AppHourSample> buckets,
  Map<String, String> labels,
  String unknownLabel,
) => compute<_AppUsageArgs, AppUsage>(
  _aggregateAppUsage,
  _AppUsageArgs(buckets, labels, unknownLabel),
);

class _AppUsageArgs {
  const _AppUsageArgs(this.buckets, this.labels, this.unknownLabel);

  final List<AppHourSample> buckets;
  final Map<String, String> labels;
  final String unknownLabel;
}

AppUsage _aggregateAppUsage(_AppUsageArgs args) {
  final byApp = <String, ({int up, int down})>{};
  var totalUp = 0;
  var totalDown = 0;
  for (final b in args.buckets) {
    if (b.direction == 1) {
      totalUp += b.bytes;
    } else {
      totalDown += b.bytes;
    }
    final entry = byApp[b.process] ?? (up: 0, down: 0);
    byApp[b.process] = b.direction == 1
        ? (up: entry.up + b.bytes, down: entry.down)
        : (up: entry.up, down: entry.down + b.bytes);
  }
  final total = totalUp + totalDown;
  final apps =
      byApp.entries
          .map(
            (e) => AppTraffic(
              packageName: e.key,
              label: e.key.isEmpty
                  ? args.unknownLabel
                  : args.labels[e.key] ?? e.key,
              upload: e.value.up,
              download: e.value.down,
              percent: total == 0 ? 0 : (e.value.up + e.value.down) / total,
            ),
          )
          .toList()
        ..sort(
          (a, b) => (b.upload + b.download).compareTo(a.upload + a.download),
        );
  return AppUsage(
    totalUpload: totalUp,
    totalDownload: totalDown,
    appCount: apps.length,
    apps: apps,
  );
}
