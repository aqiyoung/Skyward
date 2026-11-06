import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/providers/config.dart';
import 'package:skyward/providers/database.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/config/dns_leak.dart';
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
      overrides: [
        profilesProvider.overrideWith(TestProfiles.new),
        coreStatusProvider.overrideWithValue(CoreStatus.connected),
      ],
    );
    globalState.container = container;
    container.read(viewSizeProvider.notifier).value = const Size(1200, 1400);
  });

  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester, DnsProbe probe) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          locale: const Locale('en'),
          child: DnsLeakView(probe: probe),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a captured device that answers with a fake address passes', (
    tester,
  ) async {
    container
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith.tun(enable: true));
    await pump(
      tester,
      () async => const DnsProbeResult(
        lookup: '198.18.0.12',
        direct: '198.18.0.12',
      ),
    );

    expect(find.byType(ListItem), findsNWidgets(6));
    // Both probes came back with the fake block, and the tunnel and hijack
    // rows read the same config the page does.
    expect(find.text('198.18.0.12'), findsNWidgets(2));
    expect(find.text('Fail'), findsNothing);
  });

  testWidgets('an uncaptured tunnel fails the first row', (tester) async {
    container
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith.tun(enable: false));
    await pump(tester, () async => const DnsProbeResult());

    expect(find.byType(ListItem), findsWidgets);
    expect(find.text('Fail'), findsWidgets);
  });

  testWidgets('a real address on port 53 is reported as a leak', (
    tester,
  ) async {
    container
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith.tun(enable: true));
    await pump(
      tester,
      () async => const DnsProbeResult(
        lookup: '93.184.216.34',
        direct: '93.184.216.34',
      ),
    );

    expect(find.text('Fail'), findsWidgets);
    expect(find.text('93.184.216.34'), findsNWidgets(2));
  });
}
