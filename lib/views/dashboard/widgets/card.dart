import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:material_ui/material_ui.dart';

EdgeInsets dashboardCardPadding(DashboardDensity density) => switch (density) {
  DashboardDensity.standard => const EdgeInsets.symmetric(
    horizontal: 22,
    vertical: 20,
  ),
  DashboardDensity.compact => const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  ),
  DashboardDensity.mobile => const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 18,
  ),
};

double dashboardCardRadius(DashboardDensity density) => density.isDesktop
    ? DashboardCorner.desktopCard
    : DashboardCorner.mobileCard;

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    this.padding,
    this.onTap,
    this.semanticLabel,
    this.clipBehavior = Clip.none,
    required this.child,
  });

  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Off by default so a control swelling under an [ElasticPress] can paint
  /// past the card's edge; only a card whose own content bleeds clips.
  final Clip clipBehavior;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final density = DashboardDensityScope.of(context);
    final shape = AppShape.all(dashboardCardRadius(density));
    final content = Padding(
      padding: padding ?? dashboardCardPadding(density),
      child: child,
    );
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        clipBehavior: clipBehavior,
        decoration: ShapeDecoration(
          color: DashboardColors.of(context).card,
          shape: shape,
          shadows: DashboardShadows.e1(context),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: onTap == null
              ? content
              : FocusRing(
                  shape: shape,
                  child: InkWell(
                    customBorder: shape,
                    onTap: onTap,
                    child: content,
                  ),
                ),
        ),
      ),
    );
  }
}

class DashboardCardHeader extends StatelessWidget {
  const DashboardCardHeader({
    super.key,
    this.glyph,
    required this.title,
    this.leading = const [],
    this.trailing = const [],
    this.chevron = false,
  });

  static const height = 24.0;
  static const glyphSize = 18.0;

  final Glyph? glyph;
  final String title;

  /// Sits right after the title, before the space that pushes [trailing] out.
  final List<Widget> leading;
  final List<Widget> trailing;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final mobile = !DashboardDensityScope.of(context).isDesktop;
    final scale = DashboardDensityScope.scaleOf(context);
    final colorScheme = context.colorScheme;
    final iconColor = colorScheme.onSurfaceVariant;
    final style = DashboardText.cardTitle(context);
    final end = [
      ...trailing,
      if (chevron)
        GlyphIcon(
          AppGlyphs.chevronForward,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
    ];
    final start = Row(
      spacing: 8,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        ...leading,
      ],
    );
    return SizedBox(
      height: (mobile ? 26 : height) * scale,
      child: Row(
        spacing: 8,
        children: [
          // Clash-style mobile cards carry no leading icon: the title alone
          // leads the card. Desktop keeps its glyph. The mobile check must
          // be a pattern guard, not an && before the pattern: `!mobile &&
          // glyph case ...` does not parse as a pattern match and fails the
          // build with a Glyph?/bool type error.
          if (glyph case final glyph? when !mobile)
            GlyphIcon(glyph, size: glyphSize, color: iconColor),
          Expanded(
            child: end.isEmpty
                ? start
                : DashboardCappedRow(
                    start: start,
                    end: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: end,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Cut short past [_minScale]: an IPv6 address shrunk any further is unreadable.
class DashboardFitText extends StatelessWidget {
  const DashboardFitText(this.text, {super.key, required this.style});

  static const _minScale = 0.75;

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = globalState.measure
            .computeTextSize(Text(text, style: style))
            .width;
        if (width * _minScale <= constraints.maxWidth) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(text, maxLines: 1, style: style),
          );
        }
        return TooltipText(
          text: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        );
      },
    );
  }
}

/// Lays [end] out first at its own width, up to [share] of the row and scaled
/// down past that, so long translations or large text never overflow; [start]
/// takes what is left.
class DashboardCappedRow extends StatelessWidget {
  const DashboardCappedRow({
    super.key,
    required this.start,
    required this.end,
    this.share = 0.5,
    this.spacing = 8,
  });

