import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final samples = [
    (
      host: 'a.com',
      rule: 'Match',
      rulePayload: '',
      node: 'N1',
      upload: 10,
      download: 90,
    ),
    (
      host: 'b.com',
      rule: 'cn_ip',
      rulePayload: '',
      node: 'N2',
      upload: 40,
      download: 60,
    ),
    (
      host: 'a.com',
      rule: 'Match',
      rulePayload: '',
      node: 'N1',
      upload: 50,
      download: 50,
    ),
  ];

  test('aggregates totals and ranks by domain', () async {
    final stats = await aggregateTrafficTask(
      samples,
      TrafficRankKind.domain.index,
    );
    expect(stats.totalUpload, 100);
    expect(stats.totalDownload, 200);
    expect(stats.connectionCount, 3);
    expect(stats.ranking.first.key, 'a.com');
    expect(stats.ranking.first.upload, 60);
    expect(stats.ranking.first.percent, closeTo(0.55, 0.01));
    expect(stats.ruleHits, hasLength(2));
    expect(stats.ruleHits.firstWhere((h) => h.key == 'Match').hits, 2);
  });

  test('ranks by node and by rule', () async {
    final byNode = await aggregateTrafficTask(
      samples,
      TrafficRankKind.node.index,
    );
    expect(byNode.ranking.map((e) => e.key), containsAll(['N1', 'N2']));
    final byRule = await aggregateTrafficTask(
      samples,
      TrafficRankKind.rule.index,
    );
    expect(byRule.ranking.first.key, 'Match');
  });
}
