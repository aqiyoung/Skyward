import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A donut made of one arc per [segments] share, with a label in the middle.
/// Shares are fractions of the whole (they need not sum to 1; the remainder is
/// left as an empty track). Used for the rule-hit rings on the statistics page.
class RingChart extends StatelessWidget {
  const RingChart({
    super.key,
    required this.segments,
    required this.center,
    this.subtitle,
    this.size = 84,
    this.strokeWidth = 9,
    this.trackColor,
  });

  final List<double> segments;
  final String center;
  final String? subtitle;
  final double size;
  final double strokeWidth;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          segments: segments,
          colors: _palette(segments.length),
          trackColor: trackColor,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                center,
                style: TextStyle(
                  fontSize: size / 5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle case final subtitle?)
                Text(subtitle, style: TextStyle(fontSize: size / 8)),
            ],
          ),
        ),
      ),
    );
  }
}

List<Color> _palette(int count) {
  const base = [
    Color(0xFF6750A4),
    Color(0xFF9585DA),
    Color(0xFF4F7BFF),
    Color(0xFF59C2B0),
    Color(0xFFFF9F2E),
    Color(0xFFFF4D6D),
  ];
  return [for (var i = 0; i < count; i++) base[i % base.length]];
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.segments,
    required this.colors,
    required this.strokeWidth,
    this.trackColor,
  });

  final List<double> segments;
  final List<Color> colors;
  final double strokeWidth;
  final Color? trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(
      center,
      radius,
      stroke..color = trackColor ?? const Color(0x1A000000),
    );

    var start = -math.pi / 2;
    for (var i = 0; i < segments.length; i++) {
      final sweep = segments[i].clamp(0.0, 1.0) * 2 * math.pi;
      if (sweep <= 0) continue;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        stroke
          ..color = colors[i % colors.length]
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.segments != segments ||
      oldDelegate.colors != colors ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.trackColor != trackColor;
}
