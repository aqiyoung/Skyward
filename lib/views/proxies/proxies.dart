import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/page_large_title.dart';
import 'package:skyward/views/proxies/list.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tab.dart';

class ProxiesView extends ConsumerStatefulWidget {
  const ProxiesView({super.key, this.picker = false});

  /// Leaves the bar only its search and delay test, for picking a proxy from a
  /// sheet.
  final bool picker;

  @override
  ConsumerState<ProxiesView> createState() => _ProxiesViewState();
}

class _ProxiesViewState extends ConsumerState<ProxiesView> {
  final GlobalKey<ProxiesTabViewState> _proxiesTabKey = GlobalKey();

  // The same instance on every build, so the bar changing with the current
  // group or its delay test leaves the page alone.
  late final _tabView = ProxiesTabView(key: _proxiesTabKey);
  bool _isTab = false;

  void _updateStyle(
    ProxiesStyleProps Function(ProxiesStyleProps state) update,
  ) {
    ref.read(proxiesStyleSettingProvider.notifier).update(update);
  }

  List<CommonPopupMenuItem> _buildMenuItems(
    BuildContext context,
    ProxiesStyleProps style,
  ) {
    final appLocalizations = context.appLocalizations;
    return [
      _optionsMenuItem(
        glyph: AppGlyphs.appsList,
        label: appLocalizations.style,
        section: const CommonPopupMenuSection(),
        options: ProxiesType.values,
        value: style.type,
        textOf: (type) => type.label,
        onSelected: (type) =>
            _updateStyle((state) => state.copyWith(type: type)),
      ),
      _optionsMenuItem(
        glyph: AppGlyphs.sort,
        label: appLocalizations.sort,
        options: ProxiesSortType.values,
        value: style.sortType,
        textOf: (type) => switch (type) {
          ProxiesSortType.none => appLocalizations.defaultText,
          ProxiesSortType.delay => appLocalizations.delay,
          ProxiesSortType.name => appLocalizations.name,
        },
        onSelected: (type) =>
            _updateStyle((state) => state.copyWith(sortType: type)),
      ),
      _optionsMenuItem(
        glyph: AppGlyphs.dashboard,
        label: appLocalizations.layout,
        options: ProxiesLayout.values,
        value: style.layout,
        textOf: (layout) => switch (layout) {
          ProxiesLayout.tight => appLocalizations.tight,
          ProxiesLayout.standard => appLocalizations.standard,
          ProxiesLayout.loose => appLocalizations.loose,
        },
        onSelected: (layout) =>
            _updateStyle((state) => state.copyWith(layout: layout)),
      ),
      _optionsMenuItem(
        glyph: AppGlyphs.textSize,
        label: appLocalizations.size,
        options: ProxyCardType.values,
        value: style.cardType,
        textOf: (type) => type.label,
        onSelected: (type) =>
            _updateStyle((state) => state.copyWith(cardType: type)),
      ),
      if (style.type == ProxiesType.list)
        _optionsMenuItem(
          glyph: AppGlyphs.iconTile,
          label: appLocalizations.iconStyle,
          options: ProxiesIconStyle.values,
          value: style.iconStyle,
          textOf: (iconStyle) => switch (iconStyle) {
            ProxiesIconStyle.filled => appLocalizations.iconStyleFilled,
            ProxiesIconStyle.plain => appLocalizations.iconStylePlain,
            ProxiesIconStyle.hidden => appLocalizations.iconStyleHidden,
          },
          onSelected: (iconStyle) =>
              _updateStyle((state) => state.copyWith(iconStyle: iconStyle)),
        ),
      CommonPopupMenuItem(
        glyph: AppGlyphs.eyeOff,
        label: appLocalizations.hideTimeoutProxies,
        checked: style.hideTimeoutProxies,
        section: const CommonPopupMenuSection(),
        onPressed: () => _updateStyle(
          (state) =>
              state.copyWith(hideTimeoutProxies: !state.hideTimeoutProxies),
        ),
      ),
    ];
  }

  IconButtonData? _buildPrimaryAction() {
    if (!_isTab) {
      return null;
    }
    final isDelayTesting = ref.watch(currentGroupDelayTestingProvider);
    return IconButtonData(
      glyph: AppGlyphs.bolt,
      onPressed: () {
        _proxiesTabKey.currentState?.delayTestCurrentGroup();
      },
      tooltip: context.appLocalizations.delayTest,
      isLoading: isDelayTesting,
    );
  }

