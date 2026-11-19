import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A full-page traffic statistics view: hourly trend, proxy/direct split,
/// rule-hit rings, a traffic ranking and running time. Opened from the
/// dashboard's traffic card.
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
    final cs = context.colorScheme;

    return CommonScaffold(
      title: context.appLocalizations.trafficUsage,
      iconActions: [
        IconButtonData(
          glyph: AppGlyphs.refresh,
          tooltip: '刷新',
          onPressed: _refresh,
        ),
        IconButtonData(
          glyph: AppGlyphs.filter,
          tooltip: '排行维度',
          onPressed: () => setState(() {
            _kind = TrafficRankKind
                .values[(_kind.index + 1) % TrafficRankKind.values.length];
          }),
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
                  _Ranking(items: data.ranking, kind: _kind),
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
    final proxyPct = (data.proxyBytes + data.directBytes) == 0
        ? 0.0
        : data.proxyBytes / (data.proxyBytes + data.directBytes);
    final runMs = ref.watch(runTimeProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: cs.surfaceContainerLowest,
        shape: AppShape.all(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GlyphIcon(
                          AppGlyphs.connections,
                          size: 16,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '流量概览',
                          style: AppTextStyle.subheadline.of(
                            context,
                            emphasized: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('总流量', style: AppTextStyle.caption1.of(context)),
                    Text(
                      (data.totalUpload + data.totalDownload).traffic.show,
                      style: AppTextStyle.title1.of(context),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _Pill('↓ ${data.totalDownload.traffic.show}'),
                        _Pill('↑ ${data.totalUpload.traffic.show}'),
                      ],
                    ),
                  ],
                ),
              ),
              RingChart(
                segments: [proxyPct],
                center: '${(proxyPct * 100).round()}%',
                subtitle: '代理',
                size: 84,
                trackColor: cs.surfaceContainerHighest,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: AppGlyphs.clock,
                  label: '累计运行',
                  value: _duration(runMs),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  label: '代理 / 直连',
                  value:
                      '${data.proxyBytes.traffic.show} / ${data.directBytes.traffic.show}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: ShapeDecoration(
      color: context.colorScheme.surfaceContainerHighest,
      shape: AppShape.full,
    ),
    child: Text(text, style: AppTextStyle.caption1.of(context)),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({this.icon, required this.label, required this.value});

  final Glyph? icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: cs.surfaceContainerHighest,
        shape: AppShape.all(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon case final icon?) ...[
                GlyphIcon(icon, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
              ],
              Text(label, style: AppTextStyle.caption2.of(context)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyle.body.of(context, emphasized: true)),
        ],
      ),
    );
  }
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        shape: AppShape.all(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlyphIcon(
                AppGlyphs.speed,
                size: 16,
                color: context.colorScheme.primary,
              ),
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
          const SizedBox(height: 8),
          TrafficBarChart(
            points: [
              for (final p in data.trend)
                (hour: p.hour, download: p.download, upload: p.upload),
            ],
            downloadColor: downloadColor,
            uploadColor: uploadColor,
          ),
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
    return Column(
      children: [
        for (final hit in hits.take(8))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              color: cs.surfaceContainerLowest,
              shape: AppShape.all(16),
            ),
            child: Row(
              children: [
                RingChart(
                  segments: [hit.percent],
                  center: '${(hit.percent * 100).round()}%',
                  size: 56,
                  strokeWidth: 6,
                  trackColor: cs.surfaceContainerHighest,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hit.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.body.of(context, emphasized: true),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: ShapeDecoration(
                              color: cs.primaryContainer,
                              shape: AppShape.full,
                            ),
                            child: Text(
                              hit.key.startsWith('Match') ? 'Match' : 'RuleSet',
                              style: AppTextStyle.caption2.of(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${hit.hits} 次 · ${(hit.upload + hit.download).traffic.show}',
                            style: AppTextStyle.caption2.of(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Ranking extends StatelessWidget {
  const _Ranking({required this.items, required this.kind});

  final List<TrafficRankItem> items;
  final TrafficRankKind kind;

  Glyph _glyph() => switch (kind) {
    TrafficRankKind.domain => AppGlyphs.connections,
    TrafficRankKind.rule => AppGlyphs.filter,
    TrafficRankKind.node => AppGlyphs.proxies,
    TrafficRankKind.config => AppGlyphs.settings,
  };

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('暂无数据')),
      );
    }
    final cs = context.colorScheme;
    return Column(
      children: [
        for (final item in items.take(30))
          Container(
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
                    GlyphIcon(_glyph(), size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(item.percent * 100).toStringAsFixed(1)}%',
                      style: AppTextStyle.caption1
                          .of(context)
                          .copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                UsageBar(
                  fraction: item.percent,
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.55)],
                  ),
                  trackColor: cs.surfaceContainerHighest,
                ),
                const SizedBox(height: 6),
                Text(
                  '↑ ${item.upload.traffic.show}   ↓ ${item.download.traffic.show}',
                  style: AppTextStyle.caption2
                      .of(context)
                      .copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
