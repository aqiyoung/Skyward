import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/traffic_statistics/traffic_statistics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final pureBlack in [false, true]) {
      testWidgets('traffic panels and grid: $brightness, black=$pureBlack', (
        tester,
      ) async {
        final scheme = seededColorScheme(
          seedColor: const Color(0xFF3366FF),
          brightness: brightness,
        ).toPureBlack(pureBlack);
        final gridColor = scheme.onSurface.withValues(alpha: 0.24);
        late ShapeDecoration decoration;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(colorScheme: scheme).withAppTypography,
            home: Builder(
              builder: (context) {
                decoration = panelDecoration(context, AppCorner.lg);
                return Center(
                  child: SizedBox(
                    width: 320,
                    child: TrafficBarChart(
                      points: [
                        (
                          hour: DateTime(2026, 11, 20),
                          download: 1024,
                          upload: 256,
                        ),
                      ],
                      downloadColor: scheme.primary,
                      uploadColor: scheme.tertiary,
                      labelColor: scheme.onSurface,
                      gridColor: gridColor,
                    ),
                  ),
                );
              },
            ),
          ),
        );
        final card = decoration.color!;
        final page = SurfaceLevel.page.colorOf(scheme);
        if (brightness == Brightness.dark) {
          expect(card.computeLuminance(), greaterThan(page.computeLuminance()));
          expect(
            (card.computeLuminance() + 0.05) / (page.computeLuminance() + 0.05),
            greaterThan(1.15),
          );
        } else {
          // Cards are warm off-white by default; the pure-white surface is
          // a separate appearance toggle.
          expect(card.computeLuminance(), greaterThan(0.9));
        }
        final canvas = find.descendant(
          of: find.byType(TrafficBarChart),
          matching: find.byType(CustomPaint),
        );
        expect(
          tester.renderObject(canvas),
          paints
            ..line(color: gridColor)
            ..line(color: gridColor)
            ..line(color: gridColor),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('grid color changes invalidate the chart painter', (
    tester,
  ) async {
    final points = [
      (hour: DateTime(2026, 11, 20), download: 1024, upload: 256),
    ];
    Future<CustomPainter> pump(Color gridColor) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TrafficBarChart(
            points: points,
            downloadColor: const Color(0xFF3366FF),
            uploadColor: const Color(0xFF66AAFF),
            labelColor: const Color(0xFFFFFFFF),
            gridColor: gridColor,
          ),
        ),
      );
      return tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(TrafficBarChart),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter!;
    }

    final before = await pump(const Color(0x22000000));
    final after = await pump(const Color(0x3DFFFFFF));
    expect(after.shouldRepaint(before), isTrue);
  });
}
