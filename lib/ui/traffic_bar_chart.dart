import 'dart:math' as math;

import 'package:skyward/models/models.dart';
import 'package:flutter/widgets.dart';

/// A per-hour stacked bar chart: download on the bottom, upload above it,
/// with a few axis ticks and time labels. Self-drawn to match the repo's
/// no-chart-dependency stance.
class TrafficBarChart extends StatelessWidget {
  const TrafficBarChart({
    super.key,
    required this.points,
    required this.downloadColor,
    required this.uploadColor,
    this.height = 180,
  });

  final List<TrafficHourPoint> points;
  final Color downloadColor;
  final Color uploadColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('暂无数据')),
      );
    }
    return CustomPaint(
      painter: _BarPainter(
        points: points,
        downloadColor: downloadColor,
        uploadColor: uploadColor,
      ),
      child: SizedBox(height: height, width: double.infinity),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.points,
    required this.downloadColor,
    required this.uploadColor,
  });

  final List<TrafficHourPoint> points;
  final Color downloadColor;
  final Color uploadColor;

  static const _left = 46.0;
  static const _bottom = 22.0;
  static const _top = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - _left;
    final plotH = size.height - _bottom - _top;
    if (plotW <= 0 || plotH <= 0) return;

    final maxBytes = points
        .map((p) => p.download + p.upload)
        .fold<int>(0, math.max)
        .toDouble();
    // Round the axis up to a clean step so the top label is readable.
    final axisMax = _niceCeil(maxBytes == 0 ? 1 : maxBytes);

    final gridPaint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = _top + plotH * i / 2;
      canvas.drawLine(Offset(_left, y), Offset(_left + plotW, y), gridPaint);
      final value = axisMax * (2 - i) / 2;
      _drawText(
        canvas,
        _formatAxis(value),
        Offset(0, y - 6),
        const TextStyle(fontSize: 10, color: Color(0x99000000)),
      );
    }

    final slot = plotW / points.length;
    final barW = math.min(slot * 0.6, 22.0).toDouble();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final cx = _left + slot * (i + 0.5);
      final downH = plotH * p.download / axisMax;
      final upH = plotH * p.upload / axisMax;
      final x = cx - barW / 2;
      var y = _top + plotH - downH;
      canvas.drawRect(
        Rect.fromLTWH(x, y, barW, downH),
        Paint()..color = downloadColor,
      );
      y = y - upH;
      canvas.drawRect(
        Rect.fromLTWH(x, y, barW, upH),
        Paint()..color = uploadColor,
      );
      if (i % math.max(1, points.length ~/ 4) == 0) {
        _drawText(
          canvas,
          '${p.hour.hour}',
          Offset(cx - 8, _top + plotH + 5),
          const TextStyle(fontSize: 10, color: Color(0x99000000)),
        );
      }
    }
  }

  double _niceCeil(double value) {
    final magnitude = math.pow(10, math.log(value) / math.ln10).toDouble();
    return (value / magnitude).ceil() * magnitude;
  }

  String _formatAxis(double value) {
    if (value >= 1024 * 1024 * 1024) {
      return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
    if (value >= 1024 * 1024) {
      return '${(value / (1024 * 1024)).round()}MB';
    }
    if (value >= 1024) return '${(value / 1024).round()}KB';
    return value.round().toString();
  }

  void _drawText(Canvas canvas, String text, Offset at, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.points != points ||
      old.downloadColor != downloadColor ||
      old.uploadColor != uploadColor;
}
