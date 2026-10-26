import 'package:skyward/providers/app.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/glyph_finders.dart';
import '../helpers/test_app.dart';

void _noop() {}

const _mobile = Size(400, 900);

Future<void> _pumpPage(
  WidgetTester tester,
  Widget body, {
  bool hideActionsOnScroll = true,
  IconButtonData? confirmationAction,
}) async {
  tester.view.physicalSize = _mobile;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    TestApp(
      overrides: [viewSizeProvider.overrideWithBuild((_, _) => _mobile)],
      child: CommonScaffold(
        title: 'Reports',
        hideActionsOnScroll: hideActionsOnScroll,
        iconActions: [
          IconButtonData(
            glyph: AppGlyphs.edit,
            tooltip: 'Edit',
            onPressed: _noop,
          ),
        ],
        confirmationAction: confirmationAction,
        body: body,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The nearest fade around the action belongs to the bar's own step-aside.
/// When the action is opted out, or a confirmation action is present, that
/// fade is absent and the nearest one is the sheet cover, which stays
/// fully opaque.
double _actionOpacity(WidgetTester tester) {
  final button = find.widgetWithGlyph(IconButton, AppGlyphs.edit);
  final fade = find.ancestor(
    of: button,
    matching: find.byType(FadeTransition),
  );
  return tester.widget<FadeTransition>(fade.first).opacity.value;
}

Widget _rows() => ListView.builder(
  itemCount: 40,
  itemBuilder: (_, index) => SizedBox(height: 48, child: Text('row $index')),
);

void main() {
  testWidgets('an action steps aside by default as the page scrolls up', (
    tester,
  ) async {
    await _pumpPage(tester, _rows());
    expect(_actionOpacity(tester), 1.0);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(_actionOpacity(tester), 0.0);

    await tester.drag(find.byType(ListView), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(_actionOpacity(tester), 1.0);
  });

  testWidgets('an opted-out action stays put', (tester) async {
    await _pumpPage(tester, _rows(), hideActionsOnScroll: false);
    expect(_actionOpacity(tester), 1.0);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(_actionOpacity(tester), 1.0);
  });

  testWidgets('a confirmation action keeps the bar actions in reach', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      _rows(),
      confirmationAction: IconButtonData(
        glyph: AppGlyphs.check,
        tooltip: 'Done',
        onPressed: _noop,
      ),
    );
    expect(_actionOpacity(tester), 1.0);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(_actionOpacity(tester), 1.0);
  });
}
