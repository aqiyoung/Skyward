import 'package:skyward/common/common.dart';
import 'package:skyward/database/traffic_usage.dart';
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
/// total as a quiet summary so the card earns its place before being tapped —
/// plus the quota forecast: the recent pace, when the plan will run out, and
/// how early that is compared with the plan's expiry.
class TrafficUsageCard extends ConsumerWidget {
  const TrafficUsageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(
      trafficStatisticsProvider(TrafficPeriod.day, TrafficRankKind.domain),
    );
    final profile = ref.watch(currentProfileProvider);
    final total = stats.value;
    final figure = total == null
        ? '—'
        : (total.totalUpload + total.totalDownload).traffic.show;

    final quota = profile?.subscriptionInfo?.total ?? 0;
    final expireMs = profile?.subscriptionInfo?.expire ?? 0;
    final forecast = total == null
        ? const TrafficForecast(TrafficForecastKind.gathering)
        : forecastTraffic(
            days: usageDaysFromTrend(total.trend),
            used: total.totalUpload + total.totalDownload,
            total: quota,
            now: DateTime.now(),
            expiry: expireMs > 0
                ? DateTime.fromMillisecondsSinceEpoch(expireMs)
                : null,
          );

    final cs = context.colorScheme;
    return DashboardCard(
      semanticLabel: context.appLocalizations.trafficUsage,
      onTap: () => BaseNavigator.push(context, const TrafficStatisticsView()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.connections,
            title: context.appLocalizations.trafficUsage,
            chevron: true,
          ),
          Text(
            figure,
            style: DashboardText.figure(context, AppTextStyle.title1),
          ),
          Text(context.appLocalizations.today,
              style: DashboardText.label(context)),
          if (forecast.kind == TrafficForecastKind.depleted)
            Text(context.appLocalizations.trafficDepleted,
                style: DashboardText.label(context)),
          if (forecast.kind == TrafficForecastKind.gathering)
            Text(
              context.appLocalizations.trafficGathering,
              style: DashboardText.label(context).copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          if (forecast.perDay != null)
            Text(
              context.appLocalizations.trafficPerDay(
                      forecast.perDay!.traffic.show) +
                  (forecast.daysEarly > 0
                      ? context.appLocalizations.trafficRunOut(
                          forecast.daysEarly)
                      : ''),
              style: DashboardText.label(context).copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
