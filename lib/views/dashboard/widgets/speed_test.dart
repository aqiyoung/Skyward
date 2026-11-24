import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/views/speed_test/speed_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';

/// A dashboard card that runs a quick download test in place. A tap anywhere
/// else on the card opens the full connection-test page. The endpoint is the
/// same provider list the page uses, so the two stay in sync.
class SpeedTestCard extends ConsumerStatefulWidget {
  const SpeedTestCard({super.key});

  @override
  ConsumerState<SpeedTestCard> createState() => _SpeedTestCardState();
}

class _SpeedTestCardState extends ConsumerState<SpeedTestCard> {
  SpeedTestService? _service;
  bool _running = false;
  double _mbps = 0;
  SpeedPhase? _phase;
  SpeedResult? _result;
  String? _error;

  @override
  void dispose() {
    _service?.clientClose();
    super.dispose();
  }

  Future<void> _test() async {
    if (_running) {
      _service?.clientClose();
      if (mounted) setState(() => _running = false);
      return;
    }
    setState(() {
      _running = true;
      _mbps = 0;
      _phase = null;
      _error = null;
      _result = null;
    });
    final service = _service ??= SpeedTestService(
      findProxy: (uri) =>
          SkywardHttpOverrides.findProxyForReader(ref.read, uri),
    );
    try {
      final result = await service.run(
        onProgress: (phase, mbps) {
          if (!mounted) return;
          setState(() {
            _mbps = mbps;
            _phase = phase;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _mbps = result.downloadMbps ?? 0;
        _running = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = compactError(e);
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final scheme = context.colorScheme;
    final figure = _result != null
        ? (_result!.downloadMbps ?? 0).toStringAsFixed(1)
        : _mbps > 0
        ? _mbps.toStringAsFixed(1)
        : '—';
    // During a run, the caption names the stage rather than the unit, so the
    // live figure reads as "downloading" or "uploading" instead of a bare Mbps.
    final caption = _running
        ? switch (_phase) {
            SpeedPhase.download => appLocalizations.speedTestDownloading,
            SpeedPhase.upload => appLocalizations.speedTestUploading,
            SpeedPhase.latency => appLocalizations.speedTestPinging,
            null => appLocalizations.speedTestTesting,
          }
        : appLocalizations.speedTestMbps;
    return DashboardCard(
      semanticLabel: appLocalizations.speedTest,
      onTap: _running
          ? null
          : () => BaseNavigator.push(context, const SpeedTestView()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.speed,
            title: appLocalizations.speedTest,
            chevron: true,
          ),
          Row(
            children: [
              SizedBox.square(
                dimension: 64,
                child: CustomPaint(
                  painter: _MiniGauge(
                    fraction: _fraction(_mbps),
                    color: scheme.warning,
                    track: scheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: GlyphIcon(
                      AppGlyphs.speed,
                      size: 22,
                      color: scheme.warning,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      figure,
                      style: DashboardText.figure(
                        context,
                        AppTextStyle.title1,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      caption,
                      style: DashboardText.label(context),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.warning,
                  foregroundColor: scheme.onPrimary,
                  shape: AppShape.all(20),
                  minimumSize: const Size(72, 40),
                ),
                onPressed: _test,
                child: Text(
                  _running
                      ? appLocalizations.speedTestStop
                      : appLocalizations.speedTestStart,
                  style: DashboardText.label(
                    context,
                  ).copyWith(color: scheme.onPrimary),
                ),
              ),
            ],
          ),
          if (_error case final error?)
            Text(
              '${appLocalizations.speedTestFailed}: $error',
              style: DashboardText.label(context, color: scheme.error),
            ),
          if (_result != null)
            Text(
              '${appLocalizations.download} ${_result!.downloadMbps?.toStringAsFixed(1) ?? '—'}  '
              '${appLocalizations.upload} ${_result!.uploadMbps?.toStringAsFixed(1) ?? '—'}  '
              '${appLocalizations.delay} ${_result!.latencyMs ?? '—'}',
              style: DashboardText.label(context),
            ),
        ],
      ),
    );
  }
}

double _fraction(double mbps) {
  if (mbps <= 0) return 0;
  return (math.log(mbps.clamp(1.0, 1000.0)) / math.log(1000))
      .clamp(0.0, 1.0)
      .toDouble();
}

class _MiniGauge extends CustomPainter {
  const _MiniGauge({
    required this.fraction,
    required this.color,
    required this.track,
  });

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - 4,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      stroke..color = track,
    );
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * fraction,
        false,
        stroke..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniGauge old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}
