import 'package:skyward/providers/app.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

const _mobile = Size(400, 900);

Future<void> _pumpPage(WidgetTester tester, Widget body) async {
  tester.view.physicalSize = _mobile;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    TestApp(
      overrides: [viewSizeProvider.overrideWithBuild((_, _) => _mobile)],
      child: CommonScaffold(title: 'Reports', body: body),
    ),
  );
  await tester.pumpAndSettle();
}

/// The nearest fade around the title belongs to the bar's own step-aside.
double _titleOpacity(WidgetTester tester) {
  final fade = find.ancestor(
    of: find.text('Reports'),
    matching: find.byType(FadeTransition),
  );
  return tester.widget<FadeTransition>(fade.first).opacity.value;
}

Widget _rows() => ListView.builder(
  itemCount: 40,
  itemBuilder: (_, index) => SizedBox(height: 48, child: Text('row $index')),
);

void main() {
  testWidgets('the title steps aside as the page scrolls up', (tester) async {
    await _pumpPage(tester, _rows());
    expect(_titleOpacity(tester), 1.0);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(_titleOpacity(tester), 0.0);

    await tester.drag(find.byType(ListView), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(_titleOpacity(tester), 1.0);
  });

  testWidgets('a page under the tabs still moves its own title', (
    tester,
  ) async {
    // The tabs page horizontally, so the page's scroll arrives a viewport down
    // and still has to reach the bar.
    await _pumpPage(tester, PageView(children: [_rows()]));

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(_titleOpacity(tester), 0.0);
  });

  testWidgets('paging between tabs leaves the title where it is', (
    tester,
  ) async {
    await _pumpPage(tester, PageView(children: [_rows(), _rows()]));

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(_titleOpacity(tester), 1.0);
  });
}
