import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/config/settings_index.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fifth mobile tab: one index over everything the app can open.
///
/// Three kinds of result share the field: the tabs in the dock, the tool
/// entries that used to hide in "More", and the settings rows from the
/// settings search. Typing filters all three at once, so a page that is not
/// in the dock is still one query away. The heading is a fixed block in the
/// scrolling body -- the bar carries no title and nothing floats over the
/// content when the page scrolls, the same shape as the dashboard.
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
    final colorScheme = Theme.of(context).colorScheme;
    // Read the real status-bar inset above the scaffold: inside the body,
    // extendBodyBehindAppBar changes what MediaQuery's top padding means.
    final statusBarTop = MediaQuery.paddingOf(context).top;

    // Only the tabs actually in the dock are worth a "go to tab" result;
    // tool entries keep their builders even when their mode is hidden.
    final dockItems = ref.watch(currentNavigationItemsStateProvider).value;
    final allItems = ref.watch(navigationItemsStateProvider).value;

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

    final results = <Widget>[
      ...section(appLocalizations.pagesLabel, pageHits),
      ...section(appLocalizations.toolEntries, toolHits),
      ...section(appLocalizations.settings, settingsHits),
    ];

    return CommonScaffold(
      rowSeparators: false,
      title: appLocalizations.search,
      largeTitle: true,
      body: ListView(
        padding: EdgeInsets.only(
          top: statusBarTop + 12,
          bottom: 20 + context.bottomInset,
        ),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(22, 4, 22, 0),
            child: Text(
              appLocalizations.search,
              style: AppTextStyle.largeTitle.of(context, emphasized: true),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InputDecorationTheme(
              data: searchPillTheme(context),
              child: SearchField(
                hintText: appLocalizations.searchHint,
                fill: SurfaceLevel.floatingOf(
                  colorScheme,
                ).colorOf(colorScheme),
                onChanged: (value) =>
                    setState(() => _query = SearchQuery(value)),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
