import 'package:skyward/ui/icons/glyph.dart';
import 'package:skyward/ui/icons/glyph_icon.dart';
import 'package:skyward/ui/shape.dart';
import 'package:skyward/ui/surface.dart';
import 'package:material_ui/material_ui.dart';

/// A row's leading mark, set in the well `.agents/surfaces.md` gives one.
///
/// A mark that only identifies, a page's or a service's glyph, takes a neutral
/// well rather than a colour of its own: colour in this app says something is
/// selected, on, failing, or the one action a screen is for, and a list where
/// every row carried a hue would spend that meaning on decoration. The well
/// steps one level below the surface it sits on, so the same square reads on a
/// page and inside a card, and the glyph stays `onSurfaceVariant`.
///
/// The square itself is Clash for Apple Platforms' setting: its client leads
/// every destination row with a 29 dp well at radius 9, which lines a list up
/// on one rhythm instead of leaving a column of glyphs floating at their own
/// weights. Only the fill differs, because a coloured well would be the one
/// thing this app reserves.
class IconWell extends StatelessWidget {
  /// A 28 dp square holds a 17 dp glyph: the size Clash's row sets its symbol
  /// at, and large enough that a 1.5 dp stroke keeps its weight.
  const IconWell(
    this.glyph, {
    super.key,
    this.side = 28,
    this.glyphSize = 17,
    this.shape = AppShape.sm,
  });

  final Glyph glyph;
  final double side;
  final double glyphSize;

  /// A 40 dp well takes [AppShape.md], as the about page's links set it.
  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        shape: shape,
        color: context.raisedSurfaceLevel.colorOf(colorScheme),
      ),
      child: GlyphIcon(
        glyph,
        size: glyphSize,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
