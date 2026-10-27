import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:skyward/views/dashboard/widgets/card.dart';
import 'package:skyward/views/dashboard/widgets/network_control.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_profiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    globalState.container = container;
  });

  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester, SupportPlatform platform) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 360,
                child: DashboardDensityScope(
                  density: DashboardDensity.mobile,
                  scale: 1,
                  child: NetworkControlCard(platform: platform),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a phone gets the VPN and LAN status blocks under the modes', (
    tester,
  ) async {
    await pump(tester, SupportPlatform.Android);

    expect(find.text('Network control'), findsOneWidget);
    expect(find.text(Mode.rule.label), findsOneWidget);
    expect(find.text('VPN'), findsOneWidget);
    expect(find.text('System proxy'), findsNothing);
    expect(find.text('Allow LAN'), findsOneWidget);
    // Reference layout: switch-less status blocks, not switches.
    expect(find.byType(DashboardSwitch), findsNothing);
    expect(find.text('Disabled'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a desktop gets both traffic switches and the LAN one', (
    tester,
  ) async {
    await pump(tester, SupportPlatform.MacOS);

    expect(find.text(Mode.rule.label), findsOneWidget);
    expect(find.text('System proxy'), findsOneWidget);
    expect(find.text('TUN'), findsOneWidget);
    expect(find.text('VPN'), findsNothing);
    expect(find.text('Allow LAN'), findsOneWidget);
    expect(find.byType(DashboardSwitch), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the LAN block toggles it without an address', (
    tester,
  ) async {
    await pump(tester, SupportPlatform.Android);
    container.read(localIpProvider.notifier).update((_) => '192.168.1.23');
    await tester.pump();

    expect(find.text('Disabled'), findsNWidgets(2));

    await tester.tap(find.text('Allow LAN'));
    await tester.pump();

    expect(container.read(patchClashConfigProvider).allowLan, isTrue);
    expect(find.text('Enabled'), findsOneWidget);
    // Reference layout: the phone LAN block is a status block only, so
    // it shows no address and offers no copy button.
    expect(find.text('192.168.1.23:7890'), findsNothing);
    expect(find.byTooltip('Copy'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a mode tapped inside the card still changes the mode', (
    tester,
  ) async {
    await pump(tester, SupportPlatform.Android);

    await tester.tap(find.text(Mode.direct.label));
    await tester.pumpAndSettle();

    expect(container.read(patchClashConfigProvider).mode, Mode.direct);
  });
}