  void _onSearch(String value) {
    ref.read(queryProvider(QueryTag.proxies).notifier).value = value;
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      proxiesStyleSettingProvider.select(
        (state) => state.type == ProxiesType.tab,
      ),
      (prev, next) {
        if (prev != next) {
          setState(() {
            _isTab = next;
          });
        }
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(proxiesStyleSettingProvider);
    final isLoading = ref.watch(loadingProvider(LoadingTag.proxies));
    final picker = widget.picker;
    final primaryAction = _buildPrimaryAction();
    final menuItems = picker
        ? <CommonPopupMenuItem>[]
        : _buildMenuItems(context, style);
    final iconActions = <IconButtonData>[
      if (_isTab && !picker)
        IconButtonData(
          glyph: AppGlyphs.locate,
          onPressed: () {
            _proxiesTabKey.currentState?.scrollToGroupSelected();
          },
          tooltip: context.appLocalizations.scrollToSelected,
        ),
    ];
    // On a phone the heading and its buttons move into the page and the bar
    // is left completely empty, matching the dashboard and the global-search
    // tab. Pickers and compact sheets keep the ordinary bar so a sheet's own
    // chrome is not duplicated over a page heading.
    final largeTitle =
        ViewScope.isMobileOf(context) && !context.isInCompactSheet && !picker;
    final statusBarTop = MediaQuery.paddingOf(context).top;
    final body = switch (style.type) {
      ProxiesType.tab => _tabView,
      ProxiesType.list => const ProxiesListView(),
    };
    // The dock's search tab is now the only place to start a proxy search.
    // When a hit there filters this list, show the active term as a small
    // dismissible chip under the heading instead of a second search field.
    final proxyQuery = ref.watch(queryProvider(QueryTag.proxies));
    final subtitle = largeTitle && proxyQuery.isNotEmpty
        ? _QueryChip(
            query: proxyQuery,
            onClear: () =>
                ref.read(queryProvider(QueryTag.proxies).notifier).value = '',
          )
        : null;
    return CommonScaffold(
      isLoading: isLoading,
      resizeToAvoidBottomInset: false,
      primaryAction: largeTitle ? null : primaryAction,
      searchActions: largeTitle ? const [] : [?primaryAction],
      iconActions: largeTitle ? const [] : iconActions,
      menuItems: largeTitle ? const [] : menuItems,
      title: context.appLocalizations.proxies,
      searchState: largeTitle ? null : AppBarSearchState(onSearch: _onSearch),
      largeTitle: largeTitle,
      body: largeTitle
          ? PageLargeTitle(
              title: context.appLocalizations.proxies,
              statusBarTop: statusBarTop,
              actions: [?primaryAction, ...iconActions],
              menuItems: menuItems,
              subtitle: subtitle,
              body: body,
            )
          : body,
    );
  }
}

/// The active proxy filter, shown under the heading when a hit in the dock's
/// search tab opened this page. Tapping it clears the filter so the full list
/// comes back -- this page keeps no search field of its own any more.
class _QueryChip extends StatelessWidget {
  const _QueryChip({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 10),
      child: Semantics(
        button: true,
        label: context.appLocalizations.clearSearch,
        child: GestureDetector(
          onTap: onClear,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
            decoration: ShapeDecoration(
              color: SurfaceLevel.floatingOf(colorScheme).colorOf(colorScheme),
              shape: AppShape.all(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subheadline
                        .of(context)
                        .copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 6),
                GlyphIcon(
                  AppGlyphs.close,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

CommonPopupMenuItem _optionsMenuItem<T>({
  required Glyph glyph,
  required String label,
  required List<T> options,
  required T value,
  required String Function(T option) textOf,
  required ValueSetter<T> onSelected,
  CommonPopupMenuSection? section,
}) {
  return CommonPopupMenuItem(
    glyph: glyph,
    label: label,
    section: section,
    subItems: [
      for (final option in options)
        CommonPopupMenuItem(
          label: textOf(option),
          checked: option == value,
          onPressed: () => onSelected(option),
        ),
    ],
  );
}
