import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'layout.dart';
import 'style.dart';
import 'widget_registry.dart';

const _rowHeight = 64.0;
const _rowGap = 8.0;
const _addableTop = 14.0;
const _swayLoop = Duration(milliseconds: 3600);
const _swaysPerLoop = [6, 7, 5];
const _swayPhaseStep = 1.7;
const _swayTurn = 0.7 * math.pi / 180;
const _swayBob = 1.25;
const _roomDuration = Duration(milliseconds: 260);
const _appearDuration = Duration(milliseconds: 200);
const _appearScale = 0.92;
const _liftGrowth = 0.03;

/// Drop a held pile in a row's center to stack it; use the edges to reorder.
class DashboardEditor extends ConsumerStatefulWidget {
  const DashboardEditor({
    super.key,
    required this.platform,
    required this.stacks,
    required this.cardKeyOf,
    required this.padding,
    required this.gap,
    required this.onDone,
  });

  final SupportPlatform platform;
  final List<List<DashboardWidget>> stacks;

  /// Shared with the cards outside edit mode, so each keeps its state.
  final GlobalKey Function(DashboardWidget widget) cardKeyOf;
  final EdgeInsets padding;
  final double gap;
  final VoidCallback onDone;

  @override
  ConsumerState<DashboardEditor> createState() => _DashboardEditorState();
}

