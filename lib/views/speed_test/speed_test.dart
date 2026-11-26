import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/page_large_title.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Connection speed test: a live gauge for the stage in progress, honest
/// result cards (nothing on this page is derived or estimated — every
/// figure is measured), and per-activity quality hints. Colors follow the
/// app theme.
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
  void set(SpeedPhase? phase) => state = phase;
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
  int _runId = 0;

  @override
  void dispose() {
    _service?.clientClose();
    super.dispose();
  }

  SpeedTestService _serviceOf() {
    return _service ??= SpeedTestService(
      findProxy: (uri) =>
          SkywardHttpOverrides.findProxyForReader(ref.read, uri),
    );
  }

  Future<void> _start() async {
    final runId = ++_runId;
    final run = ref.read(speedRunProvider.notifier);
    final phaseNotifier = ref.read(speedPhaseProvider.notifier);
    final progress = ref.read(speedProgressProvider.notifier);
    final live = ref.read(liveSpeedsProvider.notifier);
    progress.set(0);
    live.reset();
    phaseNotifier.set(null);
    run.start();
    try {
      final result = await _serviceOf().run(
        onProgress: (phase, mbps) {
          if (!mounted || runId != _runId) return;
          phaseNotifier.set(phase);
          progress.set(mbps);
          if (phase == SpeedPhase.download) {
            live.down(mbps);
          } else if (phase == SpeedPhase.upload) {
            live.up(mbps);
          }
        },
      );
      if (!mounted || runId != _runId) return;
      live.down(result.downloadMbps ?? 0);
      live.up(result.uploadMbps ?? 0);
      run.finish(result);
    } catch (e) {
      if (!mounted || runId != _runId) return;
      run.fail(compactError(e));
    }
  }

  void _stop() {
    _runId++;
    _service?.clientClose();
    ref.read(speedRunProvider.notifier).idle();
    ref.read(speedPhaseProvider.notifier).set(null);
    ref.read(liveSpeedsProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(speedRunProvider);
    final phase = ref.watch(speedPhaseProvider);
    final live = ref.watch(liveSpeedsProvider);
    final cs = context.colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final largeTitle =
        ViewScope.isMobileOf(context) && !context.isInCompactSheet;
    final statusBarTop = MediaQuery.paddingOf(context).top;

    final result = run.result;
    final running = run.state == _RunState.running;
    final down = _figure(live.down, result?.downloadMbps);
    final up = _figure(live.up, result?.uploadMbps);
    // The gauge's arrow and color follow the value it shows: while running
    // that is the live phase; once done it settles on the download result.
    final gaugePhase = running
        ? (phase ?? SpeedPhase.latency)
        : SpeedPhase.download;
    final gaugeValue = switch (run.state) {
      _RunState.done => result?.downloadMbps ?? 0,
      _RunState.running when gaugePhase == SpeedPhase.upload => live.up,
      _RunState.running when gaugePhase == SpeedPhase.latency => 0.0,
      _RunState.running => live.down,
      _ => 0.0,
    };
    final gaugeColor = switch (gaugePhase) {
      SpeedPhase.upload => cs.tertiary,
      SpeedPhase.latency => cs.secondary,
      _ => cs.primary,
    };

    final body = Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + context.bottomInset),
      child: Column(
        children: [
          _GaugeCard(
            value: gaugeValue,
            color: gaugeColor,
            running: running,
            phase: gaugePhase,
            done: run.state == _RunState.done,
            result: result,
            endpoint: speedTestCloudflare,
            zh: zh,
          ),
          const SizedBox(height: 12),
          _ReadoutRow(
            down: down,
            up: up,
            downActive: running && phase == SpeedPhase.download,
            upActive: running && phase == SpeedPhase.upload,
            downBytes: result?.downloadBytes,
            upBytes: result?.uploadBytes,
            zh: zh,
          ),
          const SizedBox(height: 12),
          _StatsStrip(result: result, zh: zh),
          const SizedBox(height: 14),
          _QualityIcons(result: result, zh: zh),
          const Spacer(),
          _StartButton(
            state: run.state,
            onStart: _start,
            onStop: _stop,
            zh: zh,
          ),
          SizedBox(
            height: 46,
            child: switch (run.error) {
              final error? => Center(
                child: Text(
                  '${context.appLocalizations.speedTestFailed}: $error',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.error, fontSize: 13),
                ),
              ),
              null => null,
            },
          ),
        ],
      ),
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

enum _StepState { pending, active, done, skipped }

