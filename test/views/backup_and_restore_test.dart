import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/providers/database.dart';
import 'package:skyward/state.dart';
import 'package:skyward/views/backup_and_restore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    globalState.container = container;
    container.read(viewSizeProvider.notifier).value = const Size(1200, 1400);
  });

  tearDown(() => container.dispose());

  group('RestoreOptionsDialog', () {
    Future<RestoreOption?> openAndChoose(
      WidgetTester tester,
      String label,
    ) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      RestoreOption? chosen;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp(
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    chosen = await showDialog<RestoreOption>(
                      context: context,
                      builder: (_) => const RestoreOptionsDialog(),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      return chosen;
    }

    testWidgets('returns onlyProfiles for the config-only option', (
      tester,
    ) async {
      expect(
        await openAndChoose(tester, 'Restore profiles only'),
        RestoreOption.onlyProfiles,
      );
    });

    testWidgets('returns all for the full-data option', (tester) async {
      expect(
        await openAndChoose(tester, 'Restore all data'),
        RestoreOption.all,
      );
    });
  });
}
