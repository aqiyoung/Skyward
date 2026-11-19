import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The dashboard's card surface, distinct from the page in both themes.
ShapeDecoration panelDecoration(BuildContext context, double radius) {
  final cs = context.colorScheme;
  final isLight = cs.brightness == Brightness.light;
  final card = isLight
      ? const Color(0xFFFFFFFF)
      : SurfaceLevel.card.colorOf(cs);
  return ShapeDecoration(
    color: card,
    shape: AppShape.all(radius),
    shadows: DashboardShadows.e1(context),
  );
}

/// A full-page traffic statistics view: hourly trend, proxy/direct split,
/// rule-hit distribution, a traffic ranking and running time. Opened from
/// the dashboard's traffic card.
///
/// Layout: one grouped card per section with hairline-separated compact
/// rows, instead of a floating card per row. Ranking bars are scaled
/// relative to the top entry so small shares stay visible; the share of
/// the total is kept as a caption.
class TrafficStatisticsView extends ConsumerStatefulWidget {
  const TrafficStatisticsView({super.key});

  @override
  ConsumerState<TrafficStatisticsView> createState() =>
      _TrafficStatisticsViewState();
}

class _TrafficStatisticsViewState extends ConsumerState<TrafficStatisticsView> {
  TrafficPeriod _period = TrafficPeriod.day;
  TrafficRankKind _kind = TrafficRankKind.domain;

  void _refresh() {
    ref.invalidate(trafficStatisticsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(trafficStatisticsProvider(_period, _kind));
    final range = ref.watch(trafficRangeProvider);
    final groups = ref.watch(
      proxiesListStateProvider.select((state) => state.groups),
    );
    final groupIcons = <String, String>{for (final g in groups) g.name: g.icon};
    final cs = context.colorScheme;

    return CommonScaffold(
      title: context.appLocalizations.trafficUsage,
      iconActions: [
        IconButtonData(
          glyph: AppGlyphs.refresh,
          tooltip: '刷新',
          onPressed: _refresh,
        ),
      ],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            SegmentedControl<TrafficPeriod>(
              segments: const [
                (TrafficPeriod.day, '日'),
                (TrafficPeriod.week, '周'),
                (TrafficPeriod.month, '月'),
              ],
              value: _period,
              onChanged: (v) => setState(() => _period = v),
            ),
            const SizedBox(height: 12),
            _DateStrip(period: _period, range: range),
            const SizedBox(height: 12),
            stats.when(
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OverviewCard(data: data),
                  const SizedBox(height: 12),
                  _TrendCard(
                    data: data,
                    downloadColor: cs.primary,
                    uploadColor: cs.tertiary,
                  ),
                  const SizedBox(height: 16),
                  const _SectionLabel('规则命中'),
                  const SizedBox(height: 8),
                  _RuleHits(hits: data.ruleHits),
                  const SizedBox(height: 16),
                  const _SectionLabel('流量排行'),
                  const SizedBox(height: 8),
                  SegmentedControl<TrafficRankKind>(
                    segments: const [
                      (TrafficRankKind.domain, '域名'),
                      (TrafficRankKind.rule, '规则'),
                      (TrafficRankKind.node, '节点'),
                      (TrafficRankKind.config, '配置'),
                    ],
                    value: _kind,
                    onChanged: (v) => setState(() => _kind = v),
                  ),
                  const SizedBox(height: 8),
                  _Ranking(
                    items: data.ranking,
                    kind: _kind,
                    groupIcons: groupIcons,
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
      ),
    );
  }
}

/// Adaptive percent text: whole numbers once the share is big enough for
/// them to be meaningful, one decimal below that.
String _pct(double p) {
  final v = p * 100;
  return v >= 9.95 ? '${v.round()}%' : '${v.toStringAsFixed(1)}%';
}

class _Hairline extends StatelessWidget {
  const _Hairline({required this.color, this.inset = 16});

  final Color color;
  final double inset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: inset),
    child: Container(height: 1, color: color),
  );
}

