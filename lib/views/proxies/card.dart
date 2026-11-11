import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void selectGroupProxy(
  WidgetRef ref, {
  required String groupName,
  required GroupType groupType,
  required String proxyName,
}) {
  final isComputedSelected = groupType.isComputedSelected;
  if (isComputedSelected || groupType == GroupType.Selector) {
    final currentProxyName = ref.read(proxyNameProvider(groupName));
    final nextProxyName = switch (isComputedSelected) {
      true => currentProxyName == proxyName ? '' : proxyName,
      false => proxyName,
    };
    ref
        .read(proxiesActionProvider.notifier)
        .changeProxyDebounce(groupName, nextProxyName);
    return;
  }
  dialogs.showNotifier(
    currentAppLocalizations.notSelectedTip,
    level: MessageLevel.warning,
  );
}

/// Built-ins and groups have no definition, and a custom profile's own proxies
/// are the local proxies already.
bool _isAddableToLocal(Proxy proxy, {required bool isCustomProfile}) {
  return (proxy.providerName != null || !isCustomProfile) &&
      !reservedCustomProxyNames.contains(proxy.name) &&
      GroupTypeExtension.getGroupType(proxy.type) == null;
}

class ProxyCard extends ConsumerWidget {
  final String groupName;
  final Proxy proxy;
  final GroupType groupType;
  final ProxyCardType type;
  final String? testUrl;

  const ProxyCard({
    super.key,
    required this.groupName,
    required this.testUrl,
    required this.proxy,
    required this.groupType,
    required this.type,
  });

  Measure get measure => globalState.measure;

  Widget _buildProxyNameText(BuildContext context) {
    if (type == ProxyCardType.compact || type == ProxyCardType.tagged) {
      return SizedBox(
        height: measure.textHeight(AppTextStyle.subheadline) * 1,
        child: EmojiText(
          proxy.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.subheadline.of(context),
        ),
      );
    } else {
      return SizedBox(
        height: measure.textHeight(AppTextStyle.subheadline) * 2,
        child: EmojiText(
          proxy.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.subheadline.of(context),
        ),
      );
    }
  }

  void _handleSelect(WidgetRef ref) {
    selectGroupProxy(
      ref,
      groupName: groupName,
      groupType: groupType,
      proxyName: proxy.name,
    );
  }

  void _handleAddToLocalProxies(WidgetRef ref) {
    final proxiesAction = ref.read(proxiesActionProvider.notifier);
    globalState.safeRun(() => proxiesAction.addToLocalProxies(proxy.name));
  }

