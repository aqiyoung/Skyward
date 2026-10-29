import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/action.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/providers/config.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/widgets/config_item.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What this page does, and the one choice beside it: a backup of everything
/// the app keeps on this device, a way to put it back, and the strategy that
/// decides how a restore meets what is already here — all three on one card,
/// because the strategy is only ever read as part of the restore.
///
/// The cloud half is gone. A backup that needs an account to hold it is a
/// service, and this app does not run one; the rows that stayed are the ones
/// that work with nothing but the phone.
class BackupAndRestore extends ConsumerWidget {
  const BackupAndRestore({super.key});

  Future<void> _run({
    required String title,
    required String successMessage,
    required Future<bool> Function() task,
  }) async {
    final res = await globalState.loadingRun<bool>(
      task,
      tag: LoadingTag.backup_restore,
      title: title,
    );
    if (res != true) return;
    unawaited(
      dialogs.showAlert(
        title: title,
        message: TextSpan(text: successMessage),
      ),
    );
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    return _run(
      title: appLocalizations.backup,
      successMessage: appLocalizations.backupSuccess,
      task: () => ref
          .read(backupActionProvider.notifier)
          .backup((archivePath) async {
            final savedPath = await picker.saveFileWithPath(
              getBackupFileName(),
              archivePath,
            );
            return savedPath != null;
          }),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final appLocalizations = context.appLocalizations;
    final option = await dialogs.showCommonDialog<RestoreOption>(
      child: const RestoreOptionsDialog(),
    );
    if (option == null || !context.mounted) return;
    final file = await picker.pickerFile();
    final path = file?.path;
    if (path == null || !context.mounted) return;
    await _run(
      title: appLocalizations.restore,
      successMessage: appLocalizations.restoreSuccess,
      task: () => ref
          .read(backupActionProvider.notifier)
          .restore(option, (_) async => path),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final isLoading = ref.watch(loadingProvider(LoadingTag.backup_restore));
    return CommonScaffold(
      isLoading: isLoading,
      title: appLocalizations.backupAndRestore,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          // The card opens on a section gap of its own, so the body leaves
          // the bar's height alone rather than adding a second gap over it.
          top: context.sectionTopPadding,
          bottom: 16 + context.bottomInset,
        ),
        children: [
          // One card, three rows: the two things the page does and the one
          // choice they both stand on. The strategy was a card of its own
          // under a label, which made a one-row setting look like a second
          // page; it belongs to the buttons it decides for.
          generateSection(
            items: [
              ListItem(
                onTap: () {
                  _backup(context, ref);
                },
                title: Text(appLocalizations.backup),
              ),
              ListItem(
                onTap: () {
                  _restore(context, ref);
                },
                title: Text(appLocalizations.restore),
              ),
              ConfigOptionsItem<RestoreStrategy>(
                title: (l) => l.restoreStrategy,
                options: RestoreStrategy.values,
                textBuilder: (strategy) => strategy.label,
                selector: appSettingProvider.select(
                  (state) => state.restoreStrategy,
                ),
                onChanged: (ref, value) => ref
                    .read(appSettingProvider.notifier)
                    .update((state) => state.copyWith(restoreStrategy: value)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RestoreOptionsDialog extends StatefulWidget {
  const RestoreOptionsDialog({super.key});

  @override
  State<RestoreOptionsDialog> createState() => _RestoreOptionsDialogState();
}

class _RestoreOptionsDialogState extends State<RestoreOptionsDialog> {
  void _handleOnTab(RestoreOption? option) {
    if (option == null) return;
    Navigator.of(context).pop(option);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonDialog(
      title: appLocalizations.restore,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Wrap(
        children: [
          ListItem(
            onTap: () {
              _handleOnTab(RestoreOption.onlyProfiles);
            },
            title: Text(appLocalizations.restoreOnlyConfig),
          ),
          ListItem(
            onTap: () {
              _handleOnTab(RestoreOption.all);
            },
            title: Text(appLocalizations.restoreAllData),
          ),
        ],
      ),
    );
  }
}
