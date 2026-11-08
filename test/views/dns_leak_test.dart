import 'package:skyward/common/leak_probe.dart';
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
    container.listen(appSettingProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  Future<void> pump(
    WidgetTester tester,
    DnsProbe probe, {
    StunProbe? stunProbe,
  }) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          locale: const Locale('en'),
          child: DnsLeakView(
            probe: probe,
            stunProbe:
                stunProbe ??
                () async =>
                    const StunProbeResult(resolved: true, answered: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  DnsProbe captured() =>
      () async =>
          const DnsProbeResult(lookup: '198.18.0.12', direct: '198.18.0.12');

  StunProbe answered() =>
      () async => const StunProbeResult(
        resolved: true,
        answered: true,
        reflected: '203.0.113.7',
        server: 'stun.l.google.com',
      );

  void setGuard(WebrtcGuard guard) {
    container
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(webrtcGuard: guard));
  }

  testWidgets('a captured device that answers with a fake address passes', (
    tester,
  ) async {
    container
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith.tun(enable: true));
    await pump(tester, captured());

    expect(find.byType(ListItem), findsNWidgets(9));
    // Both probes came back with the fake block, and the tunnel and hijack
    // rows read the same config the page does.
    expect(find.text('198.18.0.12'), findsNWidgets(2));
    expect(find.text('Fail'), findsNothing);
    expect(find.text('WebRTC'), findsOneWidget);
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

  testWidgets('a silent STUN probe confirms the block instead of a leak', (
    tester,
  ) async {
    container
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith.tun(enable: true));
    await pump(tester, captured());

    expect(
      find.text('No STUN answer came back, so the block is in force'),
      findsOneWidget,
    );
    expect(find.text('Pass'), findsWidgets);
    expect(find.text('Fail'), findsNothing);
  });

  testWidgets('a STUN answer under the block guard fails the WebRTC rows', (
    tester,
  ) async {
    container
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith.tun(enable: true));
    await pump(tester, captured(), stunProbe: answered());

    expect(find.text('A STUN server answered'), findsOneWidget);
    expect(find.text('203.0.113.7'), findsOneWidget);
    expect(find.text('Fail'), findsWidgets);
  });

  testWidgets('leaving WebRTC alone warns and shows the reflected address', (
    tester,
  ) async {
    setGuard(WebrtcGuard.off);
    container
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith.tun(enable: true));
    await pump(tester, captured(), stunProbe: answered());

    expect(
      find.text(
        "Guard is off, so a page can read this device's public address",
      ),
      findsOneWidget,
    );
    expect(find.text('203.0.113.7'), findsOneWidget);
    expect(find.text('Warn'), findsWidgets);
  });

  testWidgets('an unresolvable STUN host stays unknown, never a pass', (
    tester,
  ) async {
    container
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith.tun(enable: true));
    await pump(
      tester,
      captured(),
      stunProbe: () async =>
          const StunProbeResult(resolved: false, answered: false),
    );

    expect(
      find.text('No STUN host could be resolved; the network is unavailable'),
      findsOneWidget,
    );
    expect(find.text('Unknown'), findsWidgets);
  });
}
