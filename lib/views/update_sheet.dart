import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter/material.dart' show Localizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _UpdatePhase { checking, latest, found, failed }

/// Opens the animated update sheet. Callers run the check separately; the
/// sheet is told the result through [initial] and animates from checking to
/// the outcome once [done] completes.
Future<void> showUpdateSheet(
  BuildContext context, {
  required Future<Map<String, dynamic>?> Function() check,
}) {
  return showSheet<void>(
    context: context,
    props: const SheetProps(detents: [0.9]),
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
      release = null;
      _failed = true;
    }
    if (!mounted) return;
    setState(() {
      _release = release;
      _phase = _failed
          ? _UpdatePhase.failed
          : release == null
              ? _UpdatePhase.latest
              : _UpdatePhase.found;
    });
  }

  bool _failed = false;

  void _accept() {
    if (_phase == _UpdatePhase.found && _release != null) {
      unawaited(
        ref
            .read(commonActionProvider.notifier)
            .checkUpdateResultHandle(data: _release, isUser: true),
      );
    }
    Navigator.of(context).pop();
  }

  void _preferences() {
    final enabled = ref.read(appSettingProvider).autoCheckUpdate;
    showSheet<void>(
      context: context,
      builder: (_) => CommonScaffold(
        title: context.appLocalizations.autoCheckUpdate,
        body: ListView(
          children: [
            generateSection(
              leadingGap: false,
              items: [
                ListItem.toggle(
                  title: Text(context.appLocalizations.autoCheckUpdate),
                  value: enabled,
                  onChanged: (value) {
                    ref
                        .read(appSettingProvider.notifier)
                        .update((state) => state.copyWith(autoCheckUpdate: value));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
    final (Glyph glyph, Color color, double? value, String title, String detail) =
        switch (_phase) {
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
          (_release?['tag_name'] as String?) ?? '',
        ),
      _UpdatePhase.failed => (
          AppGlyphs.wifiOff,
          scheme.error,
          1,
          l.versionUpdateFailed,
          zh ? '请稍后重试' : 'Please try again later',
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
        primary: FilledButton(
          onPressed: _phase == _UpdatePhase.failed
              ? () {
                  setState(() {
                    _failed = false;
                    _phase = _UpdatePhase.checking;
                  });
                  unawaited(_run());
                }
              : _accept,
          child: Text(
            _phase == _UpdatePhase.failed
                ? (zh ? '重试' : 'Retry')
                : primaryLabel,
            textAlign: TextAlign.center,
          ),
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