  final Widget start;
  final Widget end;
  final double share;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        spacing: spacing,
        children: [
          Expanded(child: start),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.max(0, constraints.maxWidth - spacing) * share,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: SizedBox(
                height: constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : null,
                child: end,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _connectedSelectDuration = Duration(milliseconds: 240);

/// A row of [DashboardConnectedButton]s; the one pressed last paints on top.
class DashboardConnectedGroup extends StatelessWidget {
  const DashboardConnectedGroup({
    super.key,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    required this.children,
  });

  final CrossAxisAlignment crossAxisAlignment;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _RaisedRow(
      crossAxisAlignment: crossAxisAlignment,
      spacing: 3,
      children: children,
    );
  }
}

class _RaisedRow extends Flex {
  const _RaisedRow({
    super.crossAxisAlignment,
    super.spacing,
    required super.children,
  }) : super(direction: Axis.horizontal);

  @override
  RenderFlex createRenderObject(BuildContext context) {
    return _RenderRaisedRow(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      clipBehavior: clipBehavior,
      spacing: spacing,
    );
  }
}

class _RenderRaisedRow extends RenderFlex {
  _RenderRaisedRow({
    super.direction,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.clipBehavior,
    super.spacing,
  });

  RenderBox? _raised;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is! PointerDownEvent) {
      return;
    }
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final offset = (child.parentData! as FlexParentData).offset;
      if ((offset & child.size).contains(entry.localPosition)) {
        if (child != _raised) {
          _raised = child;
          markNeedsPaint();
        }
        return;
      }
    }
  }

  @override
  void dropChild(RenderObject child) {
    if (child == _raised) {
      _raised = null;
    }
    super.dropChild(child);
  }

  @override
  void defaultPaint(PaintingContext context, Offset offset) {
    void paint(RenderBox child) => context.paintChild(
      child,
      (child.parentData! as FlexParentData).offset + offset,
    );
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (child != _raised) {
        paint(child);
      }
    }
    if (_raised case final raised?) {
      paint(raised);
    }
  }
}

/// Connected buttons: the ends round off the group, the inner corners stay
/// tight, and the selected one turns into a full pill. Each one swells under
/// a press. Clash-style selection is a light gray fill with blue text, not a
/// solid blue fill: blue is reserved for the selection itself, so the button
/// reads as chosen without painting the whole row blue. Dark mode keeps a
/// container fill, which a gray fill cannot carry there.
class DashboardConnectedButton extends StatelessWidget {
  const DashboardConnectedButton({
    super.key,
    required this.selected,
    required this.first,
    required this.last,
    required this.outer,
    required this.inner,
    required this.background,
    required this.onTap,
    required this.semanticLabel,
    required this.builder,
  });

  final bool selected;
  final bool first;
  final bool last;
  final double outer;
  final double inner;
  final Color background;
  final VoidCallback onTap;
  final String semanticLabel;
  final Widget Function(Color foreground) builder;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final startRest = first ? outer : inner;
    final endRest = last ? outer : inner;
    final colorScheme = context.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: ElasticPress(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: selected ? 1 : 0),
          duration: context.motionDuration(_connectedSelectDuration),
          curve: Curves.easeOutCubic,
          builder: (context, amount, child) {
            final start = lerpDouble(startRest, outer, amount)!;
            final end = lerpDouble(endRest, outer, amount)!;
            final shape = AppShape.of(
              BorderRadius.horizontal(
                left: Radius.circular(rtl ? end : start),
                right: Radius.circular(rtl ? start : end),
              ),
            );
            final isLight =
                colorScheme.brightness == Brightness.light;
            final selectedBackground = isLight
                ? const Color(0xFFE5E5EA)
                : colorScheme.primaryContainer;
            return FocusRing(
              shape: shape,
              standsOff: selected,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: Color.lerp(background, selectedBackground, amount),
                  shape: shape,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    customBorder: shape,
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    onTap: onTap,
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: builder(
            selected
                ? (colorScheme.brightness == Brightness.light
                      ? colorScheme.primary
                      : colorScheme.onPrimaryContainer)
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

enum DashboardChipTone { idle, ok, warn }

class DashboardChip extends StatelessWidget {
  const DashboardChip({
    super.key,
    required this.label,
    this.tone = DashboardChipTone.idle,
    this.dot = false,
    this.large = false,
  });

  final String label;
  final DashboardChipTone tone;
  final bool dot;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final colors = DashboardColors.of(context);
    final (background, foreground) = switch (tone) {
      DashboardChipTone.idle => (colors.tone, colorScheme.onSurfaceVariant),
      // Clash reserves bright green for running: in light mode the ok chip
      // is a vivid green capsule with white text, not a pale tint. Dark mode
      // keeps the container pair, where a vivid fill would not read.
      DashboardChipTone.ok => colorScheme.brightness == Brightness.light
          ? (colors.ok, Colors.white)
          : (colors.okContainer, colors.onOkContainer),
      DashboardChipTone.warn => (colors.warnContainer, colors.onWarnContainer),
    };
    return Container(
      height: large ? 28 : 24,
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 10),
      decoration: ShapeDecoration(color: background, shape: AppShape.full),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          if (dot)
            DecoratedBox(
              decoration: ShapeDecoration(
                color: foreground,
                shape: AppShape.circle,
              ),
              child: const SizedBox.square(dimension: 6),
            ),
          Text(
            label,
            maxLines: 1,
            style: AppTextStyle.caption1
                .of(context)
                .toTabular
                .copyWith(
                  color: foreground,
                  fontWeight: DashboardWeight.value,
                ),
          ),
        ],
      ),
    );
  }
}

