import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';

const _minSpeedScale = 8 * 1024.0;

const _chartBleed = 3.0;

enum TrafficDirection {
  upload,
  download;

  num of(Traffic traffic) => this == upload ? traffic.up : traffic.down;

  Glyph get glyph => this == upload ? AppGlyphs.arrowUp : AppGlyphs.arrowDown;

  Color colorOf(BuildContext context) => this == upload
      ? DashboardColors.of(context).series2
      : context.colorScheme.primary;

  Color glyphColorOf(BuildContext context) => this == upload
      ? context.colorScheme.onSurfaceVariant
      : context.colorScheme.primary;

  String labelOf(BuildContext context) => this == upload
      ? context.appLocalizations.upload
      : context.appLocalizations.download;
}

String _speedUnit(TrafficShow show) => '${show.unit}/s';

class _Figure extends StatelessWidget {
  const _Figure({
    required this.show,
    required this.unit,
    required this.style,
    required this.unitStyle,
  });

  final TrafficShow show;
  final String unit;
  final AppTextStyle style;
  final AppTextStyle unitStyle;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: show.value,
            style: DashboardText.figure(context, style),
          ),
          TextSpan(
            text: ' $unit',
            style: DashboardText.unit(context, unitStyle),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.clip,
    );
  }
}

/// The zero line is the chart's bottom: a card lets the chart bleed past its
/// edge so idle traffic, or none sampled yet, leaves no line.
class SpeedChart extends StatelessWidget {
  const SpeedChart({
    super.key,
    required this.direction,
    required this.traffics,
    this.color,
  });

  final TrafficDirection direction;
  final FixedList<Traffic> traffics;

  /// Overrides the direction's own color. The desktop speed cards keep
  /// the default, one direction per card, so they never need it; the
  /// status card's backdrop stacks both directions, so it does.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      values: [
        for (final traffic in traffics.list) direction.of(traffic).toDouble(),
      ],
      revision: traffics.revision,
      capacity: traffics.maxLength,
      minScale: _minSpeedScale,
      baselineRatio: 1,
      color: color ?? direction.colorOf(context),
    );
  }
}

/// The upload or the download on its own desktop card.
class SpeedCard extends ConsumerWidget {
  const SpeedCard({super.key, required this.direction});

  final TrafficDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = DashboardDensityScope.of(context);
    final compact = density.isCompact;
    final scale = DashboardDensityScope.scaleOf(context);
    final padding = dashboardCardPadding(density);
    final appLocalizations = context.appLocalizations;
    final traffics = ref.watch(trafficsProvider);
    final total = ref.watch(
      totalTrafficProvider.select((state) => direction.of(state)),
    );
    final current = direction.of(traffics.list.safeLast(const Traffic()));
    final peak = traffics.list.fold<num>(
      0,
      (peak, traffic) => math.max(peak, direction.of(traffic)),
    );
    final speed = current.traffic;
    return DashboardCard(
      padding: EdgeInsets.zero,
      semanticLabel: direction.labelOf(context),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -_chartBleed,
            right: -_chartBleed,
            bottom: -_chartBleed,
            height: compact ? 62 : 88,
            child: RepaintBoundary(
              child: SpeedChart(direction: direction, traffics: traffics),
            ),
          ),
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 24 * scale,
                  child: Row(
                    spacing: 8,
                    children: [
                      GlyphIcon(
                        direction.glyph,
                        size: 18,
                        color: direction.glyphColorOf(context),
                      ),
                      Text(
                        direction.labelOf(context),
                        maxLines: 1,
                        style: DashboardText.cardTitle(context),
                      ),
                      Expanded(
                        child: Text(
                          appLocalizations.trafficPeak(
                            '${dashboardTraffic(peak)}/s',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: DashboardText.label(context),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 6 : 10),
                _Figure(
                  show: speed,
                  unit: _speedUnit(speed),
                  style: compact
                      ? AppTextStyle.title1
                      : AppTextStyle.largeTitle,
                  unitStyle: AppTextStyle.subheadline,
                ),
                const SizedBox(height: 2),
                Text(
                  appLocalizations.trafficTotal(dashboardTraffic(total)),
                  maxLines: 1,
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
