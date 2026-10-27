import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/views/dashboard/widgets/outbound_mode.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/glyph_finders.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_profiles.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    globalState.container = container;
  });

  tearDown(() => container.dispose());

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double width = 360,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: MediaQuery.withClampedTextScaling(
                  minScaleFactor: textScale,
                  maxScaleFactor: textScale,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder buttonOf(Mode mode) => find
      .ancestor(of: find.text(mode.label), matching: find.byType(InkWell))
      .first;

  ShapeDecoration? decorationOf(WidgetTester tester, Mode mode) {
    final container = find
        .ancestor(of: buttonOf(mode), matching: find.byType(Container))
        .first;
    return tester.widget<Container>(container).decoration as ShapeDecoration?;
  }

  testWidgets(
    'the selector shows every mode, the selected one with a check and '
    'no mode glyphs',
    (tester) async {
      await pump(tester, const OutboundModeSelector());

      for (final mode in Mode.values) {
        expect(find.text(mode.label), findsOneWidget);
      }
      // Reference layout: a blue check before the selected label, and
      // no second glyph for any mode.
      expect(
        find.descendant(
          of: buttonOf(Mode.rule),
          matching: find.byGlyph(AppGlyphs.check),
        ),
        findsOneWidget,
      );
      for (final glyph in [
        AppGlyphs.rules,
        AppGlyphs.proxies,
        AppGlyphs.target,
      ]) {
        expect(find.byGlyph(glyph), findsNothing);
      }
    },
  );

  testWidgets('tapping a mode selects it and turns it into the pill', (
    tester,
  ) async {
    await pump(tester, const OutboundModeSelector());
    final tone2 = DashboardColors.of(
      tester.element(find.byType(OutboundModeSelector)),
    ).tone2;
    expect(decorationOf(tester, Mode.rule)?.color, tone2);
    expect(decorationOf(tester, Mode.direct), isNull);

    await tester.tap(buttonOf(Mode.direct));
    await tester.pumpAndSettle();

    expect(container.read(patchClashConfigProvider).mode, Mode.direct);
    expect(decorationOf(tester, Mode.direct)?.color, tone2);
    expect(decorationOf(tester, Mode.rule), isNull);
    expect(
      find.descendant(
        of: buttonOf(Mode.direct),
        matching: find.byGlyph(AppGlyphs.check),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: buttonOf(Mode.rule),
        matching: find.byGlyph(AppGlyphs.check),
      ),
      findsNothing,
    );
  });

  testWidgets('the modes keep their fills with glass on', (tester) async {
    await pump(
      tester,
      const LiquidGlassScope(enabled: true, child: OutboundModeSelector()),
    );
    final tone2 = DashboardColors.of(
      tester.element(find.byType(OutboundModeSelector)),
    ).tone2;

    expect(find.byType(LiquidGlass), findsNothing);
    expect(decorationOf(tester, Mode.rule)?.color, tone2);
  });

  testWidgets('a pressed mode stays flat, without a swell', (tester) async {
    await pump(tester, const OutboundModeSelector());
    double swellOf(Mode mode) {
      final box = tester.renderObject<RenderBox>(buttonOf(mode));
      return ElasticPress.paintBoundsOf(box).width / box.size.width;
    }

    final gesture = await tester.startGesture(
      tester.getCenter(buttonOf(Mode.rule)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The one-container selector uses a plain InkWell, not ElasticPress.
    for (final mode in Mode.values) {
      expect(swellOf(mode), moreOrLessEquals(1));
    }

    await gesture.up();
    await tester.pumpAndSettle();
    expect(container.read(patchClashConfigProvider).mode, Mode.rule);
  });

  testWidgets('the desktop bar fills its height and switches the mode', (
    tester,
  ) async {
    await pump(
      tester,
      const DashboardDensityScope(
        density: DashboardDensity.standard,
        scale: 1,
        child: SizedBox(height: 64, child: OutboundModeBar()),
      ),
      width: 600,
    );
    expect(tester.getSize(buttonOf(Mode.rule)).height, 64 - 8 * 2);

    await tester.tap(buttonOf(Mode.global));
    await tester.pumpAndSettle();

    expect(container.read(patchClashConfigProvider).mode, Mode.global);
  });

  testWidgets('large text on a narrow phone still fits', (tester) async {
    await pump(tester, const OutboundModeSelector(), width: 300, textScale: 1.4);

    expect(tester.takeException(), isNull);
  });
}
