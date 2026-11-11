import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/views/dashboard/widgets/route_coastline.dart';
import 'package:skyward/views/dashboard/widgets/route_globe.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

/// Where a stop sits on the route.
enum RouteStopRole {
  /// The phone or the machine the traffic starts from.
  local,

  /// A hop the subscription put in the way.
  relay,

  /// What the traffic was addressed to.
  destination,
}

@immutable
final class RouteStop {
  const RouteStop(this.country, this.role, {this.place});

  final GeoCountry country;
  final RouteStopRole role;

  /// A city or province the name points at more exactly than the country
  /// does. Without one the country's own stand-in is used.
  final GeoPlace? place;

  double get latitude => place?.latitude ?? country.latitude;

  double get longitude => place?.longitude ?? country.longitude;

  @override
  bool operator ==(Object other) =>
      other is RouteStop &&
      other.country == country &&
      other.role == role &&
      other.place == place;

  @override
  int get hashCode => Object.hash(country, role, place);

  @override
  String toString() => 'RouteStop(${country.code}, ${role.name}, $place)';
}

/// The coastlines, a ring at a time, ready to be filled.
///
/// Rasterised once from the 110m outline so the card carries no map package and
/// no runtime projection. Every ring was unwrapped across the antimeridian, cut
/// to the frame's latitudes -- which drops the Antarctic and the empty top of
/// the Arctic -- and thinned to the detail a card can show. It is written here
/// five base-36 characters a point: three for the x, which may reach past the
/// right edge because the sheet is drawn three times, and two for the y. Two
/// more characters open each ring with its length.

/// The latitudes the sheet's top and bottom edges sit on.
const worldMapTopLatitude = 80.0;
const worldMapBottomLatitude = -56.0;

/// The longitude the sheet's left edge sits on when the chain asks for nothing
/// else. Both edges share it: the sheet is one strip of the world, cut where
/// the strip closes.
const _leftEdgeLongitude = -180.0;

/// Draws the route a request takes, over a flat map of the world.
class RouteMap extends StatefulWidget {
  const RouteMap({super.key, required this.stops, this.globe = false});

  final List<RouteStop> stops;

  /// Whether to draw the route on a globe instead of the flat sheet. The flat
  /// sheet is the default: it fits more of the world into the same height, and
  /// a route is mostly read as "which way round" rather than as "where".
  final bool globe;

