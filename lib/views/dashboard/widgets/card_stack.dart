import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:skyward/enum/enum.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
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

enum _Phase { idle, pressing, turning, pageScrolling }

/// Swipe to switch cards, tap to open the visible card's own action; hold to scroll the page.
class CardStack extends StatefulWidget {
  const CardStack({super.key, required this.cards, required this.cardKeyOf});

  final List<DashboardWidget> cards;
  final GlobalKey Function(DashboardWidget card) cardKeyOf;

  @override
  State<CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> with TickerProviderStateMixin {
  late final _turn = AnimationController.unbounded(vsync: this);
  final _surface = GlobalKey();
  var _heldFrom = 0;
  var _index = 0;
  var _pressY = 0.0;
  var _pressPosition = Offset.zero;
  var _pageScrollY = 0.0;
  Timer? _pageScrollTimer;
  var _phase = _Phase.idle;
  var _settleGeneration = 0;
  VelocityTracker? _velocity;
  double? _downPixels;
  DockFollowHold? _dockHold;
  var _dockHeld = false;
  var _pageScrollDirection = ScrollDirection.idle;

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
    _releaseDockHold();
    _pageScrollTimer?.cancel();
    _turn.dispose();
    super.dispose();
  }

  void _releaseDockHold() {
    if (_dockHeld) {
      _dockHeld = false;
      _dockHold?.release();
    }
    _dockHold = null;
  }

  double get _cardHeight {
    final box = _surface.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize && box.size.height > 0
        ? box.size.height
        : 1;
  }

  void _press(PointerDownEvent event) {
    if (_count < 2) {
      return;
    }
    _settleGeneration++;
    _phase = _Phase.pressing;
    if (!_dockHeld) {
      _dockHold = DockFollowHoldScope.of(context);
      _dockHold?.acquire();
      _dockHeld = _dockHold != null;
    }
    _heldFrom = _index;
    _pressPosition = event.position;
    _pressY = event.position.dy;
    _pageScrollY = 0;
    _velocity = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
    _cancelPageScrollTimer();
    _pageScrollTimer = Timer(_pageScrollDelay, () {
      _pageScrollTimer = null;
      if (mounted) {
        _beginPageScroll();
      }
    });
    // Keep an existing page fling from carrying the board during card input.
    final position = Scrollable.maybeOf(context)?.position;
    _downPixels = position != null && position.hasPixels
        ? position.pixels
        : null;
    if (position != null && position.hasPixels) {
      position.jumpTo(position.pixels);
    }
  }

  void _pinPage() {
    final down = _downPixels;
    final position = Scrollable.maybeOf(context)?.position;
    if (down == null || position == null || !position.hasPixels) {
      return;
    }
    if (position.pixels != down) {
      position.jumpTo(down);
    }
  }

  void _cancelPageScrollTimer() {
    _pageScrollTimer?.cancel();
    _pageScrollTimer = null;
  }

  void _beginPageScroll() {
    if (_phase != _Phase.pressing) {
      return;
    }
    _cancelPageScrollTimer();
    _phase = _Phase.pageScrolling;
    _pageScrollY = 0;
    _pageScrollDirection = ScrollDirection.idle;
    // Scrolling the page is a real page scroll again: the dock may follow.
    _releaseDockHold();
    _turn.value = 0;
  }

