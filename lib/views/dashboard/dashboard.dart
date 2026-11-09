import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/core/core.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'edit.dart';
import 'large_title.dart';
import 'layout.dart';
import 'style.dart';
import 'widget_registry.dart';
import 'widgets/card.dart';
import 'widgets/core_status_button.dart';
import 'widgets/widgets.dart';

// Narrower columns leave the service grid's cells too tight for a status, so
// the grid takes the memory card's column instead.
const _memoryColumnMin = 290.0;

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
    return CommonScaffold(
      backgroundColor: DashboardColors.of(context).page,
      // The edit button steps aside with the title while the dashboard
      // scrolls up; this is now the scaffold default on every page.
      // Editing holds a confirmation action, which the scaffold keeps in
      // reach, so this only ever hides the edit button.
      title: editing
          ? appLocalizations.editDashboard
          : appLocalizations.dashboard,
      // The mobile home leads with an iOS Large Title in the body; the compact
      // bar title fades in as it scrolls away. Editing and the desktop grid
      // keep the ordinary bar title.
      largeTitle: editable && !editing,
      backAction: editing ? () => _setEditing(false) : null,
      actions: [if (!editing && coreLib == null) const CoreStatusButton()],
      confirmationAction: editing
          ? IconButtonData(
              glyph: AppGlyphs.check,
              tooltip: appLocalizations.done,
              onPressed: () => _setEditing(false),
            )
          : null,
      // The edit affordance now lives at the foot of the card list, not in the
      // floating bar: with the bar's title hidden at rest (large title), a lone
      // pencil up there left the whole top strip looking empty. The gear tile
      // at the bottom is where the reader goes to rearrange the cards.
      // The providers learn a resize a frame late, too late for the cards.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final room = constraints.biggest / scale;
          final layout = DashboardDensity.of(room);
          return DashboardDensityScope(
            density: layout,
            scale: scale,
            child: layout.isDesktop
                ? _DesktopDashboard(
                    platform: platform,
                    columns: dashboardColumnsOf(room.width),
                    gap: gap,
                  )
                : _MobileDashboard(
                    platform: platform,
                    gap: gap,
                    editing: editing,
                    largeTitle: editable && !editing,
                    cardKeyOf: _cardKeyOf,
                    onEdit: () => _setEditing(true),
                    onDone: () => _setEditing(false),
                  ),
          );
        },
      ),
    );
  }
}

