import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/views/dashboard/widgets/card.dart';
import 'package:skyward/views/dashboard/widgets/app_usage_sheet.dart';
import 'package:skyward/views/traffic_statistics/traffic_statistics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _UsageTab { traffic, app }

/// One card for both traffic and per-app usage, with a segmented switch. The
/// figure belongs to the selected tab and opens that tab's full view.
class UsageCard extends ConsumerStatefulWidget {
  const UsageCard({super.key});

  @override
  ConsumerState<UsageCard> createState() => _UsageCardState();
}

class _UsageCardState extends ConsumerState<UsageCard> {
  _UsageTab _tab = _UsageTab.traffic;

  String _figureFor(_UsageTab tab) {
    if (tab == _UsageTab.traffic) {
      final stats = ref.watch(
        trafficStatisticsProvider(TrafficPeriod.day, TrafficRankKind.domain),
      );
      final total = stats.value;
      return total == null
          ? '—'
          : (total.totalUpload + total.totalDownload).traffic.show;
    }
    final stats = ref.watch(appUsageProvider(AppUsagePeriod.today));
    final total = stats.value;
    return total == null
        ? '—'
        : (total.totalUpload + total.totalDownload).traffic.show;
  }

  void _open() {
    if (_tab == _UsageTab.traffic) {
      BaseNavigator.push(context, const TrafficStatisticsView());
    } else {
      showSheet(context: context, builder: (_) => const AppUsageSheet());
    }
  }

  @override
  Widget build(BuildContext context) {
    final figure = _figureFor(_tab);
    final label = _tab == _UsageTab.traffic
        ? context.appLocalizations.trafficUsage
        : context.appLocalizations.usageStats;
    return DashboardCard(
      semanticLabel: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCardHeader(
            glyph: _tab == _UsageTab.traffic
                ? AppGlyphs.connections
                : AppGlyphs.dataUsage,
            title: label,
          ),
          const SizedBox(height: 10),
          SegmentedControl<_UsageTab>(
            segments: [
              (_UsageTab.traffic, context.appLocalizations.trafficUsage),
              (_UsageTab.app, context.appLocalizations.usageStats),
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
                  context.appLocalizations.today,
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
