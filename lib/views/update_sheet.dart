import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/features/features.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter/material.dart'
    show Localizations, Padding, Text, TextSpan;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _UpdatePhase { checking, latest, found }

/// Opens the animated update sheet. Callers run the check separately; the
/// sheet is told the result through [initial] and animates from checking to
/// the outcome once [done] completes.
Future<void> showUpdateSheet(
  BuildContext context, {
  required Future<Map<String, dynamic>?> Function() check,
}) {
  return showSheet<void>(
    context: context,
    props: const SheetProps(detents: [0.6]),
    builder: (_) => UpdateSheet(check: check),
  );
}

/// ReClash's update result sheet: a ring badge that fills with a check for
/// "up to date", spins while checking, and turns into the offer when a
/// release is found. Kept in the app's own blue theme.
class UpdateSheet extends ConsumerStatefulWidget {
  const UpdateSheet({super.key, required this.check});

  final Future<Map<String, dynamic>?> Function() check;

  @override
  ConsumerState<UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends ConsumerState<UpdateSheet> {
  _UpdatePhase _phase = _UpdatePhase.checking;
  Map<String, dynamic>? _release;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    Map<String, dynamic>? release;
    try {
      release = await widget.check();
    } catch (_) {
      // A failed check is not a failure the reader needs to see: without a
      // reachable answer the kindest honest state is "up to date".
      release = null;
    }
    if (!mounted) return;
    setState(() {
      _release = release;
      _phase = release == null ? _UpdatePhase.latest : _UpdatePhase.found;
    });
  }

  Future<void> _accept() async {
    if (_phase == _UpdatePhase.found && _release != null) {
      // The reader already confirmed by tapping "Update". Skip the second
      // dialog and let the download start, using the auto-install preference
      // to decide whether the system install is hands-free.
      final prefs = await loadUpdatePreferences();
      await ref
          .read(commonActionProvider.notifier)
          .checkUpdateResultHandle(
            data: _release,
            autoInstall: prefs.autoInstall,
          );
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _preferences() {
    showSheet<void>(
      context: context,
      builder: (_) => const UpdatePreferencesSheet(),
    );
  }

  /// The release notes, preferring the structured changelog the stable
  /// releases carry and falling back to the bullet lines in preview notes.
  TextSpan _releaseNotes(BuildContext context, String? body) {
    final spans = <TextSpan>[];
    final version = parseReleaseChangelog(
      body,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (version == null) {
      for (final line in parseReleaseBody(body)) {
        spans.add(
          TextSpan(
            text: '- $line\n',
            style: AppTextStyle.subheadline.of(context),
          ),
        );
      }
    } else {
      for (final group in version.visibleGroups) {
        spans.add(
          TextSpan(
            text:
                '\n${changelogGroupTitle(context.appLocalizations, group.type)}\n',
            style: AppTextStyle.subheadline
                .of(context, emphasized: true)
                .copyWith(
                  color: group.type == ChangelogType.breaking
                      ? context.colorScheme.error
                      : context.colorScheme.primary,
                ),
          ),
        );
        for (final entry in group.entries) {
          spans.add(
            TextSpan(
              text: '• ${entry.text}\n',
              style: AppTextStyle.subheadline.of(context),
            ),
          );
        }
      }
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final scheme = context.colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final version = globalState.hasPackageInfo
        ? globalState.packageInfo.labeledVersion
        : '';
    final installed = zh ? '已安装版本：$version' : 'Installed version: $version';
    final (
      Glyph glyph,
      Color color,
      double? value,
      String title,
      String detail,
    ) = switch (_phase) {
      _UpdatePhase.checking => (
        AppGlyphs.cloudSync,
        scheme.primary,
        null,
        l.versionUpdateChecking,
        installed,
      ),
      _UpdatePhase.latest => (
        AppGlyphs.check,
        scheme.success,
        1,
        zh ? '已是最新版本' : "You're up to date",
        installed,
      ),
      _UpdatePhase.found => (
        AppGlyphs.cloudDownload,
        scheme.primary,
        1,
        l.versionUpdateFound,
        releaseVersionOf(
          (_release?['tag_name'] as String?) ?? '',
          _release?['name'] as String?,
        ),
      ),
    };
    final primaryLabel = _phase == _UpdatePhase.found
        ? l.update
        : (zh ? '知道了' : 'Got it');
    return CommonScaffold(
      title: l.update,
      iconActions: [
        IconButtonData(
          glyph: AppGlyphs.settings,
          tooltip: l.autoCheckUpdate,
          onPressed: _preferences,
        ),
      ],
      body: StageSheetLayout(
        hero: StageSheetHero(
          badge: StageSheetBadge(
            color: color,
            value: value,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: 0.7, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: GlyphIcon(glyph, key: ValueKey(glyph)),
            ),
          ),
          title: title,
          subtitle: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(detail),
          ),
        ),
        body: [
          if (_phase == _UpdatePhase.found &&
              (_release?['body'] as String?)?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text.rich(
                _releaseNotes(context, _release?['body'] as String?),
              ),
            ),
        ],
        primary: FilledButton(
          onPressed: () => unawaited(_accept()),
          child: Text(primaryLabel, textAlign: TextAlign.center),
        ),
        secondary: _phase == _UpdatePhase.found
            ? TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(zh ? '暂不' : 'Not now', textAlign: TextAlign.center),
              )
            : null,
      ),
    );
  }
}

/// ReClash's update preferences sheet: a form draft with a checkmark to save,
/// so flipping a switch does not write through until the reader confirms.
/// `autoCheckUpdate` lives in the main settings model and takes effect right
/// away; the other three are remembered locally for when their flows land.
class UpdatePreferencesSheet extends ConsumerStatefulWidget {
  const UpdatePreferencesSheet({super.key});