class _DashboardEditorState extends ConsumerState<DashboardEditor>
    with SingleTickerProviderStateMixin {
  late final _sway = AnimationController(vsync: this, duration: _swayLoop);

  late var _stacks = _copyOf(widget.stacks);
  final _leaving = <DashboardWidget>{};
  final _entering = <DashboardWidget>{};
  var _dragging = false;

  static List<List<DashboardWidget>> _copyOf(
    List<List<DashboardWidget>> stacks,
  ) => [
    for (final pile in stacks) [...pile],
  ];

  List<List<DashboardWidget>> get _settled => [
    for (final pile in _stacks)
      [
        for (final card in pile)
          if (!_leaving.contains(card)) card,
      ],
  ].where((pile) => pile.isNotEmpty).toList();

  List<DashboardWidget> get _shown => [for (final pile in _settled) ...pile];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.disableAnimations) {
      _sway.stop();
    } else if (!_sway.isAnimating) {
      _sway.repeat();
    }
  }

  @override
  void didUpdateWidget(DashboardEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
      [for (final pile in widget.stacks) ...pile],
      _shown,
    )) {
      _stacks = _copyOf(widget.stacks);
      _leaving.clear();
      _entering.clear();
    }
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  void _save() {
    final stacks = _settled;
    ref
        .read(appSettingProvider.notifier)
        .update((state) {
          final merged = _withOtherPlatforms(
            state.dashboardStacks,
            state.dashboardWidgets,
            stacks,
          );
          return state.copyWith(
            dashboardWidgets: [for (final pile in merged) ...pile],
            dashboardStacks: merged,
          );
        });
  }

  // Keep unsupported cards in their saved slots as standalone piles.
  List<List<DashboardWidget>> _withOtherPlatforms(
    List<List<DashboardWidget>>? savedStacks,
    List<DashboardWidget> savedWidgets,
    List<List<DashboardWidget>> stacks,
  ) {
    final source = savedStacks != null && savedStacks.isNotEmpty
        ? savedStacks
        : [
            for (final card in savedWidgets) [card],
          ];
    final result = [
      for (final pile in stacks) [...pile],
    ];
    for (var at = 0; at < source.length; at++) {
      for (final card in source[at]) {
        if (!card.platforms.contains(widget.platform)) {
          result.insert(at.clamp(0, result.length), [card]);
        }
      }
    }
    return result;
  }

  void _remove(DashboardWidget card) {
    setState(() => _leaving.add(card));
    _save();
  }

  void _add(DashboardWidget card) {
    setState(() {
      if (!_leaving.remove(card)) {
        _entering.add(card);
        _stacks = [
          ..._stacks,
          [card],
        ];
      }
    });
    _save();
  }

  void _turn(int at) {
    final pile = _stacks[at];
    if (pile.length < 2) {
      return;
    }
    setState(() => _stacks[at] = [...pile.skip(1), pile.first]);
    _save();
  }

  void _split(int at) {
    final pile = _stacks[at];
    if (pile.length < 2) {
      return;
    }
    setState(() {
      _stacks = [
        ..._stacks.take(at),
        for (final card in pile) [card],
        ..._stacks.skip(at + 1),
      ];
    });
    _save();
  }

  // Center drops merge piles; edge drops only reorder.
  void _drop(int from, int to, {required bool stack}) {
    if (from == to) {
      return;
    }
    setState(() {
      final pile = _stacks.removeAt(from);
      final at = (to > from ? to - 1 : to).clamp(0, _stacks.length);
      if (stack) {
        _stacks[at] = [..._stacks[at], ...pile];
      } else {
        _stacks.insert(at, pile);
      }
    });
    _save();
  }

  void _settle(DashboardWidget card) {
    _entering.remove(card);
    if (mounted && _leaving.remove(card)) {
      setState(
        () => _stacks = [
          for (final pile in _stacks)
            [
              for (final item in pile)
                if (item != card) item,
            ],
        ].where((pile) => pile.isNotEmpty).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stacks = _stacks;
    final shown = _shown;
    final addable = [
      for (final card in DashboardWidget.values)
        if (card.platforms.contains(widget.platform) && !shown.contains(card))
          card,
    ];
    final sway = context.disableAnimations ? null : _sway;
    final appLocalizations = context.appLocalizations;

    final revealPadding = EdgeInsets.only(
      top: widget.padding.top,
      bottom: widget.padding.bottom,
    );

    Widget spaced(Widget child) => Padding(
      padding: EdgeInsets.only(bottom: widget.gap),
      child: child,
    );

    return BackLayerScope(
      onBack: widget.onDone,
      child: SliverPadding(
        padding: widget.padding,
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (at, pile) in stacks.indexed)
                    _Presence(
                      key: ValueKey(pile.first),
                      entering: _entering.contains(pile.first),
                      leaving: pile.every(_leaving.contains),
                      revealPadding: revealPadding,
                      onSettled: () => _settle(pile.first),
                      child: spaced(
                        AnimatedSize(
                          alignment: Alignment.topCenter,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: _EditableStack(
                            pile: pile,
                            row: at,
                            sway: sway,
                            lifting: _dragging,
                            cardKeyOf: widget.cardKeyOf,
                            onTurn: () => _turn(at),
                            onSplit: pile.length > 1 ? () => _split(at) : null,
                            onRemove: pile.first.removable
                                ? () => _remove(pile.first)
                                : null,
                            onDrop: _drop,
                            onLift: (up) => setState(() => _dragging = up),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (addable.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.only(top: _addableTop),
                sliver: SliverList.list(
                  children: [
                    _SectionLabel(appLocalizations.dashboardAddableSection),
                    for (final card in addable)
                      Padding(
                        padding: const EdgeInsets.only(bottom: _rowGap),
                        child: _AddRow(item: card, onAdd: () => _add(card)),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Brings an added card in once its room has opened and scrolled into view,
/// and takes a removed one out before closing its room, so the cards around
/// it slide instead of jumping.
class _Presence extends StatefulWidget {
  const _Presence({
    super.key,
    required this.entering,
    required this.leaving,
    required this.revealPadding,
    required this.onSettled,
    required this.child,
  });

  final bool entering;
  final bool leaving;

  /// What floats over the viewport's edges, kept clear of an opening room.
  final EdgeInsets revealPadding;
  final VoidCallback onSettled;
  final Widget child;

  @override
  State<_Presence> createState() => _PresenceState();
}

class _PresenceState extends State<_Presence>
    with SingleTickerProviderStateMixin {
  final _content = GlobalKey();
  late final _controller = AnimationController(
    vsync: this,
    value: widget.entering ? 0 : 1,
  );
  late final _roomShare =
      _roomDuration.inMicroseconds /
      (_roomDuration + _appearDuration).inMicroseconds;
  late final _room = CurvedAnimation(
    parent: _controller,
    curve: Interval(0, _roomShare, curve: Curves.easeOutCubic),
    reverseCurve: Interval(0, _roomShare, curve: Curves.easeInCubic),
  );
  late final _appear = CurvedAnimation(
    parent: _controller,
    curve: Interval(_roomShare, 1, curve: Curves.easeOutCubic),
  );
  VoidCallback? _follow;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = context.motionDuration(
      _roomDuration + _appearDuration,
    );
    if (widget.entering && _controller.isDismissed) {
      _run();
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  @override
  void didUpdateWidget(_Presence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leaving != oldWidget.leaving) {
      _run();
    }
  }

  @override
  void dispose() {
    _stopFollowing();
    _room.dispose();
    _appear.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _run() {
    final run = widget.leaving ? _controller.reverse() : _controller.forward();
    run.then(
      (_) {
        if (mounted) {
          widget.onSettled();
        }
      },
      onError: (error, stack) {
        commonPrint.log(
          'leaving animation settled with error: $error',
          logLevel: LogLevel.warning,
        );
      },
    );
  }

  void _reveal() {
    final box = _content.currentContext?.findRenderObject();
    final position = Scrollable.maybeOf(context)?.position;
    if (!mounted || box is! RenderBox || !box.hasSize || position == null) {
      return;
    }
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) {
      return;
    }
    final rect = widget.revealPadding.inflateRect(Offset.zero & box.size);
    final leading = viewport.getOffsetToReveal(box, 0, rect: rect).offset;
    final trailing = viewport.getOffsetToReveal(box, 1, rect: rect).offset;
    final from = position.pixels;
    final to = clampDouble(
      trailing > leading ? leading : clampDouble(from, trailing, leading),
      position.minScrollExtent,
      position.maxScrollExtent + box.size.height * (1 - _room.value),
    );
    if ((to - from).abs() < precisionErrorTolerance) {
      return;
    }
    // Moved once each frame has laid the grown room out: a jump past the old
    // scroll end would send the position bouncing back to it.
    void follow() {
      final room = _room.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && position.hasPixels) {
          position.jumpTo(lerpDouble(from, to, room)!);
        }
      });
      if (room == 1) {
        _stopFollowing();
      }
    }

    _follow = follow;
    _room.addListener(follow);
  }

  void _stopFollowing() {
    final follow = _follow;
    if (follow != null) {
      _room.removeListener(follow);
      _follow = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.leaving,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Align(
          alignment: AlignmentDirectional.topStart,
          heightFactor: _room.value,
          child: KeyedSubtree(
            key: _content,
            child: Opacity(
              opacity: _appear.value,
              child: Transform.scale(
                scale: lerpDouble(_appearScale, 1, _appear.value)!,
                child: child,
              ),
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// The center drop zone stacks; the edge zones only reorder.
class _EditableStack extends StatelessWidget {
  const _EditableStack({
    required this.pile,
    required this.row,
    required this.sway,
    required this.lifting,
    required this.cardKeyOf,
    required this.onTurn,
    required this.onSplit,
    required this.onRemove,
    required this.onDrop,
    required this.onLift,
  });

  final List<DashboardWidget> pile;
  final int row;
  final Animation<double>? sway;
  final bool lifting;
  final GlobalKey Function(DashboardWidget card) cardKeyOf;
  final VoidCallback onTurn;
  final VoidCallback? onSplit;
  final VoidCallback? onRemove;
  final void Function(int from, int insertAt, {required bool stack}) onDrop;
  final ValueChanged<bool> onLift;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final top = pile.first;
    final card = AbsorbPointer(
      child: RepaintBoundary(key: cardKeyOf(top), child: top.card),
    );
    final sway = this.sway;
    final body = sway == null
        ? card
        : _Sway(sway: sway, seed: top.index, child: card);
    final onRemove = this.onRemove;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            LongPressDraggable<int>(
              data: row,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              onDragStarted: () => onLift(true),
              onDragEnd: (_) => onLift(false),
              onDraggableCanceled: (_, _) => onLift(false),
              feedback: _HeldPile(card: top, width: width),
              childWhenDragging: Opacity(opacity: 0.22, child: body),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: pile.length > 1 ? onTurn : null,
                child: body,
              ),
            ),
            if (onRemove != null)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: _RoundButton(
                  glyph: AppGlyphs.remove,
                  tooltip:
                      '${context.appLocalizations.remove} ${top.label(context)}',
                  background: colorScheme.errorContainer,
                  foreground: colorScheme.onErrorContainer,
                  onPressed: onRemove,
                ),
              ),
            if (pile.length > 1 && onSplit != null)
              PositionedDirectional(
                top: 0,
                start: 0,
                child: _PileCount(count: pile.length, onSplit: onSplit!),
              ),
            if (lifting)
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _DropBand(
                        row: row,
                        edge: -1,
                        onAccept: (from) => onDrop(from, row, stack: false),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: _DropBand(
                        row: row,
                        onAccept: (from) => onDrop(from, row, stack: true),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _DropBand(
                        row: row,
                        edge: 1,
                        onAccept: (from) => onDrop(from, row + 1, stack: false),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The overlay must not mount a card with the same key as its source.
class _HeldPile extends StatelessWidget {
  const _HeldPile({required this.card, required this.width});

  final DashboardWidget card;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: width,
        child: DashboardDensityScope(
          density: DashboardDensity.mobile,
          scale: DashboardDensityScope.scaleOf(context),
          child: _LiftedCard(
            animation: const AlwaysStoppedAnimation(1),
            child: AbsorbPointer(child: card.card),
          ),
        ),
      ),
    );
  }
}

class _PileCount extends StatelessWidget {
  const _PileCount({required this.count, required this.onSplit});

  final int count;
  final VoidCallback onSplit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Tooltip(
      message: context.appLocalizations.dashboardSplitStack,
      child: Semantics(
        button: true,
        label: context.appLocalizations.dashboardSplitStack,
        child: GestureDetector(
          onTap: onSplit,
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: ShapeDecoration(
              color: colorScheme.secondaryContainer,
              shape: AppShape.all(12),
            ),
            child: Text(
              '$count',
              style: DashboardText.label(context).copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: DashboardWeight.title,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropBand extends StatelessWidget {
  const _DropBand({
    required this.row,
    required this.onAccept,
    this.edge = 0,
  });

  final int row;
  final ValueChanged<int> onAccept;
  final int edge;

  bool get _stack => edge == 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != row,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        if (candidate.isEmpty) {
          return const SizedBox.expand();
        }
        if (_stack) {
          return Padding(
            padding: const EdgeInsets.all(2),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: AppShape.all(DashboardCorner.mobileCard),
              ),
              child: const SizedBox.expand(),
            ),
          );
        }
        return Align(
          alignment: edge < 0 ? Alignment.topCenter : Alignment.bottomCenter,
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: ShapeDecoration(
              color: colorScheme.primary,
              shape: AppShape.all(2),
            ),
          ),
        );
      },
    );
  }
}

class _Sway extends AnimatedWidget {
  const _Sway({
    required Animation<double> sway,
    required this.seed,
    required this.child,
  }) : super(listenable: sway);

  final int seed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final swings = _swaysPerLoop[seed % _swaysPerLoop.length];
    final turn =
        (listenable as Animation<double>).value * 2 * math.pi * swings +
        seed * _swayPhaseStep;
    return Transform.translate(
      offset: Offset(0, math.cos(turn) * _swayBob),
      child: Transform.rotate(angle: math.sin(turn) * _swayTurn, child: child),
    );
  }
}

class _LiftedCard extends StatelessWidget {
  const _LiftedCard({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shadows = DashboardShadows.e2(context);
    final shape = AppShape.all(DashboardCorner.mobileCard);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOut.transform(animation.value);
        return Transform.scale(
          scale: 1 + _liftGrowth * t,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: shape,
              shadows: [
                for (final shadow in shadows)
                  shadow.copyWith(
                    color: shadow.color.withValues(alpha: shadow.color.a * t),
                  ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: Text(
        text,
        style: AppTextStyle.footnote
            .of(context, emphasized: true)
            .copyWith(color: context.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.item, required this.onAdd});

  final DashboardWidget item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final colors = DashboardColors.of(context);
    final label = item.label(context);
    final description = item.description(context);
    return Container(
      height: _rowHeight,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 8, 0),
      decoration: ShapeDecoration(
        color: colors.card.withValues(alpha: 0.55),
        shape: AppShape.all(DashboardCorner.mobileBlock),
      ),
      child: Row(
        spacing: 12,
        children: [
          _RoundButton(
            glyph: AppGlyphs.add,
            tooltip: '${context.appLocalizations.add} $label',
            background: colorScheme.primary,
            foreground: colorScheme.onPrimary,
            onPressed: onAdd,
          ),
          Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: colors.card,
              shape: AppShape.all(DashboardCorner.badge),
            ),
            child: Center(
              child: GlyphIcon(
                item.glyph,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subheadline.of(context, emphasized: true),
                ),
                if (description != null)
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardText.label(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.glyph,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final Glyph glyph;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 28,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size.square(28),
          fixedSize: const Size.square(28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        icon: GlyphIcon(glyph, size: 16, color: foreground),
      ),
    );
  }
}
