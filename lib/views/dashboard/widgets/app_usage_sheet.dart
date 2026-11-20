import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A modal sheet with the per-app traffic breakdown for one period. Opened
/// from [AppUsageCard]. The four tabs are rolling windows, not the dashboard's
/// TrafficPeriod anchored to a selected date.
class AppUsageSheet extends ConsumerStatefulWidget {
  const AppUsageSheet({super.key});

  @override
  ConsumerState<AppUsageSheet> createState() => _AppUsageSheetState();
}

class _AppUsageSheetState extends ConsumerState<AppUsageSheet> {
  AppUsagePeriod _period = AppUsagePeriod.today;

  @override
  void initState() {
    super.initState();
    _ensurePackages();
  }

  /// Ask for the installed-apps permission on first open, then load the app
  /// list so package names can be shown as labels. Off Android this is a no-op.
  Future<void> _ensurePackages() async {
    final action = ref.read(systemActionProvider.notifier);
    if (ref.read(packagesProvider).isEmpty) {
      final granted = await action.isInstalledAppsPermissionGranted();
      if (!mounted) return;
      if (!granted) {
        await action.requestInstalledAppsPermission();
        if (!mounted) return;
      }
      await action.getPackages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final usage = ref.watch(appUsageProvider(_period));
    final cs = context.colorScheme;
    return CommonScaffold(
      title: context.appLocalizations.usageDetails,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          context.contentTopPadding,
          16,
          context.bottomInset,
        ),
        children: [
          SegmentedControl<AppUsagePeriod>(
            segments: [
              (AppUsagePeriod.today, context.appLocalizations.today),
              (AppUsagePeriod.last7Days, context.appLocalizations.last7Days),
              (AppUsagePeriod.thisMonth, context.appLocalizations.thisMonth),
              (AppUsagePeriod.total, context.appLocalizations.total),
            ],
            value: _period,
            onChanged: (v) => setState(() => _period = v),
          ),
          const SizedBox(height: 16),
          usage.when(
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TotalCard(data: data),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GlyphIcon(AppGlyphs.appsList, size: 18, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${context.appLocalizations.app}  ${data.appCount}',
                      style: AppTextStyle.subheadline.of(
                        context,
                        emphasized: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (data.apps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        context.appLocalizations.noData,
                        style: AppTextStyle.body.of(context),
                      ),
                    ),
                  )
                else
                  for (final app in data.apps)
                    _AppRow(
                      app: app,
                      gradient: LinearGradient(
                        colors: [
                          cs.primary,
                          cs.primary.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CommonCircleLoading.page()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(48),
              child: Center(child: Text('$error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.data});

  final AppUsage data;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: cs.surfaceContainerLowest,
        shape: AppShape.all(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.appLocalizations.trafficUsage,
            style: AppTextStyle.caption1.of(context),
          ),
          const SizedBox(height: 6),
          Text(
            (data.totalUpload + data.totalDownload).traffic.show,
            style: AppTextStyle.title1.of(context),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('↑ ${data.totalUpload.traffic.show}'),
              const SizedBox(width: 20),
              Text('↓ ${data.totalDownload.traffic.show}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app, required this.gradient});

  final AppTraffic app;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: cs.surfaceContainerLowest,
        shape: AppShape.all(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PackageIcon(packageName: app.packageName, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.body.of(context, emphasized: true),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '↑ ${app.upload.traffic.show}   ↓ ${app.download.traffic.show}',
                      style: AppTextStyle.caption2.of(context),
                    ),
                  ],
                ),
              ),
              Text(
                '${(app.percent * 100).toStringAsFixed(1)}%',
                style: AppTextStyle.caption1
                    .of(context)
                    .copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          UsageBar(fraction: app.percent, gradient: gradient),
        ],
      ),
    );
  }
}
