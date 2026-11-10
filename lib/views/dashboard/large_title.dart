import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The status line under the dashboard's large title: whether the tunnel is
/// up, and for how long. The heading itself is drawn by the shared
/// PageLargeTitle block -- the same fixed heading every other phone tab uses
/// -- so the home screen no longer scrolls its title away under the status
/// bar. This line is handed to that block as its subtitle.
///
/// The run time lives here and nowhere else: the status card below used to
/// repeat it, which read as the same number twice on one screen.
class DashboardStatusLine extends ConsumerWidget {
  const DashboardStatusLine({super.key});

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
      padding: const EdgeInsetsDirectional.only(top: 10),
      child: Row(
        children: [
          // A soft dot behind the status glyph, tinted by the state so the
          // line reads at a glance without a loud chip or a coloured card.
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
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
    );
  }
}
