import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/common.dart';
import 'package:skyward/providers/action.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/providers/config.dart';
import 'package:skyward/state.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeveloperView extends ConsumerWidget {
  const DeveloperView({super.key});

  Widget _getDeveloperList(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    return generateSection(
      title: appLocalizations.options,
      items: [
        ListItem(
          title: Text(appLocalizations.messageTest),
          onTap: () {
            for (final level in MessageLevel.values) {
              context.showNotifier(
                '${level.name}: ${appLocalizations.messageTestTip}',
                level: level,
              );
            }
          },
        ),
        ListItem(
          title: Text(appLocalizations.logsTest),
          onTap: () {
            for (int i = 0; i < 1000; i++) {
              ref
                  .read(logsProvider.notifier)
                  .add(
                    Log.app(
                      '[$i]${generateRandomString(maxLength: 200, minLength: 20)}',
                    ),
                  );
            }
          },
        ),
        if (globalState.canCrashCore)
          ListItem(
            title: Text(appLocalizations.crashTest),
            onTap: () async {
              final coreAction = ref.read(coreActionProvider.notifier);
              final res = await dialogs.showMessage(
                message: TextSpan(text: appLocalizations.confirmForceCrashCore),
                destructive: true,
              );
              if (res != true) {
                return;
              }
              unawaited(coreAction.crash());
            },
          ),
        ListItem(
          title: Text(appLocalizations.clearData),
          onTap: () async {
            final storeAction = ref.read(storeActionProvider.notifier);
            final res = await dialogs.showMessage(
              message: TextSpan(text: appLocalizations.confirmClearAllData),
              destructive: true,
              confirmText: appLocalizations.clearData,
            );
            if (res != true) {
              return;
            }
            await storeAction.handleClear();
          },
        ),
        ListItem(
          title: Text(appLocalizations.pruneCache),
          onTap: () async {
            await ref.read(storeActionProvider.notifier).shakingStore();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, ref) {
    final appLocalizations = context.appLocalizations;
    final enable = ref.watch(
      appSettingProvider.select((state) => state.developerMode),
    );
    return BaseScaffold(
      title: appLocalizations.developerMode,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.cardTopPadding,
          bottom: 16 + context.bottomInset,
        ),
        children: [
          generateSection(
            leadingGap: false,
            items: [
              ListItem.toggle(
                title: Text(appLocalizations.developerMode),
                value: enable,
                onChanged: (value) {
                  ref
                      .read(appSettingProvider.notifier)
                      .update((state) => state.copyWith(developerMode: value));
                },
              ),
            ],
          ),
          _getDeveloperList(context, ref),
        ],
      ),
    );
  }
}
