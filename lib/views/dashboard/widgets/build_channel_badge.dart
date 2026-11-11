import 'package:skyward/common/common.dart';
import 'package:skyward/ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// The channel the running build came from, worn as a slanted ribbon in the
/// home's top right corner.
///
/// A release is the app and needs no label; a dev or beta package is a build
/// being tried, and which one it is is the first thing worth knowing about it.
/// The label is read from the build itself (APP_CHANNEL), so it says the same
/// thing the version string on the tools page does.
///
/// Slanted and coloured, where the first version was a grey outline: at this
/// size an outline read as one more control beside the status button, and the
/// corner already has one of those. A ribbon with a gradient is a stamp --
/// something about the build rather than something to press -- and the slant is
/// what keeps it from looking like the pill below it.
class BuildChannelBadge extends StatelessWidget {
  const BuildChannelBadge({super.key});

  /// Tall enough to read as a badge rather than a chip, still inside the title
  /// row it shares with the page heading.
  static const _height = 26.0;

  /// How far the top edge leads the bottom one. This is the slant; without it
  /// the shape is a pill again.
  static const _slant = 7.0;

  @override
  Widget build(BuildContext context) {
    final label = buildChannelLabel();
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }
    final palette = _paletteOf(label);
    return Center(
      child: SizedBox(
        height: _height,
        child: ClipPath(
          clipper: const _RibbonClipper(_slant),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.start, palette.end],
              ),
            ),
            child: DecoratedBox(
              // The light catching the top edge: one flat gradient reads as a
              // sticker, a band that brightens toward the top reads as ribbon.
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                  stops: [0, 0.6],
                ),
              ),
              child: Padding(
                // The top edge leads, so the left side loses width a line of
                // text cannot see: the padding is split to keep the word
                // optically centred in the shape rather than in its bounding
                // box.
                padding: const EdgeInsets.only(left: 16, right: 10),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    maxLines: 1,
                    // Off the scale on purpose: this is a stamp in a corner
                    // rather than a line of text.
                    style:
                        AppTextStyle.custom(
                          context,
                          size: 12,
                          leading: 16,
                          weight: FontWeight.w800,
                        ).copyWith(
                          color: const Color(0xFFFFFFFF),
                          letterSpacing: 1.3,
                          height: 1,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The two colours a channel's ribbon runs between.
///
/// Read from the label rather than from `buildChannel`, so the ribbon and the
/// word on it cannot disagree: whatever names the channel names the colour.
_ChannelPalette _paletteOf(String label) {
  return switch (label.toUpperCase()) {
    'DEV' => const _ChannelPalette(
      start: Color(0xFF4F7BFF),
      end: Color(0xFF9E5CFF),
    ),
    'BETA' => const _ChannelPalette(
      start: Color(0xFFFF9F2E),
      end: Color(0xFFFF4D6D),
    ),
    // A channel nobody has given a colour yet: readable, plainly not one of
    // the two above.
    _ => const _ChannelPalette(
      start: Color(0xFF6B7280),
      end: Color(0xFF9CA3AF),
    ),
  };
}

class _ChannelPalette {
  const _ChannelPalette({required this.start, required this.end});

  final Color start;
  final Color end;
}

/// A rectangle whose top edge leads its bottom edge -- a ribbon cut at an
/// angle, rather than another rounded pill.
class _RibbonClipper extends CustomClipper<Path> {
  const _RibbonClipper(this.slant);

  final double slant;

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(slant, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - slant, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_RibbonClipper oldClipper) => oldClipper.slant != slant;
}
