import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/views/traffic_statistics/traffic_statistics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';

/// A dashboard card that opens the full traffic-statistics page. Shows today's
/// total as a quiet summary so the card earns its place before being tapped.
class TrafficUsageCard extends ConsumerWidget {
  const TrafficUsageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(
      trafficStatisticsProvider(TrafficPeriod.day, TrafficRankKind.domain),
    );
    final total = stats.value;
    final figure = total == null
        ? '—'
        : (total.totalUpload + total.totalDownload).traffic.show;

    return DashboardCard(
      semanticLabel: context.appLocalizations.trafficUsage,
      onTap: () => BaseNavigator.push(context, const TrafficStatisticsView()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.connections,
            title: context.appLocalizations.trafficUsage,
            chevron: true,
          ),
          const SizedBox(height: 12),
          Text(
            figure,
            style: DashboardText.figure(context, AppTextStyle.title1),
          ),
          const SizedBox(height: 4),
          Text(
            context.appLocalizations.today,
            style: DashboardText.label(context),
          ),
        ],
      ),
    );
  }
}
