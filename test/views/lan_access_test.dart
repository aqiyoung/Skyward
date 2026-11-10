import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/config/lan_access.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(TestProfiles.new),
        localIpProvider.overrideWithBuild((_, _) => '192.168.1.23'),
      ],
    );
    globalState.container = container;
  });

  tearDown(() => container.dispose());

  Future<void> pumpView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(locale: Locale('en'), child: LanAccessView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the full proxy address, LAN IP and port', (tester) async {
    await pumpView(tester);

    expect(find.text('192.168.1.23:7890'), findsOneWidget);
    expect(find.text('Intranet IP'), findsOneWidget);
    expect(find.text('Port'), findsOneWidget);
    expect(find.text('7890'), findsOneWidget);
    // The switch lives on this page now, and starts off. "Allow LAN" is both
    // the page title and the switch label, so it appears twice.
    expect(find.text('Allow LAN'), findsNWidgets(2));
    expect(find.text('Disabled'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the switch turns LAN access on', (tester) async {
    await pumpView(tester);

    await tester.tap(find.byType(CommonSwitch));
    await tester.pumpAndSettle();

    expect(container.read(patchClashConfigProvider).allowLan, isTrue);
    expect(find.text('Enabled'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('copies the complete IP:port address', (tester) async {
    String? copied;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await pumpView(tester);
    await tester.tap(find.byTooltip('Copy'));
    await tester.pumpAndSettle();

    expect(copied, '192.168.1.23:7890');
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a network there is nothing to copy', (tester) async {
    container.read(localIpProvider.notifier).update((_) => '');
    await pumpView(tester);

    expect(find.text('192.168.1.23:7890'), findsNothing);
    expect(find.text('No network'), findsNWidgets(2));
    final copy = find.byTooltip('Copy');
    expect(copy, findsOneWidget);
    final button = tester.widget<IconButton>(
      find.ancestor(of: copy, matching: find.byType(IconButton)),
    );
    expect(button.onPressed, isNull);
    // The port is still a real detail even with no address to build.
    expect(find.text('7890'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
