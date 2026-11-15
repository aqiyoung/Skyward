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

  /// The edge a pile hangs its cards from. At rest the cards behind line up
  /// with the top one, so nothing shows; an opened pile drops them below it.
  double bottomOf(WidgetTester tester, DashboardWidget card) =>
      tester.getBottomLeft(find.byKey(keyOf(card))).dy;

  /// Where the pile starts, so a card's place reads the same whatever the
  /// page folds around it.
  double pileTop(WidgetTester tester) =>
      tester.getTopLeft(find.byType(CardStack)).dy;

  /// How far the cards behind the top one peek out below it.
  double peek(WidgetTester tester, DashboardWidget behind) =>
      bottomOf(tester, behind) - bottomOf(tester, DashboardWidget.memoryInfo);

  /// Press, slide, lift. The pile opens on the press itself; the short stay
  /// before the slide only lets its gesture beat the page's scroll for the
  /// drag, and is far below the platform's long press.
  Future<void> swipe(WidgetTester tester, double dy) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CardStack)),
    );
    await tester.pump(const Duration(milliseconds: 160));
    await gesture.moveBy(Offset(0, dy));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

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
    // Well short of the platform's own long press: touch alone opens it.
    // Drive the open animation to its end: a single pump only sees the frame
    // the press lands on, before the controller has ticked.
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
    // Lift well before the short stay: the press opened it, and the up must
    // still close it, with no card left peeking out.
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(peek(tester, DashboardWidget.networkControl), closeTo(0, 1.0));
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });

  testWidgets('a swipe turns the pile to the next card', (tester) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    final height = tester
        .getSize(find.byKey(keyOf(DashboardWidget.memoryInfo)))
        .height;
    await swipe(tester, -height * 0.6);
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
    await swipe(tester, -height * 0.6);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));

    await swipe(tester, -height * 0.6);
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });

  testWidgets('a swipe the other way turns back to the card above', (
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
    await swipe(tester, height * 0.6);
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
    await swipe(tester, height * 0.6);
    expect(topOf(tester, DashboardWidget.proxyGroups), pileTop(tester));

    // One more turn back lands on the card in the middle.
    await swipe(tester, height * 0.6);
    expect(topOf(tester, DashboardWidget.networkControl), pileTop(tester));
  });

  testWidgets('a short swipe springs back to the card it started on', (
    tester,
  ) async {
    await pumpPile(tester, const [
      DashboardWidget.memoryInfo,
      DashboardWidget.networkControl,
    ]);
    await swipe(tester, -20);
    expect(topOf(tester, DashboardWidget.memoryInfo), pileTop(tester));
  });
}