  /// Past this the map stops growing: a tablet should not spend half a card on
  /// empty ocean, and the top of the frame is the emptiest part of it.
  static const maxHeight = 176.0;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap>
    with SingleTickerProviderStateMixin {
  /// Coming round to a route that crosses the seam moves the whole world under
  /// the frame. Played in one frame it reads as the card jumping; given a beat
  /// it reads as the sheet turning, which is what it is.
  static const _turnDuration = Duration(milliseconds: 420);

  late final AnimationController _turn;

  /// The cut the route asked for, and where the turn stands: the map is drawn
  /// for wherever the two are between them.
  late double _from;
  late double _goal;
  late double _to;

  @override
  void initState() {
    super.initState();
    _from = _goal = _to = _leftEdgeOf(widget.stops);
    _turn = AnimationController(vsync: this, duration: _turnDuration);
  }

  @override
  void didUpdateWidget(covariant RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _leftEdgeOf(widget.stops);
    if (next == _goal) {
      return;
    }
    // From where the sheet stands now rather than where the last move left it,
    // so a route that changes mid-turn takes over from the frame on screen.
    _from = _left;
    _goal = next;
    _to = _from + _near(next - _from);
    _turn.forward(from: 0);
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  /// The cut under the frame at this instant, on its way from one route's
  /// longitude to the next.
  double get _left =>
      _from + (_to - _from) * Curves.easeInOut.transform(_turn.value);

  @override
  Widget build(BuildContext context) {
    if (widget.globe) {
      return RouteGlobe(stops: widget.stops);
    }
    final colorScheme = context.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const span = worldMapTopLatitude - worldMapBottomLatitude;
        final size = Size(
          constraints.maxWidth,
          constraints.maxWidth * span / 360,
        );
        final map = RepaintBoundary(
          child: AnimatedBuilder(
            animation: _turn,
            builder: (context, _) => CustomPaint(
              size: size,
              painter: _RouteMapPainter(
                stops: widget.stops,
                left: _left,
                land: colorScheme.onSurfaceVariant.withValues(alpha: 0.16),
                line: colorScheme.primary.withValues(alpha: 0.55),
                marker: colorScheme.primary,
                halo: colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
          ),
        );
        if (size.height <= RouteMap.maxHeight) {
          return map;
        }
        // A wide panel makes the map taller than it should be, so it is
        // shrunk to fit the height -- the whole world stays visible (a route
        // to either pole must still show) and clipped to the card rather
        // than painted past its edges.
        return SizedBox(
          height: RouteMap.maxHeight,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            child: SizedBox.fromSize(size: size, child: map),
          ),
        );
      },
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  _RouteMapPainter({
    required this.stops,
    required this.left,
    required this.land,
    required this.line,
    required this.marker,
    required this.halo,
  });

  final List<RouteStop> stops;

  /// The longitude the sheet's left edge sits on. A route that asks for a
  /// different cut turns the map over a beat, so this arrives as a value on
  /// its way there rather than as the one the route names.
  final double left;

  final Color land;
  final Color line;
  final Color marker;
  final Color halo;

  @override
  void paint(Canvas canvas, Size size) {
    _paintLand(canvas, size, left);
    final points = [for (final stop in stops) _project(stop, size, left)];
    if (points.length > 1) {
      final paint = Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.0, size.width / 240);
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      for (var i = 0; i < points.length - 1; i++) {
        final from = points[i];
        var to = points[i + 1];
        // A chain is only turned when it steps over the seam, so a leg wider
        // than half the sheet means one wider than a world even after that --
        // two ends of it, or a hop that really is half a world. The far end
        // comes round to the near side, and the copies below decide which side
        // of the cut the leg shows on.
        final dx = to.dx - from.dx;
        if (dx.abs() > size.width / 2) {
          to = Offset(to.dx - dx.sign * size.width, to.dy);
        }
        for (final shift in const [-1.0, 0.0, 1.0]) {
          _drawArc(canvas, from, to, shift * size.width, size, paint);
        }
      }
      canvas.restore();
    }
    _paintStops(canvas, points);
  }

  void _paintLand(Canvas canvas, Size size, double left) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // The sheet is drawn three times, a world apart, so a ring that reaches
    // past the right edge comes back in on the left.
    canvas.scale(size.width, size.height);
    // The outline is held with the antimeridian at its edges, so turning the
    // sheet moves its edges under it.
    final turn = (left + 180) / 360;
    final paint = Paint()..color = land;
    for (final copy in const [-1.0, 0.0, 1.0]) {
      canvas.save();
      canvas.translate(copy - turn, 0);
      canvas.drawPath(coastlinePath, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  /// A hop on the map's one flat sheet; the curve stands in for the great
  /// circle without pretending to be the exact arc.
  void _drawArc(
    Canvas canvas,
    Offset from,
    Offset to,
    double dx,
    Size size,
    Paint paint,
  ) {
    final start = Offset(from.dx + dx, from.dy);
    final end = Offset(to.dx + dx, to.dy);
    final span = end - start;
    if (span.distanceSquared < 1) {
      return;
    }
    final lift = math.min(span.distance * 0.26, size.height * 0.45);
    final top = math.max(0.0, math.min(start.dy, end.dy) - lift);
    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(start.dx + span.dx / 2, top, end.dx, end.dy),
      paint,
    );
  }

  void _paintStops(Canvas canvas, List<Offset> points) {
    final fill = Paint()..color = marker;
    final haloPaint = Paint()..color = halo;
    final ring = Paint()
      ..color = marker
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final role = stops[i].role;
      final radius = role == RouteStopRole.relay ? 2.4 : 3.0;
      canvas.drawCircle(point, radius + 4.5, haloPaint);
      canvas.drawCircle(point, radius, fill);
      if (role == RouteStopRole.destination) {
        canvas.drawCircle(point, radius + 2.0, ring);
      }
    }
  }

  Offset _project(RouteStop stop, Size size, double left) {
    final x = ((stop.longitude - left) % 360) / 360;
    final y =
        (worldMapTopLatitude - stop.latitude) /
        (worldMapTopLatitude - worldMapBottomLatitude);
    return Offset(x * size.width, y.clamp(0.0, 1.0).toDouble() * size.height);
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) =>
      oldDelegate.left != left ||
      oldDelegate.land != land ||
      oldDelegate.line != line ||
      oldDelegate.marker != marker ||
      oldDelegate.halo != halo ||
      !listEquals(oldDelegate.stops, stops);
}

/// The longitude the sheet's left edge sits on for this chain.
///
/// A chain whose hops reach past both sides of the cut cannot be drawn in one
/// stroke: each hop would leave one edge and come back on the other, which
/// reads as a break rather than as the short way round. Such a chain gets a
/// sheet of its own -- its hops are laid end to end, each taken the short way
/// round, and the cut is put under the middle of that run -- so every hop
/// stays inside the frame. A chain that fits where the cut already is keeps
/// the map as it is, so the world does not move about between routes.
double _leftEdgeOf(List<RouteStop> stops) {
  if (stops.length < 2) {
    return _leftEdgeLongitude;
  }
  var run = stops.first.longitude;
  var previous = run;
  var low = run;
  var high = run;
  for (final stop in stops.skip(1)) {
    // A hop the short way round: a route that doubles back then stays as wide
    // as its hops and no wider.
    run += _near(stop.longitude - previous);
    previous = stop.longitude;
    low = math.min(low, run);
    high = math.max(high, run);
  }
  if (high - low > 340) {
    // Too wide for one sheet however it is turned, so the cut stays where it
    // was rather than trading the usual map for one that cannot hold it.
    return _leftEdgeLongitude;
  }
  for (var world = -3; world <= 3; world++) {
    final cut = _leftEdgeLongitude + world * 360.0;
    if (cut > low && cut < high) {
      return (low + high) / 2 - 180.0;
    }
  }
  return _leftEdgeLongitude;
}

/// [degrees] folded into (-180, 180], the way a difference in longitude reads:
/// the way round that is shorter.
double _near(double degrees) {
  final folded = degrees % 360;
  return folded > 180 ? folded - 360 : folded;
}
