import 'dart:math' as math;

import 'package:skyward/enum/enum.dart';
import 'package:material_ui/material_ui.dart';

const _minDesktopWidth = 640.0;
const _minFourColumnWidth = 860.0;
const _minStandardFourColumnWidth = 1040.0;
const _minStandardHeight = 824.0;
const _mobileMaxWidth = 560.0;

int dashboardColumnsOf(double width) => width < _minFourColumnWidth ? 2 : 4;

/// Sorts the cards into the places they show in, one place per size: the cards
/// of each size are gathered into a pile where that size first appears, and a
/// hero card always stands in a place of its own.
///
/// A place only holds cards of one size because it shows one after another in
/// the same spot, and the order the reader gave is kept twice over: the piles
/// come in the order their first card was put in, and the cards inside a pile
/// keep the order they had among themselves.
List<List<DashboardWidget>> dashboardStacksOf(List<DashboardWidget> cards) {
  final stacks = <List<DashboardWidget>>[];
  final bySize = <DashboardCardSize, List<DashboardWidget>>{};
  for (final card in cards) {
    final stack = card.size == DashboardCardSize.hero
        ? null
        : bySize.putIfAbsent(card.size, () {
            final pile = <DashboardWidget>[];
            stacks.add(pile);
            return pile;
          });
    if (stack == null) {
      stacks.add([card]);
    } else {
      stack.add(card);
    }
  }
  return stacks;
}

/// The mobile cards and their editor share one centered column.
double dashboardMobileSideOf(double width) =>
    math.max(16, (width - _mobileMaxWidth) / 2);

/// [compact] shrinks type, the start button and tiles, and drops subtitles.
enum DashboardDensity {
  standard,
  compact,
  mobile;

  bool get isDesktop => this != mobile;

  bool get isCompact => this == compact;

  static DashboardDensity of(Size size) {
    if (size.width < _minDesktopWidth) {
      return mobile;
    }
    final narrowColumns =
        dashboardColumnsOf(size.width) == 4 &&
        size.width < _minStandardFourColumnWidth;
    return narrowColumns || size.height < _minStandardHeight
        ? compact
        : standard;
  }
}

/// Every fixed height on the dashboard grows by [scale] so its text fits.
class DashboardDensityScope extends InheritedWidget {
  const DashboardDensityScope({
    super.key,
    required this.density,
    required this.scale,
    required super.child,
  });

  final DashboardDensity density;
  final double scale;

  static DashboardDensityScope? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DashboardDensityScope>();

  static DashboardDensity of(BuildContext context) =>
      _of(context)?.density ?? DashboardDensity.mobile;

  static double scaleOf(BuildContext context) => _of(context)?.scale ?? 1;

  @override
  bool updateShouldNotify(DashboardDensityScope oldWidget) =>
      density != oldWidget.density || scale != oldWidget.scale;
}
