import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';
import 'intranet_ip.dart';
import 'network_takeover.dart';
import 'outbound_mode.dart';

/// The mode switch and the controls that let traffic through, in one card:
/// all of them answer the same question, how traffic leaves this device and
/// who may come in, and each was a card of its own until the reference
/// layout put them together. On a phone the VPN and LAN controls are
/// switch-less status blocks, as in the reference layout: tapping a block
/// toggles it, and no switch widget is shown.
class NetworkControlCard extends ConsumerWidget {
  const NetworkControlCard({super.key, this.platform});

  /// The host's platform when null, so a test can pose as another one.
  final SupportPlatform? platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = this.platform ?? SupportPlatform.currentPlatform;
    final appLocalizations = context.appLocalizations;
    return DashboardCard(
      semanticLabel: appLocalizations.networkControl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.split,
            title: appLocalizations.networkControl,
          ),
          const SizedBox(height: 12),
          const OutboundModeSelector(),
          const SizedBox(height: 10),
          if (desktopPlatforms.contains(platform)) ...[
            const TakeoverSwitchRows(),
            const SizedBox(height: 8),
            const LanSwitchRow(showAddress: true),
          ] else if (platform == SupportPlatform.Android)
            // The two status blocks a phone has sit side by side: each is
            // a single value, and neither needs the card's full width.
            const Row(
              spacing: 8,
              children: [
                Expanded(child: _VpnStatusTile()),
                Expanded(child: _LanStatusTile()),
              ],
            )
          else
            const LanSwitchRow(showAddress: true),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = AppShape.all(DashboardCorner.block);
    return Container(
      decoration: ShapeDecoration(
        color: DashboardColors.of(context).tone,
        shape: shape,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: shape,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(title, maxLines: 1, style: DashboardText.rowTitle(context)),
                Text(
                  subtitle,
                  maxLines: 1,
                  style: DashboardText.label(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VpnStatusTile extends ConsumerWidget {
  const _VpnStatusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final enabled = ref.watch(vpnSettingProvider.select((state) => state.enable));
    return _StatusTile(
      title: 'VPN',
      subtitle: enabled ? appLocalizations.enabled : appLocalizations.disabled,
      onTap: () => ref
          .read(vpnSettingProvider.notifier)
          .update((state) => state.copyWith(enable: !enabled)),
    );
  }
}

class _LanStatusTile extends ConsumerWidget {
  const _LanStatusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final allowLan = ref.watch(
      patchClashConfigProvider.select((state) => state.allowLan),
    );
    return _StatusTile(
      title: appLocalizations.allowLan,
      subtitle: allowLan ? appLocalizations.enabled : appLocalizations.disabled,
      onTap: () => ref
          .read(patchClashConfigProvider.notifier)
          .update((state) => state.copyWith(allowLan: !allowLan)),
    );
  }
}
