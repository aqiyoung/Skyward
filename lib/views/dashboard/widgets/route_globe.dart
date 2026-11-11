import 'dart:math' as math;

import 'package:skyward/ui/ui.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:skyward/views/dashboard/widgets/route_coastline.dart';
import 'package:skyward/views/dashboard/widgets/routing_map.dart';
import 'package:material_ui/material_ui.dart';

/// The route drawn on a globe: the same stops and the same coastline, turned
/// back into degrees and put on a sphere.
///
/// Orthographic, not perspective: a card this size has no room for the depth
/// cues a perspective camera needs, and a sphere seen edge-on reads as a disc
/// the moment the projection bends. What sells the sphere is the limb -- the
/// coastlines running right up to a hard circular edge, then stopping -- and
/// the graticule turning under it as the globe is dragged.
class RouteGlobe extends StatefulWidget {
  const RouteGlobe({super.key, required this.stops});

  final List<RouteStop> stops;

  /// The height the card gives the map. A globe wider than this is a globe
  /// with empty ocean either side of it.
  static const maxHeight = 176.0;

  @override
  State<RouteGlobe> createState() => _RouteGlobeState();
}

class _RouteGlobeState extends State<RouteGlobe> {
  /// Where the globe faces, in degrees. Starting from the route means the
  /// card shows the part of the world it is talking about.
  late double _lat;
  late double _lon;

  /// The centre the route asks for, kept so a drag can be undone by the next
  /// route rather than by a button.
  late double _homeLat;
  late double _homeLon;

  @override
  void initState() {
    super.initState();
    _homeLat = _lat = _centreOf(widget.stops).$1;
    _homeLon = _lon = _centreOf(widget.stops).$2;
  }

  @override
  void didUpdateWidget(covariant RouteGlobe oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _centreOf(widget.stops);
    if (next.$1 == _homeLat && next.$2 == _homeLon) {
      return;
    }
    _homeLat = next.$1;
    _homeLon = next.$2;
    // A route that changed while the globe was turned elsewhere comes back to
    // the new one: the card is about the route, not about where the pointer
    // last left the sphere.
    setState(() {
      _lat = next.$1;
      _lon = next.$2;
    });
  }

  /// The route's centre on the sphere: the average of its stops as unit
  /// vectors, which is the point in the middle of them however they are spread.
  static (double, double) _centreOf(List<RouteStop> stops) {
    if (stops.isEmpty) {
      return (18, 105);
    }
    var x = 0.0;
    var y = 0.0;
    var z = 0.0;
    for (final stop in stops) {
      final lat = stop.latitude * math.pi / 180;
      final lon = stop.longitude * math.pi / 180;
      x += math.cos(lat) * math.cos(lon);
      y += math.cos(lat) * math.sin(lon);
      z += math.sin(lat);
    }
    final length = math.sqrt(x * x + y * y + z * z);
    if (length < 1e-6) {
      return (0, 0);
    }
    final latitude = math.asin((z / length).clamp(-1.0, 1.0)) * 180 / math.pi;
    final longitude = math.atan2(y, x) * 180 / math.pi;
    return (latitude, longitude);
  }

