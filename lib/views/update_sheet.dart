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
    props: const SheetProps(detents: [0.74]),
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
    // A full page instead of a sheet on top of a sheet: the stacked handle
    // bars covered the title and the lower sheet had no room for its list.
    unawaited(
      BaseNavigator.push<void>(context, const UpdatePreferencesSheet()),
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

  Widget _channelPill(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final label = globalState.isPre
        ? (zh ? '预发布版' : 'Pre-release')
        : (zh ? '正式版' : 'Stable');
    final scheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: scheme.primaryContainer,
        shape: AppShape.full,
      ),
      child: Text(
        label,
        style: AppTextStyle.footnote
            .of(context)
            .copyWith(color: scheme.onPrimaryContainer),
      ),
    );
  }

  /// The status line: channel on the left, live state on the right.
  Widget _statusLine(BuildContext context, String text, bool checking) {
    final scheme = context.colorScheme;
    return Row(
      children: [
        _channelPill(context),
        const Spacer(),
        if (checking) CommonCircleLoading(size: 16),
        if (!checking)
          GlyphIcon(
            _phase == _UpdatePhase.latest
                ? AppGlyphs.check
                : AppGlyphs.cloudDownload,
            size: 16,
            color: _phase == _UpdatePhase.latest
                ? scheme.success
                : scheme.primary,
          ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyle.subheadline
              .of(context)
              .copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// The version itself is the hero, not a decorative ring. The accent line
  /// under it carries the checking progress and the release channel colour.
  Widget _versionCard(BuildContext context, String version, String caption) {
    final scheme = context.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      decoration: ShapeDecoration(
        color: context.raisedSurfaceLevel.colorOf(scheme),
        shape: AppShape.all(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            version,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.title1
                .of(context, emphasized: true)
                .copyWith(color: scheme.primary),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              caption,
              style: AppTextStyle.footnote
                  .of(context)
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (_phase == _UpdatePhase.checking)
            const LinearProgressIndicator(minHeight: 3)
          else
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: _phase == _UpdatePhase.latest
                    ? scheme.success
                    : scheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  /// Notes get their own scrollable card, so a long changelog never pushes
  /// the action buttons off the sheet.
  Widget _notesCard(BuildContext context, String? body) {
    final l = context.appLocalizations;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final scheme = context.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: context.raisedSurfaceLevel.colorOf(scheme),
        shape: AppShape.all(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlyphIcon(AppGlyphs.code, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                zh ? '更新日志' : "What's new",
                style: AppTextStyle.headline.of(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 190),
            child: SingleChildScrollView(
              child: Text.rich(_releaseNotes(context, body)),
            ),
          ),
        ],
      ),
    );
  }

  /// Three quiet lines while the check is in flight: enough to show the
  /// panel is alive without inventing release information.
  Widget _checkingHints(BuildContext context) {
    final scheme = context.colorScheme;
    final tint = scheme.onSurface.withValues(alpha: 0.08);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final width in [1.0, 0.82, 0.64])
          Container(
            height: 10,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: ShapeDecoration(color: tint, shape: AppShape.all(6)),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: width,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final installed = globalState.hasPackageInfo
        ? globalState.packageInfo.labeledVersion
        : '';
    final remote = releaseVersionOf(
      (_release?['tag_name'] as String?) ?? '',
      _release?['name'] as String?,
    );
    final body = _release?['body'] as String?;
    final showNotes =
        _phase == _UpdatePhase.found && body?.trim().isNotEmpty == true;
    final (status, version, caption) = switch (_phase) {
      _UpdatePhase.checking => (
        l.versionUpdateChecking,
        installed,
        zh ? '正在连接更新源…' : 'Contacting the release feed…',
      ),
      _UpdatePhase.latest => (
        zh ? '已是最新版本' : "You're up to date",
        installed,
        zh ? '无需更新' : 'Nothing to install',
      ),
      _UpdatePhase.found => (
        l.versionUpdateFound,
        remote,
        zh ? '已安装：$installed' : 'Installed: $installed',
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
        hero: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statusLine(context, status, _phase == _UpdatePhase.checking),
            const SizedBox(height: 12),
            _versionCard(context, version, caption),
          ],
        ),
        body: [
          const SizedBox(height: 16),
          if (showNotes)
            _notesCard(context, body)
          else if (_phase == _UpdatePhase.checking)
            _checkingHints(context),
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
  late bool _notifyOnUpdate;
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
        _notifyOnUpdate = loaded.notifyOnUpdate;
        _channel = effectiveUpdateChannel(
          configured: loaded.channel,
          isPreBuild: globalState.isPre,
        );
      });
    });
    // Defaults until the async load lands.
    _preloadWifi = extra.preloadWifi;
    _autoInstall = extra.autoInstall;
    _notifyOnUpdate = extra.notifyOnUpdate;
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
        notifyOnUpdate: _notifyOnUpdate,
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
                zh ? '仅在 Wi-Fi 下载' : 'Download over Wi-Fi only',
                _preloadWifi,
                (value) => setState(() => _preloadWifi = value),
              ),
              _toggle(
                zh ? '发现更新时弹窗' : 'Pop up on new version',
                _notifyOnUpdate,
                (value) => setState(() => _notifyOnUpdate = value),
              ),
              if (system.isDesktop)
                _toggle(
                  zh ? '自动安装（桌面）' : 'Auto install (desktop)',
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
