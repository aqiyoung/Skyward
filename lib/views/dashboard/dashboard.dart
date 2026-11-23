import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/core/core.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/state.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/page_large_title.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'edit.dart';
import 'large_title.dart';
import 'layout.dart';
import 'style.dart';
import 'widgets/build_channel_badge.dart';
import 'widgets/core_status_button.dart';
import 'widgets/widgets.dart';

// Narrower columns leave the service grid's cells too tight for a status, so
// the grid takes the memory card's column instead.

const _maxColumnWidth = 440.0;

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key, this.platform});

  /// The host's platform when null.
  final SupportPlatform? platform;

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  var _editing = false;
  final _cardKeys = <DashboardWidget, GlobalKey>{};

  void _setEditing(bool editing) {
    setState(() => _editing = editing);
  }

  GlobalKey _cardKeyOf(DashboardWidget widget) =>
      _cardKeys.putIfAbsent(widget, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final platform = widget.platform ?? SupportPlatform.currentPlatform;
    final viewSize = ref.watch(viewSizeProvider);
    final sideWidth = ref.watch(sideWidthProvider);
    final scale = math.max(1.0, MediaQuery.textScalerOf(context).scale(1));
    final size = Size(viewSize.width - sideWidth, viewSize.height) / scale;
    final editable = !DashboardDensity.of(size).isDesktop;
    final editing = _editing && editable;
    if (_editing && !editable) {
      // Turning to the fixed grid ends rearranging for good -- it is not a mode
      // the window keeps for the reader to come back to once it narrows again.
      // The flag is cleared after this frame rather than during it, so every
      // value this frame acts on is one it read at the top.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _editing) {
          _setEditing(false);
        }
      });
    }
    final gap = cardSpacingOf(context, ref.watch(viewModeProvider));
    final appLocalizations = context.appLocalizations;
    // Read the real status-bar inset here, above the scaffold: inside the
    // body, extendBodyBehindAppBar lifts MediaQuery's top padding to the whole
    // bar height (and a wrapping removePadding can zero it), so neither is a
    // safe source for placing the heading just under the status bar.
    final statusBarTop = MediaQuery.paddingOf(context).top;
    final largeTitle = editable && !editing;
    // The providers learn a resize a frame late, too late for the cards.
    final dashboardBody = LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.biggest / scale;
        final layout = DashboardDensity.of(room);
        return DashboardDensityScope(
          density: layout,
          scale: scale,
          child: layout.isDesktop
              ? _DesktopDashboard(
                  platform: platform,
                  gap: gap,
                )
              : _MobileDashboard(
                  platform: platform,
                  gap: gap,
                  editing: editing,
                  largeTitle: largeTitle,
                  cardKeyOf: _cardKeyOf,
                  onEdit: () => _setEditing(true),
                  onDone: () => _setEditing(false),
                ),
        );
      },
    );
    return CommonScaffold(
      backgroundColor: DashboardColors.of(context).page,
      title: editing
          ? appLocalizations.editDashboard
          : appLocalizations.dashboard,
      // The resting phone home uses the same fixed PageLargeTitle block as
      // every other tab, so its heading never scrolls up under the status bar
      // and all pages share one design. Editing and the desktop grid keep the
      // ordinary bar title.
      largeTitle: largeTitle,
      backAction: editing ? () => _setEditing(false) : null,
      actions: [
        // Which channel this build is from, before the core's own state: the
        // two together are the whole answer to "what am I running".
        if (!editing) const BuildChannelBadge(),
        if (!editing && coreLib == null) const CoreStatusButton(),
      ],
      confirmationAction: editing
          ? IconButtonData(
              glyph: AppGlyphs.check,
              tooltip: appLocalizations.done,
              onPressed: () => _setEditing(false),
            )
          : null,
      // The edit affordance lives at the foot of the card list, not in the
      // empty top strip. The gear tile is where rearranging starts.
      body: largeTitle
          ? PageLargeTitle(
              title: appLocalizations.dashboard,
              statusBarTop: statusBarTop,
              subtitle: const DashboardStatusLine(),
              body: dashboardBody,
            )
          : dashboardBody,
    );
  }
}

