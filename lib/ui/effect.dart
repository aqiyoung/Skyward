import 'dart:math';
import 'package:skyward/ui/motion.dart';
import 'dart:ui';

import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/inherited.dart';
import 'package:material_ui/material_ui.dart';

class CommonExpandIcon extends StatefulWidget {
  final bool expand;

  const CommonExpandIcon({super.key, this.expand = false});

  @override
  State<CommonExpandIcon> createState() => _CommonExpandIconState();
}

class _CommonExpandIconState extends State<CommonExpandIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _iconTurns;

  // The chevron rests pointing at the rows (-90 degrees) when folded and
  // turns to face down as the group opens, on the same outline spring the
  // rows use, so the two read as one motion.
  static final Animatable<double> _iconTurnTween = UnfoldMotion.chevronTurns
      .chain(
        CurveTween(curve: SpringCurve(outlineUnfoldSpring, seconds: 0.367)),
      );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: UnfoldMotion.duration,
      vsync: this,
    );
    _iconTurns = _animationController.drive(_iconTurnTween);
    // The controller is a normalized 0..1 driver; a spring-curved tween maps
    // its endpoints to the chevron's folded/opened turns.
    if (widget.expand) {
      _animationController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant CommonExpandIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expand != widget.expand) {
      UnfoldMotion.run(_animationController, open: widget.expand);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController.view,
      builder: (_, child) {
        return RotationTransition(turns: _iconTurns, child: child!);
      },
      child: const GlyphIcon(AppGlyphs.caretDown, fill: 1),
    );
  }
}

Widget commonProxyDecorator(
  Widget child,
  int index,
  Animation<double> animation,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (_, Widget? child) {
      final double animValue = Curves.easeInOut.transform(animation.value);
      final double scale = lerpDouble(1, 1.02, animValue)!;
      return ProxyDecoratorProvider(
        isProxyDecorator: true,
        lift: animValue,
        child: Transform.scale(scale: scale, child: child),
      );
    },
    child: child,
  );
}
