import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';

Glyph _glyphOf(Mode mode) => switch (mode) {
  Mode.rule => AppGlyphs.rules,
  Mode.global => AppGlyphs.proxies,
  Mode.direct => AppGlyphs.target,
};

void _changeMode(WidgetRef ref, Mode mode) {
  if (ref.read(patchClashConfigProvider).mode == mode) return;
  ref.read(setupActionProvider.notifier).changeMode(mode);
}

/// The three modes as one connected group, for the card that holds them.
class OutboundModeSelector extends ConsumerWidget {
  const OutboundModeSelector({super.key});

  static const _outer = 26.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final tone = DashboardColors.of(context).tone;
    final style = AppTextStyle.footnote
        .of(context)
        .copyWith(fontWeight: DashboardWeight.value);
    return DashboardConnectedGroup(
      children: [
        for (final (index, item) in Mode.values.indexed)
          Expanded(
            child: DashboardConnectedButton(
              selected: item == mode,
              first: index == 0,
              last: index == Mode.values.length - 1,
              outer: _outer,
              inner: 12,
              background: tone,
              semanticLabel: item.label,
              onTap: () => _changeMode(ref, item),
              builder: (foreground) => SizedBox(
                height: 46,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 6,
                  children: [
                    // Clash-style selection mark: a blue check before the
                    // label, with the label itself in blue bold.
                    if (item == mode)
                      GlyphIcon(
                        AppGlyphs.check,
                        size: 16,
                        color: foreground,
                      ),
                    GlyphIcon(_glyphOf(item), size: 17, color: foreground),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style.copyWith(
                          color: foreground,
                          fontWeight: item == mode
                              ? DashboardWeight.title
                              : DashboardWeight.value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The desktop control row's mode switch; its buttons sit as far in from the
/// card's ends as from its edges so their corners stay concentric.
class OutboundModeBar extends ConsumerWidget {
  const OutboundModeBar({super.key});

  static const _inset = 8.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = DashboardDensityScope.of(context);
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final appLocalizations = context.appLocalizations;
    final outer = dashboardCardRadius(density) - _inset;
    final style = DashboardText.rowTitle(context);
    return DashboardCard(
      semanticLabel: appLocalizations.outboundMode,
      padding: EdgeInsetsDirectional.fromSTEB(
        dashboardCardPadding(density).left,
        _inset,
        _inset,
        _inset,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          spacing: 16,
          children: [
            GlyphIcon(
              AppGlyphs.split,
              size: 18,
              color: context.colorScheme.onSurfaceVariant,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth / 4),
              child: Text(
                appLocalizations.outboundMode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DashboardText.cardTitle(context),
              ),
            ),
            Expanded(
              child: DashboardConnectedGroup(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, item) in Mode.values.indexed)
                    Expanded(
                      child: DashboardConnectedButton(
                        selected: item == mode,
                        first: index == 0,
                        last: index == Mode.values.length - 1,
                        outer: outer,
                        inner: 10,
                        background: DashboardColors.of(context).tone,
                        semanticLabel: item.label,
                        onTap: () => _changeMode(ref, item),
                        builder: (foreground) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 6,
                          children: [
                            if (item == mode)
                              GlyphIcon(
                                AppGlyphs.check,
                                size: 16,
                                color: foreground,
                              ),
                            GlyphIcon(
                              _glyphOf(item),
                              size: 18,
                              color: foreground,
                            ),
                            Flexible(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: style.copyWith(color: foreground),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
