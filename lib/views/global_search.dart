import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/config/settings_index.dart';
import 'package:skyward/views/page_large_title.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fifth mobile tab: one index over everything the app can open.
///
/// Four kinds of result share the field: the tabs in the dock, the proxy
/// nodes behind the proxies tab, the tool entries that used to hide in
/// "More", and the settings rows from the settings search. Typing filters
/// all of them at once, so a page or a node that is not in the dock is still
/// one query away. The heading and the search field live in the same fixed
/// [PageLargeTitle] block every other phone tab uses -- the bar carries no
/// title, nothing floats over the content, and the results alone scroll.
///
/// Proxy nodes are deliberately absent while the field is empty: a profile
/// can hold hundreds of them, and an idle global search should read as a
/// short table of contents, not a dump of the whole config.
const int _maxProxyHits = 8;

class GlobalSearchView extends ConsumerStatefulWidget {
  const GlobalSearchView({super.key});

  @override
  ConsumerState<GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends ConsumerState<GlobalSearchView> {
  var _query = SearchQuery('');

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    // Read the real status-bar inset above the scaffold: inside the body,
    // extendBodyBehindAppBar changes what MediaQuery's top padding means.
    final statusBarTop = MediaQuery.paddingOf(context).top;

    // Only the tabs actually in the dock are worth a "go to tab" result;
    // tool entries keep their builders even when their mode is hidden.
    final dockItems = ref.watch(currentNavigationItemsStateProvider).value;
    final allItems = ref.watch(navigationItemsStateProvider).value;
    final groups = ref.watch(groupsProvider);

    final pageHits = <_Hit>[
      for (final item in dockItems)
        _Hit(
          [item.label.label, appLocalizations.pagesLabel, _keywordsOf(item.label)],
          (context) => ListItem(
            leading: IconWell(item.glyph),
            title: Text(item.label.label),
            subtitle: Text(appLocalizations.pagesLabel),
            arrow: true,
            onTap: () => ref
                .read(currentPageLabelProvider.notifier)
                .toPage(item.label),
          ),
        ),
    ];

    const toolLabels = {
      PageLabel.requests,
      PageLabel.connections,
      PageLabel.dns,
      PageLabel.resources,
      PageLabel.logs,
    };
    final toolHits = <_Hit>[
      for (final item in allItems)
        if (toolLabels.contains(item.label))
          _Hit(
            [
              item.label.label,
              appLocalizations.toolEntries,
              _keywordsOf(item.label),
            ],
            (context) => ListItem.open(
              leading: IconWell(item.glyph),
              title: Text(item.label.label),
              subtitle: Text(appLocalizations.toolEntries),
              widget: item.builder(context),
              forceFull: item.modes.contains(NavigationItemMode.moreFull),
            ),
          ),
    ];

    final settingsHits = <_Hit>[
      for (final entry in settingsEntries)
        _Hit(
          [
            ...entry.fieldsOf(appLocalizations),
            appLocalizations.settings,
          ],
          (context) => ListItem.open(
            leading: const IconWell(AppGlyphs.settings),
            title: Text(entry.title(appLocalizations)),
            subtitle: Text(entry.page(appLocalizations)),
            widget: entry.view(context),
          ),
        ),
    ];

    List<Widget> section(String title, List<_Hit> hits) {
      final matched = hits
          .where((hit) => _query.matches(hit.fields))
          .map((hit) => hit.builder(context))
          .toList();
      if (matched.isEmpty) return const [];
      return [generateSection(title: title, items: matched)];
    }

    /// A hit opens the proxies tab already filtered to that node. The tab's
    /// own list reads the same query provider, so no second search field is
    /// needed there -- the dock's search tab is the one place to search.
    List<Widget> proxySection() {
      if (_query.isEmpty) return const [];
      final matched = <Widget>[];
      final seen = <String>{};
      for (final group in groups) {
        for (final proxy in group.all) {
          if (!seen.add(proxy.name)) continue;
          if (!_query.matches([proxy.name, proxy.type, group.name])) continue;
          matched.add(
            ListItem(
              leading: const IconWell(AppGlyphs.proxies),
              title: Text(proxy.name),
              subtitle: Text(group.name),
              arrow: true,
              onTap: () {
                ref
                    .read(queryProvider(QueryTag.proxies).notifier)
                    .value = proxy.name;
                ref
                    .read(currentPageLabelProvider.notifier)
                    .toPage(PageLabel.proxies);
              },
            ),
          );
          if (matched.length == _maxProxyHits) break;
        }
        if (matched.length == _maxProxyHits) break;
      }
      if (matched.isEmpty) return const [];
      return [generateSection(title: appLocalizations.nodes, items: matched)];
    }

    final results = <Widget>[
      ...section(appLocalizations.pagesLabel, pageHits),
      ...proxySection(),
      ...section(appLocalizations.toolEntries, toolHits),
      ...section(appLocalizations.settings, settingsHits),
    ];

    return CommonScaffold(
      rowSeparators: false,
      title: appLocalizations.search,
      largeTitle: true,
      body: PageLargeTitle(
        title: appLocalizations.search,
        statusBarTop: statusBarTop,
        searchHint: appLocalizations.searchHint,
        onSearch: (value) => setState(() => _query = SearchQuery(value)),
        body: ListView(
          padding: EdgeInsets.only(bottom: 20 + context.bottomInset),
          children: [
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: EmptyState(
                  glyph: AppGlyphs.search,
                  title: appLocalizations.noSearchResults,
                ),
              )
            else
              ...results,
          ],
        ),
      ),
    );
  }
}

/// One index row: the text [query] matches and the row it becomes when it
/// does. Keeping the builder rather than a built widget means only the hits
/// are constructed, and a hit can open a page that is not in the dock.
class _Hit {
  const _Hit(this.fields, this.builder);

  final List<String?> fields;
  final Widget Function(BuildContext context) builder;
}

/// A few extra words so a reader can find a page by what it does, in English
/// as well as in the UI's own language.
String? _keywordsOf(PageLabel label) => switch (label) {
  PageLabel.dashboard => 'home status overview 首页 状态',
  PageLabel.proxies => 'proxy node group 节点 组',
  PageLabel.profiles => 'profile subscription config 订阅 文件',
  PageLabel.mine => 'me settings account preferences 设置 外观',
  PageLabel.search => 'find 查找',
  PageLabel.requests => 'request history 请求',
  PageLabel.connections => 'connection live 连接',
  PageLabel.dns => 'dns query domain 域名 解析',
  PageLabel.resources => 'resource rule 资源',
  PageLabel.logs => 'log 日志',
  _ => null,
};
