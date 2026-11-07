part of '../action.dart';

/// Imports, updates and switches modules.
///
/// The rules a module carries ride inside the generated config, so every write
/// here re-applies the current profile -- a switch that only changed a row in
/// the database would look like it did nothing.
@Riverpod(keepAlive: true)
class ModulesAction extends _$ModulesAction {
  @override
  void build() {}

  /// Reads [content] and stores it, either as a new module or as the new body
  /// of [updating].
  Module importModule({
    required String content,
    String? url,
    String? label,
    Module? updating,
  }) {
    final parsed = parseModule(
      content,
      fallbackName: label?.trim().isNotEmpty == true ? label!.trim() : 'Module',
    );
    final modules = ref.read(importedModulesProvider).value ?? const <Module>[];
    final existing = modules.getModule(updating?.id);
    final name = updating == null
        ? modules.uniqueLabel(label ?? parsed.name, fallback: 'Module')
        : (existing?.label ??
              modules.uniqueLabel(label ?? parsed.name, fallback: 'Module'));
    final module = (existing ?? Module.create(label: name, content: content))
        .copyWith(
          label: name,
          content: content,
          url: url ?? existing?.url,
          author: parsed.author ?? existing?.author,
          version: parsed.version ?? existing?.version,
          homepage: parsed.homepage ?? existing?.homepage,
          updatedAt: DateTime.now(),
        );
    ref.read(importedModulesProvider.notifier).put(module);
    _apply();
    return module;
  }

  void toggle(int id, bool enabled) {
    ref.read(importedModulesProvider.notifier).setEnabled(id, enabled);
    _apply();
  }

  void setPolicy(int id, String? policy) {
    final module = (ref.read(importedModulesProvider).value ?? const <Module>[])
        .getModule(id);
    if (module == null) {
      return;
    }
    final trimmed = policy?.trim();
    ref
        .read(importedModulesProvider.notifier)
        .put(
          module.copyWith(policy: trimmed?.isEmpty == true ? null : trimmed),
        );
    _apply();
  }

  void delete(Iterable<int> ids) {
    ref.read(importedModulesProvider.notifier).delAll(ids);
    _apply();
  }

  void order(int oldIndex, int newIndex) {
    ref.read(importedModulesProvider.notifier).order(oldIndex, newIndex);
    _apply();
  }

  void _apply() {
    unawaited(ref.read(setupActionProvider.notifier).applyProfile(force: true));
  }
}
