import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/features/features.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The ad-block module: a switch, the hits it blocked, and the rules behind it.
///
/// The rules live in `features/ad_block` and are put in front of every profile's
/// own by the config builder, so this page only has to say whether they go in,
/// what they blocked, and what they are.
class AdBlockView extends ConsumerWidget {
  const AdBlockView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final enabled = ref.watch(
      appSettingProvider.select((state) => state.adBlock),
    );
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final hits = ref.watch(adBlockHitListProvider);
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
            title: zh ? '拦截记录 · 近 7 天' : 'Blocked · last 7 days',
            items: [
              ...hits.when(
                data: (blocked) => blocked.isEmpty
                    ? [
                        ListItem(
                          title: Text(
                            zh ? '暂无拦截记录' : 'No blocked requests yet',
                          ),
                        ),
                      ]
                    : [
                        for (final hit in blocked)
                          ListItem(
                            title: Text(
                              hit.domain,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '${hit.hits} ${appLocalizations.hitsUnit}',
                              style: TextStyle(
                                color: context.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                loading: () => [
                  ListItem(title: Text(zh ? '统计中…' : 'Counting…')),
                ],
                error: (error, _) => [
                  ListItem(
                    title: Text(
                      zh ? '统计失败：$error' : 'Counting failed: $error',
                      maxLines: 2,
                    ),
                  ),
                ],
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