/// The gauge in a card, with the three stage steps along its bottom edge:
/// each step lights up while it runs and keeps its measured value after.
class _GaugeCard extends StatelessWidget {
  const _GaugeCard({
    required this.value,
    required this.color,
    required this.running,
    required this.phase,
    required this.done,
    required this.result,
    required this.endpoint,
    required this.zh,
  });

  final double value;
  final Color color;
  final bool running;
  final SpeedPhase? phase;
  final bool done;
  final SpeedResult? result;
  final SpeedTestEndpoint endpoint;
  final bool zh;

  _StepState _step(SpeedPhase step, bool supported) {
    if (!supported) return _StepState.skipped;
    if (result != null) return _StepState.done;
    if (!running || phase == null) return _StepState.pending;
    const order = [SpeedPhase.latency, SpeedPhase.download, SpeedPhase.upload];
    final current = order.indexOf(phase!);
    final mine = order.indexOf(step);
    if (mine < current) return _StepState.done;
    if (mine == current) return _StepState.active;
    return _StepState.pending;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: cs.surfaceContainerLow,
        shape: AppShape.xxl,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(
          children: [
            _Gauge(
              value: value,
              color: color,
              running: running,
              phase: phase,
              done: done,
              zh: zh,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _Step(
                  label: zh ? '延迟' : 'Ping',
                  value: result?.latencyMs == null
                      ? null
                      : '${result!.latencyMs} ms',
                  state: _step(SpeedPhase.latency, endpoint.ping != null),
                  color: cs.secondary,
                ),
                _StepDivider(),
                _Step(
                  label: context.appLocalizations.download,
                  value: result?.downloadMbps == null
                      ? null
                      : result!.downloadMbps!.toStringAsFixed(1),
                  state: _step(SpeedPhase.download, true),
                  color: cs.primary,
                ),
                _StepDivider(),
                _Step(
                  label: context.appLocalizations.upload,
                  value: result?.uploadMbps == null
                      ? null
                      : result!.uploadMbps!.toStringAsFixed(1),
                  state: _step(SpeedPhase.upload, endpoint.upload != null),
                  color: cs.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: context.colorScheme.outlineVariant,
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.value,
    required this.state,
    required this.color,
  });

  final String label;
  final String? value;
  final _StepState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final (dotColor, textColor) = switch (state) {
      _StepState.active => (color, cs.onSurface),
      _StepState.done => (color, cs.onSurface),
      _StepState.pending => (cs.outlineVariant, cs.onSurfaceVariant),
      _StepState.skipped => (cs.outlineVariant, cs.onSurfaceVariant),
    };
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state == _StepState.done)
                Icon(Icons.check_circle_rounded, size: 13, color: color)
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: textColor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            state == _StepState.skipped
                ? '—'
                : (value ?? (state == _StepState.active ? '···' : '—')),
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.value,
    required this.color,
    required this.running,
    required this.phase,
    required this.done,
    required this.zh,
  });

  final double value;
  final Color color;
  final bool running;
  final SpeedPhase? phase;
  final bool done;
  final bool zh;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final measuringLatency = running && phase == SpeedPhase.latency;
    final label = running
        ? switch (phase) {
            SpeedPhase.download =>
              context.appLocalizations.speedTestDownloading,
            SpeedPhase.upload => context.appLocalizations.speedTestUploading,
            SpeedPhase.latency => context.appLocalizations.speedTestPinging,
            null => context.appLocalizations.speedTestTesting,
          }
        : done
        ? (zh ? '测试完成' : 'Done')
        : context.appLocalizations.speedTestReady;
    return SizedBox(
      height: 208,
      child: CustomPaint(
        painter: _GaugePainter(
          fraction: _logFraction(value),
          color: color,
          track: cs.surfaceContainerHighest,
          tick: cs.onSurfaceVariant,
          tickLabel: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
        ),
        child: Align(
          alignment: const Alignment(0, 0.45),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (measuringLatency)
                Icon(Icons.network_ping_rounded, color: color, size: 40)
              else
                Text(
                  value > 0 ? value.toStringAsFixed(1) : '0.0',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!measuringLatency)
                    Icon(
                      phase == SpeedPhase.upload
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: color,
                      size: 14,
                    ),
                  Text(
                    measuringLatency
                        ? ' ms'
                        : ' ${context.appLocalizations.speedTestMbps}',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(label, style: TextStyle(color: color, fontSize: 13)),
            ],
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
    '0',
    '5',
    '10',
    '50',
    '100',
    '250',
    '500',
    '750',
    '1k',
  ];
  static const _start = math.pi;
  static const _sweep = math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.88);
    final radius = math.min(size.width / 2 - 26, size.height * 0.8);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
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
        center.dx + (radius - 21) * math.cos(angle),
        center.dy + (radius - 21) * math.sin(angle),
      );
      final outer = Offset(
        center.dx + (radius - 13) * math.cos(angle),
        center.dy + (radius - 13) * math.sin(angle),
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

class _ReadoutRow extends StatelessWidget {
  const _ReadoutRow({
    required this.down,
    required this.up,
    required this.downActive,
    required this.upActive,
    required this.downBytes,
    required this.upBytes,
    required this.zh,
  });

  final String down;
  final String up;
  final bool downActive;
  final bool upActive;
  final int? downBytes;
  final int? upBytes;
  final bool zh;

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
            bytes: downBytes,
            zh: zh,
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
            bytes: upBytes,
            zh: zh,
          ),
        ),
      ],
    );
  }
}

