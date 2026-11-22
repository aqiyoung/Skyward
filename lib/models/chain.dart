import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/chain.freezed.dart';
part 'generated/chain.g.dart';

/// A user-defined proxy chain: 2-3 hops, entry first, exit last. Serialized
/// into the generated config's `chains:` key; the core clones each hop into a
/// virtual node wired with dialer-proxy and exposes the chain as a selectable
/// group.
@freezed
abstract class ChainSpec with _$ChainSpec {
  const factory ChainSpec({
    required int id,
    required String name,
    required List<String> hops,
    @Default(true) bool offered,
    @JsonKey(name: 'target-group') String? targetGroup,
    @Default(false) bool heal,
  }) = _ChainSpec;

  factory ChainSpec.fromJson(Map<String, dynamic> json) =>
      _$ChainSpecFromJson(json);
}

/// The core's report for a chain after materialization.
@freezed
abstract class ChainReport with _$ChainReport {
  const factory ChainReport({
    required String name,
    required String status,
    required List<String> hops,
    @JsonKey(name: 'targetGroup') String? targetGroup,
  }) = _ChainReport;

  factory ChainReport.fromJson(Map<String, dynamic> json) =>
      _$ChainReportFromJson(json);
}
