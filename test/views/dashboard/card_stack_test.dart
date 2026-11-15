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

  double topOf(WidgetTester tester, DashboardWidget card) =>
      tester.getTopLeft(find.byKey(keyOf(card))).dy;

  /// The edge a pile hangs its cards from: each one shows that edge of the
  /// card below it, so the depth of the pile reads off these.
  double bottomOf(WidgetTester tester, DashboardWidget card) =>
      tester.getBottomLeft(find.byKey(keyOf(card))).dy;

  /// Where the pile starts, so a card's place reads the same whatever the
  /// page folds around it.
  double pileTop(WidgetTester tester) =>
      tester.getTopLeft(find.byType(CardStack)).dy;

  testWidgets('one card draws alone, with no pile around it', (tester) async {
    await pumpPile(tester, const [DashboardWidget.memoryInfo]);
    expect(find.byType(CardStack), findsOneWidget);
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });

  testWidgets('the cards under the top one peek out below it', (tester) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
    expect(
      bottomOf(tester, DashboardWidget.networkControl),
      greaterThan(bottomOf(tester, DashboardWidget.memoryInfo)),
    );
  });

  testWidgets('a plain drag leaves the pile alone', (tester) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final before = topOf(tester, DashboardWidget.networkControl);
    await tester.drag(find.byType(CardStack), const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(topOf(tester, DashboardWidget.networkControl), before);
  });

  /// A drag the pile was held for: press, wait out the long press, then move.
  Future<void> heldDrag(WidgetTester tester, double dy) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    // Long press first: the pile only turns for a drag it was held for.
    await tester.pump(const Duration(milliseconds: 1150));
    await gesture.moveBy(Offset(0, dy));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('a held drag turns the pile to the next card', (tester) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final height = tester
        .getSize(find.byKey(keyOf(DashboardWidget.memoryInfo)))
        .height;
    await heldDrag(tester, -height * 0.6);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
  });

  testWidgets('the pile turns all the way round: every card comes back', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final height = tester
        .getSize(find.byKey(keyOf(DashboardWidget.memoryInfo)))
        .height;
    await heldDrag(tester, -height * 0.6);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));

    await heldDrag(tester, -height * 0.6);
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });

  testWidgets('a drag the other way turns back to the card above', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final height = tester
        .getSize(find.byKey(keyOf(DashboardWidget.memoryInfo)))
        .height;
    // Backwards off the first card lands on the last one: the pile loops.
    await heldDrag(tester, height * 0.6);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
  });

  testWidgets('a pile of three turns back over its top edge', (tester) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
      DashboardWidget.proxyGroups,
    ]);
    final height = tester
        .getSize(find.byKey(keyOf(DashboardWidget.memoryInfo)))
        .height;
    // Backwards off the first card: the last one comes down over the edge.
    await heldDrag(tester, height * 0.6);
    expect(topOf(tester, DashboardWidget.proxyGroups), pileTop(tester));

    // One more turn back lands on the card in the middle.
    await heldDrag(tester, height * 0.6);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
  });

  testWidgets('holding the pile opens the cards under it', (tester) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final resting =
        bottomOf(tester, DashboardWidget.networkControl) -
        bottomOf(tester, DashboardWidget.memoryInfo);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    await tester.pump(const Duration(milliseconds: 1150));
    await tester.pump(const Duration(milliseconds: 200));
    final opened =
        bottomOf(tester, DashboardWidget.networkControl) -
        bottomOf(tester, DashboardWidget.memoryInfo);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(resting, greaterThan(0));
    expect(opened, greaterThan(resting));
  });

  testWidgets('a short held drag springs back to the card it started on', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    await tester.pump(const Duration(milliseconds: 1150));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });
}
