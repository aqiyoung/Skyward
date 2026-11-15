import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:skyward/enum/enum.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../layout.dart';
import '../widget_registry.dart';
import 'card.dart';

const _peekPressed = 30.0;
const _depthScale = 0.03;
const _depthBlur = 1.6;
const _tilt = 0.06;
const _pressedScale = 0.02;
const _turnAt = 0.24;
const _flick = 620.0;
const _pageScrollDelay = Duration(milliseconds: 350);

/// Touch opens the pile. Tap a dot to select; quick drags flip, holds scroll.
class CardStack extends StatefulWidget {
  const CardStack({super.key, required this.cards, required this.cardKeyOf});

  final List<DashboardWidget> cards;
  final GlobalKey Function(DashboardWidget card) cardKeyOf;

  @override
  State<CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> with TickerProviderStateMixin {
  late final _turn = AnimationController.unbounded(vsync: this);
  late final _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 130),
    reverseDuration: const Duration(milliseconds: 220),
  );
  final _surface = GlobalKey();
  var _heldFrom = 0;
  var _index = 0;
  var _pressY = 0.0;
  var _pressPosition = Offset.zero;
  var _pageScrollY = 0.0;
  Timer? _pageScrollTimer;
  var _held = false;
  var _pageScrolling = false;
  var _dragging = false;
  var _expanded = false;
  var _settled = true;

  int get _count => widget.cards.length;

  @override
  void didUpdateWidget(CardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= _count) {
      _index = 0;
      _turn.value = 0;
    }
  }

  @override
  void dispose() {
    _pageScrollTimer?.cancel();
    _turn.dispose();
    _open.dispose();
    super.dispose();
  }

  double get _cardHeight {
    final box = _surface.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize && box.size.height > 0
        ? box.size.height
        : 1;
  }

  void _press(Offset globalPosition) {
    if (_count < 2) {
      return;
    }
    _settled = false;
    _heldFrom = _index;
    _pressPosition = globalPosition;
    _pressY = globalPosition.dy;
    _pageScrollY = 0;
    _held = true;
    _dragging = false;
    _pageScrolling = false;
    _cancelPageScrollTimer();
    _pageScrollTimer = Timer(_pageScrollDelay, () {
      _pageScrollTimer = null;
      if (mounted && _held) {
        _beginPageScroll();
      }
    });
    setState(() => _expanded = true);
    _open.forward();
    // Keep an existing page fling from carrying the board during card input.
    final position = Scrollable.maybeOf(context)?.position;
    if (position != null && position.hasPixels) {
      position.jumpTo(position.pixels);
    }
  }

  void _cancelPageScrollTimer() {
    _pageScrollTimer?.cancel();
    _pageScrollTimer = null;
  }

  void _beginPageScroll() {
    if (_pageScrolling || !_held) {
      return;
    }
    _cancelPageScrollTimer();
    _pageScrolling = true;
    _pageScrollY = 0;
    _held = false;
    _dragging = false;
    setState(() {
      _expanded = false;
      _turn.value = 0;
    });
    _open.reverse();
  }

  void _scrollPage(double dragDistance) {
    if (!_pageScrolling) {
      return;
    }
    final delta = dragDistance - _pageScrollY;
    _pageScrollY = dragDistance;
    final position = Scrollable.maybeOf(context)?.position;
    if (delta == 0 || position == null || !position.hasContentDimensions) {
      return;
    }
    final pixels = (position.pixels - delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (pixels != position.pixels) {
      position.jumpTo(pixels);
    }
  }

  void _endPageScroll() {
    if (!_pageScrolling) {
      return;
    }
    _pageScrolling = false;
    _settle(0);
  }

  void _selectCard(int index) {
    if (index == _index || index < 0 || index >= _count) {
      return;
    }
    _cancelPageScrollTimer();
    _settled = true;
    _held = false;
    _dragging = false;
    _pageScrolling = false;
    _turn.stop();
    setState(() {
      _index = index;
      _turn.value = 0;
      _expanded = true;
    });
    _open.forward();
  }

  void _snapShut() {
    _cancelPageScrollTimer();
    if (_settled) {
      return;
    }
    _settled = true;
    _held = false;
    _dragging = false;
    _pageScrolling = false;
    setState(() {
      _expanded = false;
      _turn.value = 0;
    });
    _open.reverse();
  }

  void _drag(double dy) {
    if (!_held || _count < 2) {
      return;
    }
    var turn = -dy / _cardHeight;
    var index = _heldFrom;
    while (turn >= 1) {
      turn -= 1;
      index = (index + 1) % _count;
    }
    while (turn <= -1) {
      turn += 1;
      index = (index - 1 + _count) % _count;
    }
    setState(() {
      _index = index;
      _dragging = true;
    });
    _turn.value = turn;
  }

  void _settle(double velocityY) {
    _cancelPageScrollTimer();
    if (_settled) {
      return;
    }
    _settled = true;
    _held = false;
    _pageScrolling = false;
    if (!_expanded) {
      _open.reverse();
    }
    final dragging = _dragging;
    setState(() => _dragging = false);
    if (!dragging) {
      return;
    }
    final turn = _turn.value;
    var target = 0.0;
    if (turn.abs() >= _turnAt) {
      target = turn.sign;
    }
    if (velocityY.abs() > _flick) {
      target = velocityY < 0 ? 1 : -1;
    }
    _turn
        .animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _index = (_index + target.toInt() + _count) % _count;
            _turn.value = 0;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_count == 1) {
      return RepaintBoundary(
        key: widget.cardKeyOf(widget.cards.first),
        child: widget.cards.first.card,
      );
    }
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return AnimatedBuilder(
      animation: Listenable.merge([_turn, _open]),
      builder: (context, _) {
        final open = _open.value;
        final turn = _turn.value;
        final visual = math.max(open, turn.abs().clamp(0.0, 1.0).toDouble());
        final peek = _peekPressed * visual * math.min(scale, 2);
        return _pile(turn: turn, visual: visual, peek: peek);
      },
    );
  }

  Widget _pile({
    required double turn,
    required double visual,
    required double peek,
  }) {
    final top = widget.cards[_index];
    final travel = _count == 2 && turn < 0 ? -turn : turn;
    final back = turn < 0 && _count > 2 ? 1 : 0;
    final ahead = turn < 0 ? 1 : math.min(_count - 1, 2);
    // Layers paint past the fixed card height without shifting the page.
    final spill = peek * ahead;
    final layers = <Widget>[];
    for (var step = back; step >= 1; step--) {
      layers.add(
        _layer(
          card: widget.cards[(_index - step + _count) % _count],
          lift: -step - travel,
          steps: back.toDouble(),
          visual: visual,
          peek: peek,
          spill: spill,
        ),
      );
    }
    for (var step = ahead; step >= 1; step--) {
      layers.add(
        _layer(
          card: widget.cards[(_index + step) % _count],
          lift: step - travel,
          steps: ahead.toDouble(),
          visual: visual,
          peek: peek,
          spill: spill,
        ),
      );
    }
    return ClipRect(
      clipper: _PileClipper(
        over: turn < 0 ? peek : 0,
        aside: 14 * visual,
        spill: spill,
      ),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) => _press(event.position),
        onPointerMove: (event) {
          if (!_pageScrolling &&
              (event.position - _pressPosition).distance > kTouchSlop) {
            _cancelPageScrollTimer();
          }
          if (_pageScrolling) {
            _scrollPage(event.position.dy - _pressY);
          }
        },
        onPointerUp: (_) {
          _cancelPageScrollTimer();
          if (_pageScrolling) {
            _endPageScroll();
          } else if (!_dragging) {
            _settle(0);
          }
        },
        onPointerCancel: (_) {
          _cancelPageScrollTimer();
          _snapShut();
        },
        child: RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: <Type, GestureRecognizerFactory>{
            LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer
                >(
                  () => LongPressGestureRecognizer(duration: _pageScrollDelay),
                  (instance) {
                    instance.onLongPressStart = (_) => _beginPageScroll();
                    instance.onLongPressEnd = (_) => _endPageScroll();
                  },
                ),
            VerticalDragGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  VerticalDragGestureRecognizer
                >(
                  VerticalDragGestureRecognizer.new,
                  (instance) {
                    instance.onStart = (details) {
                      if (_pageScrolling) {
                        return;
                      }
                      _dragging = true;
                      _drag(details.globalPosition.dy - _pressY);
                    };
                    instance.onUpdate = (details) {
                      if (!_pageScrolling) {
                        _drag(details.globalPosition.dy - _pressY);
                      }
                    };
                    instance.onEnd = (details) {
                      if (_pageScrolling) {
                        _dragging = false;
                        _endPageScroll();
                      } else {
                        _settle(details.velocity.pixelsPerSecond.dy);
                      }
                    };
                  },
                ),
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ...layers,
              RepaintBoundary(
                key: _surface,
                child: Transform.translate(
                  offset: Offset(0, -6 * visual),
                  child: Transform.scale(
                    alignment: Alignment.topCenter,
                    scale: 1 - _pressedScale * visual,
                    child: FractionalTranslation(
                      translation: Offset(0, -travel),
                      child: _cast(
                        RepaintBoundary(
                          key: widget.cardKeyOf(top),
                          child: top.card,
                        ),
                        visual,
                      ),
                    ),
                  ),
                ),
              ),
              if (_expanded)
                Positioned(
                  right: -9,
                  top: 0,
                  bottom: 0,
                  child: KeyedSubtree(
                    key: const ValueKey('card-stack-switchable'),
                    child: Center(
                      child: _SwitchDots(
                        count: _count,
                        index: _index,
                        onSelected: _selectCard,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cast(Widget card, double visual) {
    final radius = dashboardCardRadius(DashboardDensityScope.of(context));
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: AppShape.all(radius),
        shadows: [
          BoxShadow(
            color: Color.fromARGB((0x24 * visual).round(), 0, 0, 0),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: card,
    );
  }

  Widget _layer({
    required DashboardWidget card,
    required double lift,
    required double steps,
    required double visual,
    required double peek,
    required double spill,
  }) {
    final depth = lift.abs();
    return Positioned(
      left: 0,
      right: 0,
      bottom: peek * (steps - lift) - spill,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: Opacity(
            opacity: (1 - 0.03 * depth).clamp(0.75, 1.0).toDouble() * visual,
            child: Transform.rotate(
              angle: _tilt * visual * lift,
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                alignment: Alignment.bottomCenter,
                scale: 1 - _depthScale * depth - 0.02 * visual,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: _depthBlur * depth * visual,
                    sigmaY: _depthBlur * depth * visual,
                  ),
                  child: _cast(
                    RepaintBoundary(
                      key: widget.cardKeyOf(card),
                      child: card.card,
                    ),
                    visual,
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

class _SwitchDots extends StatelessWidget {
  const _SwitchDots({
    required this.count,
    required this.index,
    required this.onSelected,
  });

  final int count;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final activeColor = context.colorScheme.onSurface.withValues(alpha: 0.85);
    final inactiveColor = context.colorScheme.onSurface.withValues(alpha: 0.3);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            key: ValueKey('card-stack-dot-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelected(i),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: ClipOval(
                  child: ColoredBox(
                    color: i == index ? activeColor : inactiveColor,
                    child: const SizedBox(width: 5, height: 5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PileClipper extends CustomClipper<Rect> {
  const _PileClipper({
    required this.over,
    required this.aside,
    required this.spill,
  });

  final double over;
  final double aside;
  final double spill;
  static const under = 12.0;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    -aside,
    -over,
    size.width + aside,
    size.height + spill + under,
  );

  @override
  bool shouldReclip(_PileClipper oldClipper) =>
      oldClipper.over != over ||
      oldClipper.aside != aside ||
      oldClipper.spill != spill;
}
