import 'dart:async';
import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/config/network.dart';
import 'package:skyward/views/page_large_title.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A Cloudflare-style connection speed test: one big arc reads the live
/// throughput, and the three finished numbers sit underneath. The endpoint
/// set is pluggable through [SpeedTestService], so no provider is hard-wired.
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
    progress.set(0);
    run.start();
    try {
      final result = await _serviceOf().run(
        onProgress: (phase, mbps) {
          if (!mounted) return;
          phaseNotifier.set(phase);
          progress.set(mbps);
        },
      );
      if (!mounted) return;
      run.finish(result);
    } catch (e) {
      if (!mounted) return;
      run.fail(compactError(e));
    }
  }

  void _stop() {
    _service?.clientClose();
    ref.read(speedRunProvider.notifier).idle();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final run = ref.watch(speedRunProvider);
    final phase = ref.watch(speedPhaseProvider);
    final progress = ref.watch(speedProgressProvider);
    final largeTitle =
        ViewScope.isMobileOf(context) && !context.isInCompactSheet;
    final statusBarTop = MediaQuery.paddingOf(context).top;

    final body = ListView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + context.bottomInset),
      children: [
        _ProviderPicker(selected: ref.watch(speedProviderProvider)),
        const SizedBox(height: 8),
        _Gauge(
          progress: progress,
          phase: phase,
          result: run.result,
          state: run.state,
          providerName:
              speedTestEndpoints[ref.read(speedProviderProvider)].name,
        ),
        const SizedBox(height: 20),
        _StartButton(state: run.state, onStart: _start, onStop: _stop),
        const SizedBox(height: 16),
        _Metrics(result: run.result, state: run.state),
        if (run.error case final error?)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              '${appLocalizations.speedTestFailed}: $error',
              style: AppTextStyle.footnote
                  .of(context)
                  .copyWith(color: context.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 20),
        _RouteTile(),
      ],
    );

    return CommonScaffold(
      title: appLocalizations.speedTest,
      largeTitle: largeTitle,
      body: largeTitle
          ? PageLargeTitle(
              title: appLocalizations.speedTest,
              statusBarTop: statusBarTop,
              body: body,
            )
          : body,
    );
  }
}

