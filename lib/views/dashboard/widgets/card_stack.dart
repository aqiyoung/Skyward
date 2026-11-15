import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:skyward/enum/enum.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../layout.dart';
import '../widget_registry.dart';
import 'card.dart';

/// How far the cards under the top one show at rest.
const _peek = 14.0;

/// How far they show once the pile is opened: the hold is what says "there is
/// more than one card here", so the pile opens up before the drag starts.
const _peekHeld = 30.0;

/// The scale each card loses per step down the pile.
const _depthScale = 0.03;

/// The blur each card takes on per step down the pile.
const _depthBlur = 1.6;

/// How far each card under the top one turns aside once the pile is open, in
/// radians. The lean is what makes the open pile read as one angled picture
/// behind the top card instead of a set of stacked borders.
const _tilt = 0.06;

/// How much the top card shrinks while it is held.
const _heldScale = 0.02;

/// How much of the card a drag must cover to turn the page.
const _turnAt = 0.24;

/// How fast a flick has to be to turn the page without travelling.
const _flick = 620.0;

/// How long the finger has to rest before the pile opens. Longer than the
/// platform's own long press: the pile turns one card per drag, so opening it
/// by accident while scrolling the board would be worse than waiting.
const _holdDelay = Duration(milliseconds: 1000);

/// One place on the dashboard holding one or more cards.
///
/// One card draws as itself, untouched. Several draw as a pile: the top card in
/// full, the ones under it peeking out, blurred and leaning aside as one
/// picture. Holding the pile opens it and shrinks the top card a little;
/// dragging then turns it, and letting go settles on whichever card is nearer,
/// so the card that stops is the card shown. The pile has no end: it turns all
/// the way round in both directions. A drag that starts without the hold
/// belongs to the page, not to the pile.
class CardStack extends StatefulWidget {
  const CardStack({super.key, required this.cards, required this.cardKeyOf});

  /// Top card first.
  final List<DashboardWidget> cards;

  /// Shared with the editor and the plain page, so a card keeps its state as
  /// the pile turns.
  final GlobalKey Function(DashboardWidget card) cardKeyOf;

  @override
  State<CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> with TickerProviderStateMixin {
  /// How far the pile has turned from the card in place: 1 is the card below
  /// it, -1 the card above it. Kept short of either end by handing the whole
  /// turn to [_index] as the drag passes a card.
  late final _turn = AnimationController.unbounded(vsync: this);

  /// How far the pile is open, 0 at rest and 1 while held.
  late final _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
  );

  final _surface = GlobalKey();

  /// The card in place when the hold began, so a long drag can turn the pile
  /// round more than once without the turn running away.
  var _heldFrom = 0;
  var _index = 0;
  var _held = false;
  var _dragging = false;

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

  void _hold() {
    if (_count < 2) {
      return;
    }
    HapticFeedback.selectionClick();
    _heldFrom = _index;
    setState(() => _held = true);
    _open.forward();
  }

