import 'package:skyward/common/app_ports.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/ui/icons/app_glyphs.dart';
import 'package:skyward/views/views.dart';
import 'package:material_ui/material_ui.dart';

class Navigation implements NavigationPort {
  static Navigation? _instance;

  @override
  List<NavigationItem> getItems({
    bool openLogs = false,
    bool hasProxies = false,
  }) {
    return [
      NavigationItem(
        glyph: AppGlyphs.dashboard,
        label: PageLabel.dashboard,
        builder: (_) =>
            const DashboardView(key: GlobalObjectKey(PageLabel.dashboard)),
      ),
      NavigationItem(
        glyph: AppGlyphs.proxies,
        label: PageLabel.proxies,
        builder: (_) =>
            const ProxiesView(key: GlobalObjectKey(PageLabel.proxies)),
        modes: hasProxies
            ? [NavigationItemMode.mobile, NavigationItemMode.desktop]
            : [],
      ),
      NavigationItem(
        glyph: AppGlyphs.profiles,
        label: PageLabel.profiles,
        builder: (_) =>
            const ProfilesView(key: GlobalObjectKey(PageLabel.profiles)),
      ),
      NavigationItem(
        glyph: AppGlyphs.requests,
        label: PageLabel.requests,
        builder: (_) =>
            const RequestsView(key: GlobalObjectKey(PageLabel.requests)),
        modes: [NavigationItemMode.moreFull],
      ),
      NavigationItem(
        glyph: AppGlyphs.connections,
        label: PageLabel.connections,
        builder: (_) =>
            const ConnectionsView(key: GlobalObjectKey(PageLabel.connections)),
        modes: [NavigationItemMode.desktop, NavigationItemMode.moreFull],
      ),
      NavigationItem(
        glyph: AppGlyphs.dns,
        label: PageLabel.dns,
        builder: (_) =>
            const DnsQueriesView(key: GlobalObjectKey(PageLabel.dns)),
        modes: [NavigationItemMode.moreFull],
      ),
      NavigationItem(
        glyph: AppGlyphs.resources,
        label: PageLabel.resources,
        builder: (_) =>
            const ResourcesView(key: GlobalObjectKey(PageLabel.resources)),
        modes: [NavigationItemMode.more],
      ),
      NavigationItem(
        glyph: AppGlyphs.logs,
        label: PageLabel.logs,
        builder: (_) => const LogsView(key: GlobalObjectKey(PageLabel.logs)),
        modes: openLogs
            ? [NavigationItemMode.desktop, NavigationItemMode.more]
            : [],
      ),
      // The global search: one index over pages, tool entries and settings.
      // Fourth in the mobile row, immediately before "Mine": the three pages
      // ahead of it are the walk through the app, while the settings centre
      // stays the corner a row is expected to end on. Desktop keeps its
      // sidebar, so this is mobile-only.
      NavigationItem(
        glyph: AppGlyphs.search,
        label: PageLabel.search,
        builder: (_) =>
            const GlobalSearchView(key: GlobalObjectKey(PageLabel.search)),
        modes: [NavigationItemMode.mobile],
      ),
      // "Mine" is the settings centre: the former tools page (tool entries +
      // settings + about) under a label and glyph that read as one's own. It
      // keeps both modes, so the desktop sidebar only changes its label.
      NavigationItem(
        glyph: AppGlyphs.account,
        label: PageLabel.mine,
        builder: (_) => const ToolsView(
          key: GlobalObjectKey(PageLabel.mine),
          label: PageLabel.mine,
        ),
        modes: [NavigationItemMode.desktop, NavigationItemMode.mobile],
      ),
    ];
  }

  Navigation._internal();

  factory Navigation() {
    _instance ??= Navigation._internal();
    return _instance!;
  }
}

final navigation = Navigation();
