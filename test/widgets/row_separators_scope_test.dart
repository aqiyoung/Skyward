import 'package:skyward/providers/app.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

const _pageSize = Size(1200, 900);

void main() {
  Future<List<Finder>> pumpPage(
    WidgetTester tester, {
    bool rowSeparators = true,
    bool useBase = false,
  }) async {
    tester.view.physicalSize = _pageSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final section = generateSection(
      items: [
        for (var index = 0; index < 3; index++)
          DecorationListItem(title: Text('row $index'), onPressed: () {}),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        overrides: [viewSizeProvider.overrideWithBuild((_, _) => _pageSize)],
        child: useBase
            ? BaseScaffold(
                title: 'page',
                rowSeparators: rowSeparators,
                body: section,
              )
            : CommonScaffold(
                title: 'page',
                rowSeparators: rowSeparators,
                body: section,
              ),
      ),
    );
    await tester.pumpAndSettle();
    return [
      for (var index = 0; index < 3; index++)
        find.widgetWithText(DecorationListItem, 'row $index'),
    ];
  }

  PaintPattern separator(WidgetTester tester, Finder row) {
    final color = Theme.of(tester.element(row)).colorScheme.outlineVariant;
    return paints..something(
      (method, arguments) =>
          method == #drawRect &&
          (arguments[1] as Paint).color.toARGB32() == color.toARGB32(),
    );
  }

  testWidgets('a page keeps its separators by default', (tester) async {
    final rows = await pumpPage(tester);

    expect(tester.renderObject(rows[0]), separator(tester, rows[0]));
    expect(tester.renderObject(rows[1]), separator(tester, rows[1]));
  });

  testWidgets('CommonScaffold with rowSeparators off draws no separator', (
    tester,
  ) async {
    final rows = await pumpPage(tester, rowSeparators: false);

    for (final row in rows) {
      expect(tester.renderObject(row), isNot(separator(tester, row)));
    }
  });

  testWidgets('BaseScaffold forwards rowSeparators to its page', (
    tester,
  ) async {
    final rows = await pumpPage(tester, rowSeparators: false, useBase: true);

    for (final row in rows) {
      expect(tester.renderObject(row), isNot(separator(tester, row)));
    }
  });

  testWidgets('separatedOf falls back to true outside a scope', (tester) async {
    late bool read;
    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (context) {
            read = ListRowSeparatorScope.separatedOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read, isTrue);
  });
}
