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

/// Aggregates [samples] off the UI isolate. [kind] is the TrafficRankKind index.
Future<TrafficStatistics> aggregateTrafficTask(
  List<TrafficSample> samples,
  int kind,
) => compute<_AggregateArgs, TrafficStatistics>(
  _aggregate,
  _AggregateArgs(samples, kind),
);

class _AggregateArgs {
  const _AggregateArgs(this.samples, this.kind);

  final List<TrafficSample> samples;
  final int kind;
}

TrafficStatistics _aggregate(_AggregateArgs args) {
  var totalUp = 0;
  var totalDown = 0;
  final ranks = <String, ({int up, int down, int hits})>{};
  final ruleHits = <String, ({int up, int down, int hits})>{};

  String keyOf(TrafficSample s) => switch (TrafficRankKind.values[args.kind]) {
    TrafficRankKind.domain => s.host.isNotEmpty ? s.host : s.rulePayload,
    TrafficRankKind.rule => s.rule.isNotEmpty ? s.rule : 'MATCH',
    TrafficRankKind.node => s.node.isNotEmpty ? s.node : 'DIRECT',
    TrafficRankKind.config => s.rule,
  };

  for (final s in args.samples) {
    totalUp += s.upload;
    totalDown += s.download;
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

  return TrafficStatistics(
    totalUpload: totalUp,
    totalDownload: totalDown,
    connectionCount: args.samples.length,
    ruleHits: hits,
    ranking: ranking,
  );
}
