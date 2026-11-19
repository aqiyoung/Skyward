import 'package:skyward/ui/icons/glyph.dart';
import 'package:skyward/ui/icons/glyph_icon.dart';
import 'package:skyward/ui/shape.dart';
import 'package:material_ui/material_ui.dart';

/// A row's leading glyph, with no well behind it.
///
/// Option B of the simplification pass: the 28 dp square remains only as a
/// spacer, so a page's rows still line up on one rhythm, but the raised neutral
/// well it used to sit in is no longer painted. A mark that only identifies is
/// left in `onSurfaceVariant` with no colour of its own -- colour in this app
/// says something is selected, on, failing, or the one action a screen is for.
///
/// The spacing follows Clash for Apple Platforms' setting, whose client leads
/// every destination row with a 29 dp mark at one rhythm. Keeping the square
/// while dropping its fill is what makes every list read a step lighter: the
/// glyph still distinguishes a page, a tool or a setting, but the column of
/// grey boxes under it -- and the white card behind that -- no longer stacks
/// into a third layer.
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
      // Option B of the simplification pass: the well's raised, neutral
      // fill is gone. The square stays only as a 28 dp spacer so rows keep
      // their shared rhythm, and the shape is no longer painted. The glyph
      // alone identifies the row, in `onSurfaceVariant` as before.
      decoration: ShapeDecoration(shape: shape),
      child: GlyphIcon(
        glyph,
        size: glyphSize,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
