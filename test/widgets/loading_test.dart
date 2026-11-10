import 'package:skyward/ui/loading.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Size loadingSize(WidgetTester tester) => tester.getSize(
    find.descendant(
      of: find.byType(CommonCircleLoading),
      matching: find.byType(CustomPaint),
    ),
  );

  testWidgets('CommonCircleLoading takes the ambient icon size', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: IconTheme(
            data: IconThemeData(size: 20),
            child: CommonCircleLoading(),
          ),
        ),
      ),
    );

    expect(loadingSize(tester), const Size.square(20));
  });

  testWidgets('CommonCircleLoading takes an explicit or page size', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommonCircleLoading(size: 16),
              CommonCircleLoading.page(),
            ],
          ),
        ),
      ),
    );

    final sizes = tester
        .widgetList<CommonCircleLoading>(find.byType(CommonCircleLoading))
        .map((loading) => tester.getSize(find.byWidget(loading)));
    expect(sizes, [const Size.square(16), const Size.square(128)]);
  });

  testWidgets('CommonCircleLoading.page stays under the illustration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: CommonCircleLoading.page())),
    );

    expect(loadingSize(tester), const Size.square(96));
  });

  testWidgets('CommonCircleLoading fills a tight slot', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 32,
            child: CommonCircleLoading(size: 24),
          ),
        ),
      ),
    );

    expect(loadingSize(tester), const Size.square(32));
  });

  testWidgets('CommonCircleLoading keeps turning until disposed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: CommonCircleLoading())),
    );
    await tester.pump(const Duration(milliseconds: 2500));

    expect(SchedulerBinding.instance.transientCallbackCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(SchedulerBinding.instance.transientCallbackCount, 0);
  });

  testWidgets('CommonCircleLoading exposes an optional label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CommonCircleLoading(semanticLabel: 'Loading profiles'),
      ),
    );

    expect(find.bySemanticsLabel('Loading profiles'), findsOneWidget);
  });

  for (final disableAnimations in [false, true]) {
    testWidgets('CommonCircleLoading paints a whole loop, '
        'disableAnimations: $disableAnimations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommonCircleLoading(size: 12),
                  CommonCircleLoading.page(),
                ],
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 110; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('CommonCircleLoading.page draws back in with its switcher', (
    tester,
  ) async {
    final presence = AnimationController(vsync: tester, value: 1);
    addTearDown(presence.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ActivityPresence(
            animation: presence,
            child: const CommonCircleLoading.page(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    presence.value = 0;
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(loadingSize(tester), const Size.square(128));
  });
}
