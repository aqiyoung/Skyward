import 'dart:math' as math;

import 'package:skyward/ui/context.dart';
import 'package:skyward/ui/haptic.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/liquid_glass.dart';
import 'package:skyward/ui/navigation_dock.dart'
    show NavigationDockDestination, dockGlassShadows, dockShadows;
import 'package:skyward/ui/shape.dart';
import 'package:skyward/ui/surface.dart';
import 'package:material_ui/material_ui.dart';

/// The open bar: wide and hefty, spanning the page with a small margin either
/// side. This is the normal state, the way X shows its dock.
const double _height = 76;
const double _edgeMargin = 16;
const double _bottomMargin = 20;

/// The folded ball: deliberately shorter than the open bar, so folding reads
/// as the whole bar shrinking rather than just the ends coming in.
const double _collapsedSize = 50;
const double _iconSize = 30;
const double _chipSize = 66;
const double _borderWidth = 1.6;

/// How far a finger has to travel across the bar before it starts scrubbing
/// the selection, so a tap that wobbles still counts as a tap.
const double _scrubSlop = 10;

/// How far a flick on the folded ball has to travel to step one tab over.
const double _stepTravel = 36;
const Duration _morph = Duration(milliseconds: 420);
const Duration _fade = Duration(milliseconds: 220);

/// A wide, hefty rounded bar that spans the page with the selected glyph in a
/// chip. On a long scroll the whole bar shrinks down to a small ball holding
/// only the selected glyph, then grows back.
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
      hapticSelection(context);
      widget.onSelected(index);
    }
  }

  void _step(double direction) {
    final next = (widget.selectedIndex + (direction < 0 ? -1 : 1)).clamp(
      0,
      _count - 1,
    );
    if (next != widget.selectedIndex) {
      hapticSelection(context);
      widget.onSelected(next);
    }
    _travel = 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final s = widget.scale;
    final height = _height * s;
    final ball = _collapsedSize * s;
    // A stadium radius clamps to half the short side, so the corners stay
    // round through the whole width/height animation, not just at its ends.
    const radius = AppRadius.full;
    final bottom = math.max(
      _bottomMargin * s,
      MediaQuery.paddingOf(context).bottom,
    );
    final dark = colorScheme.brightness == Brightness.dark;
    final selected = widget.destinations[widget.selectedIndex];
    final glass = LiquidGlassScope.of(context);
    final ultra =
        LiquidGlassScope.qualityOf(context) == LiquidGlassQuality.ultra;

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
            // Open, the bar spans the page with just a margin either side;
            // folded, it shrinks into a ball against the leading edge.
            final full = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _dragStart,
              onHorizontalDragUpdate: (details) => _dragUpdate(details, full),
              onHorizontalDragEnd: (_) => _travel = 0,
              child: AnimatedContainer(
                duration: _morph,
                curve: Curves.easeOutCubic,
                width: widget.collapsed ? ball : full,
                height: widget.collapsed ? ball : height,
                decoration: ShapeDecoration(
                  shape: AppShape.full,
                  // Glass draws its own depth through the pane; when it is off
                  // the bar takes the same light lift as the other docks,
                  // never a second heavy shadow on top of a backdrop blur.
                  shadows: glass ? const [] : dockShadows(colorScheme),
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRSuperellipse(
                  borderRadius: radius,
                  child: _CapsuleSurface(
                    glass: glass,
                    style: LiquidGlassStyle.pill(colorScheme),
                    shadows: ultra ? dockGlassShadows(colorScheme) : const [],
                    colorScheme: colorScheme,
                    dark: dark,
                    scale: s,
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
                                        onTap: () {
                                          hapticTap(context);
                                          widget.onSelected(i);
                                        },
                                        scale: s,
                                        colorScheme: colorScheme,
                                        glass: glass,
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
                                scale: s * 0.8,
                                colorScheme: colorScheme,
                                showChip: false,
                                glass: glass,
                              ),
                            ),
                          ),
                        ),
                        if (!glass)
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
                        if (!glass)
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
            );
          },
        ),
      ),
    );
  }
}

/// What the capsule stands on: the same glass pane as the other docks, or a
/// plain opaque surface when glass is off. The old fixed `blur(18)` painted a
/// blur no switch could turn off, which is why the bar kept flickering and
/// cost memory on low-end devices.
class _CapsuleSurface extends StatelessWidget {
  const _CapsuleSurface({
    required this.glass,
    required this.style,
    required this.shadows,
    required this.colorScheme,
    required this.dark,
    required this.scale,
    required this.child,
  });

  final bool glass;
  final LiquidGlassStyle style;
  final List<BoxShadow> shadows;
  final ColorScheme colorScheme;
  final bool dark;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (glass) {
      // The pane supplies tint, haze, rim and dispersion. Anything painted
      // behind it would only muddy the refraction.
      return LiquidGlass(style: style, shadows: shadows, child: child);
    }
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: SurfaceLevel.floatingOf(colorScheme).colorOf(colorScheme),
        shape: AppShape.full.copyWith(
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: dark ? 0.30 : 0.72,
            ),
            width: _borderWidth * scale,
          ),
        ),
      ),
      child: child,
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
    this.glass = false,
  });

  final Glyph glyph;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double scale;
  final ColorScheme colorScheme;
  final bool showChip;
  final bool glass;

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
                        ? colorScheme.onSurface.withValues(
                            alpha: glass ? 0.06 : 0.14,
                          )
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