  void _scrollPage(double dragDistance, Offset globalPosition) {
    if (_phase != _Phase.pageScrolling) {
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
    if (pixels == position.pixels) {
      return;
    }
    final applied = pixels - position.pixels;
    position.jumpTo(pixels);
    _reportPageScroll(position, applied, globalPosition);
  }

  /// A held pile scrolls the page by hand, which no drag ever reports: tell
  /// scroll listeners a finger is moving the page, as a list would.
  void _reportPageScroll(
    ScrollPosition position,
    double applied,
    Offset globalPosition,
  ) {
    final direction = applied > 0
        ? ScrollDirection.reverse
        : ScrollDirection.forward;
    if (direction != _pageScrollDirection) {
      _pageScrollDirection = direction;
      UserScrollNotification(
        metrics: position,
        context: context,
        direction: direction,
      ).dispatch(context);
    }
    ScrollUpdateNotification(
      metrics: position,
      context: context,
      scrollDelta: applied,
      dragDetails: DragUpdateDetails(
        globalPosition: globalPosition,
        delta: Offset(0, -applied),
        primaryDelta: -applied,
      ),
    ).dispatch(context);
  }

  void _endPageScroll() {
    if (_phase != _Phase.pageScrolling) {
      return;
    }
    _phase = _Phase.idle;
  }

  void _finishPress() {
    _cancelPageScrollTimer();
    if (_phase != _Phase.pressing) {
      return;
    }
    _phase = _Phase.idle;
  }

  void _snapShut() {
    _cancelPageScrollTimer();
    if (_phase == _Phase.idle) {
      return;
    }
    _phase = _Phase.idle;
    _turn.stop();
    setState(() {
      _index = _heldFrom;
      _turn.value = 0;
    });
  }

  void _drag(double dy) {
    if ((_phase != _Phase.pressing && _phase != _Phase.turning) || _count < 2) {
      return;
    }
    _phase = _Phase.turning;
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
    setState(() => _index = index);
    _turn.value = turn;
  }

  void _settle(double velocityY) {
    _cancelPageScrollTimer();
    if (_phase != _Phase.turning) {
      return;
    }
    _phase = _Phase.idle;
    final turn = _turn.value;
    var target = 0.0;
    if (turn.abs() >= _turnAt) {
      target = turn.sign;
    }
    if (velocityY.abs() > _flick) {
      target = velocityY < 0 ? 1 : -1;
    }
    final generation = _settleGeneration;
    _turn
        .animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (!mounted || generation != _settleGeneration) {
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
      animation: _turn,
      builder: (context, _) {
        final turn = _turn.value;
        final visual = turn.abs().clamp(0.0, 1.0).toDouble();
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
        behavior: HitTestBehavior.opaque,
        onPointerDown: _press,
        onPointerMove: (event) {
          _velocity?.addPosition(event.timeStamp, event.position);
          if (_phase == _Phase.pageScrolling) {
            _scrollPage(event.position.dy - _pressY, event.position);
            return;
          }
          if (_phase != _Phase.pressing && _phase != _Phase.turning) {
            return;
          }
          if ((event.position - _pressPosition).distance > kTouchSlop) {
            _cancelPageScrollTimer();
            _drag(event.position.dy - _pressY);
          }
          _pinPage();
        },
        onPointerUp: (event) {
          _velocity?.addPosition(event.timeStamp, event.position);
          _releaseDockHold();
          _cancelPageScrollTimer();
          switch (_phase) {
            case _Phase.pageScrolling:
              _endPageScroll();
            case _Phase.turning:
              _pinPage();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _phase == _Phase.idle) {
                  _pinPage();
                }
              });
              _settle(_velocity?.getVelocity().pixelsPerSecond.dy ?? 0);
            case _Phase.pressing:
              _finishPress();
            case _Phase.idle:
              break;
          }
        },
        onPointerCancel: (_) {
          _releaseDockHold();
          _cancelPageScrollTimer();
          _snapShut();
        },
        child: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
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
                >(VerticalDragGestureRecognizer.new, (instance) {
                  instance.onStart = (details) {
                    _drag(details.globalPosition.dy - _pressY);
                  };
                  instance.onUpdate = (details) {
                    _drag(details.globalPosition.dy - _pressY);
                  };
                  instance.onEnd = (details) {
                    if (_phase == _Phase.pageScrolling) {
                      _endPageScroll();
                    } else {
                      _settle(details.velocity.pixelsPerSecond.dy);
                    }
                  };
                }),
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
                          // The card keeps its own taps; the recognizers
                          // above own drags and long press.
                          child: top.card,
                        ),
                        visual,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _PileDots(
                    count: _count,
                    index: _index,
                    visual: visual,
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

/// One dot per card in the pile, the current one lit.
class _PileDots extends StatelessWidget {
  const _PileDots({
    required this.count,
    required this.index,
    required this.visual,
  });

  final int count;
  final int index;
  final double visual;

  @override
  Widget build(BuildContext context) {
    if (visual <= 0) {
      return const SizedBox.shrink();
    }
    final colorScheme = context.colorScheme;
    return Opacity(
      opacity: visual,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: Column(
            key: const ValueKey('card-stack-dots'),
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              for (var i = 0; i < count; i++)
                Container(
                  width: i == index ? 6 : 5,
                  height: i == index ? 6 : 5,
                  decoration: ShapeDecoration(
                    color: i == index
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.28),
                    shape: AppShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
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
