import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A full-page traffic statistics view: day/week/month totals, rule-hit rings
/// and a traffic ranking by domain / rule / node / config. Opened from the
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

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(trafficStatisticsProvider(_period, _kind));
    final range = ref.watch(trafficRangeProvider);

    return CommonScaffold(
      title: context.appLocalizations.trafficUsage,
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
            const SizedBox(height: 16),
            stats.when(
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TotalsCard(data: data),
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
                  _Ranking(items: data.ranking),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
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

  String _label() {
    return switch (period) {
      TrafficPeriod.day =>
        '${range.year}-${range.month.toString().padLeft(2, '0')}-${range.day.toString().padLeft(2, '0')}',
      TrafficPeriod.week => '${range.month}/${range.day} 起',
      TrafficPeriod.month => '${range.year}/${range.month}',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const GlyphIcon(AppGlyphs.chevronBack),
          onPressed: () =>
              ref.read(trafficRangeProvider.notifier).shift(period, -1),
        ),
        Text(_label()),
        IconButton(
          icon: const GlyphIcon(AppGlyphs.chevronForward),
          onPressed: () =>
              ref.read(trafficRangeProvider.notifier).shift(period, 1),
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.data});

  final TrafficStatistics data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceContainerLowest,
        shape: AppShape.all(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('总流量', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(
            (data.totalUpload + data.totalDownload).traffic.show,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('↑ ${data.totalUpload.traffic.show}'),
              const SizedBox(width: 20),
              Text('↓ ${data.totalDownload.traffic.show}'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${data.connectionCount} 条连接',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
  );
}

class _RuleHits extends StatelessWidget {
  const _RuleHits({required this.hits});

  final List<RuleHit> hits;

  @override
  Widget build(BuildContext context) {
    if (hits.isEmpty) {
      return const Text('暂无数据');
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final hit in hits.take(8))
          SizedBox(
            width: 96,
            child: Column(
              children: [
                RingChart(
                  segments: [hit.percent],
                  center: '${(hit.percent * 100).round()}%',
                ),
                const SizedBox(height: 4),
                Text(hit.key, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${hit.hits} 次', style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Ranking extends StatelessWidget {
  const _Ranking({required this.items});

  final List<TrafficRankItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('暂无数据')),
      );
    }
    final colorScheme = context.colorScheme;
    return Column(
      children: [
        for (final item in items.take(30))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(item.percent * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRSuperellipse(
                  borderRadius: AppRadius.full,
                  child: SizedBox(
                    height: 6,
                    child: FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: item.percent.clamp(0.0, 1.0),
                      child: ColoredBox(color: colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '↑ ${item.upload.traffic.show}   ↓ ${item.download.traffic.show}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
