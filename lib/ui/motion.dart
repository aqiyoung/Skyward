import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

const fadeTabDuration = Duration(milliseconds: 220);
const fadeTabCurve = Curves.easeInOut;

/// Plays [spring] over the first [seconds] of an animation, easing out the
/// remaining residual so the curve still ends exactly at 1.
class SpringCurve extends Curve {
  SpringCurve(SpringDescription spring, {required this.seconds})
    : _simulation = SpringSimulation(spring, 0, 1, 0);

  final double seconds;
  final SpringSimulation _simulation;

  late final double _residual = 1 - _simulation.x(seconds);

  @override
  double transformInternal(double t) =>
      _simulation.x(t * seconds) + _residual * t;
}

Duration frameIntervalOf(BuildContext context) {
  final rate = View.maybeOf(context)?.display.refreshRate ?? 0;
  return rate > 0
      ? Duration(microseconds: Duration.microsecondsPerSecond ~/ rate)
      : Duration.zero;
}

/// Ends [simulation] at [end], where a controller would hold an overshoot.
class ArrivingSimulation extends Simulation {
  ArrivingSimulation(this.simulation, {required this.end})
    : _start = simulation.x(0),
      super(tolerance: simulation.tolerance);

  final Simulation simulation;
  final double end;
  final double _start;

  @override
  double x(double time) => simulation.x(time);

  @override
  double dx(double time) => simulation.dx(time);

  @override
  bool isDone(double time) =>
      simulation.isDone(time) ||
      (_start != end && (x(time) - end) * (_start - end) <= 0);
}

final dropletSpring = SpringDescription.withDampingRatio(
  mass: 1,
  stiffness: 165,
  ratio: 0.8,
);

/// Rises to 1 at [peak] and back, as iOS 27's droplets overshoot and swell.
double riseAndFall(double time, double peak, double sharpness) {
  if (time <= 0) {
    return 0;
  }
  final x = time / peak;
  return math.pow(x, sharpness) * math.exp(sharpness * (1 - x));
}

/// The spring UIKit uses for an outline disclosure: critically damped,
/// settling about 0.367 s from rest. Reading [CASpringAnimation] gives these
/// numbers; a plain [SpringCurve] on the same description is what makes a
/// group's rows and chevron move as one soft block instead of snapping.
final outlineUnfoldSpring = SpringDescription(
  mass: 1,
  stiffness: 631.65,
  damping: 50.27,
);

/// Drives a disclosure controller on [outlineUnfoldSpring], starting from
/// wherever it stands and at its current velocity, so a tap part-way through
/// a fold turns it around without a jolt.
abstract final class UnfoldMotion {
  static const duration = Duration(milliseconds: 367);
  static const tolerance = Tolerance(distance: 1e-3, velocity: 0.03);

  /// A folded chevron points at the label (-90 degrees); opening turns it to
  /// face the rows below (0). Skyward's caret-down glyph reads the reverse.
  static final chevronTurns = Tween<double>(begin: -0.25, end: 0);

  static void run(
    AnimationController controller, {
    required bool open,
    bool animate = true,
  }) {
    final target = open ? 1.0 : 0.0;
    if (!controller.isAnimating && controller.value == target) {
      return;
    }
    final simulation = SpringSimulation(
      outlineUnfoldSpring,
      animate ? controller.value : target,
      target,
      animate ? controller.velocity : 0,
      snapToEnd: true,
      tolerance: tolerance,
    );
    open
        ? controller.animateWith(simulation)
        : controller.animateBackWith(simulation);
  }
}
