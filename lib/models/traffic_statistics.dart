import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/traffic_statistics.freezed.dart';

/// Aggregated traffic for one ranking key; [percent] is its share (0..1).
@freezed
abstract class TrafficRankItem with _$TrafficRankItem {
  const factory TrafficRankItem({
    required String key,
    required int upload,
    required int download,
    required double percent,
  }) = _TrafficRankItem;
}

/// One rule's hit statistics, shown as a ring.
@freezed
abstract class RuleHit with _$RuleHit {
  const factory RuleHit({
    required String key,
    required int hits,
    required int upload,
    required int download,
    required double percent,
  }) = _RuleHit;
}

/// The aggregate a statistics page needs for one period and dimension.
@freezed
abstract class TrafficStatistics with _$TrafficStatistics {
  const factory TrafficStatistics({
    required int totalUpload,
    required int totalDownload,
    required int connectionCount,
    required List<RuleHit> ruleHits,
    required List<TrafficRankItem> ranking,
  }) = _TrafficStatistics;
}
