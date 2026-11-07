import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:skyward/ui/context.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/navigation_dock.dart' show NavigationDockDestination;
import 'package:skyward/ui/shape.dart';
import 'package:skyward/ui/surface.dart';
import 'package:material_ui/material_ui.dart';

const double _height = 56;
const double _edgeMargin = 14;
const double _bottomMargin = 22;
const double _iconSize = 24;
const double _chipSize = 44;
const double _dotSize = 9;
const double _collapsedSize = 60;
const Duration _morph = Duration(milliseconds: 420);
const Duration _fade = Duration(milliseconds: 220);

/// A single rounded bar that hovers over the page, with the selected glyph in
/// a chip and a dot in the theme colour. On a long scroll it folds down to a
/// ball holding only the selected glyph.
class CapsuleNavigationDock extends StatelessWidget {
  const CapsuleNavigationDock({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.scale = 1,
    this.collapsed = false,
  });

  final List<NavigationDockDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double scale;
  final bool collapsed;

  static double insetOf(BuildContext context, [double scale = 1]) =>
      _height * scale +
      math.max(_bottomMargin * scale, MediaQuery.paddingOf(context).bottom);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final s = scale;
    final height = _height * s;
    final radius = AppRadius.all(height / 2);
    final bottom = math.max(
      _bottomMargin * s,
      MediaQuery.paddingOf(context).bottom,
    );
    final floating = SurfaceLevel.floatingOf(colorScheme).colorOf(colorScheme);
    final dark = colorScheme.brightness == Brightness.dark;

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
            final selected = destinations[selectedIndex];
            return AnimatedContainer(
              duration: _morph,
              curve: Curves.easeOutCubic,
              width: collapsed ? _collapsedSize * s : full,
              height: height,
              decoration: ShapeDecoration(
                shape: AppShape.full,
                shadows: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.16),
                    blurRadius: 20 * s,
                    offset: Offset(0, 6 * s),
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
                      color: floating.withValues(alpha: dark ? 0.78 : 0.84),
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
                          opacity: collapsed ? 0 : 1,
                          duration: _fade,
                          child: IgnorePointer(
                            ignoring: collapsed,
                            child: SizedBox(
                              width: full,
                              child: Row(
                                children: [
                                  for (var i = 0; i < destinations.length; i++)
                                    Expanded(
                                      child: _Destination(
                                        glyph: destinations[i].glyph,
                                        label: destinations[i].label,
                                        selected: i == selectedIndex,
                                        onTap: () => onSelected(i),
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
                          opacity: collapsed ? 1 : 0,
                          duration: _fade,
                          child: IgnorePointer(
                            ignoring: !collapsed,
                            child: Center(
                              child: _Destination(
                                glyph: selected.glyph,
                                label: selected.label,
                                selected: true,
                                onTap: () => onSelected(selectedIndex),
                                scale: s,
                                colorScheme: colorScheme,
                                showChip: false,
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
                                  colorScheme.onSurface.withValues(
                                    alpha: dark ? 0.06 : 0.10,
                                  ),
                                  Colors.transparent,
                                ],
                                stops: const [0, 0.5],
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
                                  colorScheme.primary.withValues(alpha: 0.07),
                                  Colors.transparent,
                                  Colors.transparent,
                                  colorScheme.tertiary.withValues(alpha: 0.06),
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

class _Destination extends StatelessWidget {
  const _Destination({
    required this.glyph,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scale,
    required this.colorScheme,
    this.showChip = true,
  });

  final Glyph glyph;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double scale;
  final ColorScheme colorScheme;
  final bool showChip;

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
                    ? colorScheme.onSurface.withValues(alpha: 0.11)
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
            if (selected)
              Align(
                alignment: const Alignment(0.62, -0.62),
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
    );
  }
}