  void _drag(DragUpdateDetails details, Size size) {
    final radius = size.shortestSide / 2;
    if (radius <= 0) {
      return;
    }
    // A drag across the whole globe turns it half a circle: the finger keeps
    // the patch of surface it grabbed under it.
    final perPixel = 180 / (math.pi * radius);
    setState(() {
      _lon = ((_lon - details.delta.dx * perPixel) + 540) % 360 - 180;
      _lat = (_lat + details.delta.dy * perPixel).clamp(-80.0, 80.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth,
          math.min(constraints.maxWidth, RouteGlobe.maxHeight),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) => _drag(details, size),
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: _RouteGlobePainter(
                stops: widget.stops,
                centreLatitude: _lat,
                centreLongitude: _lon,
                ocean: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
                land: colorScheme.onSurfaceVariant.withValues(alpha: 0.52),
                graticule: colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                limb: colorScheme.outlineVariant.withValues(alpha: 0.55),
                line: colorScheme.primary.withValues(alpha: 0.72),
                marker: colorScheme.primary,
                halo: colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RouteGlobePainter extends CustomPainter {
  _RouteGlobePainter({
    required this.stops,
    required this.centreLatitude,
    required this.centreLongitude,
    required this.ocean,
    required this.land,
    required this.graticule,
    required this.limb,
    required this.line,
    required this.marker,
    required this.halo,
  });

  final List<RouteStop> stops;
  final double centreLatitude;
  final double centreLongitude;
  final Color ocean;
  final Color land;
  final Color graticule;
  final Color limb;
  final Color line;
  final Color marker;
  final Color halo;

  late final _Projection _projection = _Projection(
    centreLatitude: centreLatitude,
    centreLongitude: centreLongitude,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;
    if (radius <= 0) {
      return;
    }
    _projection.fit(centre, radius);

    _paintSphere(canvas, centre, radius);
    _paintGraticule(canvas);
    _paintCoastlines(canvas);
    _paintRoute(canvas);
    _paintLimb(canvas, centre, radius);
  }

  /// The body: a flat disc with the light coming from the upper left, which is
  /// the reading everyone already gives a sphere in a card. The dark rim on the
  /// far side is what turns the circle into a ball -- without it the coastlines
  /// look printed on a disc.
  void _paintSphere(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(centre, radius, Paint()..color = ocean);
    final shade = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.4, -0.5),
        radius: 1.0,
        colors: [Color(0x16FFFFFF), Color(0x00FFFFFF), Color(0x52000000)],
        stops: [0.0, 0.52, 1.0],
      ).createShader(Rect.fromCircle(center: centre, radius: radius));
    canvas.drawCircle(centre, radius, shade);
  }

  void _paintLimb(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = limb
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  /// Meridians every 30 degrees and parallels every 30, drawn only where the
  /// surface faces the viewer.
  void _paintGraticule(Canvas canvas) {
    final paint = Paint()
      ..color = graticule
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var lon = -180; lon < 180; lon += 30) {
      _stroke(canvas, [
        for (var lat = -80; lat <= 80; lat += 4)
          (lat.toDouble(), lon.toDouble()),
      ], paint);
    }
    for (var lat = -60; lat <= 60; lat += 30) {
      _stroke(canvas, [
        for (var lon = -180; lon <= 180; lon += 4)
          (lat.toDouble(), lon.toDouble()),
      ], paint);
    }
  }

  void _paintCoastlines(Canvas canvas) {
    final paint = Paint()
      ..color = land
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeJoin = StrokeJoin.round;
    for (final ring in coastlineRings) {
      _stroke(canvas, [
        for (final point in ring) (point.latitude, point.longitude),
      ], paint);
    }
  }

  void _paintRoute(Canvas canvas) {
    final paint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;
    for (var i = 0; i < stops.length - 1; i++) {
      _stroke(canvas, _greatCircle(stops[i], stops[i + 1]), paint);
    }
    final fill = Paint()..color = marker;
    final ring = Paint()
      ..color = marker
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final glow = Paint()..color = halo;
    for (final stop in stops) {
      final point = _projection.project(stop.latitude, stop.longitude);
      if (point == null) {
        continue;
      }
      final radius = stop.role == RouteStopRole.relay ? 2.2 : 2.8;
      canvas.drawCircle(point, radius + 4.0, glow);
      canvas.drawCircle(point, radius, fill);
      if (stop.role == RouteStopRole.destination) {
        canvas.drawCircle(point, radius + 1.8, ring);
      }
    }
  }

  /// Points along the great circle between two stops, so a long leg bows the
  /// way it would on a real globe rather than cutting across the map.
  Iterable<(double, double)> _greatCircle(RouteStop from, RouteStop to) sync* {
    final a = _unit(from.latitude, from.longitude);
    final b = _unit(to.latitude, to.longitude);
    final dot = (a.$1 * b.$1 + a.$2 * b.$2 + a.$3 * b.$3).clamp(-1.0, 1.0);
    final omega = math.acos(dot);
    const steps = 28;
    if (omega < 1e-4) {
      yield (from.latitude, from.longitude);
      return;
    }
    final sinOmega = math.sin(omega);
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final ka = math.sin((1 - t) * omega) / sinOmega;
      final kb = math.sin(t * omega) / sinOmega;
      final x = a.$1 * ka + b.$1 * kb;
      final y = a.$2 * ka + b.$2 * kb;
      final z = a.$3 * ka + b.$3 * kb;
      yield (
        math.asin(z.clamp(-1.0, 1.0)) * 180 / math.pi,
        math.atan2(y, x) * 180 / math.pi,
      );
    }
  }

  static (double, double, double) _unit(double latitude, double longitude) {
    final lat = latitude * math.pi / 180;
    final lon = longitude * math.pi / 180;
    return (
      math.cos(lat) * math.cos(lon),
      math.cos(lat) * math.sin(lon),
      math.sin(lat),
    );
  }

  /// One polyline, split wherever it passes behind the globe: the back of a
  /// sphere is not drawn, and a segment that crosses the limb would otherwise
  /// cut straight across the face.
  void _stroke(Canvas canvas, Iterable<(double, double)> points, Paint paint) {
    final path = Path();
    var drawing = false;
    for (final (latitude, longitude) in points) {
      final point = _projection.project(latitude, longitude);
      if (point == null) {
        drawing = false;
        continue;
      }
      if (!drawing) {
        path.moveTo(point.dx, point.dy);
        drawing = true;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RouteGlobePainter oldDelegate) =>
      oldDelegate.centreLatitude != centreLatitude ||
      oldDelegate.centreLongitude != centreLongitude ||
      oldDelegate.ocean != ocean ||
      oldDelegate.land != land ||
      !listEquals(oldDelegate.stops, stops);
}

/// Orthographic projection onto the globe's face.
final class _Projection {
  _Projection({required this.centreLatitude, required this.centreLongitude});

  final double centreLatitude;
  final double centreLongitude;

  late Offset _centre;
  late double _radius;
  late double _sinLat;
  late double _cosLat;

  void fit(Offset centre, double radius) {
    _centre = centre;
    _radius = radius;
    final lat = centreLatitude * math.pi / 180;
    _sinLat = math.sin(lat);
    _cosLat = math.cos(lat);
  }

  /// The point's place on the face, or null when it is on the far side. The
  /// test is the depth, not the distance from the centre: the back of a sphere
  /// projects inside the same circle as the front.
  Offset? project(double latitude, double longitude) {
    final lat = latitude * math.pi / 180;
    final dLon = (longitude - centreLongitude) * math.pi / 180;
    final cosLat = math.cos(lat);
    final sinLat = math.sin(lat);
    final cosDLon = math.cos(dLon);
    final depth = _sinLat * sinLat + _cosLat * cosLat * cosDLon;
    if (depth <= 0) {
      return null;
    }
    final x = cosLat * math.sin(dLon);
    final y = _cosLat * sinLat - _sinLat * cosLat * cosDLon;
    return Offset(_centre.dx + _radius * x, _centre.dy - _radius * y);
  }
}
