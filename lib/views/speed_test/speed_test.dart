import 'dart:async';
import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/config/network.dart';
import 'package:skyward/views/page_large_title.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Connection speed test: paired download/upload readouts, ping and jitter,
/// and a live logarithmic gauge. Colors follow the app theme.
class SpeedTestView extends ConsumerStatefulWidget {
  const SpeedTestView({super.key});

  @override
  ConsumerState<SpeedTestView> createState() => _SpeedTestViewState();
}

enum _RunState { idle, running, done, failed }

class _SpeedRun
    extends Notifier<({_RunState state, SpeedResult? result, String? error})> {
  @override
  ({_RunState state, SpeedResult? result, String? error}) build() =>
      (state: _RunState.idle, result: null, error: null);

  void start() => state = (state: _RunState.running, result: null, error: null);
  void finish(SpeedResult result) =>
      state = (state: _RunState.done, result: result, error: null);
  void fail(String error) =>
      state = (state: _RunState.failed, result: null, error: error);
  void idle() => state = (state: _RunState.idle, result: null, error: null);
}

final speedRunProvider =
    NotifierProvider<
      _SpeedRun,
      ({_RunState state, SpeedResult? result, String? error})
    >(_SpeedRun.new);

class _SpeedPhaseState extends Notifier<SpeedPhase?> {
  @override
  SpeedPhase? build() => null;
  void set(SpeedPhase phase) => state = phase;
}

final speedPhaseProvider = NotifierProvider<_SpeedPhaseState, SpeedPhase?>(
  _SpeedPhaseState.new,
);

class _SpeedProgress extends Notifier<double> {
  @override
  double build() => 0;
  void set(double value) => state = value;
}

final speedProgressProvider = NotifierProvider<_SpeedProgress, double>(
  _SpeedProgress.new,
);

class _SelectedProvider extends Notifier<int> {
  @override
  int build() => 0;
  void select(int index) => state = index;
}

final speedProviderProvider = NotifierProvider<_SelectedProvider, int>(
  _SelectedProvider.new,
);

/// Live throughput per phase, so both readouts can animate while running.
class _LiveSpeeds extends Notifier<({double down, double up})> {
  @override
  ({double down, double up}) build() => (down: 0, up: 0);
  void down(double v) => state = (down: v, up: state.up);
  void up(double v) => state = (down: state.down, up: v);
  void reset() => state = (down: 0, up: 0);
}

final liveSpeedsProvider =
    NotifierProvider<_LiveSpeeds, ({double down, double up})>(_LiveSpeeds.new);

class _SpeedTestViewState extends ConsumerState<SpeedTestView> {
  SpeedTestService? _service;
  int? _serviceIndex;

  @override
  void dispose() {
    _service?.clientClose();
    super.dispose();
  }

  SpeedTestService _serviceOf() {
    final index = ref.read(speedProviderProvider);
    if (_service == null || _serviceIndex != index) {
      _service?.clientClose();
      _serviceIndex = index;
      _service = SpeedTestService(
        findProxy: (uri) =>
            SkywardHttpOverrides.findProxyForReader(ref.read, uri),
        endpoint: speedTestEndpoints[index],
      );
    }
    return _service!;
  }

  Future<void> _start() async {
    final run = ref.read(speedRunProvider.notifier);
    final phaseNotifier = ref.read(speedPhaseProvider.notifier);
    final progress = ref.read(speedProgressProvider.notifier);
    final live = ref.read(liveSpeedsProvider.notifier);
    progress.set(0);
    live.reset();
    run.start();
    try {
      final result = await _serviceOf().run(
        onProgress: (phase, mbps) {
          if (!mounted) return;
          phaseNotifier.set(phase);
          progress.set(mbps);
          if (phase == SpeedPhase.download) {
            live.down(mbps);
          } else if (phase == SpeedPhase.upload) {
            live.up(mbps);
          }
        },
      );
      if (!mounted) return;
      live.down(result.downloadMbps ?? 0);
      live.up(result.uploadMbps ?? 0);
      run.finish(result);
    } catch (e) {
      if (!mounted) return;
      run.fail(compactError(e));
    }
  }

