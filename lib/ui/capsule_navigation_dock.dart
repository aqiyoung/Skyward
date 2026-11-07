import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:skyward/ui/context.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/navigation_dock.dart' show NavigationDockDestination;
import 'package:skyward/ui/shape.dart';
import 'package:skyward/ui/surface.dart';
import 'package:material_ui/material_ui.dart';

const double _height = 66;
const double _edgeMargin = 16;
const double _bottomMargin = 20;
const double _iconSize = 27;
const double _chipSize = 54;
const double _dotSize = 9;

/// How far a finger has to travel across the bar before it starts scrubbing
/// the selection, so a tap that wobbles still counts as a tap.
const double _scrubSlop = 10;

/// How far a flick on the folded ball has to travel to step one tab over.
const double _stepTravel = 36;
const Duration _morph = Duration(milliseconds: 420);
const Duration _fade = Duration(milliseconds: 220);

/// A single rounded bar that hovers over the page, with the selected glyph in
/// a chip and a dot in the theme colour. On a long scroll it folds down to a
/// ball holding only the selected glyph.
///
/// A finger dragged across the bar takes the selection with it, the way a
/// segmented control does, so the tabs can be changed without aiming at one.
class CapsuleNavigationDock extends StatefulWidget {
  const CapsuleNavigationDock({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.onExpand,
    this.scale = 1,
    this.collapsed = false,
  });

  final List<NavigationDockDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Called when the folded ball is tapped. Without it a tap on the ball is a
  /// tap on the selected tab, which changes nothing.
  final VoidCallback? onExpand;

  final double scale;
  final bool collapsed;

  static double insetOf(BuildContext context, [double scale = 1]) =>
      _height * scale +
      math.max(_bottomMargin * scale, MediaQuery.paddingOf(context).bottom);

  @override
  State<CapsuleNavigationDock> createState() => _CapsuleNavigationDockState();
}

class _CapsuleNavigationDockState extends State<CapsuleNavigationDock> {
  /// Travel of the current drag, used both to clear the slop and to decide
  /// when a flick on the ball has gone far enough.
  double _travel = 0;
  bool _scrubbing = false;

  int get _count => widget.destinations.length;

  void _dragStart(DragStartDetails details) {
    _travel = 0;
    _scrubbing = false;
  }

  void _dragUpdate(DragUpdateDetails details, double width) {
    _travel += details.delta.dx;
    if (widget.collapsed) {
      // There is no room to scrub inside a ball: a flick steps one tab over
      // and the ball stays where it is.
      if (_travel.abs() >= _stepTravel) {
        _step(_travel.sign);
      }
      return;
    }
    if (!_scrubbing && _travel.abs() < _scrubSlop) {
      return;
    }
    _scrubbing = true;
    final slot = width / _count;
    if (slot <= 0) {
      return;
    }
    final index = (details.localPosition.dx / slot).floor().clamp(
      0,
      _count - 1,
    );
    if (index != widget.selectedIndex) {
      widget.onSelected(index);
    }
  }

  void _step(double direction) {
    final next = (widget.selectedIndex + (direction < 0 ? -1 : 1)).clamp(
      0,
      _count - 1,
    );
    if (next != widget.selectedIndex) {
      widget.onSelected(next);
    }
    _travel = 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final s = widget.scale;
    final height = _height * s;
    final radius = AppRadius.all(height / 2);
    final bottom = math.max(
      _bottomMargin * s,
      MediaQuery.paddingOf(context).bottom,
    );
    final floating = SurfaceLevel.floatingOf(colorScheme).colorOf(colorScheme);
    final dark = colorScheme.brightness == Brightness.dark;
    final selected = widget.destinations[widget.selectedIndex];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _edgeMargin * s,
        8 * s,
        _edgeMargin * s,
        bottom,
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final full = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _dragStart,
              onHorizontalDragUpdate: (details) => _dragUpdate(details, full),
              onHorizontalDragEnd: (_) => _travel = 0,
              child: AnimatedContainer(
                duration: _morph,
                curve: Curves.easeOutCubic,
                width: widget.collapsed ? height : full,
                height: height,
                decoration: ShapeDecoration(
                  shape: AppShape.full,
                  shadows: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.18),
                      blurRadius: 24 * s,
                      offset: Offset(0, 8 * s),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRSuperellipse(
                  borderRadius: radius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: floating.withValues(alpha: dark ? 0.78 : 0.86),
                        shape: AppShape.full.copyWith(
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: dark ? 0.22 : 0.55,
                            ),
                          ),
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // A fixed width keeps the glyphs from being squeezed
                          // while the bar narrows; the clip hides the rest.
                          AnimatedOpacity(
                            opacity: widget.collapsed ? 0 : 1,
                            duration: _fade,
                            child: IgnorePointer(
                              ignoring: widget.collapsed,
                              child: SizedBox(
                                width: full,
                                child: Row(
                                  children: [
                                    for (var i = 0; i < _count; i++)
                                      Expanded(
                                        child: _Destination(
                                          glyph: widget.destinations[i].glyph,
                                          label: widget.destinations[i].label,
                                          selected: i == widget.selectedIndex,
                                          onTap: () => widget.onSelected(i),
                                          scale: s,
                                          colorScheme: colorScheme,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: widget.collapsed ? 1 : 0,
                            duration: _fade,
                            child: IgnorePointer(
                              ignoring: !widget.collapsed,
                              child: Center(
                                child: _Destination(
                                  glyph: selected.glyph,
                                  label: selected.label,
                                  selected: true,
                                  onTap: () => widget.onExpand?.call(),
                                  scale: s,
                                  colorScheme: colorScheme,
                                  showChip: false,
                                  showDot: false,
                                ),
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                shape: AppShape.full,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(
                                      alpha: dark ? 0.10 : 0.55,
                                    ),
                                    Colors.transparent,
                                  ],
                                  stops: const [0, 0.6],
                                ),
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                shape: AppShape.full,
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.05),
                                    Colors.transparent,
                                    Colors.transparent,
                                    colorScheme.tertiary.withValues(
                                      alpha: 0.05,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.glyph,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scale,
    required this.colorScheme,
    this.showChip = true,
    this.showDot = true,
  });

  final Glyph glyph;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double scale;
  final ColorScheme colorScheme;
  final bool showChip;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final chip = _chipSize * s;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: SizedBox(
            width: chip,
            height: chip,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: _fade,
                  width: chip,
                  height: chip,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected && showChip
                        ? colorScheme.onSurface.withValues(alpha: 0.10)
                        : Colors.transparent,
                  ),
                ),
                IconTheme(
                  data: IconThemeData(
                    color: selected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    size: _iconSize * s,
                  ),
                  child: AnimatedGlyph(glyph: glyph, filled: selected),
                ),
                if (selected && showDot)
                  Align(
                    alignment: const Alignment(0.8, -0.8),
                    child: Container(
                      width: _dotSize * s,
                      height: _dotSize * s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                        border: Border.all(
                          color: SurfaceLevel.floatingOf(
                            colorScheme,
                          ).colorOf(colorScheme),
                          width: 2 * s,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
