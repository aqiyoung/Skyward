import 'package:skyward/ui/shape.dart';
import 'package:flutter/widgets.dart';

/// A slim, layered usage bar: a soft rounded track with a gradient fill on
/// top. [fraction] is clamped to 0..1. Colours are passed in so this stays a
/// pure UI primitive with no dependency on the app layer.
class UsageBar extends StatelessWidget {
  const UsageBar({
    super.key,
    required this.fraction,
    required this.gradient,
    this.trackColor,
    this.height = 6,
  });

  final double fraction;
  final Gradient gradient;
  final Color? trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fill = fraction.clamp(0.0, 1.0);
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: trackColor ?? const Color(0x14000000),
          shape: AppShape.full,
        ),
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: fill,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              gradient: gradient,
              shape: AppShape.full,
            ),
          ),
        ),
      ),
    );
  }
}