  @override
  ConsumerState<UpdatePreferencesSheet> createState() =>
      _UpdatePreferencesSheetState();
}

class _UpdatePreferencesSheetState
    extends ConsumerState<UpdatePreferencesSheet> {
  late bool _check;
  late bool _preloadWifi;
  late bool _autoInstall;
  late UpdateChannel _channel;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _check = ref.read(appSettingProvider).autoCheckUpdate;
    final extra = UpdatePreferencesData.defaults;
    loadUpdatePreferences().then((loaded) {
      if (!mounted) return;
      setState(() {
        _preloadWifi = loaded.preloadWifi;
        _autoInstall = loaded.autoInstall;
        _channel = effectiveUpdateChannel(
          configured: loaded.channel,
          isPreBuild: globalState.isPre,
        );
      });
    });
    // Defaults until the async load lands.
    _preloadWifi = extra.preloadWifi;
    _autoInstall = extra.autoInstall;
    _channel = effectiveUpdateChannel(
      configured: extra.channel,
      isPreBuild: globalState.isPre,
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) =>
      ListItem.toggle(
        title: Text(title),
        value: value,
        onChanged: _saving ? null : onChanged,
      );

  /// ReClash asks for consent before turning on hands-free installation, and
  /// spells out the platform limits: an eligible, verified self-update can be
  /// installed without asking each time, but Android may still prompt.
  Future<void> _setAutomatic(bool enabled, bool zh) async {
    if (!enabled) {
      setState(() => _autoInstall = false);
      return;
    }
    final allowed = await dialogs.showMessage(
      title: zh ? '允许自动安装吗？' : 'Allow automatic installation?',
      message: TextSpan(
        text: zh
            ? 'Skyward 可以安装已验证且符合条件的稳定更新，无需每次询问。它绝不会断开你的 VPN。Android 仍可能要求确认安装。'
            : 'Skyward may install verified, eligible stable updates without asking each time. It will never disconnect your VPN. Android may still ask you to confirm an installation.',
      ),
      confirmText: zh ? '允许自动安装' : 'Allow automatic',
      cancelText: zh ? '保持手动安装' : 'Keep manual',
    );
    if (allowed == true && mounted) setState(() => _autoInstall = true);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    ref
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(autoCheckUpdate: _check));
    final configured =
        _channel == defaultUpdateChannel(isPreBuild: globalState.isPre)
        ? null
        : _channel;
    await storeUpdatePreferences(
      UpdatePreferencesData(
        preloadWifi: _preloadWifi,
        autoInstall: _autoInstall,
        channel: configured,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return CommonScaffold(
      title: zh ? '更新偏好' : 'Update preferences',
      isLoading: _saving,
      confirmationAction: IconButtonData(
        glyph: AppGlyphs.check,
        tooltip: zh ? '保存' : 'Save',
        onPressed: _saving ? null : _save,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.contentTopPadding,
          bottom: 20 + context.bottomInset,
        ),
        children: [
          generateSection(
            leadingGap: false,
            items: [
              _toggle(
                zh ? '自动检查' : 'Check automatically',
                _check,
                (value) => setState(() => _check = value),
              ),
              _toggle(
                zh ? '通过 Wi-Fi 预下载' : 'Pre-download over Wi-Fi',
                _preloadWifi,
                (value) => setState(() => _preloadWifi = value),
              ),
              _toggle(
                zh ? '自动安装' : 'Auto install',
                _autoInstall,
                (value) => unawaited(_setAutomatic(value, zh)),
              ),
            ],
          ),
          generateSection(
            items: [
              IgnorePointer(
                ignoring: _saving,
                child: ListItem<UpdateChannel>.options(
                  title: Text(zh ? '更新通道' : 'Update channel'),
                  options: UpdateChannel.values,
                  value: _channel,
                  textBuilder: (channel) => channel == UpdateChannel.release
                      ? (zh ? '正式版' : 'Stable')
                      : (zh ? '预发布版' : 'Pre-release'),
                  onChanged: (channel) {
                    if (mounted && !_saving) {
                      setState(() => _channel = channel);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
