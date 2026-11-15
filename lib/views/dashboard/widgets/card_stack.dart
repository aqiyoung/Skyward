import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Brightness, ImageFilter;

import 'package:skyward/enum/enum.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

/// How long a finger has to rest on a pile before the press is read as
/// "switch a card" instead of "scroll past". Contact alone already opens the
/// pile; this short hold is the decision, and it is what locks the board.
const _holdConfirm = Duration(milliseconds: 120);

/// A move bigger than this before the hold is confirmed means the finger was
/// scrolling past, not switching. It stays below Flutter's touch slop (18) so
/// the decision is always made before the board's drag recognizer claims the
/// move -- whichever order the hit test happens to deliver them in.
const _scrollIntent = 10.0;

/// One place on the dashboard holding one or more cards.
///
/// At rest a stack is a single card with nothing peeking out behind it -- the
/// way a HyperOS widget stack shows one widget on the desktop. Touching it
/// opens the pile at once; resting the finger there for a fraction of a second
/// confirms "switch a card" (with a haptic tick and a dot rail), and from then
/// on sliding up or down turns the pile with no end in either direction while
/// the board is held perfectly still. Lifting the finger folds everything back
/// to the one card in well under a second.
///
/// The decision is explicit, not a race: a plain [Listener] outside the gesture
/// arena sees every pointer event and classifies the press from three things a
/// touch screen can actually report -- contact, how long it stayed, and how far
/// it moved. Pressure is not usable on Android (it reads ~1.0 on an ordinary
/// finger). A single-purpose recognizer holds a seat in the arena; the state
/// tells it to claim the gesture once the hold is confirmed, or to yield it to
/// the board when the finger is clearly scrolling past. Nothing the board does
/// can reach in and cancel an opened pile any more. A single card has nothing
/// to switch, so it installs no gesture at all and the page scrolls over it.
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

  /// The confirm timer and the arena seat for the press currently in flight.
  Timer? _armTimer;
  _PileClaim? _claim;

  /// The pointer that started the press, so a second finger cannot steer it.
  int? _pointer;
  double _downY = 0;
  double _lastY = 0;
  Duration? _lastMove;
  double _velocityY = 0;

  /// The card in place when the press began, so a long drag can turn the pile
  /// round more than once without the turn running away.
  var _heldFrom = 0;
  var _index = 0;
  var _held = false;
  var _armed = false;
  var _boardScroll = false;
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
    _cancelTimer();
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

  void _cancelTimer() {
    _armTimer?.cancel();
    _armTimer = null;
  }

  /// Contact. This is the first of the three signals and it is enough on its
  /// own for the visual: the pile opens the instant a finger lands, so the
  /// place reads as switchable without waiting for a drag or a long press.
  void _press(PointerDownEvent event) {
    if (_count < 2) {
      return;
    }
    _cancelTimer();
    _pointer = event.pointer;
    _downY = event.position.dy;
    _lastY = event.position.dy;
    _lastMove = event.timeStamp;
    _velocityY = 0;
    _settled = false;
    _heldFrom = _index;
    _held = true;
    _armed = false;
    _boardScroll = false;
    _dragging = false;

    // Stop a fling still carrying the board: pressing a pile must not leave
    // the page scrolling on behind the opened card. Jumping to where it
    // already is only cancels the activity, it moves nothing.
    final position = Scrollable.maybeOf(context)?.position;
    if (position != null && position.hasPixels) {
      position.jumpTo(position.pixels);
    }
    _open.forward();
    _armTimer = Timer(_holdConfirm, _arm);
  }

  /// The hold is confirmed: this press is about switching cards. Claim the
  /// gesture outright so the board cannot take it later, and give a small
  /// haptic tick so the finger knows the pile is now live.
  void _arm() {
    _armTimer = null;
    if (!_held || _settled || _boardScroll) {
      return;
    }
    _armed = true;
    _claim?.claim();
    // A phone without a vibrator, or a test binding with no platform channel,
    // simply has nothing to answer; the visual dot rail is the real cue.
    HapticFeedback.selectionClick().ignore();
    setState(() {});
  }

  /// The finger moved before the hold was confirmed. That is a scroll past,
  /// not a switch: fold the pile back and hand the gesture to the board before
  /// its drag recognizer reaches touch slop.
  void _yieldToBoard() {
    _cancelTimer();
    _boardScroll = true;
    _claim?.yieldToBoard();
    _open.reverse();
  }

  void _move(PointerMoveEvent event) {
    if (!_held || _settled || event.pointer != _pointer) {
      return;
    }
    final dt = _lastMove == null
        ? Duration.zero
        : event.timeStamp - _lastMove!;
    if (dt.inMicroseconds > 0) {
      _velocityY =
          (event.position.dy - _lastY) / (dt.inMicroseconds / 1000000.0);
    }
    _lastY = event.position.dy;
    _lastMove = event.timeStamp;
    final dy = event.position.dy - _downY;

    if (!_armed) {
      if (!_boardScroll && dy.abs() > _scrollIntent) {
        _yieldToBoard();
      }
      return;
    }
    if (_boardScroll) {
      return;
    }
    _drag(dy);
  }

  /// The pointer was cancelled by the system. Fold straight back so nothing
  /// is left open or half turned.
  void _snapShut() {
    _cancelTimer();
    if (_settled) {
      return;
    }
    _settled = true;
    _held = false;
    _armed = false;
    _boardScroll = false;
    _turn.value = 0;
    _open.reverse();
    setState(() {});
  }

  void _up(PointerUpEvent event) {
    if (event.pointer != _pointer) {
      return;
    }
    _cancelTimer();
    _settle(_velocityY);
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

  /// The finger came up. Whoever classified the press, lifting it folds the
  /// pile back; a real turn settles to the nearer card before it does.
  void _settle(double velocityY) {
    if (_settled) {
      return;
    }
    _settled = true;
    _held = false;
    _armed = false;
    _boardScroll = false;
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
    // The layers hang below the card by this much. It is paint only: the pile
    // must keep the exact height of the one card on top, or pressing it would
    // grow the whole dashboard and make the scroll end jump under the finger.
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
    // At rest this clips to exactly the card's own rectangle: no layers, no
    // extra room above or below, so a stack reads as one ordinary card.
    return ClipRect(
      clipper: _PileClipper(
        over: turn < 0 ? peek : 0,
        aside: 14 * visual,
        spill: spill,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...layers,
          // Once the hold is confirmed, a HyperOS-style dot rail at the side
          // says plainly that this place holds more than one card and can be
          // switched. It is the visible proof that the press was detected.
          if (_armed)
            Positioned(
              right: -9,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: KeyedSubtree(
                  key: const ValueKey('card-stack-switchable'),
                  child: Center(
                    child: _SwitchDots(count: _count, index: _index),
                  ),
                ),
              ),
            ),
          // The card on top is the only child that sizes the Stack, so the
          // pile keeps exactly its height however far it opens. The layers
          // below are painted past its bottom edge, never laid out under it.
          //
          // The Listener sits outside the gesture arena: it sees the down,
          // every move and the up no matter who wins the arena, so no press
          // can leave the pile open behind it and no cancel can snatch the
          // opened pile away. The recognizer underneath only holds a seat.
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _press,
            onPointerMove: _move,
            onPointerUp: _up,
            onPointerCancel: (_) => _snapShut(),
            child: RawGestureDetector(
              behavior: HitTestBehavior.translucent,
              gestures: <Type, GestureRecognizerFactory>{
                _PileClaim:
                    GestureRecognizerFactoryWithHandlers<_PileClaim>(
                      () {
                        final claim = _PileClaim();
                        _claim = claim;
                        return claim;
                      },
                      (_) {
                        // No callbacks by design: the state classifies the
                        // press, this recognizer only claims or yields it.
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
    required double spill,
  }) {
    final depth = lift.abs();
    return Positioned(
      left: 0,
      right: 0,
      // The pile keeps the height of the one card on top, so a layer hangs
      // past the bottom edge instead of being laid out beneath it. Subtracting
      // the spill keeps every edge exactly where the padded layout put it.
      bottom: peek * (steps - lift) - spill,
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

/// The HyperOS-style rail: one dot per card, the one in place filled in. It
/// only exists while a press is confirmed as a switch, so it doubles as the
/// test's proof that the detection actually ran.
class _SwitchDots extends StatelessWidget {
  const _SwitchDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final on = dark ? const Color(0xD9FFFFFF) : const Color(0x8A000000);
    final off = dark ? const Color(0x55FFFFFF) : const Color(0x33000000);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: ClipOval(
              child: ColoredBox(
                color: i == index ? on : off,
                child: const SizedBox(width: 5, height: 5),
              ),
            ),
          ),
      ],
    );
  }
}

/// Clips a pile to its place, keeping the little a card above the top one
/// shows over the edge while the pile turns back to it. Every extra margin is
/// scaled by how open the pile is, so a resting pile clips to its own card.
class _PileClipper extends CustomClipper<Rect> {
  const _PileClipper({
    required this.over,
    required this.aside,
    required this.spill,
  });

  /// Room kept over the top edge for a card turning back over it.
  final double over;

  /// Room at the sides for the corners of an opened pile, which lean out of
  /// the pile's own width.
  final double aside;

  /// How far the layers hang below the card on top. Paint only: the pile keeps
  /// the card's height, so opening it never changes the board's scroll extent.
  final double spill;

  /// A little extra room under the bottom edge for the card's own shadow.
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

/// A seat in the gesture arena, and nothing else. It never resolves on a
/// pointer event: the state decides from contact, hold and travel, then calls
/// [claim] (switching -- hold the board still) or [yieldToBoard] (the finger
/// was scrolling past). Doing it on the hold timer rather than on the first
/// move means the board cannot win a race it was never invited to, and a tap
/// inside the card still goes to the card.
class _PileClaim extends OneSequenceGestureRecognizer {
  var _resolved = false;

  void claim() => _resolve(GestureDisposition.accepted);

  void yieldToBoard() => _resolve(GestureDisposition.rejected);

  void _resolve(GestureDisposition disposition) {
    if (_resolved) {
      return;
    }
    _resolved = true;
    try {
      resolve(disposition);
    } catch (_) {
      // The arena already closed -- the board got there first. Nothing left
      // to claim; the state's own classification still stands.
    }
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _resolved = false;
    startTrackingPointer(event.pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) => stopTrackingPointer(pointer);

  @override
  void rejectGesture(int pointer) => stopTrackingPointer(pointer);

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'pile press claim';
}
