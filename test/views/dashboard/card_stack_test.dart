import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/ui.dart';
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

  GlobalKey keyOf(DashboardWidget card) => keys.putIfAbsent(card, GlobalKey.new);

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

  Future<void> pumpScrollablePile(
    WidgetTester tester,
    ScrollController scroll, {
    DockFollowHold? dockHold,
    List<DashboardWidget> cards = const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ],
  }) async {
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
                      child: dockHold == null
                          ? CardStack(cards: cards, cardKeyOf: keyOf)
                          : DockFollowHoldScope(
                              hold: dockHold,
                              child: CardStack(cards: cards, cardKeyOf: keyOf),
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

  double bottomOf(WidgetTester tester, DashboardWidget card) =>
      tester.getBottomLeft(find.byKey(keyOf(card))).dy;

  double pileTop(WidgetTester tester) =>
      tester.getTopLeft(find.byType(CardStack)).dy;

  double topHeight(WidgetTester tester) =>
      tester.getSize(find.byType(CardStack)).height;

  Offset cardTapPoint(WidgetTester tester, DashboardWidget card) {
    final text = find.descendant(
      of: find.byKey(keyOf(card)),
      matching: find.byType(Text),
    ).first;
    return tester.getCenter(text);
  }

  double peek(WidgetTester tester, DashboardWidget behind) =>
      bottomOf(tester, behind) - bottomOf(tester, DashboardWidget.memoryInfo);

  Future<void> dragFrom(
    WidgetTester tester,
    Offset start,
    double dy,
  ) async {
    final gesture = await tester.startGesture(start);
    await tester.pump();
    const steps = 8;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(0, dy / steps));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

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

  testWidgets('the pile shows one dot per card, and a lone card none', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
      DashboardWidget.proxyGroups,
    ]);
    final dots = find.byKey(const ValueKey('card-stack-dots'));
    expect(dots, findsOneWidget);
    expect(
      find.descendant(of: dots, matching: find.byType(Container)),
      findsNWidgets(3),
    );

    await pumpPile(tester, const [DashboardWidget.memoryInfo]);
    expect(find.byKey(const ValueKey('card-stack-dots')), findsNothing);
  });

  testWidgets('at rest a stack is one clean card, with nothing behind it', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
    expect(peek(tester, DashboardWidget.networkControl), closeTo(0, 1.0));
    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0),
      findsWidgets,
    );
  });

  testWidgets('a tap switches to the next card without opening the pile', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
    expect(peek(tester, DashboardWidget.networkControl), closeTo(0, 1.0));

    final gesture = await tester.startGesture(
      cardTapPoint(tester, DashboardWidget.memoryInfo),
    );
    await tester.pump();
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
    expect(peek(tester, DashboardWidget.networkControl), closeTo(0, 1.0));

    await gesture.up();
    await tester.pumpAndSettle();

    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
    expect(peek(tester, DashboardWidget.memoryInfo), closeTo(0, 1.0));
  });

  testWidgets('a tap on a control inside the top card switches the pile', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.networkControl,
      DashboardWidget.memoryInfo,
    ]);
    final control = find
        .descendant(
          of: find.byKey(keyOf(DashboardWidget.networkControl)),
          matching: find.byType(InkWell),
        )
        .first;
    await tester.tapAt(tester.getCenter(control));
    await tester.pumpAndSettle();

    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });

  testWidgets('repeated taps cycle through every card and wrap around', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
      DashboardWidget.proxyGroups,
    ]);

    var current = DashboardWidget.memoryInfo;
    for (final card in const [
      DashboardWidget.networkControl,
      DashboardWidget.proxyGroups,
      DashboardWidget.memoryInfo,
    ]) {
      await tester.tapAt(cardTapPoint(tester, current));
      await tester.pumpAndSettle();
      expect(topOf(tester, card), pileTop(tester), reason: 'selected $card');
      current = card;
    }
  });

  testWidgets('a swipe turns the pile to the next card', (tester) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    await swipe(tester, -0.6);
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
    await swipe(tester, 0.6);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
  });

  testWidgets('a pile of three turns back over its top edge', (tester) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
      DashboardWidget.proxyGroups,
    ]);
    await swipe(tester, 0.6);
    expect(topOf(tester, DashboardWidget.proxyGroups), pileTop(tester));

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

  testWidgets('switching a card leaves the scrolling board perfectly still', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await pumpScrollablePile(tester, scroll);
    expect(scroll.offset, 0);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    final dy = topHeight(tester) * -0.6;
    for (var step = 0; step < 8; step++) {
      await gesture.moveBy(Offset(0, dy / 8));
      await tester.pump(const Duration(milliseconds: 16));
      expect(scroll.offset, 0);
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(scroll.offset, 0);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
  });

  testWidgets('holding before a drag scrolls instead of switching cards', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await pumpScrollablePile(tester, scroll);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
    for (var step = 0; step < 8; step++) {
      await gesture.moveBy(const Offset(0, -25));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(scroll.offset, greaterThan(0));
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });

  testWidgets('a tap switches the pile inside the scrolling board', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await pumpScrollablePile(tester, scroll);

    await tester.tapAt(tester.getCenter(find.byType(CardStack)));
    await tester.pumpAndSettle();

    expect(scroll.offset, 0);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
  });

  testWidgets('a tap on a control switches the pile inside the board', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await pumpScrollablePile(
      tester,
      scroll,
      cards: const [
        DashboardWidget.networkControl,
        DashboardWidget.memoryInfo,
      ],
    );

    final control = find
        .descendant(
          of: find.byKey(keyOf(DashboardWidget.networkControl)),
          matching: find.byType(InkWell),
        )
        .first;
    await tester.tapAt(tester.getCenter(control));
    await tester.pumpAndSettle();

    expect(scroll.offset, 0);
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });

  testWidgets('flipping holds the dock until the hold-scroll takes over', (
    tester,
  ) async {
    final hold = DockFollowHold();
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await pumpScrollablePile(tester, scroll, dockHold: hold);

    final tap = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    await tester.pump();
    expect(hold.held, isTrue, reason: 'the pile owns the finger');
    await tap.up();
    await tester.pumpAndSettle();
    expect(hold.held, isFalse);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));

    final drag = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(hold.held, isFalse, reason: 'page scrolling is the page again');
    for (var step = 0; step < 4; step++) {
      await drag.moveBy(const Offset(0, -25));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await drag.up();
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    expect(hold.held, isFalse);
  });

  testWidgets('the board can still scroll from outside a pile', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await pumpScrollablePile(tester, scroll);

    await dragFrom(tester, const Offset(200, 600), -200);

    expect(scroll.offset, greaterThan(0));
  });
}
