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
  int kind,
) => compute<_AggregateArgs, TrafficStatistics>(
  _aggregate,
  _AggregateArgs(samples, hours, kind),
);

class _AggregateArgs {
  const _AggregateArgs(this.samples, this.hours, this.kind);

  final List<TrafficSample> samples;
  final List<TrafficHourSample> hours;
  final int kind;
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

  for (final s in args.samples) {
    final key = keyOf(s);
    ranks[key] = (
      up: (ranks[key]?.up ?? 0) + s.upload,
      down: (ranks[key]?.down ?? 0) + s.download,
      hits: (ranks[key]?.hits ?? 0) + 1,
    );
    final ruleKey = s.rule.isNotEmpty ? s.rule : 'MATCH';
    ruleHits[ruleKey] = (
      up: (ruleHits[ruleKey]?.up ?? 0) + s.upload,
      down: (ruleHits[ruleKey]?.down ?? 0) + s.download,
      hits: (ruleHits[ruleKey]?.hits ?? 0) + 1,
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

  final totalBytes = totalUp + totalDown;
  double share(int up, int down) =>
      totalBytes == 0 ? 0 : (up + down) / totalBytes;

  final ranking =
      ranks.entries
          .map(
            (e) => TrafficRankItem(
              key: e.key,
              upload: e.value.up,
              download: e.value.down,
              percent: share(e.value.up, e.value.down),
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
              percent: share(e.value.up, e.value.down),
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
    connectionCount: args.samples.length,
    proxyBytes: proxyBytes,
    directBytes: directBytes,
    ruleHits: hits,
    ranking: ranking,
    trend: trend,
  );
}