/// A block inside a card, one tone off the card itself.
class DashboardBlock extends StatelessWidget {
  const DashboardBlock({
    super.key,
    required this.radius,
    this.color,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.semanticLabel,
    required this.child,
  });

  final double radius;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shape = AppShape.all(radius);
    final content = Padding(padding: padding, child: child);
    return Container(
      decoration: ShapeDecoration(
        color: color ?? DashboardColors.of(context).tone,
        shape: shape,
      ),
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: Semantics(
                button: true,
                label: semanticLabel,
                child: FocusRing(
                  shape: shape,
                  child: InkWell(
                    customBorder: shape,
                    onTap: onTap,
                    child: content,
                  ),
                ),
              ),
            ),
    );
  }
}

/// An M3 Expressive shape, filled, with [child] centered on it.
class ShapeBadge extends StatelessWidget {
  const ShapeBadge({
    super.key,
    required this.shape,
    required this.color,
    required this.size,
    this.rotation = 0,
    this.ring,
    this.child,
  });

  final RoundedPolygon shape;
  final Color color;
  final double size;

  /// Turns the shape alone, leaving [child] upright.
  final double rotation;
  final BorderSide? ring;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ShapePainter(
        path: shapePathOf(shape),
        color: color,
        rotation: rotation,
        ring: ring,
      ),
      child: SizedBox.square(
        dimension: size,
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

final _shapePaths = Expando<Path>();

Path shapePathOf(RoundedPolygon shape) => _shapePaths[shape] ??= shape.toPath();

/// Paints a path laid out in the unit square, the space [MaterialShapes]
/// are normalized to.
class ShapePainter extends CustomPainter {
  const ShapePainter({
    required this.path,
    required this.color,
    this.rotation = 0,
    this.ring,
  });

  final Path path;
  final Color color;
  final double rotation;
  final BorderSide? ring;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(rotation)
      ..scale(size.width, size.height)
      ..translate(-0.5, -0.5)
      ..drawPath(path, Paint()..color = color);
    if (ring case final ring?) {
      strokeUnitShape(canvas, path, size.width, ring);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ShapePainter oldDelegate) =>
      oldDelegate.path != path ||
      oldDelegate.color != color ||
      oldDelegate.rotation != rotation ||
      oldDelegate.ring != ring;
}

/// Strokes [side] along a unit-square [path] drawn at [extent], placing it by
/// [BorderSide.strokeAlign] with a scale about the center rather than an offset.
void strokeUnitShape(Canvas canvas, Path path, double extent, BorderSide side) {
  final scale = 1 + side.width * side.strokeAlign / extent;
  canvas
    ..save()
    ..translate(0.5, 0.5)
    ..scale(scale)
    ..translate(-0.5, -0.5)
    ..drawPath(path, side.toPaint()..strokeWidth = side.width / extent / scale)
    ..restore();
}

class DashboardSwitch extends StatelessWidget {
  const DashboardSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  /// A switch lays out past its track, which would set every row's height.
  static const trackWidth = CommonSwitch.trackWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: trackWidth,
      height: CommonSwitch.trackHeight,
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: CommonSwitch(
          value: value,
          onChanged: onChanged,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}

/// A row holding one setting behind a switch: a cookie-6 icon container while
/// it is on, a plain circle while it is off.
class DashboardSwitchRow extends StatelessWidget {
  const DashboardSwitchRow({
    super.key,
    required this.glyph,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.iconSize,
    required this.padding,
    required this.radius,
    this.color,
    this.onTap,
    this.showIcon = true,
    this.trailing,
  });

  final Glyph glyph;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final bool showIcon;

  /// Sits between the text and the switch, for an action on what the row now
  /// says rather than on its setting.
  final Widget? trailing;

  static const _gap = 12.0;

  /// Whether each of [titles] fits beside the icon in rows [width] wide, so
  /// sibling rows can drop their icons together before a title is cut short.
  static bool iconFits(
    BuildContext context, {
    required double width,
    required double iconSize,
    required EdgeInsetsGeometry padding,
    required Iterable<String> titles,
  }) {
    final style = DashboardText.rowTitle(context);
    final room =
        width -
        padding.horizontal -
        iconSize -
        _gap * 2 -
        DashboardSwitch.trackWidth;
    return titles.every(
      (title) =>
          globalState.measure
              .computeTextSize(Text(title, style: style))
              .width <=
          room,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final colors = DashboardColors.of(context);
    final glyphSize = iconSize * 0.5;
    return DashboardBlock(
      radius: radius,
      color: color,
      padding: padding,
      onTap: onTap,
      semanticLabel: title,
      child: Row(
        spacing: _gap,
        children: [
          if (showIcon)
            AnimatedSwitcher(
              duration: context.motionDuration(commonDuration),
              child: value
                  ? ShapeBadge(
                      key: const ValueKey(true),
                      shape: MaterialShapes.cookie6Sided,
                      color: colorScheme.primary,
                      size: iconSize,
                      child: GlyphIcon(
                        glyph,
                        size: glyphSize,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : ShapeBadge(
                      key: const ValueKey(false),
                      shape: MaterialShapes.circle,
                      color: colors.card,
                      size: iconSize,
                      child: GlyphIcon(
                        glyph,
                        size: glyphSize,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardText.rowTitle(context),
                ),
                if (subtitle case final subtitle?)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardText.label(context),
                  ),
              ],
            ),
          ),
          if (trailing case final trailing?) trailing,
          DashboardSwitch(
            value: value,
            onChanged: onChanged,
            semanticLabel: title,
          ),
        ],
      ),
    );
  }
}

/// A switch sized to share a row with another: no icon, the title on the
/// switch's line and its value under both, where half a card is too narrow
/// for the icon a full-width row carries.
class DashboardSwitchTile extends StatelessWidget {
  const DashboardSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTap,
    this.trailing,
    this.radius = DashboardCorner.mobileBlock,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  /// Rides the value's line, which spans the tile, rather than the title's.
  final Widget? trailing;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DashboardBlock(
      radius: radius,
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
      onTap: onTap,
      semanticLabel: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 6,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.footnote
                      .of(context)
                      .copyWith(fontWeight: DashboardWeight.value),
                ),
              ),
              DashboardSwitch(
                value: value,
                onChanged: onChanged,
                semanticLabel: title,
              ),
            ],
          ),
          if (subtitle case final subtitle?)
            SizedBox(
              height: 22,
              child: Row(
                spacing: 2,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        style: AppTextStyle.caption2
                            .of(context)
                            .toTabular
                            .copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                  if (trailing case final trailing?) trailing,
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The last [height] dp of a list that runs past its card fade out instead of
/// showing a scroll bar.
class DashboardFadeOut extends StatelessWidget {
  const DashboardFadeOut({super.key, required this.child});

  static const height = 44.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final stop = bounds.height <= 0
            ? 1.0
            : ((bounds.height - height) / bounds.height).clamp(0.0, 1.0);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Colors.black, Colors.black, Colors.transparent],
          stops: [0, stop, 1],
        ).createShader(bounds);
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: child,
      ),
    );
  }
}

class DashboardIconButton extends StatelessWidget {
  const DashboardIconButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.onPressed,
  });

  static const size = 32.0;
  static const glyphSize = 18.0;

  final Glyph glyph;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // A 24 tall card header would otherwise squeeze the circle into a pill.
    return SizedBox(
      width: size,
      child: OverflowBox(
        fit: OverflowBoxFit.deferToChild,
        minHeight: size,
        maxHeight: size,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          iconSize: glyphSize,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(size),
            fixedSize: const Size.square(size),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: context.colorScheme.onSurfaceVariant,
          ),
          onPressed: onPressed,
          icon: GlyphIcon(glyph, size: glyphSize),
        ),
      ),
    );
  }
}
