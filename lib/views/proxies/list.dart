import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:skyward/ui/motion.dart';
import 'dart:async';
import 'dart:math';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/chains/page.dart';
import 'package:skyward/views/chains/state.dart';
import 'package:skyward/views/chains/widgets.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'card.dart';
import 'common.dart';
import 'routing.dart';
import 'routing_strategy.dart';

const _pinnedHeaderGap = 8.0;
const _headerInset = 10.0;
const _headerButtonInset = 4.0;
const _groupInset = 16.0;
const _liftDistance = 16.0;
const _groupMinWidth = 360.0;
const _groupMaxColumns = 3;
const _lastRowGrowth = _headerInset - proxyGridSpacing;

class ProxiesListView extends ConsumerStatefulWidget {
  const ProxiesListView({super.key});

  @override
  ConsumerState<ProxiesListView> createState() => _ProxiesListViewState();
}

class _ProxiesListViewState extends ConsumerState<ProxiesListView> {
  late final ScrollController _controller;
  int _columns = 1;
  int _groupColumns = 1;
  double _gap = 0;

  /// Chain reports are shared by every group band; loading them once here
  /// keeps each group sliver from calling the core for the same data.
  List<ChainReport> _chainReports = const [];

  @override
  void initState() {
    super.initState();
    _controller = sheetScrollController(context);
    unawaited(_loadChainReports());
  }

  Future<void> _loadChainReports() async {
    // A page can be built before the Core is reachable (tests, startup, a
    // restart). Asking then only starts a reconnect timer that outlives the
    // widget; the reports are loaded on the next build once it is connected.
    if (kDebugMode || ref.read(coreStatusProvider) != CoreStatus.connected) {
      return;
    }
    final reports = await ref.read(coreHandlerProvider).getChainReport();
    if (mounted) setState(() => _chainReports = reports);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChange(String groupName) {
    _autoScrollToGroup(groupName);
    final tempUnfoldSet = Set<String>.from(ref.read(unfoldSetProvider));
    if (!tempUnfoldSet.remove(groupName)) {
      tempUnfoldSet.add(groupName);
    }
    ref
        .read(proxiesActionProvider.notifier)
        .updateCurrentUnfoldSet(tempUnfoldSet);
  }

  GroupOffsets _getGroupOffsets() {
    final state = ref.read(proxiesListStateProvider);
    final offsets = <double>[];
    final rowExtent = getRowExtent(state.proxyCardType);
    final columnOffsets = List.filled(_groupColumns, 0.0);
    for (final (index, group) in state.groups.indexed) {
      final column = index % _groupColumns;
      offsets.add(columnOffsets[column]);
      columnOffsets[column] += listHeaderHeight + _gap;
      if (state.currentUnfoldSet.contains(group.name)) {
        final rowCount = (group.all.length + _columns - 1) ~/ _columns;
        columnOffsets[column] += _rowsExtent(rowCount, rowExtent);
      }
    }
    return GroupOffsets(state.groups, offsets);
  }

  double _getGroupOffset(String groupName) {
    if (!_controller.hasClients || _controller.position.maxScrollExtent == 0) {
      return 0;
    }
    return _getGroupOffsets().offsetOf(groupName);
  }

  void _scrollToMakeVisibleWithPadding({
    required double containerHeight,
    required double pixels,
    required double start,
    required double end,
    double padding = 24,
  }) {
    final visibleStart = pixels;
    final visibleEnd = pixels + containerHeight;

    final isElementVisible = start >= visibleStart && end <= visibleEnd;
    if (isElementVisible) {
      return;
    }

    double targetScrollOffset;

    if (end <= visibleStart) {
      targetScrollOffset = start;
    } else if (start >= visibleEnd) {
      targetScrollOffset = end - containerHeight + padding;
    } else {
      final visibleTopPart = end - visibleStart;
      final visibleBottomPart = visibleEnd - start;
      if (visibleTopPart.abs() >= visibleBottomPart.abs()) {
        targetScrollOffset = end - containerHeight + padding;
      } else {
        targetScrollOffset = start;
      }
    }

    targetScrollOffset = targetScrollOffset.clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );

    _controller.jumpTo(targetScrollOffset);
  }

