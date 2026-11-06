// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../module.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Module _$ModuleFromJson(Map<String, dynamic> json) => _Module(
  id: (json['id'] as num).toInt(),
  label: json['label'] as String,
  url: json['url'] as String?,
  content: json['content'] as String? ?? '',
  enabled: json['enabled'] as bool? ?? true,
  order: json['order'] as String?,
  author: json['author'] as String?,
  version: json['version'] as String?,
  homepage: json['homepage'] as String?,
  policy: json['policy'] as String?,
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ModuleToJson(_Module instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'url': instance.url,
  'content': instance.content,
  'enabled': instance.enabled,
  'order': instance.order,
  'author': instance.author,
  'version': instance.version,
  'homepage': instance.homepage,
  'policy': instance.policy,
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
