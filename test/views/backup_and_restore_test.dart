import 'package:skyward/common/dav_client.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/features/form/form.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/providers/config.dart';
import 'package:skyward/providers/database.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/backup_and_restore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/glyph_finders.dart';
import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

const _existing = DAVProps(
  uri: 'https://dav.example.com/remote',
  user: 'alice',
  password: 'secret',
  fileName: 'custom.zip',
);

/// Answers the reachability probe without a socket: the page pings on open,
/// and a test has no server behind the address it was given.
class _FakeDAVClient extends DAVClient {
  _FakeDAVClient(super.dav);

  @override
  Future<bool> ping() async => true;
}

DAVConnectionController _offlineController() =>
    DAVConnectionController(createClient: _FakeDAVClient.new);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    globalState.container = container;
    container.read(viewSizeProvider.notifier).value = const Size(1200, 1400);
    container.listen(davSettingProvider, (_, _) {}, fireImmediately: true);
  });

  tearDown(() => container.dispose());

  void sizeView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpForm(WidgetTester tester, Widget form) async {
    sizeView(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showFormSheet<void>(context: context, builder: (_) => form),
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
  }

  Future<void> pumpPage(WidgetTester tester) async {
    sizeView(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: BackupAndRestore(connection: _offlineController()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String title) => find.descendant(
    of: find.widgetWithText(FormRow, title),
    matching: find.byType(TextFormField),
  );

  Future<void> save(WidgetTester tester) async {
    // A narrow sheet puts the confirm action at the foot as a labelled button;
    // a wide one keeps it in the bar as a check glyph. The sheet width follows
    // the view, so the test looks for whichever one the layout produced.
    final foot = find.widgetWithText(TextButton, 'Save');
    if (foot.evaluate().isNotEmpty) {
      await tester.tap(foot);
    } else {
      await tester.tap(find.widgetWithGlyph(IconButton, AppGlyphs.check));
    }
    await tester.pumpAndSettle();
  }

  group('RestoreOptionsDialog', () {
    Future<RestoreOption?> openAndChoose(
      WidgetTester tester,
      String label,
    ) async {
      sizeView(tester);
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

  group('BackupAndRestore', () {
    testWidgets('offers a binding row while nothing is bound', (tester) async {
      await pumpPage(tester);

      expect(find.text('Please bind WebDAV'), findsOneWidget);
      expect(find.text('Bind'), findsOneWidget);
      // The cloud rows only exist once there is a server to point them at.
      expect(find.text('Edit'), findsNothing);
      expect(find.text('custom.zip'), findsNothing);
    });

    testWidgets('shows the bound account, file name and both directions', (
      tester,
    ) async {
      container.read(davSettingProvider.notifier).update((_) => _existing);

      await pumpPage(tester);

      expect(find.text('alice'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('custom.zip'), findsOneWidget);
      // Backup and Restore each appear twice: once for the server, once for
      // the file the picker hands back.
      expect(find.text('Backup'), findsNWidgets(2));
      expect(find.text('Restore'), findsNWidgets(2));
    });
  });

  group('WebDAVForm', () {
    testWidgets('rejects an empty form and stores nothing', (tester) async {
      await pumpForm(tester, const WebDAVForm());

      await save(tester);

      expect(container.read(davSettingProvider), isNull);
      expect(find.byType(WebDAVForm), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ErrorBanner),
          matching: find.text('Please enter a valid WebDAV address'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('names the password toggle by what pressing it does', (
      tester,
    ) async {
      await pumpForm(tester, const WebDAVForm());

      final toggle = find.descendant(
        of: find.widgetWithText(FormRow, 'Password'),
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(toggle).tooltip, 'Show password');

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(tester.widget<IconButton>(toggle).tooltip, 'Hide password');
    });

    testWidgets('rejects a malformed address', (tester) async {
      await pumpForm(tester, const WebDAVForm());

      await tester.enterText(field('Address'), 'not-a-url');
      await tester.enterText(field('Account'), 'alice');
      await tester.enterText(field('Password'), 'secret');
      await save(tester);

      expect(container.read(davSettingProvider), isNull);
      expect(find.byType(WebDAVForm), findsOneWidget);
    });

    testWidgets('stores a valid binding with the default file name', (
      tester,
    ) async {
      await pumpForm(tester, const WebDAVForm());

      await tester.enterText(
        field('Address'),
        'https://dav.example.com/remote',
      );
      await tester.enterText(field('Account'), 'alice');
      await tester.enterText(field('Password'), 'secret');
      await save(tester);

      final dav = container.read(davSettingProvider);
      expect(dav?.uri, 'https://dav.example.com/remote');
      expect(dav?.user, 'alice');
      expect(dav?.password, 'secret');
      expect(dav?.fileName, defaultDavFileName);
      expect(find.byType(WebDAVForm), findsNothing);
    });

    testWidgets('editing preserves the previously chosen file name', (
      tester,
    ) async {
      container.read(davSettingProvider.notifier).update((_) => _existing);
      await pumpForm(tester, const WebDAVForm(dav: _existing));

      await tester.enterText(field('Account'), 'bob');
      await save(tester);

      final dav = container.read(davSettingProvider);
      expect(dav?.user, 'bob');
      expect(dav?.fileName, 'custom.zip');
    });

    testWidgets('offers delete only when editing an existing binding', (
      tester,
    ) async {
      await pumpForm(tester, const WebDAVForm());
      expect(find.widgetWithText(FormRow, 'Delete'), findsNothing);
      Navigator.of(tester.element(find.byType(WebDAVForm))).pop();
      await tester.pumpAndSettle();

      await pumpForm(tester, const WebDAVForm(dav: _existing));
      expect(find.widgetWithText(FormRow, 'Delete'), findsOneWidget);
    });

    testWidgets('delete clears the stored binding', (tester) async {
      container.read(davSettingProvider.notifier).update((_) => _existing);
      await pumpForm(tester, const WebDAVForm(dav: _existing));

      await tester.tap(find.widgetWithText(FormRow, 'Delete'));
      await tester.pumpAndSettle();

      expect(container.read(davSettingProvider), isNull);
    });

    testWidgets('toggles password visibility', (tester) async {
      await pumpForm(tester, const WebDAVForm(dav: _existing));

      expect(find.byGlyph(AppGlyphs.eye), findsOneWidget);
      await tester.tap(find.byGlyph(AppGlyphs.eye));
      await tester.pumpAndSettle();
      expect(find.byGlyph(AppGlyphs.eyeOff), findsOneWidget);
    });
  });
}