  void _autoScrollToGroup(String groupName) {
    final pixels = _controller.position.pixels;
    final offset = _getGroupOffset(groupName);
    _scrollToMakeVisibleWithPadding(
      containerHeight: max(
        _controller.position.viewportDimension -
            context.appBarInset -
            _pinnedHeaderGap,
        0,
      ),
      pixels: pixels,
      start: offset,
      end: offset + listHeaderHeight,
    );
  }

  void _scrollToGroupSelected(String groupName) {
    final cardType = ref.read(proxiesListStateProvider).proxyCardType;
    final proxies = ref
        .read(proxiesListStateProvider)
        .groups
        .getGroup(groupName)
        ?.all;
    if (proxies == null) {
      return;
    }
    final rowOffset = selectedRowOffset(
      proxies: proxies,
      selectedProxyName: ref.read(selectedProxyNameProvider(groupName)),
      columns: _columns,
      rowExtent: getRowExtent(cardType),
    );
    if (rowOffset == null) {
      return;
    }
    animateScrollTo(_controller, _getGroupOffset(groupName) + rowOffset);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return Consumer(
      builder: (_, ref, _) {
        final groups = ref.watch(
          proxiesListStateProvider.select((state) => state.groups),
        );
        final cardType = ref.watch(
          proxiesListStateProvider.select((state) => state.proxyCardType),
        );
        ref.watch(themeSettingProvider.select((state) => state.textScale));
        final viewMode = ref.watch(viewModeProvider);
        final proxiesLayout = ref.watch(
          proxiesStyleSettingProvider.select((state) => state.layout),
        );
        final isSearching = ref.watch(
          queryProvider(
            QueryTag.proxies,
          ).select((query) => SearchQuery(query).isNotEmpty),
        );
        return NullStatusSwitcher(
          isEmpty: groups.isEmpty,
          isSearching: isSearching,
          nullStatus: NullStatus(
            illustration: NullStatusIllustration.proxies,
            label: appLocalizations.nullTip(appLocalizations.proxies),
          ),
          child: WidthBuilder(
            builder: (_, maxWidth) {
              final gap = cardSpacingOf(context, viewMode);
              final width = max(maxWidth - _groupInset * 2, 0.0);
              final groupColumns = viewMode == ViewMode.mobile
                  ? 1
                  : ((width + gap) / (_groupMinWidth + gap)).floor().clamp(
                      1,
                      _groupMaxColumns,
                    );
              final groupWidth =
                  (width - gap * (groupColumns - 1)) / groupColumns;
              final columns = getProxiesColumns(
                max(groupWidth - _headerInset * 2, 0),
                proxiesLayout,
              );
              _columns = columns;
              _groupColumns = groupColumns;
              _gap = gap;
              Widget buildGroup(Group group) => _GroupSliver(
                key: _GroupSliverKey(group.name),
                group: group,
                columns: columns,
                cardType: cardType,
                gap: gap,
                reports: _chainReports,
                onChange: _handleChange,
                onScrollToSelected: _scrollToGroupSelected,
              );
              final barInset = context.appBarInset;
              return CommonScrollBar(
                controller: _controller,
                thumbVisibility: true,
                child: CustomScrollView(
                  key: proxiesListStoreKey,
                  controller: _controller,
                  slivers: [
                    PinnedHeaderSliver(
                      child: SizedBox(height: barInset + _pinnedHeaderGap),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _groupInset,
                      ),
                      sliver: groupColumns == 1
                          ? SliverMainAxisGroup(
                              slivers: groups.map(buildGroup).toList(),
                            )
                          : SliverCrossAxisGroup(
                              slivers: [
                                for (
                                  var column = 0;
                                  column < groupColumns;
                                  column++
                                ) ...[
                                  if (column > 0)
                                    SliverConstrainedCrossAxis(
                                      maxExtent: gap,
                                      sliver: const SliverToBoxAdapter(),
                                    ),
                                  SliverCrossAxisExpanded(
                                    flex: 1,
                                    sliver: SliverMainAxisGroup(
                                      slivers: [
                                        for (
                                          var index = column;
                                          index < groups.length;
                                          index += groupColumns
                                        )
                                          buildGroup(groups[index]),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 16 + context.bottomInset),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

double _rowsExtent(int rowCount, double rowExtent) =>
    rowCount == 0 ? 0 : rowCount * rowExtent + _lastRowGrowth;

class _GroupSliverKey extends ValueKey<String> {
  const _GroupSliverKey(super.value);
}

/// Watches only its own group's fold state, so folding one group leaves the
/// cards of every other group untouched, and keeps its rows sliver while the
/// inputs that shape it are equal.
class _GroupSliver extends ConsumerStatefulWidget {
  const _GroupSliver({
    super.key,
    required this.group,
    required this.columns,
    required this.cardType,
    required this.gap,
    required this.reports,
    required this.onChange,
    required this.onScrollToSelected,
  });

  final Group group;
  final int columns;
  final ProxyCardType cardType;
  final double gap;
  final List<ChainReport> reports;
  final void Function(String groupName) onChange;
  final void Function(String groupName) onScrollToSelected;

  @override
  ConsumerState<_GroupSliver> createState() => _GroupSliverState();
}

class _GroupSliverState extends ConsumerState<_GroupSliver>
    with SingleTickerProviderStateMixin {
  Widget? _rows;
  double _rowExtent = 0;
  late final _controller = AnimationController(
    vsync: this,
    value: ref.read(unfoldSetProvider).contains(widget.group.name) ? 1 : 0,
  );
  late final _unfold = UnfoldEntryTransition.curveOf(_controller);

  /// Enabled link chains that the Core injected into this group. They show in
  /// their own band above the servers, so they must be kept out of the server
  /// rows to avoid showing each one twice.
  List<SavedChain> get _chainsInGroup {
    final chains = ref.watch(chainsProvider);
    if (chains.isEmpty) return const [];
    final names = widget.group.all.map((p) => p.name).toSet();
    return chains.where((c) => c.enabled && names.contains(c.name)).toList();
  }

  /// Reports are loaded once by the parent view and passed down; each group
  /// used to call the core on its own, which meant one round trip per group.
  ChainReport? _reportOf(int id) {
    for (final report in widget.reports) {
      if (report.id == id) return report;
    }
    return null;
  }

  List<Proxy> get _serverProxies {
    final chains = _chainsInGroup.map((c) => c.name).toSet();
    if (chains.isEmpty) return widget.group.all;
    return widget.group.all.where((p) => !chains.contains(p.name)).toList();
  }

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((_) => setState(() {}));
    ref.listenManual(
      unfoldSetProvider.select((state) => state.contains(widget.group.name)),
      (_, isExpand) => _handleUnfold(isExpand),
    );
  }

  @override
  void dispose() {
    _unfold.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleUnfold(bool isExpand) {
    // A spring driven from the current value and velocity: a second tap during
    // the fold reverses without a jolt, and the rows move with the chevron.
    UnfoldMotion.run(
      _controller,
      open: isExpand,
      animate: !context.disableAnimations,
    );
  }

  @override
  void didUpdateWidget(_GroupSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.group != oldWidget.group ||
        widget.columns != oldWidget.columns ||
        widget.cardType != oldWidget.cardType) {
      _rows = null;
    }
  }

  Widget _buildRow(BuildContext context, List<Proxy> proxies) {
    final group = widget.group;
    final cardType = widget.cardType;
    final groupName = group.name;
    final children = proxies
        .map<Widget>(
          (proxy) => Flexible(
            child: SizedBox(
              height: getItemHeight(cardType),
              child: ProxyCard(
                testUrl: group.testUrl,
                type: cardType,
                groupType: group.type,
                key: ValueKey('$groupName.${proxy.name}'),
                proxy: proxy,
                groupName: groupName,
              ),
            ),
          ),
        )
        .fill(widget.columns, filler: (_) => const Flexible(child: SizedBox()))
        .separated(const SizedBox(width: 8));
    return SurfaceScope(
      level: context.raisedSurfaceLevel,
      child: Padding(
        padding: const EdgeInsets.only(
          left: _headerInset,
          right: _headerInset,
          bottom: proxyGridSpacing,
        ),
        child: Row(children: children.toList()),
      ),
    );
  }

  Widget _buildRows(double extent) {
    final rows = _serverProxies.chunks(widget.columns).toList();
    return SliverFixedExtentList(
      itemExtent: extent,
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildRow(context, rows[index]),
        childCount: rows.length,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  /// The card reaches up behind the header's rounded bottom corners, so the
  /// two read as one while the rows unfold or fold.
  Widget _buildUnfoldingRows(double extent, ShapeDecoration decoration) {
    final rows = _serverProxies.chunks(widget.columns).toList();
    final visible = min(
      rows.length.toDouble(),
      MediaQuery.sizeOf(context).height / extent,
    );
    final count = min(rows.length, visible.floor() + 1);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -AppCorner.xl.ap(context),
          left: 0,
          right: 0,
          bottom: 0,
          child: DecoratedBox(decoration: decoration),
        ),
        SizeTransition(
          sizeFactor: _unfold,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              for (var index = 0; index < count; index++)
                UnfoldEntryTransition(
                  animation: _unfold,
                  index: index,
                  visibleCount: visible,
                  child: SizedBox(
                    height: extent,
                    child: _buildRow(context, rows[index]),
                  ),
                ),
              if (count == rows.length) const SizedBox(height: _lastRowGrowth),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupName = widget.group.name;
    final isExpand = ref.watch(
      unfoldSetProvider.select((state) => state.contains(groupName)),
    );
    final unfolded = _controller.isCompleted;
    Widget? rows;
    if (!_controller.isDismissed && widget.group.all.isNotEmpty) {
      final extent = getRowExtent(widget.cardType);
      final decoration = ShapeDecoration(
        color: context.raisedSurfaceLevel.colorOf(context.colorScheme),
        shape: AppShape.vertical(
          top: AppCorner.none,
          bottom: AppCorner.xl.ap(context),
        ),
      );
      if (!unfolded) {
        _rows = null;
        rows = SliverToBoxAdapter(
          child: _buildUnfoldingRows(extent, decoration),
        );
      } else {
        if (_rows == null || _rowExtent != extent) {
          _rows = _buildRows(extent);
          _rowExtent = extent;
        }
        rows = DecoratedSliver(
          decoration: decoration,
          sliver: SliverMainAxisGroup(
            slivers: [
              _rows!,
              const SliverToBoxAdapter(child: SizedBox(height: _lastRowGrowth)),
            ],
          ),
        );
      }
    } else {
      _rows = null;
    }
    Widget buildHeader({double floating = 0, double lift = 0}) => SizedBox(
      height: listHeaderHeight,
      child: ListHeader(
        enterAnimated: false,
        floating: floating,
        lift: lift,
        onScrollToSelected: widget.onScrollToSelected,
        key: ValueKey(groupName),
        isExpand: isExpand,
        unfolded: unfolded,
        group: widget.group,
        onChange: widget.onChange,
      ),
    );
    return SliverPadding(
      padding: EdgeInsets.only(bottom: widget.gap),
      sliver: SliverMainAxisGroup(
        slivers: [
          _buildPinnedHeader(isExpand, buildHeader),
          ?_buildChainBand(),
          ?rows,
        ],
      ),
    );
  }

  /// The chains band above the servers, with a link to manage them all.
  Widget? _buildChainBand() {
    final chains = _chainsInGroup;
    if (chains.isEmpty) return null;
    final scheme = context.colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _headerInset,
          2,
          _headerInset,
          proxyGridSpacing,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    zh ? '链路' : 'Chains',
                    style: AppTextStyle.footnote
                        .of(context, emphasized: true)
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                TextButton(
                  onPressed: () => openChainsPage(context),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(zh ? '全部链路' : 'All chains'),
                      const GlyphIcon(AppGlyphs.chevronForward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            SurfaceScope(
              level: context.raisedSurfaceLevel,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final chain in chains)
                      _ChainChip(
                        chain: chain,
                        zh: zh,
                        groupName: widget.group.name,
                        groupType: widget.group.type,
                        report: _reportOf(chain.id),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rounds the header and lifts it as its own rows scroll under it, and lets
  /// the shadow go before the end of the group pushes it out. The page color
  /// behind its upper half hides the rows that went under it, which would
  /// otherwise show around its top corners and above it. Every header is laid
  /// out on every pass, so one beyond the cache area builds nothing.
  Widget _buildPinnedHeader(
    bool isExpand,
    Widget Function({double floating, double lift}) buildHeader,
  ) {
    final columns = widget.columns;
    final rowCount = (_serverProxies.length + columns - 1) ~/ columns;
    final rowsExtent = isExpand ? _rowsExtent(rowCount, _rowExtent) : 0.0;
    final groupExtent =
        listHeaderHeight +
        (_controller.isDismissed
            ? 0.0
            : _rowsExtent(rowCount, getRowExtent(widget.cardType)));
    (double, double, double, Color)? headerState;
    Widget? header;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final beyondCache =
            constraints.remainingCacheExtent <= 0 ||
            constraints.scrollOffset + constraints.cacheOrigin >= groupExtent;
        final under = isExpand
            ? constraints.scrollOffset + constraints.overlap
            : 0.0;
        final state = beyondCache
            ? null
            : (
                (under / _liftDistance).clamp(0.0, 1.0),
                (min(under, rowsExtent - under) / _liftDistance).clamp(
                  0.0,
                  1.0,
                ),
                isExpand ? constraints.overlap : 0.0,
                context.surfaceLevel.colorOf(context.colorScheme),
              );
        if (header != null && state == headerState) {
          return header!;
        }
        headerState = state;
        if (state == null) {
          return header = PinnedHeaderSliver(
            child: SizedBox(height: listHeaderHeight),
          );
        }
        final (floating, lift, cover, pageColor) = state;
        return header = PinnedHeaderSliver(
          child: RepaintBoundary(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -cover,
                  left: 0,
                  right: 0,
                  height: cover + listHeaderHeight / 2,
                  child: ColoredBox(color: pageColor),
                ),
                buildHeader(floating: floating, lift: lift),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ListHeader extends ConsumerWidget {
  final Group group;

  final Function(String groupName) onChange;
  final Function(String groupName) onScrollToSelected;
  final bool isExpand;

  /// Whether the rows have settled under the header, squaring its bottom.
  final bool unfolded;

  final bool enterAnimated;

  /// How far the group's own rows have scrolled under the pinned header, as a
  /// fraction of the distance that rounds its bottom corners.
  final double floating;

  /// The shadow that lifts the header off the rows under it.
  final double lift;

  const ListHeader({
    super.key,
    this.enterAnimated = true,
    this.floating = 0,
    this.lift = 0,
    required this.group,
    required this.onChange,
    required this.onScrollToSelected,
    required this.isExpand,
    required this.unfolded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupName = group.name;
    final isDelayTesting = ref.watch(
      delayTestingGroupsProvider.select((state) => state.contains(groupName)),
    );
    final (scripted, profile) = ref.watch(
      rcxGroupProvider(groupName).select(
        (state) => switch (state) {
          null => (false, null),
          final group => (true, group.control.isManual ? null : group.profile),
        },
      ),
    );
    final behaviour = watchGroupBehaviour(ref, group);
    final showRouting = behaviour || scripted;
    final colorScheme = context.colorScheme;
    final level = floating > 0
        ? SurfaceLevel.floatingOf(colorScheme)
        : context.raisedSurfaceLevel;
    final radius = AppCorner.xl.ap(context);
    final card = CommonCard(
      enterActionsOnRight: true,
      enterAnimated: enterAnimated,
      key: key,
      radius: radius - _headerButtonInset,
      child: Padding(
        padding: const EdgeInsets.all(_headerInset - _headerButtonInset),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  _GroupIcon(group: group),
                  Flexible(child: _GroupSummary(groupName: groupName)),
                ],
              ),
            ),
            _GroupActions(
              isExpand: isExpand,
              isDelayTesting: isDelayTesting,
              groupType: group.type,
              routingLabel: profile == null
                  ? null
                  : rcxProfileTitle(context, ref, profile),
              routingTooltip: behaviour
                  ? context.appLocalizations.rcxBehaviour
                  : null,
              onRouting: showRouting
                  ? () => unawaited(
                      behaviour
                          ? showGroupBehaviour(context, groupName)
                          : showRoutingSheet(context, groupName),
                    )
                  : null,
              onScrollToSelected: () {
                onScrollToSelected(groupName);
              },
              onDelayTest: () {
                ref
                    .read(proxiesActionProvider.notifier)
                    .delayTestPageGroup(groupName);
              },
              onToggle: () {
                onChange(groupName);
              },
            ),
          ],
        ),
      ),
      onPressed: () {
        onChange(groupName);
      },
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: level.colorOf(colorScheme),
        shape: AppShape.vertical(
          top: radius,
          bottom: unfolded ? radius * floating : radius,
        ),
        shadows: lift == 0 ? null : _floatingShadows(colorScheme, lift),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_headerButtonInset),
        child: SurfaceScope(
          // CommonCard fills one level above its scope.
          level: level.previous,
          child: card,
        ),
      ),
    );
  }
}

List<BoxShadow> _floatingShadows(ColorScheme colorScheme, double lift) {
  final strength = colorScheme.brightness == Brightness.dark ? 3.0 : 1.0;
  return [
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.08 * strength * lift),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.04 * strength * lift),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];
}

class _GroupIcon extends ConsumerWidget {
  const _GroupIcon({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconStyle = ref.watch(
      proxiesStyleSettingProvider.select((state) => state.iconStyle),
    );
    return switch (iconStyle) {
      ProxiesIconStyle.filled => LayoutBuilder(
        builder: (_, constraints) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                alignment: Alignment.center,
                padding: EdgeInsets.all(6.ap(context)),
                decoration: ShapeDecoration(
                  color: Color.alphaBlend(
                    GroupBadge.colorOf(
                      context,
                      group.type,
                    ).withValues(alpha: 0.14),
                    context.raisedSurfaceLevel.colorOf(context.colorScheme),
                  ),
                  shape: AppShape.all(AppCorner.xl.ap(context) - _headerInset),
                ),
                clipBehavior: Clip.antiAlias,
                child: IconTheme.merge(
                  data: IconThemeData(
                    size: constraints.maxHeight - 12.ap(context),
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  child: CommonTargetIcon(
                    src: GroupIconSource.of(name: group.name, icon: group.icon),
                    fallback: GroupBadge(name: group.name),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      ProxiesIconStyle.plain => Container(
        margin: const EdgeInsets.only(left: 2, right: 10),
        child: LayoutBuilder(
          builder: (_, constraints) {
            return IconTheme.merge(
              data: IconThemeData(
                size: constraints.maxHeight,
                color: context.colorScheme.onSurfaceVariant,
              ),
              child: CommonTargetIcon(
                src: GroupIconSource.of(name: group.name, icon: group.icon),
                fallback: GroupBadge(name: group.name),
              ),
            );
          },
        ),
      ),
      // Lines the title up with the proxy card names below, which sit at the
      // row inset plus the card padding.
      ProxiesIconStyle.hidden => const SizedBox(width: 4),
    };
  }
}

class _GroupSummary extends StatelessWidget {
  const _GroupSummary({required this.groupName});

  final String groupName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EmojiText(
          GroupMonogram.labelOf(context, groupName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.callout.of(context, emphasized: true),
        ),
        const SizedBox(height: 2),
        Flexible(flex: 1, child: _SelectedProxyName(groupName: groupName)),
      ],
    );
  }
}

class _SelectedProxyName extends ConsumerWidget {
  const _SelectedProxyName({required this.groupName});

  final String groupName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxyName = ref
        .watch(selectedProxyNameProvider(groupName))
        .takeFirstValid([]);
    if (proxyName.isEmpty) {
      return const SizedBox.shrink();
    }
    final control = ref.watch(
      rcxGroupProvider(groupName).select((state) => state?.control),
    );
    final l = context.appLocalizations;
    final mode = switch (control) {
      null => null,
      RcxControl(isManual: true) => null,
      RcxControl(isPinned: true) => l.rcxPinnedLabel,
      _ => l.rcxModeAuto,
    };
    return EmojiText(
      mode == null ? proxyName : '$mode · $proxyName',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyle.caption1.of(context, emphasized: true).toLight,
    );
  }
}

class _GroupActions extends StatelessWidget {
  const _GroupActions({
    required this.isExpand,
    required this.isDelayTesting,
    required this.groupType,
    this.routingLabel,
    this.routingTooltip,
    this.onRouting,
    required this.onScrollToSelected,
    required this.onDelayTest,
    required this.onToggle,
  });

  final bool isExpand;
  final bool isDelayTesting;
  final GroupType groupType;
  final String? routingLabel;
  final String? routingTooltip;
  final VoidCallback? onRouting;
  final VoidCallback onScrollToSelected;
  final VoidCallback onDelayTest;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TonalButtonTheme(
      size: TonalButtonSize.compact,
      child: Row(
        children: [
          if (isExpand)
            TonalButtonGroup(
              size: TonalButtonSize.compact,
              children: [
                IconButton(
                  tooltip: context.appLocalizations.scrollToSelected,
                  onPressed: onScrollToSelected,
                  iconSize: 19,
                  icon: const GlyphIcon(AppGlyphs.locate),
                ),
                IconButton(
                  tooltip: context.appLocalizations.delayTest,
                  onPressed: isDelayTesting ? null : onDelayTest,
                  icon: isDelayTesting
                      ? CommonCircleLoading(size: TonalButtonSize.compact.icon)
                      : const GlyphIcon(AppGlyphs.bolt),
                ),
                if (onRouting != null)
                  IconButton(
                    tooltip:
                        routingTooltip ?? context.appLocalizations.rcxTitle,
                    onPressed: onRouting,
                    iconSize: 19,
                    icon: const GlyphIcon(AppGlyphs.shuffle),
                  ),
              ],
            )
          // Selector is the default group and the expand arrow already
          // says a choice can be made, so its name is noise on every row;
          // a computed group keeps its name, because it is the reason the
          // row cannot be picked from directly.
          else if (routingLabel != null)
            Text(
              routingLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.caption1
                  .of(context, emphasized: true)
                  .toLight,
            )
          else if (groupType != GroupType.Selector)
            Text(
              groupType.name,
              style: AppTextStyle.caption1
                  .of(context, emphasized: true)
                  .toLight,
            ),
          const SizedBox(width: 6),
          ElasticPress(
            child: IconButton(
              tooltip: isExpand
                  ? context.appLocalizations.showLess
                  : context.appLocalizations.showMore,
              onPressed: onToggle,
              icon: CommonExpandIcon(expand: isExpand),
            ),
          ),
        ],
      ),
    );
  }
}

/// One enabled chain in the band. It reads like a server: flags, name, the
/// route as its detail line, a warning mark when the core reported problems,
/// and the check badge when it is the group's current selection.
class _ChainChip extends ConsumerWidget {
  const _ChainChip({
    required this.chain,
    required this.zh,
    required this.groupName,
    required this.groupType,
    required this.report,
  });

  final SavedChain chain;
  final bool zh;
  final String groupName;
  final GroupType groupType;
  final ChainReport? report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final entry = chain.hops.first;
    final exit = chain.hops.last;
    final selected =
        ref.watch(selectedProxyNameProvider(groupName)) == chain.name;
    final delay = ref.watch(
      delayProvider(proxyName: chain.name, testUrl: null),
    );
    final broken = report?.status == 'broken';
    final warned = broken || (report?.issues.isNotEmpty ?? false);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        decoration: ShapeDecoration(
          color: context.raisedSurfaceLevel.colorOf(scheme),
          shape: AppShape.all(16),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: AppShape.all(16),
            onTap: () => selectGroupProxy(
              ref,
              groupName: groupName,
              groupType: groupType,
              proxyName: chain.name,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PairedFlags(entry, exit, size: 24),
                      if (selected)
                        Positioned(
                          right: -6,
                          bottom: -4,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: scheme.primary,
                            child: GlyphIcon(
                              AppGlyphs.check,
                              size: 12,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          chain.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.footnote.of(context),
                        ),
                        Text(
                          '$entry → $exit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.caption2.of(context),
                        ),
                      ],
                    ),
                  ),
                  if (warned)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GlyphIcon(
                        broken ? AppGlyphs.error : AppGlyphs.warning,
                        size: 14,
                        color: broken ? scheme.error : scheme.warning,
                      ),
                    ),
                  if (delay != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '$delay ms',
                        style: AppTextStyle.caption2
                            .of(context, emphasized: true)
                            .copyWith(color: scheme.delayColor(delay)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
