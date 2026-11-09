import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The iOS Large Title that leads the mobile dashboard. It gathers the two
/// facts a reader glances at first -- whether the tunnel is up, and for how
/// long -- into one line under the title, instead of leaving them to be found
/// scattered across cards.
///
/// Shown by the page's own scrolling body as a fixed heading: it is part of
/// the page, not a bar title, and carries no compact copy that would fade in
/// or float over the content when the page scrolls. It simply scrolls away
/// with the cards beneath it.
class DashboardLargeTitle extends ConsumerWidget {
  const DashboardLargeTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final colors = DashboardColors.of(context);
    final status = ref.watch(coreStatusProvider);
    final runTime = ref.watch(runTimeProvider);

    final (String label, Color tone) = switch (status) {
      CoreStatus.connected => (appLocalizations.connected, colors.ok),
      CoreStatus.connecting => (appLocalizations.connecting, colors.warn),
      CoreStatus.disconnected => (
        appLocalizations.disconnected,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 6, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizations.dashboard,
            style: AppTextStyle.largeTitle.of(context, emphasized: true),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // A soft dot behind the status glyph, tinted by the state so the
              // line reads at a glance without a loud chip or a coloured card.
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tone,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subheadline
                      .of(context)
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
              if (status == CoreStatus.connected) ...[
                const SizedBox(width: 8),
                Text(
                  '·',
                  style: AppTextStyle.subheadline
                      .of(context)
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Text(
                  getTimeText(runTime),
                  style: DashboardText.value(
                    context,
                    AppTextStyle.subheadline,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
