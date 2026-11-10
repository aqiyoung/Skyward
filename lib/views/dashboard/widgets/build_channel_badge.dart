import 'package:skyward/common/common.dart';
import 'package:skyward/ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// The channel the running build came from, worn in the home's top right
/// corner.
///
/// A release is the app and needs no label; a dev or beta package is a build
/// being tried, and which one it is is the first thing worth knowing about it.
/// The label is read from the build itself (APP_CHANNEL), so it says the same
/// thing the version string on the tools page does.
///
/// Drawn as an outline rather than a filled pill: it is a label, not a
/// control, and the only filled pill in that corner is the core's status,
/// which is the one that changes.
class BuildChannelBadge extends StatelessWidget {
  const BuildChannelBadge({super.key});

  /// The hairline the app draws the rest of its borders with.
  static const _strokeWidth = 0.67;

  @override
  Widget build(BuildContext context) {
    final label = buildChannelSuffix();
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }
    final colorScheme = context.colorScheme;
    return Center(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: AppShape.full.copyWith(
            side: BorderSide(
              color: colorScheme.onSurfaceVariant.opacity30,
              width: _strokeWidth,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          child: Text(
            label,
            maxLines: 1,
            // Off the scale on purpose: this is a stamp in a corner rather
            // than a line of text, and the smallest rung still reads as one.
            style:
                AppTextStyle.custom(
                  context,
                  size: 10,
                  leading: 14,
                  weight: FontWeight.w600,
                ).copyWith(
                  // The channel is a stamp, not prose: a monospaced face keeps the
                  // two labels the same width as each other.
                  fontFamily: 'monospace',
                  letterSpacing: 0.4,
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }
}