/// Four columns fill the window, the tables taking what the rows above them
/// leave. A window too short for the tables, and every two column one, gets
/// the summary cards instead, so no list scrolls inside a page that scrolls.
class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({
    required this.platform,
    required this.columns,
    required this.gap,
  });

  final SupportPlatform platform;
  final int columns;
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
    final controlHeight = (compact ? 56 : 64) * scale;
    final middleHeight = (compact ? 152 : 176) * scale;
    final tablesHeight = connectionsTableMinHeight(density, scale);
    final summaryHeight = (compact ? 112 : 120) * scale;
    // A world map reads best wide: the board takes the full width, and the
    // connections table below it keeps its row only when the window can spare
    // it -- on shorter windows the board stays and the table steps down to the
    // summary cards, which the Connections page still carries in full.
    final routingHeight = (compact ? 290 : 300) * scale;
    return LayoutBuilder(
      builder: (context, constraints) {
        final room =
            constraints.maxWidth - base.horizontal - gap * (columns - 1);
        final column = math.min(room / columns, _maxColumnWidth * scale);
        final inset = (room - column * columns) / 2;
        final padding = base.copyWith(
          start: base.start + inset,
          end: base.end + inset,
        );
        double span(int columns) => column * columns + gap * (columns - 1);
        Widget row(List<(int, Widget)> cards) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: [
            for (final (columns, card) in cards)
              SizedBox(
                width: span(columns),
                child: RepaintBoundary(child: card),
              ),
          ],
        );
        Widget sized(double height, Widget child) =>
            SizedBox(height: height, child: child);
        final switches = desktopPlatforms.contains(platform)
            ? const [
                (1, NetworkTakeoverTile(TakeoverSwitch.systemProxy)),
                (1, NetworkTakeoverTile(TakeoverSwitch.tun)),
              ]
            : const [(2, VpnTile())];
        final half = columns ~/ 2;
        final summaries = row([
          (half, const ConnectionStatsCard()),
          (half, const ProxyGroupsSummaryCard()),
        ]);
        if (columns == 2) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            child: Column(
              spacing: gap,
              children: [
                sized(
                  topHeight,
                  const RepaintBoundary(child: CurrentOutboundCard()),
                ),
                sized(
                  topHeight,
                  row(const [
                    (1, SpeedCard(direction: TrafficDirection.upload)),
                    (1, SpeedCard(direction: TrafficDirection.download)),
                  ]),
                ),
                sized(
                  controlHeight,
                  const RepaintBoundary(child: OutboundModeBar()),
                ),
                sized(controlHeight, row(switches)),
                sized(
                  middleHeight,
                  row(const [(1, IntranetIpCard()), (1, ProfilesCard())]),
                ),
                sized(
                  middleHeight,
                  row(const [(1, ServiceStatusCard()), (1, MemoryInfo())]),
                ),
                sized(
                  routingHeight,
                  const RepaintBoundary(child: RoutingBoardCard()),
                ),
                sized(summaryHeight, summaries),
              ],
            ),
          );
        }
        final rows = [
          sized(
            topHeight,
            row(const [
              (2, CurrentOutboundCard()),
              (1, SpeedCard(direction: TrafficDirection.upload)),
              (1, SpeedCard(direction: TrafficDirection.download)),
            ]),
          ),
          sized(
            controlHeight,
            row([(2, const OutboundModeBar()), ...switches]),
          ),
          sized(
            middleHeight,
            row([
              (1, const IntranetIpCard()),
              (1, const ProfilesCard()),
              if (column >= _memoryColumnMin * scale) ...[
                (1, const ServiceStatusCard()),
                (1, const MemoryInfo()),
              ] else
                (2, const ServiceStatusCard()),
            ]),
          ),
          sized(
            routingHeight,
            row(const [(4, RoutingBoardCard())]),
          ),
        ];
        final rowsHeight =
            padding.vertical +
            topHeight +
            controlHeight +
            middleHeight +
            routingHeight +
            gap * 4;
        final tablesFit = constraints.maxHeight >= rowsHeight + tablesHeight;
        final fills = constraints.maxHeight >= rowsHeight + summaryHeight;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: fills ? constraints.maxHeight : null,
            child: Padding(
              padding: padding,
              child: Column(
                spacing: gap,
                children: [
                  ...rows,
                  if (tablesFit)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: gap,
                        children: const [
                          Expanded(
                            flex: 3,
                            child: RepaintBoundary(
                              child: ConnectionsTableCard(),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: RepaintBoundary(child: ProxyGroupsCard()),
                          ),
                        ],
                      ),
                    )
                  else if (fills)
                    Expanded(child: summaries)
                  else
                    sized(summaryHeight, summaries),
                ],
              ),
            ),
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
    final saved = ref.watch(
      dashboardStateProvider.select((state) => state.dashboardWidgets),
    );
    // A large-title home has no bar surface at rest, so it needs only the
    // status bar's clearance -- not the whole toolbar height the floating bar
    // would otherwise push the title down by. Editing keeps the ordinary bar
    // and its full inset.
    final top = largeTitle
        ? MediaQuery.viewPaddingOf(context).top + 8
        : MediaQuery.paddingOf(context).top + 4;
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
            final widgets = [
              for (final widget in saved)
                if (widget.platforms.contains(platform)) widget,
            ];
            if (editing) {
              return DashboardEditor(
                platform: platform,
                widgets: widgets,
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
                    // The iOS Large Title + status line lead the home screen and
                    // scroll away with the content; the bar's compact title is
                    // faded in by CommonScaffold as this goes under the bar.
                    const DashboardLargeTitle(),
                    for (final widget in widgets)
                      RepaintBoundary(
                        key: cardKeyOf(widget),
                        child: widget.card,
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

/// The quiet gear row at the foot of the board. It replaces the pencil that
/// used to float alone in the bar; tapping it opens the card editor. Kept as a
/// normal card so it reads as part of the board, not a floating control.
class _EditDashboardTile extends StatelessWidget {
  const _EditDashboardTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return DashboardCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      onTap: onTap,
      semanticLabel: appLocalizations.editDashboard,
      child: ListItem(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        leading: const IconWell(
          AppGlyphs.settings,
          side: 36,
          glyphSize: 20,
          shape: AppShape.md,
        ),
        title: Text(appLocalizations.editDashboard),
        // The card carries the tap; the row only shows the forward chevron so
        // one press does not drive two ink wells.
        arrow: true,
      ),
    );
  }
}
