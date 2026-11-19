import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// One hour's bytes, in the UI's own plain type so the chart stays independent
/// of the app's models (lib/ui may not reach lib/models).
typedef TrafficBarPoint = ({DateTime hour, int download, int upload});

/// A per-hour stacked bar chart: download on the bottom, upload above it,
/// with a few axis ticks and time labels. Self-drawn to match the repo's
/// no-chart-dependency stance.
class TrafficBarChart extends StatelessWidget {
  const TrafficBarChart({
    super.key,
    required this.points,
    required this.downloadColor,
    required this.uploadColor,
    required this.labelColor,
    this.height = 180,
  });

  final List<TrafficBarPoint> points;
  final Color downloadColor;
  final Color uploadColor;
  final Color labelColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('暂无数据', style: TextStyle(color: labelColor)),
        ),
      );
    }
    return CustomPaint(
      painter: _BarPainter(
        points: points,
        downloadColor: downloadColor,
        uploadColor: uploadColor,
        labelColor: labelColor,
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
    required this.labelColor,
  });

  final List<TrafficBarPoint> points;
  final Color downloadColor;
  final Color uploadColor;
  final Color labelColor;

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
        TextStyle(fontSize: 10, color: labelColor),
      );
    }

    final slot = plotW / points.length;
    final barW = math.min(slot * 0.55, 18.0).toDouble();
    // Vertical gradients give each bar a little depth instead of reading as a
    // flat block of colour.
    final downPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [downloadColor.withValues(alpha: 0.65), downloadColor],
      ).createShader(Rect.fromLTWH(0, _top, 0, plotH));
    final upPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [uploadColor.withValues(alpha: 0.65), uploadColor],
      ).createShader(Rect.fromLTWH(0, _top, 0, plotH));
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final cx = _left + slot * (i + 0.5);
      final downH = plotH * p.download / axisMax;
      final upH = plotH * p.upload / axisMax;
      final x = cx - barW / 2;
      var y = _top + plotH - downH;
      canvas.drawRect(Rect.fromLTWH(x, y, barW, downH), downPaint);
      y = y - upH;
      canvas.drawRect(Rect.fromLTWH(x, y, barW, upH), upPaint);
      if (i % math.max(1, points.length ~/ 4) == 0) {
        _drawText(
          canvas,
          '${p.hour.hour}',
          Offset(cx - 8, _top + plotH + 5),
          TextStyle(fontSize: 10, color: labelColor),
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
      old.uploadColor != uploadColor ||
      old.labelColor != labelColor;
}
