import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/features/features.dart';
import 'package:skyward/features/form/form.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Imported modules: a switch each, and the rules they carry.
///
/// A module is not a profile's property -- the switch applies to whatever
/// profile is running -- so the page lives under advanced config rather than
/// inside a profile.
class ModulesView extends ConsumerStatefulWidget {
  const ModulesView({super.key});

  @override
  ConsumerState<ModulesView> createState() => _ModulesViewState();
}

class _ModulesViewState extends ConsumerState<ModulesView> {
  Future<void> _handleImportFromUrl() async {
    final appLocalizations = context.appLocalizations;
    final url = await dialogs.showUrlInput(title: appLocalizations.importUrl);
    if (url == null || !mounted) {
      return;
    }
    final res = await globalState.loadingRun(
      () => request.getTextResponseForUrl(url),
      title: appLocalizations.importUrl,
      tag: LoadingTag.modules,
    );
    final content = res?.data ?? '';
    if (!mounted) {
      return;
    }
    if (content.trim().isEmpty) {
      dialogs.showNotifier(
        appLocalizations.moduleEmpty,
        level: MessageLevel.error,
      );
      return;
    }
    ref
        .read(modulesActionProvider.notifier)
        .importModule(content: content, url: url);
  }

  Future<void> _handlePaste() async {
    final res = await showFormSheet<({String? label, String content})>(
      context: context,
      builder: (_) => const _ModulePasteForm(),
    );
    if (res == null || !mounted) {
      return;
    }
    ref
        .read(modulesActionProvider.notifier)
        .importModule(content: res.content, label: res.label);
  }

  Future<void> _handleUpdate(Module module) async {
    final appLocalizations = context.appLocalizations;
    final url = module.url;
    if (url == null || url.isEmpty) {
      dialogs.showNotifier(
        appLocalizations.moduleNoUrl,
        level: MessageLevel.error,
      );
      return;
    }
    final res = await globalState.loadingRun(
      () => request.getTextResponseForUrl(url),
      title: module.label,
      tag: LoadingTag.modules,
    );
    final content = res?.data ?? '';
    if (!mounted) {
      return;
    }
    if (content.trim().isEmpty) {
      dialogs.showNotifier(
        appLocalizations.moduleEmpty,
        level: MessageLevel.error,
      );
      return;
    }
    ref
        .read(modulesActionProvider.notifier)
        .importModule(content: content, updating: module);
    dialogs.showNotifier(
      appLocalizations.moduleUpdated(module.label),
      level: MessageLevel.success,
    );
  }

