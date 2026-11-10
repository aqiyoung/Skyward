import 'package:skyward/common/common.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';

typedef DashboardRowMetrics = ({
  EdgeInsets padding,
  double titleStart,
  double radius,
  double icon,
  bool subtitle,
});

/// The rows of a card that holds switches, as opposed to a whole switch filling
/// a card of its own.
const DashboardRowMetrics cardRowMetrics = (
  padding: EdgeInsets.fromLTRB(10, 10, 12, 10),
  titleStart: 14,
  radius: 20,
  icon: 38,
  subtitle: true,
);

/// A tile's icon and switch sit as far in from its ends as from its edges, so
/// a full pill keeps both concentric with its corners. Without the icon, the
/// title lines up with the content of the cards above and below.
DashboardRowMetrics _tileMetricsOf(DashboardDensity density) =>
    density.isCompact
    ? (
        padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
        titleStart: dashboardCardPadding(density).left,
        radius: dashboardCardRadius(density),
        icon: 36,
        subtitle: false,
      )
    : (
        padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
        titleStart: dashboardCardPadding(density).left,
        radius: dashboardCardRadius(density),
        icon: 40,
        subtitle: true,
      );

enum TakeoverSwitch { systemProxy, tun }

class TakeoverRow extends ConsumerWidget {
  const TakeoverRow({
    super.key,
    required this.kind,
    required this.metrics,
    required this.showIcon,
    this.color,
  });

  final TakeoverSwitch kind;
  final DashboardRowMetrics metrics;
  final bool showIcon;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final systemProxy = kind == TakeoverSwitch.systemProxy;
    final title = _titleOf(context, kind);
    final value = systemProxy
        ? ref.watch(networkSettingProvider.select((state) => state.systemProxy))
        : ref.watch(
            patchClashConfigProvider.select((state) => state.tun.enable),
          );
    final on = systemProxy
        ? appLocalizations.portValue(
            ref.watch(
              patchClashConfigProvider.select((state) => state.mixedPort),
            ),
          )
        : appLocalizations.enabled;
    void change(bool value) => systemProxy
        ? ref
              .read(networkSettingProvider.notifier)
              .update((state) => state.copyWith(systemProxy: value))
        : ref
              .read(patchClashConfigProvider.notifier)
              .update((state) => state.copyWith.tun(enable: value));
    return DashboardSwitchRow(
      glyph: systemProxy ? AppGlyphs.shuffle : AppGlyphs.vpn,
      title: title,
      subtitle: metrics.subtitle
          ? value
                ? on
                : appLocalizations.disabled
          : null,
      value: value,
      iconSize: metrics.icon,
      padding: showIcon
          ? metrics.padding
          : metrics.padding.copyWith(left: metrics.titleStart),
      radius: metrics.radius,
      color: color,
      showIcon: showIcon,
      onTap: () => change(!value),
      onChanged: change,
    );
  }
}

String _titleOf(BuildContext context, TakeoverSwitch kind) => switch (kind) {
  TakeoverSwitch.systemProxy => context.appLocalizations.systemProxy,
  TakeoverSwitch.tun => context.appLocalizations.tun,
};

/// Both switches as rows, for the card that holds them.
class TakeoverSwitchRows extends StatelessWidget {
  const TakeoverSwitchRows({super.key});

  @override
  Widget build(BuildContext context) {
    const metrics = cardRowMetrics;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showIcon = DashboardSwitchRow.iconFits(
          context,
          width: constraints.maxWidth,
          iconSize: metrics.icon,
          padding: metrics.padding,
          titles: [
            for (final kind in TakeoverSwitch.values) _titleOf(context, kind),
          ],
        );
        return Column(
          spacing: 8,
          children: [
            for (final kind in TakeoverSwitch.values)
              TakeoverRow(kind: kind, metrics: metrics, showIcon: showIcon),
          ],
        );
      },
    );
  }
}

/// One switch as a card of its own, in the desktop's control row.
class NetworkTakeoverTile extends StatelessWidget {
  const NetworkTakeoverTile(this.kind, {super.key});

  final TakeoverSwitch kind;

  @override
  Widget build(BuildContext context) {
    final metrics = _tileMetricsOf(DashboardDensityScope.of(context));
    return DashboardCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) => TakeoverRow(
          kind: kind,
          metrics: metrics,
          color: Colors.transparent,
          showIcon: DashboardSwitchRow.iconFits(
            context,
            width: constraints.maxWidth,
            iconSize: metrics.icon,
            padding: metrics.padding,
            titles: [
              for (final kind in TakeoverSwitch.values) _titleOf(context, kind),
            ],
          ),
        ),
      ),
    );
  }
}

void _setVpn(WidgetRef ref, bool value) => ref
    .read(vpnSettingProvider.notifier)
    .update((state) => state.copyWith(enable: value));

/// The VPN switch in the grid's control row, in place of the takeover tiles.
class VpnTile extends ConsumerWidget {
  const VpnTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final metrics = _tileMetricsOf(DashboardDensityScope.of(context));
    final enabled = ref.watch(
      vpnSettingProvider.select((state) => state.enable),
    );
    return DashboardCard(
      padding: EdgeInsets.zero,
      child: DashboardSwitchRow(
        glyph: AppGlyphs.vpn,
        title: 'VPN',
        subtitle: metrics.subtitle
            ? enabled
                  ? appLocalizations.enabled
                  : appLocalizations.disabled
            : null,
        value: enabled,
        iconSize: metrics.icon,
        padding: metrics.padding,
        radius: metrics.radius,
        color: Colors.transparent,
        onTap: () => _setVpn(ref, !enabled),
        onChanged: (value) => _setVpn(ref, value),
      ),
    );
  }
}

/// The VPN switch as a row, for the card that holds it.
class VpnSwitchRow extends ConsumerWidget {
  const VpnSwitchRow({super.key, this.compact = false});

  /// Shares a row with the LAN switch on a phone, where half the card is too
  /// narrow for an icon beside the title.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const metrics = cardRowMetrics;
    final appLocalizations = context.appLocalizations;
    final enabled = ref.watch(
      vpnSettingProvider.select((state) => state.enable),
    );
    final subtitle = enabled
        ? appLocalizations.enabled
        : appLocalizations.disabled;
    if (compact) {
      return DashboardSwitchTile(
        title: 'VPN',
        subtitle: subtitle,
        value: enabled,
        onTap: () => _setVpn(ref, !enabled),
        onChanged: (value) => _setVpn(ref, value),
      );
    }
    return DashboardSwitchRow(
      glyph: AppGlyphs.vpn,
      title: 'VPN',
      subtitle: subtitle,
      value: enabled,
      iconSize: metrics.icon,
      padding: metrics.padding,
      radius: metrics.radius,
      onTap: () => _setVpn(ref, !enabled),
      onChanged: (value) => _setVpn(ref, value),
    );
  }
}
