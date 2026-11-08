import 'package:skyward/common/common.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/dashboard/widgets/intranet_ip.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The detail page behind the phone dashboard's "Allow LAN" status block.
///
/// The block itself is only a status line: tapping it used to flip the switch
/// straight away, which left no room to show what the switch actually serves.
/// This page keeps the switch and puts the connection details beside it, so
/// the address other devices have to configure is visible and copyable.
class LanAccessView extends ConsumerWidget {
  const LanAccessView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final allowLan = ref.watch(
      patchClashConfigProvider.select((state) => state.allowLan),
    );
    final port = ref.watch(
      patchClashConfigProvider.select((state) => state.mixedPort),
    );
    final localIp = ref.watch(localIpProvider);

    // The whole `IP:port` string is the point of this page: it is what another
    // device on the same network has to be told. Keep it complete even before
    // the switch is on, so the details are readable either way.
    final hasIp = localIp != null && localIp.isNotEmpty;
    final address = hasIp ? '$localIp:$port' : null;
    final status = allowLan
        ? appLocalizations.enabled
        : appLocalizations.disabled;

    return BaseScaffold(
      rowSeparators: false,
      title: appLocalizations.allowLan,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.sectionTopPadding,
          bottom: 16 + context.bottomInset,
        ),
        children: [
          generateSection(
            title: appLocalizations.address,
            items: [
              ListItem(
                title: Text(
                  address ?? appLocalizations.noNetwork,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.title3
                      .of(context, emphasized: true)
                      .copyWith(
                        color: hasIp
                            ? null
                            : context.colorScheme.onSurfaceVariant,
                      ),
                ),
                subtitle: Text(status, style: context.listSubtitleStyle),
                trailing: IconButton(
                  tooltip: appLocalizations.copy,
                  onPressed: address == null
                      ? null
                      : () => copyToClipboard(context, address),
                  icon: const GlyphIcon(AppGlyphs.copy, size: 20),
                ),
              ),
              ListItem(
                title: Text(appLocalizations.intranetIP),
                trailing: Text(
                  hasIp ? localIp : appLocalizations.noNetwork,
                  style: context.listSubtitleStyle,
                ),
              ),
              ListItem(
                title: Text(appLocalizations.port),
                trailing: Text('$port', style: context.listSubtitleStyle),
              ),
            ],
          ),
          generateSection(
            items: [
              ConfigToggleItem(
                title: (l) => l.allowLan,
                selector: patchClashConfigProvider.select(
                  (state) => state.allowLan,
                ),
                onChanged: (ref, value) => ref
                    .read(patchClashConfigProvider.notifier)
                    .update((state) => state.copyWith(allowLan: value)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