  Future<void> _handleDelete(Module module) async {
    final appLocalizations = context.appLocalizations;
    final res = await dialogs.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(
        text: appLocalizations.deleteMultipTip(appLocalizations.modules),
      ),
      destructive: true,
      confirmText: appLocalizations.delete,
    );
    if (res != true || !mounted) {
      return;
    }
    ref.read(modulesActionProvider.notifier).delete([module.id]);
  }

  void _handleOpen(Module module) {
    unawaited(BaseNavigator.push(context, ModuleDetailView(module.id)));
  }

  List<CommonPopupMenuItem> _buildMenuItems(Module module) {
    final appLocalizations = context.appLocalizations;
    return [
      CommonPopupMenuItem(
        glyph: AppGlyphs.sync,
        label: appLocalizations.update,
        onPressed: () => _handleUpdate(module),
      ),
      CommonPopupMenuItem(
        danger: true,
        glyph: AppGlyphs.delete,
        label: appLocalizations.delete,
        onPressed: () => _handleDelete(module),
      ),
    ];
  }

  Widget _buildItem(List<Module> modules, int index) {
    final module = modules[index];
    final parsed = parseModule(module.content, fallbackName: module.label);
    final subtitle = [
      if (module.author?.isNotEmpty == true) module.author!,
      if (module.version?.isNotEmpty == true) 'v${module.version}',
      parsed.format.label,
    ].join(' · ');
    return SortableItem(
      key: ValueKey(module.id),
      index: index,
      child: ContextMenuRegion(
        menuItems: _buildMenuItems(module),
        child: ItemPositionProvider(
          position: ItemPosition.get(index, modules.length),
          child: DecorationListItem(
            leading: const IconWell(AppGlyphs.puzzle),
            title: Text(
              module.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.listCaptionStyle,
            ),
            trailing: CommonSwitch(
              value: module.enabled,
              onChanged: (value) {
                ref
                    .read(modulesActionProvider.notifier)
                    .toggle(module.id, value);
              },
            ),
            onPressed: () => _handleOpen(module),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final state = ref.watch(importedModulesProvider);
    final modules = state.value ?? const <Module>[];
    return CommonScaffold(
      title: appLocalizations.modules,
      canSort: modules.length > 1,
      isLoading: ref.watch(loadingProvider(LoadingTag.modules)),
      actions: [
        CommonPopupBox(
          targetBuilder: (open) => IconButton(
            tooltip: appLocalizations.add,
            onPressed: open,
            icon: const GlyphIcon(AppGlyphs.addCircle),
          ),
          popupBuilder: (_) => CommonPopupMenu(
            items: [
              CommonPopupMenuItem(
                glyph: AppGlyphs.cloudDownload,
                label: appLocalizations.importUrl,
                onPressed: _handleImportFromUrl,
              ),
              CommonPopupMenuItem(
                glyph: AppGlyphs.paste,
                label: appLocalizations.paste,
                onPressed: _handlePaste,
              ),
            ],
          ),
        ),
      ],
      body: NullStatusSwitcher(
        isLoading: state.isLoading,
        isEmpty: modules.isEmpty,
        nullStatus: NullStatus(
          label: appLocalizations.nullTip(appLocalizations.modules),
          illustration: NullStatusIllustration.rules,
        ),
        child: ReorderableListView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            context.contentTopPadding,
            16,
            16 + context.bottomInset,
          ),
          buildDefaultDragHandles: false,
          itemCount: modules.length,
          itemBuilder: (_, index) => _buildItem(modules, index),
          proxyDecorator: (_, index, animation) => commonProxyDecorator(
            _buildItem(modules, index),
            index,
            animation,
          ),
          onReorderItem: ref.read(modulesActionProvider.notifier).order,
        ),
      ),
    );
  }
}

/// One module, as the file describes it.
///
/// The page reads the stored text again rather than a parsed snapshot: what a
/// module means is a property of its text, and an update can change both the
/// rules and the sections that get skipped.
class ModuleDetailView extends ConsumerWidget {
  static const _maxRulesShown = 300;

  final int moduleId;

  const ModuleDetailView(this.moduleId, {super.key});

  String _skipReason(ModuleSkipReason reason, AppLocalizations l10n) {
    return switch (reason) {
      ModuleSkipReason.httpsDecryption => l10n.moduleSkipHttps,
      ModuleSkipReason.scriptRuntime => l10n.moduleSkipScript,
      ModuleSkipReason.unsupportedRule => l10n.moduleSkipRule,
      ModuleSkipReason.remoteRuleSet => l10n.moduleSkipRuleSet,
      ModuleSkipReason.unresolvedPolicy => l10n.moduleSkipPolicy,
      ModuleSkipReason.unsupportedGeneral => l10n.moduleSkipGeneral,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final module = ref.watch(
      importedModulesProvider.select(
        (state) =>
            state.value?.where((item) => item.id == moduleId).firstOrNull,
      ),
    );
    if (module == null) {
      return CommonScaffold(
        title: appLocalizations.modules,
        body: const SizedBox.shrink(),
      );
    }
    final parsed = parseModule(module.content, fallbackName: module.label);
    final shownRules = parsed.rules.take(_maxRulesShown).toList();
    return CommonScaffold(
      title: module.label,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          context.cardTopPadding,
          16,
          16 + context.bottomInset,
        ),
        children: [
          generateSection(
            leadingGap: false,
            items: [
              ListItem.toggle(
                title: Text(module.label),
                subtitle: Text(parsed.format.label),
                value: module.enabled,
                onChanged: (value) {
                  ref
                      .read(modulesActionProvider.notifier)
                      .toggle(module.id, value);
                },
              ),
              if (module.author?.isNotEmpty == true)
                ListItem(
                  title: Text(appLocalizations.author),
                  trailing: Text(module.author!),
                ),
              if (module.version?.isNotEmpty == true)
                ListItem(
                  title: Text(appLocalizations.version),
                  trailing: Text(module.version!),
                ),
              if (module.homepage?.isNotEmpty == true)
                ListItem(
                  title: Text(appLocalizations.link),
                  trailing: Text(
                    module.homepage!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () =>
                      unawaited(launchUrl(Uri.parse(module.homepage!))),
                ),
              if (module.url?.isNotEmpty == true)
                ListItem(
                  title: const Text('URL'),
                  trailing: Text(
                    module.url!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          generateSection(
            title: appLocalizations.modulePolicy,
            footer: appLocalizations.modulePolicyTip,
            items: [
              ListItem.input(
                title: Text(appLocalizations.modulePolicy),
                dialogTitle: appLocalizations.modulePolicy,
                value: module.policy ?? '',
                onChanged: (value) {
                  ref
                      .read(modulesActionProvider.notifier)
                      .setPolicy(module.id, value);
                },
              ),
            ],
          ),
          generateSection(
            title: '${appLocalizations.rules} · ${parsed.rules.length}',
            footer: parsed.rules.length > _maxRulesShown
                ? appLocalizations.moduleRulesTruncated(_maxRulesShown)
                : null,
            items: [
              for (final rule in shownRules)
                ListItem(
                  title: Text(
                    rule.toRawValue(module.policy),
                    style: AppTextStyle.footnote.of(context).toJetBrainsMono,
                  ),
                ),
            ],
          ),
          generateSection(
            title:
                '${appLocalizations.moduleSkipped} · ${parsed.skipped.length}',
            items: [
              for (final skip in parsed.skipped)
                ListItem(
                  title: Text(
                    skip.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.footnote.of(context).toJetBrainsMono,
                  ),
                  subtitle: Text(
                    _skipReason(skip.reason, appLocalizations),
                    style: context.listCaptionStyle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The paste path: a name, and the file's text.
class _ModulePasteForm extends StatefulWidget {
  const _ModulePasteForm();

  @override
  State<_ModulePasteForm> createState() => _ModulePasteFormState();
}

class _ModulePasteFormState extends State<_ModulePasteForm> {
  final _labelController = TextEditingController();
  final _contentController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _labelController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() {
        _error = context.appLocalizations.moduleEmpty;
      });
      return;
    }
    final label = _labelController.text.trim();
    Navigator.of(
      context,
    ).pop((label: label.isEmpty ? null : label, content: content));
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return FormPage(
      title: appLocalizations.modules,
      error: _error,
      onSave: _handleSave,
      children: [
        generateSection(
          leadingGap: false,
          items: [
            FormRow(
              title: appLocalizations.name,
              trailing: FormRowTextField(
                controller: _labelController,
                hintText: appLocalizations.optional,
              ),
            ),
          ],
        ),
        generateSection(
          title: appLocalizations.content,
          footer: appLocalizations.modulePasteTip,
          items: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _contentController,
                maxLines: 12,
                minLines: 6,
                style: AppTextStyle.footnote.of(context).toJetBrainsMono,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