  void _drag(double dy) {
    if (!_held || _count < 2) {
      return;
    }
    // The drag is measured from where the hold began, so a drag past a whole
    // card hands it to the index and carries on from the next one: the pile
    // has no end to run into.
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

  void _release(double velocityY) {
    final dragging = _dragging;
    _held = false;
    _open.reverse();
    setState(() => _dragging = false);
    if (!dragging) {
      return;
    }
    // A flick turns the page even when it never travelled far; otherwise the
    // card nearer the top is the one that stays.
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
        final peek = (_peek + (_peekHeld - _peek) * open) * math.min(scale, 2);
        return _pile(turn: _turn.value, open: open, peek: peek);
      },
    );
  }

  Widget _pile({
    required double turn,
    required double open,
    required double peek,
  }) {
    final top = widget.cards[_index];
    // A pile of two has the same card below it and above it, so turning back
    // is the turn forwards played from the other side.
    final travel = _count == 2 && turn < 0 ? -turn : turn;
    // Turning back shows the card above the top one over its edge, while the
    // ones below it step back: only one card shows on each side of the turn.
    final back = turn < 0 && _count > 2 ? 1 : 0;
    final ahead = turn < 0 ? 1 : math.min(_count - 1, 2);
    final layers = <Widget>[];
    for (var step = back; step >= 1; step--) {
      layers.add(
        _layer(
          card: widget.cards[(_index - step + _count) % _count],
          lift: -step - travel,
          steps: back.toDouble(),
          open: open,
          peek: peek,
        ),
      );
    }
    for (var step = ahead; step >= 1; step--) {
      layers.add(
        _layer(
          card: widget.cards[(_index + step) % _count],
          lift: step - travel,
          steps: ahead.toDouble(),
          open: open,
          peek: peek,
        ),
      );
    }
    // The pile is as tall as its top card plus the edges peeking under it; the
    // clip keeps a taller card from spilling onto the next place, while still
    // letting the card above show over the top edge.
    return ClipRect(
      // Only a pile turning back needs the room over its top edge; at rest
      // nothing may show there, or a card taller than the one in place would
      // spill onto the place above it.
      clipper: _PileClipper(over: turn < 0 ? peek : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...layers,
          Padding(
            padding: EdgeInsets.only(bottom: peek * ahead),
            child: RawGestureDetector(
              behavior: HitTestBehavior.translucent,
              // The platform's own long press fires at 0.5s; a pile that opens
              // that fast opens while the board is being scrolled past it.
              gestures: {
                LongPressGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      LongPressGestureRecognizer
                    >(
                      () => LongPressGestureRecognizer(duration: _holdDelay),
                      (instance) {
                        instance.onLongPressStart = (_) => _hold();
                        instance.onLongPressMoveUpdate = (details) =>
                            _drag(details.offsetFromOrigin.dy);
                        instance.onLongPressEnd = (details) =>
                            _release(details.velocity.pixelsPerSecond.dy);
                      },
                    ),
              },
              child: RepaintBoundary(
                key: _surface,
                child: Transform.translate(
                  // The card in place lifts a little under the finger, which
                  // is what makes room for the edges to open under it.
                  offset: Offset(0, -6 * open),
                  child: Transform.scale(
                    alignment: Alignment.topCenter,
                    scale: 1 - _heldScale * open,
                    child: FractionalTranslation(
                      translation: Offset(0, -travel),
                      child: _cast(
                        RepaintBoundary(
                          key: widget.cardKeyOf(top),
                          child: top.card,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A card with the shadow it casts on the edge of the one below it. Every
  /// card in a pile is white, and the shadow is what says how many there are.
  Widget _cast(Widget card) {
    final radius = dashboardCardRadius(DashboardDensityScope.of(context));
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: AppShape.all(radius),
        shadows: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 10,
            spreadRadius: -2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: card,
    );
  }

  /// One card of the pile, hung one edge further up the pile for every step
  /// it sits below the top one, so what shows under the top card is the bottom
  /// edge of the card beneath it -- rounded corners and all, whatever height
  /// the two cards happen to be. An opened pile also turns it aside, so the
  /// edges read as one angled picture behind the card in place.
  Widget _layer({
    required DashboardWidget card,
    required double lift,
    required double steps,
    required double open,
    required double peek,
  }) {
    final depth = lift.abs();
    return Positioned(
      left: 0,
      right: 0,
      bottom: peek * (steps - lift),
      // Only the card in place is there to read: the ones under it are a hint
      // that there is more, not more to be read out of turn.
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: Opacity(
            opacity: (1 - 0.03 * depth).clamp(0.75, 1),
            child: Transform.rotate(
              angle: _tilt * open * lift,
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                alignment: Alignment.bottomCenter,
                scale: 1 - _depthScale * depth - 0.02 * open,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: _depthBlur * depth,
                    sigmaY: _depthBlur * depth,
                  ),
                  // The key wraps the card itself in both modes, so the card
                  // keeps its state as the page turns to editing.
                  child: _cast(
                    RepaintBoundary(
                      key: widget.cardKeyOf(card),
                      child: card.card,
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

/// Clips a pile to its place, keeping the little a card above the top one
/// shows over the edge while the pile turns back to it.
class _PileClipper extends CustomClipper<Rect> {
  const _PileClipper({required this.over});

  /// Room kept over the top edge for a card turning back over it.
  final double over;

  /// The little kept under the bottom edge lets the shadow of the card in
  /// place fall onto the edges below it, which is what says how many there
  /// are; without it the pile reads as one white slab.
  static const under = 12.0;

  /// Room at the sides for the corners of an opened pile, which lean out of
  /// the pile's own width.
  static const aside = 14.0;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-aside, -over, size.width + aside, size.height + under);

  @override
  bool shouldReclip(_PileClipper oldClipper) => oldClipper.over != over;
}