class _ReadoutCard extends StatelessWidget {
  const _ReadoutCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.active,
    required this.bytes,
    required this.zh,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool active;
  final int? bytes;
  final bool zh;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: cs.surfaceContainerLow,
        shape: active
            ? RoundedSuperellipseBorder(
                borderRadius: AppRadius.xl,
                side: BorderSide(color: color, width: 2),
              )
            : AppShape.xl,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 17),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  context.appLocalizations.speedTestMbps,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 31,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              bytes == null
                  ? ' '
                  : '${zh ? '传输' : 'Transferred'} ${_formatBytes(bytes!)}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Measured facts only: ping and jitter from the latency stage, then the
/// server used and, once finished, how long the run took and how much data
/// it moved.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.result, required this.zh});

  final SpeedResult? result;
  final bool zh;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final totalBytes =
        (result?.downloadBytes ?? 0) + (result?.uploadBytes ?? 0);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: cs.surfaceContainerLow,
        shape: AppShape.xl,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            _StatItem(
              label: 'Ping',
              value: result?.latencyMs == null
                  ? '—'
                  : '${result!.latencyMs} ms',
            ),
            _StatItem(
              label: 'Jitter',
              value: result?.jitterMs == null ? '—' : '${result!.jitterMs} ms',
            ),
            _StatItem(
              label: zh ? '用时' : 'Time',
              value: result == null
                  ? '—'
                  : '${(result!.elapsedMs / 1000).toStringAsFixed(0)}s',
            ),
            _StatItem(
              label: zh ? '流量' : 'Data',
              value: result == null ? '—' : _formatBytes(totalBytes),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// Quality hints, each rated on the metric that actually governs it:
/// browsing and video on download throughput, gaming on latency and
/// jitter, calls on jitter.
class _QualityIcons extends StatelessWidget {
  const _QualityIcons({required this.result, required this.zh});

  final SpeedResult? result;
  final bool zh;

  int _byDownload(double mbps, List<double> cuts) =>
      cuts.where((c) => mbps >= c).length;

  int _byLatency(int ms, List<int> cuts) => cuts.where((c) => ms <= c).length;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final down = result?.downloadMbps;
    final ping = result?.latencyMs;
    final jitter = result?.jitterMs;
    final items = <(IconData, String, int)>[
      (
        Icons.language_rounded,
        zh ? '网页' : 'Web',
        down == null ? 0 : _byDownload(down, [1, 3, 5, 10, 25]),
      ),
      (
        Icons.sports_esports_rounded,
        zh ? '游戏' : 'Game',
        ping == null || jitter == null
            ? 0
            : math.min(
                _byLatency(ping, [200, 120, 80, 50, 30]),
                _byLatency(jitter, [50, 30, 20, 10, 5]),
              ),
      ),
      (
        Icons.video_library_rounded,
        zh ? '视频' : 'Video',
        down == null ? 0 : _byDownload(down, [3, 5, 10, 25, 50]),
      ),
      (
        Icons.badge_rounded,
        zh ? '通话' : 'VoIP',
        jitter == null ? 0 : _byLatency(jitter, [100, 60, 30, 15, 8]),
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final (icon, label, dots) in items)
          Column(
            children: [
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: cs.surfaceContainerLow,
                  shape: AppShape.lg,
                ),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    icon,
                    color: dots > 0 ? cs.primary : cs.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: i < dots ? cs.primary : cs.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({
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
          shape: AppShape.full,
        ),
        onPressed: running ? onStop : onStart,
        icon: Icon(
          running ? Icons.stop_rounded : Icons.speed_rounded,
          size: 20,
        ),
        label: Text(
          running
              ? context.appLocalizations.speedTestStop
              : context.appLocalizations.speedTestStart,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