  List<CommonPopupMenuItem> _menuItems(
    BuildContext context,
    WidgetRef ref, {
    required bool inUse,
    required bool pinned,
    required bool addable,
  }) {
    final appLocalizations = context.appLocalizations;
    return [
      if (groupType == GroupType.Selector)
        CommonPopupMenuItem(
          glyph: AppGlyphs.checkCircle,
          label: appLocalizations.select,
          checked: inUse,
          onPressed: () => _handleSelect(ref),
        )
      else if (groupType.isComputedSelected)
        CommonPopupMenuItem(
          glyph: AppGlyphs.pin,
          label: appLocalizations.preferred,
          checked: pinned,
          onPressed: () => _handleSelect(ref),
        ),
      if (addable)
        CommonPopupMenuItem(
          glyph: AppGlyphs.listAdd,
          label: appLocalizations.addToLocalProxies,
          onPressed: () => _handleAddToLocalProxies(ref),
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measure = globalState.measure;
    final isLoose = type == ProxyCardType.loose;
    final isTagged = type == ProxyCardType.tagged;
    final delayText = _DelayText(
      proxy: proxy,
      testUrl: testUrl,
      alignment: isLoose ? Alignment.centerLeft : Alignment.centerRight,
    );
    final proxyNameText = _buildProxyNameText(context);
    final typeStyle = AppTextStyle.footnote
        .of(context)
        .copyWith(
          overflow: TextOverflow.ellipsis,
          color: context.colorScheme.onSurfaceVariant,
        );
    final details = switch (type) {
      ProxyCardType.loose => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: measure.textHeight(AppTextStyle.footnote),
              child: _ProxyDesc(proxy: proxy, style: typeStyle),
            ),
            const SizedBox(height: 6),
            delayText,
          ],
        ),
      ProxyCardType.tagged => _ProtocolTag(type: proxy.type),
      _ => SizedBox(
          height: measure.textHeight(AppTextStyle.footnote),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                flex: 1,
                child: TooltipText(
                  text: Text(proxy.type, maxLines: 1, style: typeStyle),
                ),
              ),
              delayText,
            ],
          ),
        ),
    };
    return Consumer(
      builder: (context, ref, _) {
        final inUse = ref.watch(
          selectedProxyNameProvider(
            groupName,
          ).select((name) => name == proxy.name),
        );
        final pinned =
            groupType.isComputedSelected &&
            ref.watch(
              proxyNameProvider(groupName).select((name) => name == proxy.name),
            );
        final isCustomProfile = ref.watch(
          currentProfileProvider.select(
            (profile) => profile?.type == ProfileType.custom,
          ),
        );
        return ContextMenuRegion(
          menuItems: _menuItems(
            context,
            ref,
            inUse: inUse,
            pinned: pinned,
            addable: _isAddableToLocal(proxy, isCustomProfile: isCustomProfile),
          ),
          child: CommonCard(
            radius: AppCorner.lg,
            enterActionsOnRight: true,
            key: key,
            onPressed: () => _handleSelect(ref),
            isSelected: inUse,
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: isTagged
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Expanded(child: proxyNameText),
                      if (pinned)
                        SelectionBadge.preferred(inUse: inUse)
                      else if (inUse)
                        const SelectionBadge(),
                      if (isTagged) delayText,
                    ],
                  ),
                  SizedBox(height: isTagged ? 6 : 8),
                  details,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProxyDesc extends ConsumerWidget {
  const _ProxyDesc({required this.proxy, required this.style});

  final Proxy proxy;
  final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGroup = GroupType.values.any((type) => type.name == proxy.type);
    final nodeName = isGroup
        ? ref.watch(
            realSelectedProxyStateProvider(
              proxy.name,
            ).select((state) => state.proxyName),
          )
        : proxy.name;
    return EmojiText(
      nodeName == proxy.name ? proxy.type : '${proxy.type}($nodeName)',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

class _DelayText extends ConsumerStatefulWidget {
  const _DelayText({
    required this.proxy,
    required this.testUrl,
    required this.alignment,
  });

  final Proxy proxy;
  final String? testUrl;
  final Alignment alignment;

  @override
  ConsumerState<_DelayText> createState() => _DelayTextState();
}

class _DelayTextState extends ConsumerState<_DelayText> {
  final FocusNode _focusNode = SkipTraversalFocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final isFocused = _focusNode.hasPrimaryFocus;
    if (isFocused == _isFocused) {
      return;
    }
    setState(() {
      _isFocused = isFocused;
    });
  }

  void _handleTestCurrentDelay() {
    ref
        .read(proxiesActionProvider.notifier)
        .proxyDelayTest(widget.proxy, widget.testUrl);
  }

  /// Why a failed test failed, where the row has no room to print it: a
  /// long press on touch, a hover with a pointer. A null message leaves the
  /// label alone, so a test that has not run yet shows no empty tip.
  Widget _withFailureTip({required String? message, required Widget child}) {
    if (message == null || message.isEmpty) {
      return child;
    }
    return Tooltip(message: message, child: child);
  }

  Widget _withFocusRing(BuildContext context, Widget child) {
    if (!_isFocused) {
      return child;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -2,
          right: -3,
          bottom: -2,
          left: -3,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: AppShape.xs.copyWith(
                  side: focusRingSide(context.colorScheme),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final measure = globalState.measure;
    final delay = ref.watch(
      delayProvider(proxyName: widget.proxy.name, testUrl: widget.testUrl),
    );
    final phase = ref.watch(
      delayTestPhaseProvider(
        proxyName: widget.proxy.name,
        testUrl: widget.testUrl,
      ),
    );
    final failure = ref.watch(
      delayFailureProvider(
        proxyName: widget.proxy.name,
        testUrl: widget.testUrl,
      ),
    );
    return Actions(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _handleTestCurrentDelay();
            return null;
          },
        ),
      },
      child: Focus(
        focusNode: _focusNode,
        child: SizedBox(
          height: measure.textHeight(AppTextStyle.caption2),
          child: FadeBox(
            alignment: widget.alignment,
            child: phase != null || delay == null
                ? SizedBox(
                    height: measure.textHeight(AppTextStyle.caption2),
                    width: measure.textHeight(AppTextStyle.caption2),
                    child: _withFocusRing(context, switch (phase) {
                      DelayTestPhase.running => CommonCircleLoading(
                        size: measure.textHeight(AppTextStyle.caption2),
                      ),
                      DelayTestPhase.queued => GlyphIcon(
                        AppGlyphs.clock,
                        size: measure.textHeight(AppTextStyle.caption2),
                        color: context.colorScheme.onSurfaceVariant.opacity38,
                      ),
                      null => Tooltip(
                        message: context.appLocalizations.delayTest,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _handleTestCurrentDelay,
                          child: GlyphIcon(
                            AppGlyphs.bolt,
                            size: measure.textHeight(AppTextStyle.caption2),
                          ),
                        ),
                      ),
                    }),
                  )
                : GestureDetector(
                    onTap: _handleTestCurrentDelay,
                    child: _withFocusRing(
                      context,
                      _withFailureTip(
                        message: delay > 0 ? null : failure,
                        child: Text(
                          delay > 0
                              ? '$delay ms'
                              : delayFailureText(
                                  delay,
                                  context.appLocalizations,
                                ),
                          maxLines: 1,
                          style: AppTextStyle.caption2
                              .of(context, emphasized: true)
                              .copyWith(
                                overflow: TextOverflow.ellipsis,
                                color: context.colorScheme.delayColor(delay),
                              ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}


/// The tagged card's second line: a coloured protocol chip. A runtime proxy
/// only carries its type, so this is one chip rather than the row of
/// transport/security badges a client reading the raw profile can show.
class _ProtocolTag extends StatelessWidget {
  const _ProtocolTag({required this.type});

  final String type;

  static (Color, Color) _colors(BuildContext context, String type) {
    final dark = context.colorScheme.brightness == Brightness.dark;
    final name = type.toLowerCase();
    // Fixed tones, like [GroupBadge.colorOf]: each family keeps its own hue
    // whatever the theme takes, and both tones read on light and dark cards.
    final base = switch (name) {
      _ when name.contains('vless') || name.contains('vmess') =>
        dark ? const Color(0xFF8AB4F8) : const Color(0xFF2C66D6),
      _ when name.contains('trojan') || name.contains('reality') =>
        dark ? const Color(0xFFF5B85E) : const Color(0xFFB26A0B),
      _ when name.contains('shadowsocks') ||
          name == 'ss' ||
          name.contains('socks') ||
          name == 'http' =>
        dark ? const Color(0xFF7BD8A4) : const Color(0xFF1D8A55),
      _ when name.contains('hysteria') ||
          name.contains('tuic') ||
          name.contains('wireguard') =>
        dark ? const Color(0xFF6FD3D0) : const Color(0xFF0E8684),
      _ => dark ? const Color(0xFFC4A6F7) : const Color(0xFF7A45C9),
    };
    return (base.withValues(alpha: dark ? 0.22 : 0.14), base);
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors(context, type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(color: background, shape: AppShape.full),
      child: Text(
        type,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.caption1
            .of(context, emphasized: true)
            .copyWith(color: foreground),
      ),
    );
  }
}
