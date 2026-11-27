import 'dart:math' as math;

import 'package:skyward/ui/ui.dart';
import 'package:material_ui/material_ui.dart';

const _contentMaxWidth = 520.0;
const _badgeSize = 96.0;
const _ringWidth = 6.0;
const _ringInset = 2.0;
const _badgeCentre = 0.3;
const _secondaryHeight = 48.0;
const _ctaHeight = 52.0;

/// A one-purpose sheet for a step-driven flow: the badge rests at a fixed
/// share of the height and the foot keeps both button slots, so neither the
/// badge nor the main button jumps when the step changes.
class StageSheetLayout extends StatelessWidget {
  const StageSheetLayout({
    super.key,
    required this.hero,
    this.body = const [],
    this.primary,
    this.secondary,
  });

  final Widget hero;
  final List<Widget> body;
  final Widget? primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final scroll = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          math.max(
            context.contentTopPadding,
            constraints.maxHeight * _badgeCentre - _badgeSize / 2,
          ),
          16,
          16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [hero, ...body],
            ),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: scroll),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12 + context.bottomInset),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: _ctaHeight, child: primary),
                  SizedBox(
                    height: _secondaryHeight,
                    child: Center(child: secondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A badge, a title and an optional line under it, centered. Text swaps with
/// a short fade so state changes read as one step rather than a rebuild.
class StageSheetHero extends StatelessWidget {
  const StageSheetHero({
    super.key,
    required this.badge,
    required this.title,
    this.subtitle,
  });

  final Widget badge;
  final String title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          badge,
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: Column(
              key: ValueKey(title),
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.title2.of(context, emphasized: true),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  DefaultTextStyle.merge(
                    textAlign: TextAlign.center,
                    style: AppTextStyle.subheadline
                        .of(context)
                        .copyWith(color: context.colorScheme.onSurfaceVariant),
                    child: subtitle,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A glyph ringed by progress. A non-null [value] draws a full or partial
/// ring; null spins a quarter arc while the work is still in progress.
class StageSheetBadge extends StatelessWidget {
  const StageSheetBadge({
    super.key,
    required this.color,
    this.value = 0,
    required this.child,
  });

  final Color color;
  final double? value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final level = context.raisedSurfaceLevel;
    final well = level.colorOf(context.colorScheme);
    final track = context.colorScheme.surfaceContainerHighest;
    final content = Center(
      child: IconTheme.merge(
        data: IconThemeData(color: color, size: 40),
        child: child,
      ),
    );
    final value = this.value;
    return SizedBox.square(
      dimension: _badgeSize,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: (value ?? 0).clamp(0, 1)),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, shown, child) => CustomPaint(
          painter: _RingPainter(
            well: well,
            track: track,
            color: color,
            value: shown,
          ),
          child: child,
        ),
        child: value != null
            ? content
            : Stack(
                fit: StackFit.expand,
                children: [_RingSpinner(color: color), content],
              ),
      ),
    );
  }
}

class _RingSpinner extends StatefulWidget {
  const _RingSpinner({required this.color});
  final Color color;

  @override
  State<_RingSpinner> createState() => _RingSpinnerState();
}

class _RingSpinnerState extends State<_RingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turns;

  @override
  void initState() {
    super.initState();
    _turns = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _turns,
    child: CustomPaint(
      painter: _RingPainter(
        well: const Color(0x00000000),
        track: const Color(0x00000000),
        color: widget.color,
        value: 0.25,
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.well,
    required this.track,
    required this.color,
    this.value = 0,
  });

  final Color well;
  final Color track;
  final Color color;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(center, radius, Paint()..color = well);
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - _ringWidth / 2 - _ringInset,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, stroke..color = track);
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      stroke..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.well != well;
}
