import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:skyward/enum/enum.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../layout.dart';
import '../widget_registry.dart';
import 'card.dart';

/// How far the cards under the top one show once a finger is down. At rest
/// they show nothing at all: a stack is one clean card until it is pressed.
const _peekPressed = 30.0;

/// The scale each card loses per step down the pile.
const _depthScale = 0.03;

/// The blur each card takes on per step down the pile.
const _depthBlur = 1.6;

/// How far each card under the top one turns aside while the pile is open, in
/// radians. The lean is what makes the open pile read as one angled picture
/// behind the top card instead of a set of stacked borders.
const _tilt = 0.06;

/// How much the top card shrinks while the pile is open.
const _pressedScale = 0.02;

/// How much of the card a drag must cover to turn the page.
const _turnAt = 0.24;

/// How fast a flick has to be to turn the page without travelling.
const _flick = 620.0;

/// How long a finger must rest before its drag belongs to the pile. Far below
/// the platform's long press: the pile opens on touch, and this only decides
/// whether a fast swipe scrolls the board or turns the pile. At rest the pile
/// never fights the board for a vertical drag.
const _engageDelay = Duration(milliseconds: 110);

/// One place on the dashboard holding one or more cards.
///
/// At rest a stack is a single card with nothing peeking out behind it -- the
/// way a HyperOS widget stack shows one widget on the desktop. Pressing it
/// opens the pile at once, with no long-press wait: the cards behind lean aside
/// as one angled picture, so the place reads as switchable. Sliding up or down
/// turns the pile, with no end in either direction. Lifting the finger folds
/// everything back to the one card in a fraction of a second.
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

  /// How far the pile is open: 0 at rest, 1 while a finger is down. It opens
  /// almost at once on press and folds back in well under a second on release.
  late final _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 130),
    reverseDuration: const Duration(milliseconds: 220),
  );

  final _surface = GlobalKey();

  /// The card in place when the press began, so a long drag can turn the pile
  /// round more than once without the turn running away.
  var _heldFrom = 0;
  var _index = 0;
  var _held = false;
  var _dragging = false;
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

  /// A finger went down. The pile opens right away, with no hold to wait out.
  /// A plain Listener sits outside the gesture arena, so opening it does not
  /// take the tap away from whatever is inside the card, nor does it delay the
  /// page's own scroll from winning a quick swipe.
  void _press() {
    if (_count < 2) {
      return;
    }
    _settled = false;
    _heldFrom = _index;
    _held = true;
    _dragging = false;
    _open.forward();
  }

  /// The short hold won the arena: from here on this drag belongs to the pile
  /// and its moves turn it. A quick swipe instead never reaches here, so the
  /// board keeps scrolling and nothing turns.
  void _engage() {
    if (_count < 2) {
      return;
    }
    _heldFrom = _index;
  }

  /// The page won the arena instead (a quick swipe to scroll). Fold straight
  /// back so scrolling never leaves an opened pile or a half turn behind.
  void _snapShut() {
    if (_settled) {
      return;
    }
    _settled = true;
    _held = false;
    _dragging = false;
    _turn.value = 0;
    _open.reverse();
  }

  void _drag(double dy) {
    if (!_held || _count < 2) {
      return;
    }
    // The drag is measured from where the press began, so a drag past a whole
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

  /// The finger came up, the gesture was cancelled, or the page won the drag.
  /// Whichever fires first folds the pile back; the rest are ignored.
  void _settle(double velocityY) {
    if (_settled) {
      return;
    }
    _settled = true;
    _held = false;
    _open.reverse();
    final dragging = _dragging;
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
        final turn = _turn.value;
        // At rest every trace of the pile is zero: one card, no layers, no
        // extra height. A turn still in flight keeps the pile visible while it
        // settles, so the card under the top one can slide into place.
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
          visual: visual,
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
          visual: visual,
          peek: peek,
        ),
      );
    }
    // At rest this clips to exactly the card's own rectangle: no layers, no
    // extra room above or below, so a stack reads as one ordinary card.
    return ClipRect(
      clipper: _PileClipper(over: turn < 0 ? peek : 0, aside: 14 * visual),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...layers,
          Padding(
            padding: EdgeInsets.only(bottom: peek * ahead),
            // A plain Listener sits outside the gesture arena: it opens the
            // pile on the down and, crucially, always sees the up -- even a tap
            // too short to become a press, or a swipe the page's scroll won.
            // That way no press can ever leave the pile open behind it.
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _press(),
              onPointerUp: (_) => _settle(0),
              onPointerCancel: (_) => _snapShut(),
              child: RawGestureDetector(
                behavior: HitTestBehavior.translucent,
                gestures: <Type, GestureRecognizerFactory>{
                  LongPressGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        LongPressGestureRecognizer
                      >(
                        () => LongPressGestureRecognizer(
                          duration: _engageDelay,
                        ),
                        (instance) {
                          // Only after the short stay does the drag belong to
                          // the pile; a fast swipe goes to the page instead.
                          instance.onLongPressStart = (_) => _engage();
                          instance.onLongPressMoveUpdate = (details) =>
                              _drag(details.offsetFromOrigin.dy);
                          instance.onLongPressEnd = (details) =>
                              _settle(details.velocity.pixelsPerSecond.dy);
                          instance.onLongPressCancel = _snapShut;
                        },
                      ),
                },
                child: RepaintBoundary(
                  key: _surface,
                  child: Transform.translate(
                    // The card in place lifts a little under the finger, which
                    // is what makes room for the edges to open under it.
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A card with the shadow it casts on the edge of the one below it. The
  /// shadow is a sign the pile is open, so at rest it fades to nothing and the
  /// card is just itself.
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

  /// One card of the pile, hung one edge further up the pile for every step
  /// it sits below the top one, so what shows under the top card is the bottom
  /// edge of the card beneath it -- rounded corners and all, whatever height
  /// the two cards happen to be. An opened pile also turns it aside, so the
  /// edges read as one angled picture behind the card in place.
  Widget _layer({
    required DashboardWidget card,
    required double lift,
    required double steps,
    required double visual,
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
                  // The key wraps the card itself in both modes, so the card
                  // keeps its state as the page turns to editing.
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

/// Clips a pile to its place, keeping the little a card above the top one
/// shows over the edge while the pile turns back to it. Every extra margin is
/// scaled by how open the pile is, so a resting pile clips to its own card.
class _PileClipper extends CustomClipper<Rect> {
  const _PileClipper({required this.over, required this.aside});

  /// Room kept over the top edge for a card turning back over it.
  final double over;

  /// Room at the sides for the corners of an opened pile, which lean out of
  /// the pile's own width.
  final double aside;

  /// A little room under the bottom edge for the card's own shadow. It never
  /// changes the layout: a ClipRect only clips paint, it does not size itself.
  static const under = 12.0;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-aside, -over, size.width + aside, size.height + under);

  @override
  bool shouldReclip(_PileClipper oldClipper) =>
      oldClipper.over != over || oldClipper.aside != aside;
}