/// The desktop board follows the product render: a status and speed row above
/// two equal columns, with the tall Route card on the right.
class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({
    required this.platform,
    required this.gap,
  });

  final SupportPlatform platform;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final density = DashboardDensityScope.of(context);
    final compact = density.isCompact;
    final scale = DashboardDensityScope.scaleOf(context);
    final base = EdgeInsetsDirectional.fromSTEB(
      16,
      MediaQuery.paddingOf(context).top,
      24,
      24 + MediaQuery.paddingOf(context).bottom,
    );
    final topHeight = (compact ? 176 : 208) * scale;
    // The small cards carry more space than their content needs. Trim it, but
    // keep the Route card at its old height so the two columns still end at
    // the same line: the left column loses two rows here, the right only one.
    final middleHeight = (compact ? 128 : 152) * scale;
    final routingHeight = (compact ? 316 : 368) * scale;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two equal columns, as in the render: the status card and the pair
        // of speed cards share the top row, and the two columns below line up
        // with them. `_maxColumnWidth` keeps the board from stretching.
        const columnCount = 2;
        final room = constraints.maxWidth - base.horizontal - gap;
        final column = math.min(room / columnCount, _maxColumnWidth * scale);
        final inset = (room - column * columnCount) / 2;
        final padding = base.copyWith(
          start: base.start + inset,
          end: base.end + inset,
        );
        Widget sized(double height, Widget child) =>
            SizedBox(height: height, child: child);
        Widget halfRow(List<Widget> cards) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: [
            for (final card in cards)
              Expanded(child: RepaintBoundary(child: card)),
          ],
        );
        // Top row: status on the left, the two speed cards on the right.
        final top = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: [
            Expanded(
              child: RepaintBoundary(child: CurrentOutboundCard()),
            ),
            Expanded(
              child: halfRow(const <Widget>[
                SpeedCard(direction: TrafficDirection.upload),
                SpeedCard(direction: TrafficDirection.download),
              ]),
            ),
          ],
        );
        // Below it, the reference layout folds the mode selector and the
        // VPN/LAN switches into one Network control card on the left. The
        // Route card on the right is the tall one, with the proxy-group
        // summary underneath it.
        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: [
            const RepaintBoundary(child: NetworkControlCard()),
            sized(
              middleHeight,
              halfRow(const <Widget>[IntranetIpCard(), ProfilesCard()]),
            ),
            sized(
              middleHeight,
              halfRow(const <Widget>[ServiceStatusCard(), MemoryInfo()]),
            ),
          ],
        );
        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: [
            sized(
              routingHeight,
              const RepaintBoundary(child: RoutingBoardCard()),
            ),
            sized(
              middleHeight,
              const RepaintBoundary(child: ProxyGroupsSummaryCard()),
            ),
          ],
        );
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: [
              sized(topHeight, top),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: gap,
                children: [
                  Expanded(child: left),
                  Expanded(child: right),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileDashboard extends ConsumerWidget {
  const _MobileDashboard({
    required this.platform,
    required this.gap,
    required this.editing,
    required this.largeTitle,
    required this.cardKeyOf,
    required this.onEdit,
    required this.onDone,
  });

  final SupportPlatform platform;
  final double gap;
  final bool editing;
  final bool largeTitle;
  final GlobalKey Function(DashboardWidget widget) cardKeyOf;
  final VoidCallback onEdit;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardStateProvider);
    // The shared large-title block already owns the strip under the status
    // bar, so the cards start flush beneath its own bottom spacing. Editing
    // has no such block: its ordinary bar needs the full inset back.
    final top = largeTitle ? 0.0 : MediaQuery.paddingOf(context).top + 4;
    final bottom = 16 + context.bottomInset;
    return CustomScrollView(
      // A viewport per card lays them all out and holds the scroll end still.
      scrollCacheExtent: editing
          ? ScrollCacheExtent.viewport(DashboardWidget.values.length.toDouble())
          : null,
      slivers: [
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final side = dashboardMobileSideOf(constraints.crossAxisExtent);
            // The piles come from the saved arrangement when the reader has
            // stacked any by hand, and from the cards' sizes before that. A
            // pile is what the board draws in one place, so a card this
            // platform cannot show drops out of its pile and a pile left empty
            // drops out of the board.
            final stacks = [
              for (final pile in dashboard.stacks)
                [
                  for (final card in pile)
                    if (card.platforms.contains(platform)) card,
                ],
            ].where((pile) => pile.isNotEmpty).toList();
            if (editing) {
              return DashboardEditor(
                platform: platform,
                stacks: stacks,
                cardKeyOf: cardKeyOf,
                padding: EdgeInsets.fromLTRB(side, top, side, bottom),
                gap: gap,
                onDone: onDone,
              );
            }
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(side, top, side, bottom),
              // A lazy list estimates the cards it has not laid out from the
              // ones it has; cards this uneven move the scroll end as it goes.
              sliver: SliverToBoxAdapter(
                child: Column(
                  spacing: gap,
                  children: [
                    for (final stack in stacks)
                      CardStack(
                        key: ValueKey(stack.first),
                        cards: stack,
                        cardKeyOf: cardKeyOf,
                      ),
                    // Rearranging the cards is a quiet action at the foot of
                    // the board, not a pencil floating in the empty top strip.
                    // A gear marks it as a settings-style edit of the board.
                    _EditDashboardTile(onTap: onEdit),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A small, centred hint at the foot of the board. It replaces the pencil
/// that used to float alone in the bar, and deliberately is not another full
/// card: a quiet capsule that reads as a hint rather than as board content.
/// Tapping it opens the card editor.
class _EditDashboardTile extends StatelessWidget {
  const _EditDashboardTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    return Center(
      child: Semantics(
        button: true,
        label: appLocalizations.editDashboard,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: ShapeDecoration(
              color: DashboardColors.of(context).tone2,
              shape: AppShape.all(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlyphIcon(
                  AppGlyphs.settings,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  appLocalizations.editDashboard,
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
