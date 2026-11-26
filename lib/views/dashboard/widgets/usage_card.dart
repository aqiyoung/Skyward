import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/views/dashboard/widgets/card.dart';
import 'package:skyward/views/dashboard/widgets/ad_block_hits_sheet.dart';
import 'package:skyward/views/dashboard/widgets/app_usage_sheet.dart';
import 'package:skyward/views/traffic_statistics/traffic_statistics.dart';
import 'package:flutter/material.dart' show Localizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _UsageTab { traffic, app, blocked }

/// One card for traffic, per-app usage and ad-block hits, with a segmented
/// switch. The figure belongs to the selected tab and opens that tab's full
/// view. Ad-block hits live here rather than in a card of their own: adding a
/// fourth stats card would only recreate the duplicate-card problem.
class UsageCard extends ConsumerStatefulWidget {
  const UsageCard({super.key});

  @override
  ConsumerState<UsageCard> createState() => _UsageCardState();
}

class _UsageCardState extends ConsumerState<UsageCard> {
  _UsageTab _tab = _UsageTab.traffic;

  String _figureFor(_UsageTab tab) {
    switch (tab) {
      case _UsageTab.traffic:
        final stats = ref.watch(
          trafficStatisticsProvider(TrafficPeriod.day, TrafficRankKind.domain),
        );
        final total = stats.value;
        return total == null
            ? '—'
            : (total.totalUpload + total.totalDownload).traffic.show;
      case _UsageTab.app:
        final stats = ref.watch(appUsageProvider(AppUsagePeriod.today));
        final total = stats.value;
        return total == null
            ? '—'
            : (total.totalUpload + total.totalDownload).traffic.show;
      case _UsageTab.blocked:
        final blocked = ref.watch(adBlockHitListProvider).value;
        if (blocked == null) return '—';
        return '${blocked.fold<int>(0, (sum, hit) => sum + hit.hits)}';
    }
  }

  void _open() {
    switch (_tab) {
      case _UsageTab.traffic:
        BaseNavigator.push(context, const TrafficStatisticsView());
      case _UsageTab.app:
        showSheet(context: context, builder: (_) => const AppUsageSheet());
      case _UsageTab.blocked:
        showSheet(context: context, builder: (_) => const AdBlockHitsSheet());
    }
  }

  @override
  Widget build(BuildContext context) {
    final figure = _figureFor(_tab);
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final label = switch (_tab) {
      _UsageTab.traffic => context.appLocalizations.trafficUsage,
      _UsageTab.app => context.appLocalizations.usageStats,
      _UsageTab.blocked => zh ? '广告拦截' : 'Ads blocked',
    };
    final caption = switch (_tab) {
      _UsageTab.traffic || _UsageTab.app => context.appLocalizations.today,
      _UsageTab.blocked => () {
        final blocked = ref.watch(adBlockHitListProvider).value;
        return blocked == null
            ? (zh ? '近 7 天' : 'Last 7 days')
            : (zh
                ? '近 7 天 · ${blocked.length} 个域名'
                : 'Last 7 days · ${blocked.length} domains');
      }(),
    };
    return DashboardCard(
      semanticLabel: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCardHeader(
            glyph: switch (_tab) {
              _UsageTab.traffic => AppGlyphs.connections,
              _UsageTab.app => AppGlyphs.dataUsage,
              _UsageTab.blocked => AppGlyphs.block,
            },
            title: label,
          ),
          const SizedBox(height: 10),
          SegmentedControl<_UsageTab>(
            segments: [
              (_UsageTab.traffic, context.appLocalizations.trafficUsage),
              (_UsageTab.app, context.appLocalizations.usageStats),
              (_UsageTab.blocked, zh ? '广告拦截' : 'Ads blocked'),
            ],
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _open,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      figure,
                      style: DashboardText.figure(context, AppTextStyle.title1),
                    ),
                    const Spacer(),
                    GlyphIcon(
                      AppGlyphs.chevronForward,
                      size: 20,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: DashboardText.label(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