class _DateStrip extends ConsumerWidget {
  const _DateStrip({required this.period, required this.range});

  final TrafficPeriod period;
  final DateTime range;

  String _label() => switch (period) {
    TrafficPeriod.day =>
      '${range.year}-${range.month.toString().padLeft(2, '0')}-${range.day.toString().padLeft(2, '0')}',
    TrafficPeriod.week => '${range.month}/${range.day} 起',
    TrafficPeriod.month => '${range.year}/${range.month}',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const GlyphIcon(AppGlyphs.chevronBack),
          tooltip: '上一段',
          onPressed: () =>
              ref.read(trafficRangeProvider.notifier).shift(period, -1),
        ),
        Text(_label(), style: AppTextStyle.body.of(context)),
        IconButton(
          icon: const GlyphIcon(AppGlyphs.chevronForward),
          tooltip: '下一段',
          onPressed: () =>
              ref.read(trafficRangeProvider.notifier).shift(period, 1),
        ),
      ],
    );
  }
}

class _OverviewCard extends ConsumerWidget {
  const _OverviewCard({required this.data});

  final TrafficStatistics data;

  // runTimeProvider is the already-elapsed milliseconds, not a timestamp.
  String _duration(int? elapsedMs) {
    if (elapsedMs == null || elapsedMs <= 0) return '—';
    final minutes = Duration(milliseconds: elapsedMs).inMinutes;
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours 小时 ${minutes % 60} 分';
    return '${hours ~/ 24} 天 ${hours % 24} 小时';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final splitTotal = data.proxyBytes + data.directBytes;
    final proxyPct = splitTotal == 0 ? 0.0 : data.proxyBytes / splitTotal;
    final runMs = ref.watch(runTimeProvider);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: panelDecoration(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlyphIcon(AppGlyphs.connections, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                '流量概览',
                style: AppTextStyle.subheadline.of(context, emphasized: true),
              ),
              const Spacer(),
              Text(
                '${data.connectionCount} 条连接',
                style: AppTextStyle.caption1
                    .of(context)
                    .copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('总流量', style: AppTextStyle.caption1.of(context)),
          Text(
            (data.totalUpload + data.totalDownload).traffic.show,
            style: AppTextStyle.title1.of(context),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FlowStat(
                dotColor: cs.primary,
                label: '下载',
                bytes: data.totalDownload,
              ),
              const SizedBox(width: 28),
              _FlowStat(
                dotColor: cs.tertiary,
                label: '上传',
                bytes: data.totalUpload,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SplitBar(
            proxyFraction: proxyPct,
            proxyColor: cs.primary,
            directColor: cs.onSurfaceVariant.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '代理 ${data.proxyBytes.traffic.show} · ${_pct(proxyPct)}',
                style: AppTextStyle.caption1.of(context),
              ),
              const Spacer(),
              Text(
                '直连 ${data.directBytes.traffic.show} · ${_pct(1 - proxyPct)}',
                style: AppTextStyle.caption1
                    .of(context)
                    .copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: cs.surfaceContainerHighest),
          const SizedBox(height: 12),
          Row(
            children: [
              GlyphIcon(AppGlyphs.clock, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('累计运行', style: AppTextStyle.caption1.of(context)),
              const SizedBox(width: 8),
              Text(
                _duration(runMs),
                style: AppTextStyle.body.of(context, emphasized: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowStat extends StatelessWidget {
  const _FlowStat({
    required this.dotColor,
    required this.label,
    required this.bytes,
  });

  final Color dotColor;
  final String label;
  final int bytes;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: ShapeDecoration(color: dotColor, shape: AppShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: AppTextStyle.caption1.of(context)),
      const SizedBox(width: 6),
      Text(
        bytes.traffic.show,
        style: AppTextStyle.body.of(context, emphasized: true),
      ),
    ],
  );
}

/// A two-segment horizontal bar: proxy share filled from the start, the
/// rest is direct traffic. Reads clearly even at 100% / 0%, where a ring
/// shows nothing.
class _SplitBar extends StatelessWidget {
  const _SplitBar({
    required this.proxyFraction,
    required this.proxyColor,
    required this.directColor,
  });

  final double proxyFraction;
  final Color proxyColor;
  final Color directColor;

  @override
  Widget build(BuildContext context) => ClipRSuperellipse(
    borderRadius: BorderRadius.circular(999),
    child: Container(
      height: 10,
      color: directColor,
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: proxyFraction.clamp(0.0, 1.0),
        child: Container(color: proxyColor),
      ),
    ),
  );
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.data,
    required this.downloadColor,
    required this.uploadColor,
  });

  final TrafficStatistics data;
  final Color downloadColor;
  final Color uploadColor;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    TrafficHourPoint? peak;
    for (final p in data.trend) {
      if (peak == null ||
          (p.download + p.upload) > (peak.download + peak.upload)) {
        peak = p;
      }
    }
    final hasData = peak != null && (peak.download + peak.upload) > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlyphIcon(AppGlyphs.speed, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                '流量趋势',
                style: AppTextStyle.subheadline.of(context, emphasized: true),
              ),
              const Spacer(),
              _LegendDot(color: downloadColor, label: '下载'),
              const SizedBox(width: 10),
              _LegendDot(color: uploadColor, label: '上传'),
            ],
          ),
          if (hasData) ...[
            const SizedBox(height: 4),
            Text(
              '峰值 ${peak.hour.hour}:00 · '
              '${(peak.download + peak.upload).traffic.show}',
              style: AppTextStyle.caption2
                  .of(context)
                  .copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          if (hasData)
            TrafficBarChart(
              points: [
                for (final p in data.trend)
                  (hour: p.hour, download: p.download, upload: p.upload),
              ],
              downloadColor: downloadColor,
              uploadColor: uploadColor,
              labelColor: context.colorScheme.onSurfaceVariant,
              height: 150,
            )
          else
            const SizedBox(height: 150, child: Center(child: Text('暂无数据'))),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: ShapeDecoration(color: color, shape: AppShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyle.caption2.of(context)),
    ],
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyle.subheadline.of(context, emphasized: true));
}

class _RuleHits extends StatelessWidget {
  const _RuleHits({required this.hits});

  final List<RuleHit> hits;

  @override
  Widget build(BuildContext context) {
    if (hits.isEmpty) {
      return const Text('暂无数据');
    }
    final cs = context.colorScheme;
    final shown = hits.take(8).toList();
    final totalHits = hits.fold<int>(0, (sum, h) => sum + h.hits);
    final top = hits.first;
    return Container(
      decoration: panelDecoration(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                RingChart(
                  segments: [for (final h in hits.take(5)) h.percent],
                  center: '$totalHits',
                  subtitle: '次命中',
                  size: 76,
                  strokeWidth: 7,
                  trackColor: cs.surfaceContainerHighest,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        top.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.body.of(context, emphasized: true),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '占命中流量 ${_pct(top.percent)} · ${top.hits} 次',
                        style: AppTextStyle.caption1
                            .of(context)
                            .copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '共 ${hits.length} 条规则有命中',
                        style: AppTextStyle.caption2
                            .of(context)
                            .copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Hairline(color: cs.surfaceContainerHighest),
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) _Hairline(color: cs.surfaceContainerHighest),
            _RuleRow(hit: shown[i]),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.hit});

  final RuleHit hit;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hit.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.body.of(context, emphasized: true),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _pct(hit.percent),
                style: AppTextStyle.body.of(context, emphasized: true),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${hit.hits} 次 · ↑ ${hit.upload.traffic.show} '
            '↓ ${hit.download.traffic.show}',
            style: AppTextStyle.caption2
                .of(context)
                .copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          UsageBar(
            fraction: hit.percent,
            height: 4,
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.55)],
            ),
            trackColor: cs.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}

class _Ranking extends StatelessWidget {
  const _Ranking({
    required this.items,
    required this.kind,
    required this.groupIcons,
  });

  final List<TrafficRankItem> items;
  final TrafficRankKind kind;

  /// Group name -> the icon its config declares ('' when it declares none).
  final Map<String, String> groupIcons;

  Glyph _glyph() => switch (kind) {
    TrafficRankKind.domain => AppGlyphs.connections,
    TrafficRankKind.rule => AppGlyphs.filter,
    TrafficRankKind.node => AppGlyphs.proxies,
    TrafficRankKind.config => AppGlyphs.settings,
  };

  /// The 22dp leading slot of a ranking row: for the node ranking, the
  /// group's own official logo (the same resolution the proxies page
  /// uses: the icon its config declares wins, then the bundled service
  /// marks); other kinds keep their generic glyph.
  Widget _leading(BuildContext context, TrafficRankItem item) {
    final cs = context.colorScheme;
    final glyph = SizedBox.square(
      dimension: 22,
      child: Center(
        child: GlyphIcon(_glyph(), size: 16, color: cs.onSurfaceVariant),
      ),
    );
    return switch (kind) {
      TrafficRankKind.node => _ItemIcon(
        src: GroupIconSource.of(
          name: item.key,
          icon: groupIcons[item.key] ?? '',
        ),
        fallback: GroupBadge(name: item.key),
      ),
      _ => glyph,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('暂无数据')),
      );
    }
    final cs = context.colorScheme;
    final shown = items.take(30).toList();
    final maxTotal = shown.fold<int>(
      0,
      (m, e) => math.max(m, e.upload + e.download),
    );
    return Container(
      decoration: panelDecoration(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) _Hairline(color: cs.surfaceContainerHighest),
            _RankRow(
              index: i,
              item: shown[i],
              leading: _leading(context, shown[i]),
              relativeFraction: maxTotal == 0
                  ? 0
                  : (shown[i].upload + shown[i].download) / maxTotal,
            ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// A ranking row's icon slot: the item's own picture at 22dp, softly
/// rounded, with [fallback] shown while it loads or when it cannot be
/// fetched.
class _ItemIcon extends StatelessWidget {
  const _ItemIcon({required this.src, required this.fallback});

  final String src;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => ClipRSuperellipse(
    borderRadius: BorderRadius.circular(6),
    child: SizedBox.square(
      dimension: 22,
      child: IconTheme.merge(
        data: const IconThemeData(size: 22),
        child: CommonTargetIcon(src: src, fallback: fallback),
      ),
    ),
  );
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.index,
    required this.item,
    required this.leading,
    required this.relativeFraction,
  });

  final int index;
  final TrafficRankItem item;
  final Widget leading;
  final double relativeFraction;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final total = item.upload + item.download;
    final isTop = index < 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${index + 1}',
                  style: AppTextStyle.caption1
                      .of(context)
                      .copyWith(
                        color: isTop ? cs.primary : cs.onSurfaceVariant,
                        fontWeight: isTop ? FontWeight.w700 : FontWeight.w400,
                      ),
                ),
              ),
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.key.isEmpty ? '未知' : item.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.body.of(context, emphasized: true),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                total.traffic.show,
                style: AppTextStyle.body.of(context, emphasized: true),
              ),
            ],
          ),
          const SizedBox(height: 6),
          UsageBar(
            fraction: relativeFraction,
            height: 4,
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.55)],
            ),
            trackColor: cs.surfaceContainerHighest,
          ),
          const SizedBox(height: 4),
          Text(
            '占 ${item.percent.toStringAsFixed(1)}% · '
            '↑ ${item.upload.traffic.show} ↓ ${item.download.traffic.show}',
            style: AppTextStyle.caption2
                .of(context)
                .copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
