import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app_usage_sheet.dart';
import 'card.dart';

/// A dashboard card that opens the per-app "使用详情" sheet. Shows today's
/// total as a quiet summary so the card earns its place before being tapped.
class AppUsageCard extends ConsumerWidget {
  const AppUsageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(appUsageProvider(AppUsagePeriod.today));
    final total = stats.value;
    final figure = total == null
        ? '—'
        : (total.totalUpload + total.totalDownload).traffic.show;

    return DashboardCard(
      semanticLabel: context.appLocalizations.usageStats,
      onTap: () =>
          showSheet(context: context, builder: (_) => const AppUsageSheet()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.dataUsage,
            title: context.appLocalizations.usageStats,
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
