import 'package:skyward/manager/app_manager.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    globalState.appEnv = 'stable';
  });

  Future<void> pump(WidgetTester tester, {required bool safeMode}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [safeModeProvider.overrideWithValue(safeMode)],
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: AppEnvManager(child: SizedBox(key: Key('child'))),
        ),
      ),
    );
  }

  testWidgets('a debug build labels itself, whatever its channel', (
    tester,
  ) async {
    await pump(tester, safeMode: false);

    // A package carries its channel in the home's corner pill; the ribbon is
    // for the build that exists on one machine only.
    final banner = tester.widget<Banner>(find.byType(Banner));
    expect(banner.message, 'DEBUG');
    expect(find.byKey(const Key('child')), findsOneWidget);
  });

  testWidgets('a safe mode build is bannered on any channel', (tester) async {
    await pump(tester, safeMode: true);

    final banner = tester.widget<Banner>(find.byType(Banner));
    expect(banner.message, 'SAFE MODE');
    expect(find.byKey(const Key('child')), findsOneWidget);
  });
}