/// The big semicircular arc. A logarithmic scale (1 / 5 / 10 / 50 / 100 /
/// 250 / 500 / 1000+) gives useful resolution at both low and high speeds,
/// the same shape readers will recognise from a speed test.
class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.progress,
    required this.phase,
    required this.result,
    required this.state,
    required this.providerName,
  });

  final double progress;
  final SpeedPhase? phase;
  final SpeedResult? result;
  final _RunState state;
  final String providerName;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final scheme = context.colorScheme;
    final orange = scheme.warning;
    final shown = switch (state) {
      _RunState.done => result?.downloadMbps ?? 0,
      // Latency is measured in ms, not Mbps; showing the previous stage's
      // throughput under a "measuring latency" label would be misleading.
      _RunState.running when phase == SpeedPhase.latency => 0.0,
      _RunState.running => progress,
      _ => 0.0,
    };
    // While running, name the stage so the reader knows whether the live
    // number is download, upload or latency -- a bare "testing" hides it.
    final label = switch (state) {
      _RunState.idle => appLocalizations.speedTestReady,
      _RunState.running => switch (phase) {
        SpeedPhase.download => appLocalizations.speedTestDownloading,
        SpeedPhase.upload => appLocalizations.speedTestUploading,
        SpeedPhase.latency => appLocalizations.speedTestPinging,
        null => appLocalizations.speedTestTesting,
      },
      _RunState.done => appLocalizations.speedTestResult,
      _RunState.failed => appLocalizations.speedTestFailed,
    };

    return Column(
      children: [
        SizedBox(
          width: 320,
          height: 250,
          child: CustomPaint(
            painter: _GaugePainter(
              fraction: _logFraction(shown),
              color: orange,
              track: scheme.surfaceContainerHighest,
              tick: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              tickLabel: AppTextStyle.custom(
                context,
                size: 11,
                leading: 14,
              ).copyWith(color: scheme.onSurfaceVariant),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shown <= 0 ? '—' : shown.toStringAsFixed(1),
                      style: AppTextStyle.largeTitle
                          .of(context, emphasized: true)
                          .copyWith(color: scheme.onSurface),
                    ),
                    Text(
                      appLocalizations.speedTestMbps,
                      style: AppTextStyle.body
                          .of(context)
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: AppTextStyle.subheadline
                          .of(context, emphasized: true)
                          .copyWith(color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Text(
          result?.service ?? providerName,
          style: AppTextStyle.footnote
              .of(context)
              .copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Maps Mbps to 0..1 on a log scale anchored at 1 and capped at 1000.
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
    '1',
    '5',
    '10',
    '50',
    '100',
    '250',
    '500',
    '1000+',
  ];
  static const _start = math.pi; // 9 o'clock
  static const _sweep = math.pi; // to 3 o'clock, over the top

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.82);
    final radius = math.min(size.width / 2 - 18, size.height * 0.72);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
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

    // Tick marks and their labels around the outside of the arc.
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labelStyle = tickLabel;
    for (var i = 0; i < _ticks.length; i++) {
      final angle = _start + _sweep * i / (_ticks.length - 1);
      final inner = Offset(
        center.dx + (radius - 26) * math.cos(angle),
        center.dy + (radius - 26) * math.sin(angle),
      );
      final outer = Offset(
        center.dx + (radius - 18) * math.cos(angle),
        center.dy + (radius - 18) * math.sin(angle),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = tick
          ..strokeWidth = 1.5,
      );

      final label = _ticks[i];
      final labelPos = Offset(
        center.dx + (radius + 14) * math.cos(angle),
        center.dy + (radius + 14) * math.sin(angle),
      );
      textPainter
        ..text = TextSpan(text: label, style: labelStyle)
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
    required this.state,
    required this.onStart,
    required this.onStop,
  });

  final _RunState state;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final scheme = context.colorScheme;
    final running = state == _RunState.running;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.warning,
          foregroundColor: scheme.onPrimary,
          shape: AppShape.all(28),
        ),
        onPressed: running ? onStop : onStart,
        icon: GlyphIcon(
          AppGlyphs.playPause(running ? 1 : 0),
          size: 20,
          fill: 1,
          color: scheme.onPrimary,
        ),
        label: Text(
          running
              ? appLocalizations.speedTestStop
              : appLocalizations.speedTestStart,
          style: AppTextStyle.body.of(context, emphasized: true),
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.result, required this.state});

  final SpeedResult? result;
  final _RunState state;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final scheme = context.colorScheme;
    final labelStyle = AppTextStyle.footnote
        .of(context)
        .copyWith(color: scheme.onSurfaceVariant);
    const dash = '—';
    final done = state == _RunState.done && result != null;
    final download = done && result!.downloadMbps != null
        ? result!.downloadMbps!.toStringAsFixed(1)
        : dash;
    final upload = done && result!.uploadMbps != null
        ? result!.uploadMbps!.toStringAsFixed(1)
        : dash;
    final latency = done && result!.latencyMs != null
        ? '${result!.latencyMs}'
        : dash;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerLow,
        shape: AppShape.all(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _metric(
              context,
              '↓ ${appLocalizations.download}',
              download,
              appLocalizations.speedTestMbps,
              labelStyle,
              scheme,
            ),
          ),
          Expanded(
            child: _metric(
              context,
              '↑ ${appLocalizations.upload}',
              upload,
              appLocalizations.speedTestMbps,
              labelStyle,
              scheme,
            ),
          ),
          Expanded(
            child: _metric(
              context,
              '◷ ${appLocalizations.delay}',
              latency,
              appLocalizations.speedTestMs,
              labelStyle,
              scheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String title,
    String value,
    String unit,
    TextStyle labelStyle,
    ColorScheme scheme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: labelStyle),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyle.title2
              .of(context, emphasized: true)
              .copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 2),
        Text(unit, style: labelStyle),
      ],
    );
  }
}

/// A row of tappable service names. The chosen provider's endpoints decide
/// which stages run, so switching also clears any previous result.
class _ProviderPicker extends ConsumerWidget {
  const _ProviderPicker({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    return Row(
      spacing: 8,
      children: [
        for (var i = 0; i < speedTestEndpoints.length; i++)
          Semantics(
            button: true,
            selected: i == selected,
            child: GestureDetector(
              onTap: () {
                if (i == selected) return;
                ref.read(speedProviderProvider.notifier).select(i);
                ref.read(speedRunProvider.notifier).idle();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: ShapeDecoration(
                  color: i == selected
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerLow,
                  shape: AppShape.all(18),
                ),
                child: Text(
                  speedTestEndpoints[i].name,
                  style: AppTextStyle.footnote
                      .of(context)
                      .copyWith(
                        color: i == selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RouteTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final scheme = context.colorScheme;
    return ListTile(
      shape: AppShape.all(20),
      tileColor: scheme.surfaceContainerLow,
      leading: GlyphIcon(
        AppGlyphs.globe,
        size: 24,
        color: scheme.onSurfaceVariant,
      ),
      title: Text(appLocalizations.speedTestRoute),
      subtitle: Text(appLocalizations.speedTestSystemRoute),
      trailing: GlyphIcon(
        AppGlyphs.chevronForward,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
      onTap: () {
        // The speed test runs through the system route; open the network
        // settings that choose the routing mode and the mixed port.
        Navigator.of(context).push(
          PagedSheetRoute(
            builder: (_) => BaseScaffold(
              title: appLocalizations.network,
              body: const NetworkListView(),
            ),
          ),
        );
      },
    );
  }
}
