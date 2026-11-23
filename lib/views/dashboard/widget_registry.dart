import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/dashboard/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

extension DashboardWidgetView on DashboardWidget {
  Widget get card => switch (this) {
    DashboardWidget.currentOutbound => const CurrentOutboundCard(),
    DashboardWidget.networkControl => const NetworkControlCard(),
    DashboardWidget.networkOverview => const NetworkOverviewCard(),
    DashboardWidget.routingBoard => const RoutingBoardCard(),
    DashboardWidget.profiles => const ProfilesCard(),
    DashboardWidget.proxyGroups => const ProxyGroupsCard(),
    DashboardWidget.memoryInfo => const MemoryInfo(),
    DashboardWidget.trafficStats => const TrafficUsageCard(),
    DashboardWidget.appUsage => const AppUsageCard(),
    DashboardWidget.speedTest => const SpeedTestCard(),
  };

  Glyph get glyph => switch (this) {
    DashboardWidget.currentOutbound => AppGlyphs.status,
    DashboardWidget.networkControl => AppGlyphs.split,
    DashboardWidget.networkOverview => AppGlyphs.verified,
    DashboardWidget.routingBoard => AppGlyphs.proxies,
    DashboardWidget.profiles => AppGlyphs.profiles,
    DashboardWidget.proxyGroups => AppGlyphs.layers,
    DashboardWidget.memoryInfo => AppGlyphs.memory,
    DashboardWidget.trafficStats => AppGlyphs.connections,
    DashboardWidget.appUsage => AppGlyphs.dataUsage,
    DashboardWidget.speedTest => AppGlyphs.speed,
  };

  String label(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return switch (this) {
      DashboardWidget.currentOutbound => appLocalizations.status,
      DashboardWidget.networkControl => appLocalizations.networkControl,
      DashboardWidget.networkOverview => appLocalizations.networkOverview,
      DashboardWidget.routingBoard => appLocalizations.routeBoard,
      DashboardWidget.profiles => appLocalizations.profile,
      DashboardWidget.proxyGroups => appLocalizations.proxyGroup,
      DashboardWidget.memoryInfo => appLocalizations.memoryInfo,
      DashboardWidget.trafficStats => appLocalizations.trafficUsage,
      DashboardWidget.appUsage => appLocalizations.usageStats,
      DashboardWidget.speedTest => appLocalizations.speedTest,
    };
  }

  String? description(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return switch (this) {
      DashboardWidget.currentOutbound => appLocalizations.currentOutboundDesc,
      DashboardWidget.routingBoard => appLocalizations.routeBoardDesc,
      DashboardWidget.memoryInfo => appLocalizations.memoryInfoDesc,
      _ => null,
    };
  }

  /// It holds the start button, which has nowhere else to go.
  bool get removable => this != DashboardWidget.currentOutbound;
}
