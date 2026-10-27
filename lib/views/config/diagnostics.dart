import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/config.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The few facts a reader is asked for when something misbehaves, on one page
/// they can read out or copy, instead of a screenshot of four other screens.
class DiagnosticsView extends ConsumerStatefulWidget {
  const DiagnosticsView({super.key});

  @override
  ConsumerState<DiagnosticsView> createState() => _DiagnosticsViewState();
}

class _DiagnosticsViewState extends ConsumerState<DiagnosticsView> {
  int? _databaseSize;
  int? _tempSize;

  @override
  void initState() {
    super.initState();
    unawaited(_measure());
  }

  Future<void> _measure() async {
    final databaseSize = await pathSize(await appPath.databasePath);
    final tempSize = await pathSize(await appPath.tempPath);
    if (!mounted) {
      return;
    }
    setState(() {
      _databaseSize = databaseSize;
      _tempSize = tempSize;
    });
  }

  String _coreStatusText(AppLocalizations appLocalizations, CoreStatus status) {
    return switch (status) {
      CoreStatus.connected => appLocalizations.connected,
      CoreStatus.connecting => appLocalizations.connecting,
      CoreStatus.disconnected => appLocalizations.disconnected,
    };
  }

  List<(String, String)> _rows(
    AppLocalizations appLocalizations,
    PatchClashConfig clashConfig,
    CoreStatus coreStatus,
  ) {
    return [
      (
        appLocalizations.coreStatus,
        _coreStatusText(appLocalizations, coreStatus),
      ),
      (appLocalizations.mixedPort, '${clashConfig.mixedPort}'),
      (
        appLocalizations.tun,
        clashConfig.tun.enable
            ? appLocalizations.enabled
            : appLocalizations.disabled,
      ),
      (
        appLocalizations.database,
        _databaseSize?.traffic.show ?? appLocalizations.noData,
      ),
      (
        appLocalizations.temporary,
        _tempSize?.traffic.show ?? appLocalizations.noData,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final clashConfig = ref.watch(patchClashConfigProvider);
    final coreStatus = ref.watch(coreStatusProvider);
    final rows = _rows(appLocalizations, clashConfig, coreStatus);
    return BaseScaffold(
      title: appLocalizations.diagnostics,
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(top: context.contentTopPadding, bottom: 16),
        children: [
          generateSection(
            items: [
              ListItem(
                title: const Text(appName),
                trailing: Text(
                  'v${globalState.packageInfo.displayVersion}',
                  style: context.listSubtitleStyle,
                ),
              ),
              for (final (title, value) in rows)
                ListItem(
                  title: Text(title),
                  trailing: Text(value, style: context.listSubtitleStyle),
                ),
            ],
          ),
          const SizedBox(height: 24),
          generateSection(
            items: [
              ListItem(
                title: Text(appLocalizations.copy),
                leading: const IconWell(AppGlyphs.copy),
                onTap: _databaseSize == null ? null : () => _copy(rows),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copy(List<(String, String)> rows) {
    final report = [
      '$appName v${globalState.packageInfo.displayVersion}',
      for (final (title, value) in rows) '$title: $value',
    ].join('\n');
    Clipboard.setData(ClipboardData(text: report));
  }
}
