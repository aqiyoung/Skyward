import 'package:collection/collection.dart';
import 'package:skyward/common/common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/module.freezed.dart';

part 'generated/module.g.dart';

/// An imported module: the file it came from, the switch, and the policy a
/// `PROXY` rule should end up pointing at.
///
/// The content stays verbatim so the detail page can parse it again after an
/// update; what a module means is a property of its text, not of a snapshot we
/// took the day it was imported.
@freezed
abstract class Module with _$Module {
  const factory Module({
    required int id,
    required String label,
    String? url,
    @Default('') String content,
    @Default(true) bool enabled,
    String? order,
    String? author,
    String? version,
    String? homepage,
    String? policy,
    DateTime? updatedAt,
  }) = _Module;

  factory Module.fromJson(Map<String, Object?> json) => _$ModuleFromJson(json);

  factory Module.create({
    required String label,
    required String content,
    String? url,
  }) {
    return Module(
      id: snowflake.id,
      label: label,
      content: content,
      url: url,
      updatedAt: DateTime.now(),
    );
  }
}

extension ModulesExt on List<Module> {
  Module? getModule(int? id) {
    if (id == null) {
      return null;
    }
    final index = indexWhere((module) => module.id == id);
    return index == -1 ? null : this[index];
  }

  List<Module> get enabled => where((module) => module.enabled).toList();

  bool hasLabel(String label, {Module? except}) {
    return any((module) => module.id != except?.id && module.label == label);
  }

  String uniqueLabel(String name, {required String fallback}) {
    final trimmed = name.trim();
    final base = trimmed.isEmpty ? fallback : trimmed;
    if (!hasLabel(base)) {
      return base;
    }
    var index = 2;
    while (hasLabel('$base ($index)')) {
      index++;
    }
    return '$base ($index)';
  }
}
