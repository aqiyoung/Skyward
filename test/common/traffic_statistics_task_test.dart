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
      node: 'DIRECT',
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

  final hour = DateTime(2026, 11, 19, 8);
  final hours = [
    (hour: hour, direction: 0, proxied: 0, bytes: 100),
    (hour: hour, direction: 1, proxied: 0, bytes: 60),
    (hour: hour, direction: 0, proxied: 1, bytes: 100),
    (hour: hour, direction: 1, proxied: 1, bytes: 40),
  ];

  test('aggregates totals, proxy split and ranks by domain', () async {
    final stats = await aggregateTrafficTask(
      samples,
      hours,
      TrafficRankKind.domain.index,
    );
    expect(stats.totalUpload, 100);
    expect(stats.totalDownload, 200);
    expect(stats.proxyBytes, 160);
    expect(stats.directBytes, 140);
    expect(stats.connectionCount, 3);
    expect(stats.ranking.first.key, 'a.com');
    expect(stats.ranking.first.upload, 60);
    expect(stats.ranking.first.percent, closeTo(0.667, 0.01));
    // Percentages are each ranking's share of its own sum, never > 100%.
    expect(
      stats.ranking.every((e) => e.percent >= 0 && e.percent <= 1),
      isTrue,
    );
    expect(
      stats.ranking.fold<double>(0, (sum, e) => sum + e.percent),
      closeTo(1, 0.01),
    );
    expect(stats.ruleHits.every((e) => e.percent <= 1), isTrue);
    expect(stats.ruleHits, hasLength(2));
    expect(stats.ruleHits.firstWhere((h) => h.key == 'Match').hits, 2);
    expect(stats.trend, hasLength(1));
    expect(stats.trend.single.download, 200);
    expect(stats.trend.single.upload, 100);
  });

  test('ranks by node and by rule', () async {
    final byNode = await aggregateTrafficTask(
      samples,
      hours,
      TrafficRankKind.node.index,
    );
    expect(byNode.ranking.map((e) => e.key), containsAll(['N1', 'DIRECT']));
    final byRule = await aggregateTrafficTask(
      samples,
      hours,
      TrafficRankKind.rule.index,
    );
    expect(byRule.ranking.first.key, 'Match');
  });

  test('aggregates per-app usage with labels and sorted percentages', () async {
    final buckets = [
      (process: 'com.douyin', direction: 0, bytes: 100),
      (process: 'com.douyin', direction: 1, bytes: 50),
      (process: 'com.gallery', direction: 0, bytes: 30),
      (process: '', direction: 0, bytes: 20),
    ];
    final usage = await aggregateAppUsageTask(buckets, {
      'com.douyin': '抖音',
      'com.gallery': '相册',
    }, '未知');
    expect(usage.totalUpload, 50);
    expect(usage.totalDownload, 150);
    expect(usage.appCount, 3);
    expect(usage.apps.first.packageName, 'com.douyin');
    expect(usage.apps.first.label, '抖音');
    expect(usage.apps.first.percent, closeTo(150 / 200, 0.01));
    final unknown = usage.apps.firstWhere((a) => a.packageName.isEmpty);
    expect(unknown.label, '未知');
    expect(
      usage.apps.fold<double>(0, (sum, a) => sum + a.percent),
      closeTo(1, 0.01),
    );
  });
}
