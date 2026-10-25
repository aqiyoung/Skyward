import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:skyward/common/common.dart';
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

/// The land, one character a cell, ready to be read as dots.
///
/// Rasterised once from the 110m outline so the card carries no map package and
/// no runtime projection: the rows below are already in the equirectangular
/// frame the painter wants, with the Antarctic and the empty top of the Arctic
/// dropped. Columns run 360 / [worldMapColumns] of longitude each, starting at
/// 180 west.
const worldMapRows = [
  '..........................###.###############.........#.......................#.....................',
  '..................#......###......##########......................#.......#######...................',
  '#.....#..........####..#.#####.....#########.............#.......#...#################.#####........',
  '#...#######################...##...######.............#######.########.#############################',
  '.....####################.##..##....###.....#........###############################################',
  '....#####.##############....###......#.............####.#.###################################..##...',
  '.............############....####...............#...###.################################.....##.....',
  '..............#############.#######............#.#.#######################################...#......',
  '................###############.#.#..............#########################################..........',
  '................################..................########.#.###########################............',
  '...............###############..................###.##.###....########################..............',
  '................#############..................###....#..##########################..#..............',
  '................#############...................#####.......#######################..#.##...........',
  '..................#########....................#######..#...########################..#.............',
  '..................#####....#...................#####################################................',
  '....................###.......................##################.#...##############.................',
  '......#..............##..#..#................###############.#####....####..#####...................',
  '......................###....................################.###.....###...####...#................',
  '.........................##..................##################........#.....###....................',
  '..........................#..####.............##################.......#.....#.#....................',
  '............................######.............#################........#.........#.#...............',
  '............................########.................##########..............##..##.................',
  '............................########.................#########................#.###.................',
  '...........................############..............########.................#........###..#.......',
  '............................############..............#######...................##......###.........',
  '............................############..............#######............................#..........',
  '.............................##########..............########..#.....................###.#..........',
  '..............................#########..............#######..##....................#######.........',
  '...............................########...............######..#...................##########........',
  '..............................#######.................#####.......................##########........',
  '..............................######...................####.......................###########.......',
  '..............................#####....................###........................###..#####........',
  '..............................####.......................................................###......#.',
  '..............................###...................................................................',
  '..............................##.................................................................#..',
  '.............................###....................................................................',
  '.............................##.....................................................................',
  '..............................#.....................................................................',
];

const worldMapColumns = 100;
const worldMapRowCount = 38;

/// The latitudes the first and the last row are centred on.
const worldMapTopLatitude = 80.0;
const worldMapBottomLatitude = -56.0;

/// Draws the route a request takes, over a dot map of the world.
class RouteMap extends StatelessWidget {
  const RouteMap({super.key, required this.stops});

  final List<RouteStop> stops;

  /// Past this the map stops growing: a tablet should not spend half a card on
  /// empty ocean, and the top of the frame is the emptiest part of it.
  static const maxHeight = 176.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth,
          constraints.maxWidth * worldMapRowCount / worldMapColumns,
        );
        final map = RepaintBoundary(
          child: CustomPaint(
            size: size,
            painter: _RouteMapPainter(
              stops: stops,
              land: colorScheme.onSurfaceVariant.withValues(alpha: 0.24),
              line: colorScheme.primary.withValues(alpha: 0.55),
              marker: colorScheme.primary,
              halo: colorScheme.primary.withValues(alpha: 0.16),
            ),
          ),
        );
        if (size.height <= maxHeight) {
          return map;
        }
        return SizedBox(
          height: maxHeight,
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
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
    required this.land,
    required this.line,
    required this.marker,
    required this.halo,
  });

  final List<RouteStop> stops;
  final Color land;
  final Color line;
  final Color marker;
  final Color halo;

  /// The same device keeps the same width, so the dot field is worth keeping;
  /// the outline is 3800 cells and only its geometry is cached.
  ///
  /// One slot per size, because the dashboard shows the map at two of them at
  /// once -- the card, and the sheet opened over it -- and a single slot made
  /// them take turns throwing each other out, which cost the full scan on every
  /// frame. The cap keeps a window being dragged from growing the map without
  /// bound; a dragged size is not one that comes back.
  static const _landCacheLimit = 4;
  static final Map<Size, List<Offset>> _landCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    _paintLand(canvas, size);
    final points = [for (final stop in stops) _project(stop, size)];
    if (points.length > 1) {
      // A route that goes the short way round leaves the map on one side and
      // returns on the other, so the path is drawn three times, a world apart,
      // and the card's edge decides which copy shows.
      final paint = Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.0, size.width / 240);
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      for (final shift in const [0.0, -1.0, 1.0]) {
        for (var i = 0; i < points.length - 1; i++) {
          _drawArc(canvas, points[i], points[i + 1], shift * size.width, size, paint);
        }
      }
      canvas.restore();
    }
    _paintStops(canvas, points);
  }

  void _paintLand(Canvas canvas, Size size) {
    var points = _landCache[size];
    if (points == null) {
      if (_landCache.length >= _landCacheLimit) {
        _landCache.remove(_landCache.keys.first);
      }
      points = _landPoints(size);
      _landCache[size] = points;
    }
    canvas.drawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = land
        ..strokeCap = StrokeCap.round
        // Just over half a cell, so the dots stay apart and read as a grid of
        // specks rather than a filled outline.
        ..strokeWidth = math.max(1.3, size.width / worldMapColumns * 0.62),
    );
  }

  List<Offset> _landPoints(Size size) {
    final step = size.width / worldMapColumns;
    final rowHeight = size.height / worldMapRowCount;
    final points = <Offset>[];
    for (var row = 0; row < worldMapRows.length; row++) {
      final cells = worldMapRows[row];
      for (var column = 0; column < cells.length; column++) {
        if (cells[column] == '#') {
          points.add(
            Offset((column + 0.5) * step, (row + 0.5) * rowHeight),
          );
        }
      }
    }
    return points;
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

  Offset _project(RouteStop stop, Size size) {
    final x = (stop.longitude + 180) / 360;
    final y = (worldMapTopLatitude - stop.latitude) /
        (worldMapTopLatitude - worldMapBottomLatitude);
    return Offset(
      x * size.width,
      y.clamp(0.0, 1.0).toDouble() * size.height,
    );
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) =>
      oldDelegate.land != land ||
      oldDelegate.line != line ||
      oldDelegate.marker != marker ||
      oldDelegate.halo != halo ||
      !listEquals(oldDelegate.stops, stops);
}