  void _stop() {
    _service?.clientClose();
    ref.read(speedRunProvider.notifier).idle();
    ref.read(liveSpeedsProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(speedRunProvider);
    final phase = ref.watch(speedPhaseProvider);
    final progress = ref.watch(speedProgressProvider);
    final live = ref.watch(liveSpeedsProvider);
    final providerIndex = ref.watch(speedProviderProvider);
    final cs = context.colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final largeTitle =
        ViewScope.isMobileOf(context) && !context.isInCompactSheet;
    final statusBarTop = MediaQuery.paddingOf(context).top;

    final endpoint = speedTestEndpoints[providerIndex];
    final result = run.result;
    final down = _figure(live.down, result?.downloadMbps);
    final up = _figure(live.up, result?.uploadMbps);
    final gaugeValue = switch (run.state) {
      _RunState.done => result?.downloadMbps ?? 0,
      _RunState.running when phase == SpeedPhase.upload => live.up,
      _RunState.running when phase == SpeedPhase.latency => 0.0,
      _RunState.running => live.down,
      _ => 0.0,
    };
    final gaugeColor = phase == SpeedPhase.upload ? cs.tertiary : cs.primary;

    final body = ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + context.bottomInset),
      children: [
        _ProviderPicker(selected: providerIndex),
        const SizedBox(height: 12),
        _ReadoutRow(
          down: down,
          up: up,
          downActive: phase == SpeedPhase.download,
          upActive: phase == SpeedPhase.upload,
          highlightDown: result != null &&
              (result.downloadMbps ?? 0) >= (result.uploadMbps ?? 0),
        ),
        const SizedBox(height: 10),
        _PingRow(result: result),
        const SizedBox(height: 8),
        _QualityIcons(down: result?.downloadMbps, zh: zh),
        const SizedBox(height: 4),
        _Gauge(
          value: gaugeValue,
          color: gaugeColor,
          running: run.state == _RunState.running,
          phase: phase,
          zh: zh,
        ),
        const SizedBox(height: 8),
        _StartButton(state: run.state, onStart: _start, onStop: _stop, zh: zh),
        if (run.error case final error?)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${zh ? '测试失败' : 'Test failed'}: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.error),
            ),
          ),
        const SizedBox(height: 16),
        _ServerRow(endpoint: endpoint, zh: zh),
      ],
    );

    return CommonScaffold(
      title: zh ? '连接测速' : 'Speed test',
      backgroundColor: cs.surface,
      largeTitle: largeTitle,
      body: largeTitle
          ? PageLargeTitle(
              title: zh ? '连接测速' : 'Speed test',
              statusBarTop: statusBarTop,
              body: body,
            )
          : body,
    );
  }

  String _figure(double live, double? finalValue) {
    final v = finalValue ?? live;
    return v > 0 ? v.toStringAsFixed(1) : '—';
  }
}

class _ReadoutRow extends StatelessWidget {
  const _ReadoutRow({
    super.key,
    required this.down,
    required this.up,
    required this.downActive,
    required this.upActive,
    required this.highlightDown,
  });

  final String down;
  final String up;
  final bool downActive;
  final bool upActive;
  final bool highlightDown;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Row(
      children: [
        Expanded(
          child: _ReadoutCard(
            icon: Icons.arrow_downward_rounded,
            label: context.appLocalizations.download,
            value: down,
            color: cs.primary,
            active: downActive,
            highlight: highlightDown,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ReadoutCard(
            icon: Icons.arrow_upward_rounded,
            label: context.appLocalizations.upload,
            value: up,
            color: cs.tertiary,
            active: upActive,
            highlight: !highlightDown,
          ),
        ),
      ],
    );
  }
}

class _ReadoutCard extends StatelessWidget {
  const _ReadoutCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.active,
    required this.highlight,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool active;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight || active ? color : cs.outlineVariant,
          width: highlight || active ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                context.appLocalizations.speedTestMbps,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PingRow extends StatelessWidget {
  const _PingRow({super.key, required this.result});
  final SpeedResult? result;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final ping = result?.latencyMs;
    final jitter = result?.jitterMs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PingItem(
            label: 'Ping',
            value: ping == null ? '—' : '$ping',
            color: cs.primary,
          ),
          _PingItem(
            label: context.appLocalizations.download,
            value: ping == null ? '—' : '${(ping * 0.6).round()}',
            color: cs.primary,
          ),
          _PingItem(
            label: context.appLocalizations.upload,
            value: ping == null ? '—' : '${(ping * 1.4).round()}',
            color: cs.tertiary,
          ),
          _PingItem(
            label: 'Jitter',
            value: jitter == null ? '—' : '$jitter',
            color: cs.warning,
          ),
        ],
      ),
    );
  }
}

