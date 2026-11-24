import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/database/database.dart';
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
class AdBlockView extends ConsumerStatefulWidget {
  const AdBlockView({super.key});

  @override
  ConsumerState<AdBlockView> createState() => _AdBlockViewState();
}

class _AdBlockViewState extends ConsumerState<AdBlockView> {
  List<AdBlockHit> _hits = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadHits());
  }

  Future<void> _loadHits() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final rows = await database.nativeTrafficDao.between(start, now);
    final hits = adBlockHits(rows);
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final enabled = ref.watch(
      appSettingProvider.select((state) => state.adBlock),
    );
    final zh = Localizations.localeOf(context).languageCode == 'zh';
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
          _hitsSection(zh),
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

  Widget _hitsSection(bool zh) {
    final label = zh ? '拦截记录 · 近 7 天' : 'Blocked · last 7 days';
    if (!_loaded) {
      return generateSection(
        items: [
          ListItem(
            title: Text(label),
            subtitle: Text(zh ? '统计中…' : 'Counting…'),
          ),
        ],
      );
    }
    if (_hits.isEmpty) {
      return generateSection(
        items: [
          ListItem(
            title: Text(label),
            subtitle: Text(
              zh ? '暂无拦截记录' : 'No blocked requests yet',
            ),
          ),
        ],
      );
    }
    return generateSection(
      items: [
        for (final hit in _hits)
          ListItem(
            title: Text(
              hit.domain,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '${hit.hits} ${context.appLocalizations.hitsUnit}',
              style: TextStyle(
                color: context.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
      ],
      title: label,
    );
  }
}
