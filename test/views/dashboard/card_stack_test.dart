import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/views/dashboard/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_profiles.dart';

void main() {
  late ProviderContainer container;
  final keys = <DashboardWidget, GlobalKey>{};

  GlobalKey keyOf(DashboardWidget card) =>
      keys.putIfAbsent(card, GlobalKey.new);

  setUp(() {
    container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    globalState.container = container;
  });

  tearDown(() => container.dispose());

  Future<void> pumpPile(
    WidgetTester tester,
    List<DashboardWidget> cards,
  ) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    container.read(viewSizeProvider.notifier).value = const Size(412, 1400);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: Center(
            child: SizedBox(
              width: 380,
              child: CardStack(cards: cards, cardKeyOf: keyOf),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The same pile, but inside a scrolling board like the real dashboard.
  /// Room below the pile makes the board genuinely scrollable.
  Future<void> pumpScrollablePile(
    WidgetTester tester,
    ScrollController scroll,
  ) async {
    tester.view.physicalSize = const Size(412, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    container.read(viewSizeProvider.notifier).value = const Size(412, 700);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: CustomScrollView(
            controller: scroll,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 380,
                      child: CardStack(
                        cards: const [
                          DashboardWidget.memoryInfo,
                          DashboardWidget.networkControl,
                        ],
                        cardKeyOf: keyOf,
                      ),
                    ),
                    const SizedBox(height: 1600),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double topOf(WidgetTester tester, DashboardWidget card) =>
      tester.getTopLeft(find.byKey(keyOf(card))).dy;

  /// The edge a pile hangs its cards from. At rest the cards behind line up
  /// with the top one, so nothing shows; an opened pile drops them below it.
  double bottomOf(WidgetTester tester, DashboardWidget card) =>
      tester.getBottomLeft(find.byKey(keyOf(card))).dy;

  /// Where the pile starts, so a card's place reads the same whatever the
  /// page folds around it.
  double pileTop(WidgetTester tester) =>
      tester.getTopLeft(find.byType(CardStack)).dy;

  /// The height of the card currently on top. Cards in a pile are not all the
  /// same height, so a swipe is measured against the one actually showing --
  /// exactly what a finger sees on a real screen.
  double topHeight(WidgetTester tester) =>
      tester.getSize(find.byType(CardStack)).height;

  /// How far the cards behind the top one peek out below it.
  double peek(WidgetTester tester, DashboardWidget behind) =>
      bottomOf(tester, behind) - bottomOf(tester, DashboardWidget.memoryInfo);

  /// A real finger crosses a card in several frames, not one jump. Splitting
  /// the move lets the drag recognizer settle and the release carry a velocity.
  ///
  /// A press only becomes a switch after the finger rests on the pile for a
  /// moment, so every swipe confirms the hold first. Sliding before that is a
  /// deliberate "scroll past", covered by its own test below.
  /// Drives frames past a switch's turn, timed rest and fold so the pile is
  /// back to one plain card. Pumping in small steps lets any timer the switch
  /// scheduled fire on the way, instead of betting on one exact duration.
  Future<void> foldBack(WidgetTester tester) async {
    for (var step = 0; step < 16; step++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  Future<void> dragFrom(WidgetTester tester, Offset start, double dy) async {
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    const steps = 8;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(0, dy / steps));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await foldBack(tester);
  }

  /// Press, slide, lift across a fraction of the visible card's height.
  /// Negative turns forwards, positive turns back. Measuring against the card
  /// on top keeps every turn consistent even when the cards differ in height.
  Future<void> swipe(WidgetTester tester, double fraction) async => dragFrom(
    tester,
    tester.getCenter(find.byType(CardStack)),
    topHeight(tester) * fraction,
  );

  testWidgets('one card draws alone, with no pile around it', (tester) async {
    await pumpPile(tester, const [DashboardWidget.memoryInfo]);
    expect(find.byType(CardStack), findsOneWidget);
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });

  testWidgets('at rest a stack is one clean card, with nothing behind it', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
    // No edge of the card underneath hangs below the top one.
    expect(peek(tester, DashboardWidget.networkControl), closeTo(0, 1.0));
    // The layers are still there to keep their state, but fully transparent.
    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0),
      findsWidgets,
    );
  });

  testWidgets('pressing opens the pile at once, with no long hold', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    // Touch alone opens it. Drive the open animation to its end: a single pump
    // only sees the frame the press lands on, before the controller has ticked.
    await tester.pumpAndSettle();
    expect(peek(tester, DashboardWidget.networkControl), greaterThan(10));
    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity > 0),
      findsWidgets,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('lifting the finger folds the pile back to one card', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    // Let the pile actually open before lifting, so the fold-back is a real
    // transition from an opened pile and not a no-op on a resting one.
    await tester.pumpAndSettle();
    expect(peek(tester, DashboardWidget.networkControl), greaterThan(10));
    await gesture.up();
    // The fold-back is a fraction of a second, not a slow settle.
    await tester.pumpAndSettle();
    expect(peek(tester, DashboardWidget.networkControl), closeTo(0, 1.0));
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0),
      findsWidgets,
    );
  });

  testWidgets('a tap too short to turn still folds the pile back', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    // Lift without dragging: the press opened it, and the up must still close
    // it, with no card left peeking out.
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(peek(tester, DashboardWidget.networkControl), closeTo(0, 1.0));
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });

  testWidgets('holding past the confirm without sliding opens the detail', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    // Past the hold confirm, but no slide: the card's own tap must win.
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(MemoryDetailSheet), findsOneWidget);
  });

  testWidgets('jitter below the slide threshold still opens the detail', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(0, 4));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(MemoryDetailSheet), findsOneWidget);
  });

  testWidgets('a swipe turns the pile to the next card', (tester) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    await swipe(tester, -0.6);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
  });

  testWidgets('a switch holds the new card open before folding back', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final openLayers = find.byWidgetPredicate(
      (w) => w is Opacity && w.opacity > 0,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    await tester.pump(const Duration(milliseconds: 160));
    final dy = topHeight(tester) * -0.6;
    for (var step = 0; step < 8; step++) {
      await gesture.moveBy(Offset(0, dy / 8));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();

    await tester.pump(const Duration(milliseconds: 260));
    expect(openLayers, findsWidgets, reason: 'held open after the switch');

    await foldBack(tester);
    expect(openLayers, findsNothing);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
  });

  testWidgets('the pile turns all the way round: every card comes back', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    await swipe(tester, -0.6);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));

    await swipe(tester, -0.6);
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });

  testWidgets('a swipe the other way turns back to the card above', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    // Backwards off the first card lands on the last one: the pile loops.
    await swipe(tester, 0.6);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
  });

  testWidgets('a pile of three turns back over its top edge', (tester) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
      DashboardWidget.proxyGroups,
    ]);
    // Backwards off the first card: the last one comes down over the edge.
    await swipe(tester, 0.6);
    expect(topOf(tester, DashboardWidget.proxyGroups), pileTop(tester));

    // One more turn back lands on the card in the middle.
    await swipe(tester, 0.6);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
  });

  testWidgets('a short swipe springs back to the card it started on', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    await dragFrom(tester, tester.getCenter(find.byType(CardStack)), -20);
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });

  testWidgets('resting a finger detects a switch without any drag', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    // Nothing says "switchable" until a finger actually lands and rests.
    expect(find.byKey(const ValueKey('card-stack-switchable')), findsNothing);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    await tester.pumpAndSettle();
    // Contact opens the pile, and the short hold is detected as "switch":
    // the dot rail is the visible proof, with no long press and no slide.
    expect(peek(tester, DashboardWidget.networkControl), greaterThan(10));
    expect(find.byKey(const ValueKey('card-stack-switchable')), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('card-stack-switchable')), findsNothing);
  });

  testWidgets('sliding off before the hold is confirmed scrolls the board', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await pumpScrollablePile(tester, scroll);
    expect(scroll.offset, 0);

    // A finger lands on the pile but sweeps away at once, before the hold is
    // confirmed: that is a scroll past, not a card switch.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    await tester.pump();
    const steps = 8;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(const Offset(0, -25));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(scroll.offset, greaterThan(0));
    expect(find.byKey(const ValueKey('card-stack-switchable')), findsNothing);
  });

  testWidgets('switching a card leaves the scrolling board perfectly still', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await pumpScrollablePile(tester, scroll);
    expect(scroll.offset, 0);

    // A decisive vertical swipe on the pile: the page must not scroll a
    // single pixel while the pile turns.
    await swipe(tester, -0.6);

    expect(scroll.offset, 0);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
  });

  testWidgets('the board can still scroll from outside a pile', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await pumpScrollablePile(tester, scroll);

    // Drag on the empty space below the pile, away from any card.
    await dragFrom(tester, const Offset(200, 600), -200);

    expect(scroll.offset, greaterThan(0));
  });
}
