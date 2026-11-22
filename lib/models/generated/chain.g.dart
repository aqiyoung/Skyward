// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../chain.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChainSpec _$ChainSpecFromJson(Map<String, dynamic> json) => _ChainSpec(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  hops: (json['hops'] as List<dynamic>).map((e) => e as String).toList(),
  offered: json['offered'] as bool? ?? true,
  targetGroup: json['target-group'] as String?,
  heal: json['heal'] as bool? ?? false,
);

Map<String, dynamic> _$ChainSpecToJson(_ChainSpec instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'hops': instance.hops,
      'offered': instance.offered,
      'target-group': instance.targetGroup,
      'heal': instance.heal,
    };

_ChainReport _$ChainReportFromJson(Map<String, dynamic> json) => _ChainReport(
  name: json['name'] as String,
  status: json['status'] as String,
  hops: (json['hops'] as List<dynamic>).map((e) => e as String).toList(),
  targetGroup: json['targetGroup'] as String?,
);

Map<String, dynamic> _$ChainReportToJson(_ChainReport instance) =>
    <String, dynamic>{
      'name': instance.name,
      'status': instance.status,
      'hops': instance.hops,
      'targetGroup': instance.targetGroup,
    };