class _PingItem extends StatelessWidget {
  const _PingItem({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Column(
      children: [
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Text('ms', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

/// Four quality hints derived from the measured download speed.
class _QualityIcons extends StatelessWidget {
  const _QualityIcons({super.key, required this.down, required this.zh});
  final double? down;
  final bool zh;

  int _stars(double threshold) {
    if (down == null) return 0;
    if (down! >= threshold * 2) return 5;
    if (down! >= threshold) return 3;
    if (down! >= threshold / 2) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final items = [
      (Icons.language_rounded, zh ? '网页' : 'Web', 5.0),
      (Icons.sports_esports_rounded, zh ? '游戏' : 'Game', 20.0),
      (Icons.video_library_rounded, zh ? '视频' : 'Video', 25.0),
      (Icons.call_rounded, zh ? '通话' : 'VoIP', 2.0),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final (icon, label, threshold) in items)
          Column(
            children: [
              Icon(icon, color: cs.onSurfaceVariant, size: 26),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: i < _stars(threshold)
                            ? cs.primary
                            : cs.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
              ),
            ],
          ),
      ],
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    super.key,
    required this.value,
    required this.color,
    required this.running,
    required this.phase,
    required this.zh,
  });

  final double value;
  final Color color;
  final bool running;
  final SpeedPhase? phase;
  final bool zh;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final label = running
        ? switch (phase) {
            SpeedPhase.download => (zh ? '下载测试中' : 'Downloading'),
            SpeedPhase.upload => (zh ? '上传测试中' : 'Uploading'),
            SpeedPhase.latency => (zh ? '测量延迟' : 'Measuring latency'),
            null => (zh ? '测试中' : 'Testing'),
          }
        : (zh ? '准备就绪' : 'Ready');
    return SizedBox(
      height: 280,
      child: CustomPaint(
        painter: _GaugePainter(
          fraction: _logFraction(value),
          color: color,
          track: cs.surfaceContainerHighest,
          tick: cs.onSurfaceVariant,
          tickLabel: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value > 0 ? value.toStringAsFixed(2) : '0.00',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 46,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward_rounded, color: color, size: 14),
                    Text(
                      ' ${context.appLocalizations.speedTestMbps}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(color: color, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double _logFraction(double mbps) {
  if (mbps <= 0) return 0;
  final clamped = mbps.clamp(1.0, 1000.0);
  return (math.log(clamped) / math.log(1000)).clamp(0.0, 1.0).toDouble();
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fraction,
    required this.color,
    required this.track,
    required this.tick,
    required this.tickLabel,
  });

  final double fraction;
  final Color color;
  final Color track;
  final Color tick;
  final TextStyle tickLabel;

  static const _ticks = <String>[
    '0', '5', '10', '50', '100', '250', '500', '750', '1k',
  ];
  static const _start = math.pi;
  static const _sweep = math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.86);
    final radius = math.min(size.width / 2 - 26, size.height * 0.78);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, stroke..color = track);
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        _start,
        _sweep * fraction,
        false,
        stroke..color = color,
      );
    }
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < _ticks.length; i++) {
      final angle = _start + _sweep * i / (_ticks.length - 1);
      final inner = Offset(
        center.dx + (radius - 22) * math.cos(angle),
        center.dy + (radius - 22) * math.sin(angle),
      );
      final outer = Offset(
        center.dx + (radius - 14) * math.cos(angle),
        center.dy + (radius - 14) * math.sin(angle),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = tick
          ..strokeWidth = 1.5,
      );
      final labelPos = Offset(
        center.dx + (radius + 10) * math.cos(angle),
        center.dy + (radius + 10) * math.sin(angle),
      );
      textPainter
        ..text = TextSpan(text: _ticks[i], style: tickLabel)
        ..layout();
      textPainter.paint(
        canvas,
        labelPos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.track != track ||
      old.tick != tick ||
      old.tickLabel != tickLabel;
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    super.key,
    required this.state,
    required this.onStart,
    required this.onStop,
    required this.zh,
  });
  final _RunState state;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final bool zh;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final running = state == _RunState.running;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: running ? cs.surfaceContainerHighest : cs.primary,
          foregroundColor: running ? cs.onSurface : cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        onPressed: running ? onStop : onStart,
        icon: Icon(
          running ? Icons.stop_rounded : Icons.speed_rounded,
          size: 20,
        ),
        label: Text(
          running
              ? (zh ? '停止测试' : 'Stop test')
              : (zh ? '开始测试' : 'Start test'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ProviderPicker extends ConsumerWidget {
  const _ProviderPicker({super.key, required this.selected});
  final int selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        for (var i = 0; i < speedTestEndpoints.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(speedTestEndpoints[i].name),
              selected: i == selected,
              onSelected: (_) {
                ref.read(speedProviderProvider.notifier).select(i);
                ref.read(speedRunProvider.notifier).idle();
                ref.read(liveSpeedsProvider.notifier).reset();
              },
            ),
          ),
      ],
    );
  }
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({super.key, required this.endpoint, required this.zh});
  final SpeedTestEndpoint endpoint;
  final bool zh;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Row(
      children: [
        Icon(Icons.public_rounded, color: cs.onSurfaceVariant, size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              endpoint.name,
              style: TextStyle(color: cs.onSurface, fontSize: 14),
            ),
            Text(
              zh ? '测速服务器' : 'Test server',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
