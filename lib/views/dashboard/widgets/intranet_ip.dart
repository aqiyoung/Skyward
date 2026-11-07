import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';
import 'network_takeover.dart';

Future<void> copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    context.showNotifier(
      context.appLocalizations.copySuccess,
      level: MessageLevel.success,
    );
  }
}

/// The address other devices on the network dial, empty when the device has
/// none yet, and null while that is still being read.
String? lanAddress(WidgetRef ref, {required bool allowLan}) {
  final localIp = ref.watch(localIpProvider);
  if (localIp == null || localIp.isEmpty) {
    return null;
  }
  return allowLan
      ? '$localIp:${ref.watch(patchClashConfigProvider.select((state) => state.mixedPort))}'
      : localIp;
}

/// The LAN proxy switch: the address it serves, and a copy of that address.
class LanSwitchRow extends ConsumerWidget {
  const LanSwitchRow({
    super.key,
    this.metrics = cardRowMetrics,
    this.showAddress = false,
    this.compact = false,
  });

  final DashboardRowMetrics metrics;

  /// The row is the only place the address appears, as it is in the card that
  /// holds the switches, so it prints the whole address and offers to copy it.
  final bool showAddress;

  /// Shares a row with the VPN switch on a phone, where half the card is too
  /// narrow for an icon beside the title.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final allowLan = ref.watch(
      patchClashConfigProvider.select((state) => state.allowLan),
    );
    final port = ref.watch(
      patchClashConfigProvider.select((state) => state.mixedPort),
    );
    final address = showAddress ? lanAddress(ref, allowLan: allowLan) : null;
    final copyable = showAddress && allowLan && address != null;
    final title = appLocalizations.allowLan;
    final subtitle = allowLan
        ? (copyable ? address : appLocalizations.portValue(port))
        : appLocalizations.disabled;
    void change(bool value) => ref
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith(allowLan: value));
    if (compact) {
      return DashboardSwitchTile(
        title: title,
        subtitle: subtitle,
        value: allowLan,
        trailing: copyable ? CopyAddressButton(address) : null,
        onTap: () => change(!allowLan),
        onChanged: change,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final showIcon = DashboardSwitchRow.iconFits(
          context,
          width: constraints.maxWidth,
          iconSize: metrics.icon,
          padding: metrics.padding,
          titles: [title],
        );
        return DashboardSwitchRow(
          glyph: AppGlyphs.wifi,
          title: title,
          subtitle: subtitle,
          value: allowLan,
          iconSize: metrics.icon,
          padding: showIcon
              ? metrics.padding
              : metrics.padding.copyWith(left: metrics.titleStart),
          radius: metrics.radius,
          showIcon: showIcon,
          trailing: copyable
              ? DashboardIconButton(
                  glyph: AppGlyphs.copy,
                  tooltip: appLocalizations.copy,
                  onPressed: () => copyToClipboard(context, address),
                )
              : null,
          onTap: () => change(!allowLan),
          onChanged: change,
        );
      },
    );
  }
}

/// The copy button a narrow tile can afford: a glyph on the address's line,
/// where the full-size icon button would set the tile's height.
class CopyAddressButton extends StatelessWidget {
  const CopyAddressButton(this.address, {super.key});

  final String address;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 22, height: 22),
      tooltip: context.appLocalizations.copy,
      onPressed: () => copyToClipboard(context, address),
      icon: GlyphIcon(
        AppGlyphs.copy,
        size: 14,
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// The local address in a card of its own, in the desktop grid.
class IntranetIpCard extends ConsumerWidget {
  const IntranetIpCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = DashboardDensityScope.of(context);
    final scale = DashboardDensityScope.scaleOf(context);
    final mobile = !density.isDesktop;
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final localIp = ref.watch(localIpProvider);
    final allowLan = ref.watch(
      patchClashConfigProvider.select((state) => state.allowLan),
    );
    final address = lanAddress(ref, allowLan: allowLan);
    final figure = mobile
        ? (style: AppTextStyle.title1, top: 12.0)
        : density.isCompact
        ? (style: AppTextStyle.title2, top: 8.0)
        : (style: AppTextStyle.title2, top: 10.0);
    final DashboardRowMetrics row = density.isCompact
        ? (
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            titleStart: 12,
            radius: 16,
            icon: 32,
            subtitle: true,
          )
        : (
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            titleStart: 14,
            radius: 20,
            icon: 38,
            subtitle: true,
          );
    final style = DashboardText.figure(
      context,
      figure.style,
    ).copyWith(letterSpacing: 0);
    return DashboardCard(
      semanticLabel: appLocalizations.intranetIP,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: mobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.devices,
            title: appLocalizations.intranetIP,
            trailing: [
              Transform.translate(
                offset: const Offset(8, 0),
                child: DashboardIconButton(
                  glyph: AppGlyphs.copy,
                  tooltip: appLocalizations.copy,
                  onPressed: address == null
                      ? null
                      : () => copyToClipboard(context, address),
                ),
              ),
            ],
          ),
          SizedBox(height: figure.top),
          SizedBox(
            height: figure.style.leading * scale,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: switch (localIp) {
                null => SkeletonText(width: 120, style: style),
                '' => Text(
                  appLocalizations.noNetwork,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                final ip => DashboardFitText(ip, style: style),
              },
            ),
          ),
          if (mobile) const SizedBox(height: 14) else const Spacer(),
          LanSwitchRow(metrics: row),
        ],
      ),
    );
  }
}
