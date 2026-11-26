import 'package:skyward/common/common.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The full list of ad domains blocked in the last seven days. Opened from the
/// blocked tab of [UsageCard]; the same provider feeds the settings page, so
/// the two can never disagree.
class AdBlockHitsSheet extends ConsumerWidget {
  const AdBlockHitsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final hits = ref.watch(adBlockHitListProvider);
    final unit = context.appLocalizations.hitsUnit;
    return CommonScaffold(
      title: zh ? '广告拦截 · 近 7 天' : 'Blocked ads · last 7 days',
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          context.contentTopPadding,
          16,
          context.bottomInset,
        ),
        children: [
          generateSection(
            leadingGap: false,
            items: [
              ...hits.when(
                data: (blocked) => blocked.isEmpty
                    ? [
                        ListItem(
                          title: Text(
                            zh
                                ? '暂无拦截记录，稍后再来看看'
                                : 'No blocked requests yet — check back later',
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
                              '${hit.hits} $unit',
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
        ],
      ),
    );
  }
}
