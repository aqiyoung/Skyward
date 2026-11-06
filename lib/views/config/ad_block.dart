import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/features/features.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The ad-block module: one switch, and the list it stands behind.
///
/// The rules live in `features/ad_block` and are put in front of every profile's
/// own by the config builder, so this page only has to say whether they go in
/// and what they are.
class AdBlockView extends ConsumerWidget {
  const AdBlockView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final enabled = ref.watch(
      appSettingProvider.select((state) => state.adBlock),
    );
    return BaseScaffold(
      rowSeparators: false,
      title: appLocalizations.rulePresetAdBlock,
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
                title: Text(appLocalizations.rulePresetAdBlock),
                subtitle: Text(appLocalizations.adBlockDescription),
                value: enabled,
                onChanged: (value) {
                  ref
                      .read(appSettingProvider.notifier)
                      .update((state) => state.copyWith(adBlock: value));
                  // The rules travel inside the generated config, so a core
                  // that is already running only sees the change once the
                  // profile is applied again.
                  unawaited(
                    ref
                        .read(setupActionProvider.notifier)
                        .applyProfile(force: true),
                  );
                },
              ),
            ],
          ),
          generateSection(
            items: [
              ListItem(
                title: Text(appLocalizations.rules),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final raw in adBlockRules)
                      Text(
                        raw,
                        style: AppTextStyle.footnote
                            .of(context)
                            .toJetBrainsMono
                            .copyWith(color: context.colorScheme.tertiary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
