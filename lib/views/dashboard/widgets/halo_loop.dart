import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A pulsing halo around a circular control, drawn from its own loop.
class RunningHalo extends StatefulWidget {
  const RunningHalo({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<RunningHalo> createState() => _RunningHaloState();
}

class _RunningHaloState extends State<RunningHalo>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 900);

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: _duration,
  );

  @override
  void initState() {
    super.initState();
    _loop.repeat();
  }

  @override
  void dispose() {
    _loop.stop();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _loop,
      builder: (_, __) => CustomPaint(
        painter: _HaloPainter(
          value: _loop.value,
          size: widget.size,
          color: widget.color,
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

/// A translucent arc that sweeps around the center and pulses in its alpha:
/// the hand to see "the core is running."
class _HaloPainter extends CustomPainter {
  const _HaloPainter({
    required this.value,
    required this.size,
    required this.color,
  });

  final double value;
  final double size;
  final Color color;

  @override
  void paint(Canvas canvas, Size _) {
    final center = Offset(size / 2, size / 2);
    final progress = (value + 1) % 1;
    final angle = progress * math.pi * 2;
    final start = angle;
    final end = start + (0.55 + math.sin(value * math.pi) * 0.45) * math.pi;
    final alpha = 0.5 + 0.5 * math.sin(value * math.pi * 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.45 * alpha);
    final radius = size / 2 + 8;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(start)
      ..drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        0,
        end,
        false,
        paint,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _HaloPainter old) =>
      old.value != value || old.size != size || old.color != color;
}
