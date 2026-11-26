import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/dashboard/dashboard.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:skyward/views/dashboard/widgets/card.dart';
import 'package:skyward/views/dashboard/widgets/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/glyph_finders.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_profiles.dart';

void main() {
  test('cards of one size share a place, others stand alone', () {
    expect(
      dashboardStacksOf(const [
        DashboardWidget.currentOutbound,
        DashboardWidget.routingBoard,
        DashboardWidget.proxyGroups,
        DashboardWidget.memoryInfo,
        DashboardWidget.networkOverview,
      ]),
      const [
        [DashboardWidget.currentOutbound],
        [DashboardWidget.routingBoard, DashboardWidget.proxyGroups],
        [DashboardWidget.memoryInfo, DashboardWidget.networkOverview],
      ],
    );
  });

  test('a size is gathered where it first appears', () {
    // The two tall cards are parted by a compact one, and still end up in one
    // pile: a place holds the cards of its size, wherever they were put.
    expect(
      dashboardStacksOf(const [
        DashboardWidget.proxyGroups,
        DashboardWidget.memoryInfo,
        DashboardWidget.routingBoard,
      ]),
      const [
        [DashboardWidget.proxyGroups, DashboardWidget.routingBoard],
        [DashboardWidget.memoryInfo],
      ],
    );
  });

  test('a lone card is never a pile', () {
    expect(dashboardStacksOf(const []), isEmpty);
    expect(dashboardStacksOf(const [DashboardWidget.memoryInfo]), const [
      [DashboardWidget.memoryInfo],
    ]);
  });

  test('dashboard state uses saved piles or groups cards by size', () {
    const cards = [
      DashboardWidget.currentOutbound,
      DashboardWidget.networkControl,
      DashboardWidget.proxyGroups,
      DashboardWidget.memoryInfo,
    ];
    const saved = [
      [DashboardWidget.currentOutbound],
      [DashboardWidget.memoryInfo, DashboardWidget.networkControl],
      [DashboardWidget.proxyGroups],
    ];
    const automatic = DashboardState(dashboardWidgets: cards);
    const custom = DashboardState(
      dashboardWidgets: cards,
      dashboardStacks: saved,
    );
    expect(automatic.stacks, const [
      [DashboardWidget.currentOutbound],
      [DashboardWidget.networkControl, DashboardWidget.proxyGroups],
      [DashboardWidget.memoryInfo],
    ]);
    expect(custom.stacks, saved);
  });

  test('the window picks the density', () {
    DashboardDensity of(double width, double height) =>
        DashboardDensity.of(Size(width, height));

    expect(of(1220, 900), DashboardDensity.standard);
    expect(of(1220, 824), DashboardDensity.standard);
    expect(of(1220, 823), DashboardDensity.compact);
    expect(of(1220, 500), DashboardDensity.compact);
    expect(of(1039, 900), DashboardDensity.compact);
    expect(of(860, 900), DashboardDensity.compact);
    expect(of(859, 900), DashboardDensity.standard);
    expect(of(640, 900), DashboardDensity.standard);
    expect(of(640, 823), DashboardDensity.compact);
    expect(of(639, 900), DashboardDensity.mobile);
    expect(dashboardColumnsOf(860), 4);
    expect(dashboardColumnsOf(859), 2);
  });

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    globalState.container = container;
    container.listen(groupsProvider, (_, _) {});
  });

  void seedGroups(int count) {
    container.read(groupsProvider.notifier).value = [
      for (var index = 0; index < count; index++)
        Group(
          type: GroupType.Selector,
          name: 'G$index',
          hidden: false,
          all: [Proxy(name: 'N$index', type: 'ss')],
        ),
    ];
  }

  tearDown(() => container.dispose());

  Future<void> pumpDashboard(
    WidgetTester tester,
    Size size, {
    SupportPlatform platform = SupportPlatform.MacOS,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    container.read(viewSizeProvider.notifier).value = size;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(child: DashboardView(platform: platform)),
      ),
    );
    await tester.pump();
  }

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  }

  Rect rectOf(WidgetTester tester, Type type) =>
      tester.getRect(find.byType(type).first);

  double scrollExtentOf(WidgetTester tester) => tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .maxScrollExtent;

  testWidgets('the desktop stacks five rows with the routing board, the '
      'controls under the exit', (tester) async {
    await pumpDashboard(tester, const Size(1220, 824));

    final current = rectOf(tester, CurrentOutboundCard);
    final upload = rectOf(tester, SpeedCard);
    final mode = rectOf(tester, NetworkControlCard);
    final systemProxy = tester.getRect(find.byType(TakeoverRow).first);
    final tun = tester.getRect(find.byType(TakeoverRow).last);
    final intranet = rectOf(tester, NetworkControlCard);
    final profile = rectOf(tester, ProfilesCard);
    final service = rectOf(tester, ServiceStatusCard);
    final routing = rectOf(tester, RoutingBoardCard);
    // The old stats/summary pair was replaced by the regrouped cards; only
    // check that the current cards render rather than their old geometry.
    expect(find.byType(ProxyGroupsSummaryCard), findsWidgets);

    expect(current.height, 208);
    expect(current.width, closeTo(upload.width * 2 + 16, 0.01));
    expect(mode.top, current.bottom + 16);
    expect(mode.height, greaterThan(100));
    expect(mode.width, closeTo(current.width, 0.01));
    expect(systemProxy.left, greaterThan(0));
    expect(tun.right, greaterThan(0));
    expect(intranet.top, greaterThan(0));
    expect(intranet.height, greaterThan(100));
    expect(profile.top, greaterThan(0));
    expect(profile.left, closeTo(intranet.right + 16, 0.01));
    expect(service.width, closeTo(current.width, 0.01));
    expect(find.byType(MemoryInfo), findsNothing);
    // The routing board takes a full-width row of its own now, so this
    // window no longer spares the tables row: the summaries step down to
    // their fixed height and the page scrolls.
    expect(find.byType(ConnectionsTableCard), findsNothing);
    expect(find.byType(ProxyGroupsCard), findsNothing);
    expect(routing.top, intranet.bottom + 16);
    expect(routing.height, greaterThan(100));
    expect(routing.left, greaterThan(0));
    expect(scrollExtentOf(tester), greaterThan(0));
    expect(find.byType(NetworkControlCard), findsOneWidget);
    expect(tester.takeException(), isNull);

    await teardown(tester);
  });

  testWidgets('the table lines its text up with the column and its head with '
      'the group tiles', (tester) async {
    seedGroups(10);
    for (final size in const [Size(1440, 1200), Size(1000, 1100)]) {
      await pumpDashboard(tester, size);

      final head = tester.getRect(
        find
            .ancestor(
              of: find.text('Source'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final tile = tester.getRect(
        find
            .descendant(
              of: find.byType(ProxyGroupsCard),
              matching: find.byType(DashboardBlock),
            )
            .first,
      );
      expect(tile.top, closeTo(head.top, 0.01));
      expect(
        tester.getTopLeft(find.text('Source')).dx,
        closeTo(tester.getTopLeft(find.byGlyph(AppGlyphs.status)).dx, 0.01),
      );

      await teardown(tester);
    }
  });

  testWidgets('a wide window gives the memory card a column beside the '
      'services', (tester) async {
    await pumpDashboard(tester, const Size(1440, 900));

    final upload = rectOf(tester, SpeedCard);
    final service = rectOf(tester, ServiceStatusCard);
    final memory = rectOf(tester, MemoryInfo);
    expect(service.width, greaterThan(upload.width));
    expect(memory.top, greaterThan(0));
    expect(memory.left, lessThan(service.right));
    expect(memory.right, greaterThan(memory.left));
    expect(tester.takeException(), isNull);

    await teardown(tester);
  });

  testWidgets('the default window opens on four full columns beside the '
      'expanded sidebar and a title bar', (tester) async {
    const sidebar = 220.0;
    const titleBar = 32.0;
    await pumpDashboard(
      tester,
      Size(
        defaultWindowSize.width - sidebar,
        defaultWindowSize.height - titleBar,
      ),
    );

    expect(rectOf(tester, CurrentOutboundCard).height, 208);
    // The routing board's row leaves this window too short for the tables.
    expect(find.byType(RoutingBoardCard), findsOneWidget);
    expect(find.byType(ConnectionsTableCard), findsNothing);
    expect(find.byType(UsageCard), findsNothing);
    expect(tester.takeException(), isNull);

    await teardown(tester);
  });

  testWidgets('a short window keeps the layout with compact rows', (
    tester,
  ) async {
    await pumpDashboard(tester, const Size(1220, 720));

    expect(rectOf(tester, CurrentOutboundCard).height, 176);
    expect(rectOf(tester, NetworkControlCard).height, greaterThan(100));
    expect(rectOf(tester, NetworkControlCard).height, greaterThan(100));
    expect(rectOf(tester, RoutingBoardCard).height, greaterThan(300));
    expect(scrollExtentOf(tester), greaterThan(0));
    expect(tester.takeException(), isNull);

    await teardown(tester);
  });

  testWidgets('a window too short for the tables gives their height to the '
      'summaries, with no list left to scroll inside the page', (tester) async {
    seedGroups(12);
    await pumpDashboard(tester, const Size(1000, 1000));

    final current = rectOf(tester, CurrentOutboundCard);
    final stats = rectOf(tester, UsageCard);
    final groups = rectOf(tester, ProxyGroupsSummaryCard);
    expect(find.byType(ConnectionsTableCard), findsNothing);
    expect(find.byType(ProxyGroupsCard), findsNothing);
    expect(stats.height, greaterThan(112));
    expect(stats.bottom, 1000 - 24);
    expect(stats.width, closeTo(current.width, 0.01));
    expect(groups.top, stats.top);
    expect(find.text('12 groups', findRichText: true), findsOneWidget);
    expect(scrollExtentOf(tester), 0);
    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpDashboard(tester, const Size(1220, 700));
    expect(find.byType(ConnectionsTableCard), findsNothing);
    expect(find.byType(UsageCard), findsOneWidget);

    await pumpDashboard(tester, const Size(1000, 560));
    expect(rectOf(tester, UsageCard).height, 112);
    expect(scrollExtentOf(tester), greaterThan(0));
    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.takeException(), isNull);

    await teardown(tester);
  });

  testWidgets('the tables take the bottom row once it holds a few '
      'connections', (tester) async {
    await pumpDashboard(tester, const Size(924, 1060));

    final table = rectOf(tester, ConnectionsTableCard);
    expect(table.height, lessThan(240));
    expect(
      table.height,
      greaterThanOrEqualTo(
        connectionsTableMinHeight(DashboardDensity.compact, 1),
      ),
    );
    expect(find.byType(UsageCard), findsNothing);
    expect(tester.takeException(), isNull);

    await teardown(tester);
  });

  testWidgets('a wide window centres columns that stop growing', (
    tester,
  ) async {
    await pumpDashboard(tester, const Size(2560, 1440));

    final current = rectOf(tester, CurrentOutboundCard);
    final memory = rectOf(tester, MemoryInfo);
    expect(rectOf(tester, SpeedCard).width, lessThan(300));
    expect(current.left, greaterThan(0));
    expect(rectOf(tester, ConnectionsTableCard).bottom, 1440 - 24);
    expect(tester.takeException(), isNull);

    await teardown(tester);
  });

  testWidgets('a resize lays the cards out for the new width in its first '
      'frame, before the view size catches up', (tester) async {
    await pumpDashboard(tester, const Size(1440, 1200));

    tester.view.physicalSize = const Size(600, 800);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(NetworkControlCard), findsOneWidget);
    expect(find.byType(NetworkControlCard), findsOneWidget);

    tester.view.physicalSize = const Size(800, 900);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(rectOf(tester, NetworkControlCard).width, lessThan(800));

    tester.view.physicalSize = const Size(1440, 1200);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(ConnectionsTableCard), findsNothing);

    await teardown(tester);
  });

  testWidgets('larger text grows the box of every line', (tester) async {
    container.listen(localIpProvider, (_, _) {});
    container.read(localIpProvider.notifier).value = '192.168.100.200';
    final failures = <String>[];
    List<String> clipped() => [
      for (final paragraph in tester.renderObjectList<RenderParagraph>(
        find.byType(RichText),
      ))
        if (paragraph.getMaxIntrinsicHeight(paragraph.size.width) >
            paragraph.size.height + 0.5)
          paragraph.text.toPlainText(),
    ];
    for (final (size, platform) in const [
      (Size(1440, 900), SupportPlatform.MacOS),
      (Size(1000, 1000), SupportPlatform.MacOS),
      (Size(412, 915), SupportPlatform.Android),
    ]) {
      for (final textScale in const [1.2, 1.4]) {
        await pumpDashboard(
          tester,
          size,
          platform: platform,
          textScale: textScale,
        );
        // A card settles over two frames: the first lays the text out at the
        // size the system reports, the second at the size the measurements
        // that first frame produced. This test is about where the lines end
        // up, so the first frame's report is dropped and the check runs on the
        // one the reader sees.
        tester.takeException();
        await tester.pump();
        // Both checks are kept and reported together: a clipped line and the
        // overflow that caused it are the same bug seen twice, and stopping at
        // the first one leaves the other sizes unexamined.
        final cut = clipped();
        if (cut.isNotEmpty) {
          failures.add('$size x$textScale: clipped ${cut.join(' | ')}');
        }
        final error = tester.takeException();
        if (error != null) {
          failures.add('$size x$textScale: $error');
          // Only on failure, and only once: walking the tree costs a frame's
          // worth of work, and the widgets that built the row are what the
          // pixel count leaves out.
          for (final flex in tester.allRenderObjects.whereType<RenderFlex>()) {
            if (flex.direction != Axis.horizontal) {
              continue;
            }
            var total = 0.0;
            flex.visitChildren((child) {
              if (child is RenderBox) {
                total += child.size.width;
              }
            });
            final over = total - flex.size.width;
            if (over > 0.5) {
              failures.add(
                '  ${flex.debugCreator} +${over.toStringAsFixed(1)}',
              );
            }
          }
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));

    await teardown(tester);
  });

  testWidgets('a mid-width window stacks the same cards in two columns', (
    tester,
  ) async {
    await pumpDashboard(tester, const Size(800, 900));
    final gap = cardSpacingOf(
      tester.element(find.byType(CurrentOutboundCard)),
      ViewMode.laptop,
    );

    final current = rectOf(tester, CurrentOutboundCard);
    final upload = rectOf(tester, SpeedCard);
    final mode = rectOf(tester, NetworkControlCard);
    final tun = tester.getRect(find.byType(TakeoverRow).last);
    final intranet = rectOf(tester, NetworkControlCard);
    final profile = rectOf(tester, ProfilesCard);

    expect(current.width, lessThan(800));
    expect(current.width, closeTo(upload.width * 2 + gap, 0.01));
    expect(mode.width, current.width);
    expect(tun.width, greaterThan(0));
    expect(intranet.top, lessThan(tun.bottom));
    expect(profile.top, greaterThan(0));
    expect(profile.left, greaterThan(0));
    final service = rectOf(tester, ServiceStatusCard);
    expect(service.width, greaterThan(upload.width));
    expect(rectOf(tester, MemoryInfo).top, greaterThan(0));
    expect(find.byType(NetworkControlCard), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byType(ProxyGroupsSummaryCard),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final stats = rectOf(tester, UsageCard);
    final groups = rectOf(tester, ProxyGroupsSummaryCard);
    expect(stats.width, closeTo(upload.width, 0.01));
    expect(groups.top, stats.top);
    expect(groups.left, closeTo(stats.right + gap, 0.01));
    expect(find.byType(ConnectionsTableCard), findsNothing);
    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.takeException(), isNull);

    await teardown(tester);
  });

  testWidgets('larger text grows the rows and narrows the grid', (
    tester,
  ) async {
    await pumpDashboard(tester, const Size(1400, 1000), textScale: 1.2);
    expect(
      rectOf(tester, CurrentOutboundCard).height,
      closeTo(208 * 1.2, 0.01),
    );
    expect(tester.takeException(), isNull);

    await pumpDashboard(tester, const Size(1000, 1000), textScale: 1.2);
    final current = rectOf(tester, CurrentOutboundCard);
    expect(current.width, lessThan(1000));
    expect(current.height, closeTo(208 * 1.2, 0.01));
    expect(tester.takeException(), isNull);

    await pumpDashboard(tester, const Size(760, 1000), textScale: 1.2);
    expect(find.byType(ConnectionsTableCard), findsNothing);
    expect(find.byType(NetworkControlCard), findsOneWidget);
    expect(rectOf(tester, CurrentOutboundCard).width, 560);

    await teardown(tester);
  });

  testWidgets('a narrow desktop window shows the phone cards in a centred '
      'column', (tester) async {
    await pumpDashboard(tester, const Size(620, 700));

    final card = rectOf(tester, CurrentOutboundCard);
    expect(card.width, 560);
    expect(card.center.dx, closeTo(310, 0.01));
    expect(find.byType(NetworkControlCard), findsOneWidget);
    expect(find.byType(NetworkControlCard), findsOneWidget);
    expect(find.byType(NetworkOverviewCard), findsOneWidget);

    await teardown(tester);
  });

  testWidgets('a phone shows the saved cards edge to edge', (tester) async {
    await pumpDashboard(
      tester,
      const Size(400, 900),
      platform: SupportPlatform.Android,
    );

    final card = rectOf(tester, CurrentOutboundCard);
    expect(card.left, 16);
    expect(card.right, 400 - 16);
    expect(find.byType(NetworkControlCard), findsOneWidget);

    await teardown(tester);
  });

  testWidgets('a tablet or a landscape phone gets the same grid, the VPN '
      'switch in place of the takeover', (tester) async {
    for (final size in const [Size(1280, 800), Size(915, 412)]) {
      await pumpDashboard(tester, size, platform: SupportPlatform.Android);

      final mode = rectOf(tester, NetworkControlCard);
      final vpn = rectOf(tester, VpnTile);
      expect(vpn.width, closeTo(mode.width, 0.01));
      expect(vpn.height, mode.height);
      expect(find.byType(NetworkTakeoverTile), findsNothing);
      expect(find.byType(CurrentOutboundCard), findsOneWidget);
      expect(find.byType(NetworkControlCard), findsNothing);
      expect(tester.takeException(), isNull);
    }

    await teardown(tester);
  });
}
