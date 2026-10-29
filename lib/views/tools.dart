import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/about.dart';
import 'package:skyward/views/access.dart';
import 'package:skyward/views/backup_and_restore.dart';
import 'package:skyward/views/config/diagnostics.dart';
import 'package:skyward/views/config/general.dart';
import 'package:skyward/views/config/storage.dart';
import 'package:skyward/views/hotkey.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/advanced.dart';
import 'config/custom_resources.dart';
import 'config/settings_search.dart';
import 'developer.dart';
import 'theme.dart';

class ToolsView extends ConsumerStatefulWidget {
  const ToolsView({super.key});

  @override
  ConsumerState<ToolsView> createState() => _ToolViewState();
}

class _ToolViewState extends ConsumerState<ToolsView> {
  Widget _buildNavigationMenuItem(NavigationItem navigationItem) {
    return ListItem.open(
      leading: IconWell(navigationItem.glyph),
      title: Text(navigationItem.label.label),
      widget: navigationItem.builder(context),
      forceFull: navigationItem.modes.contains(NavigationItemMode.moreFull),
    );
  }

  /// What the tab ends on: one way into the about page, the build it is — the
  /// row that also asks whether a newer one exists — and the two lines the
  /// licence asks a reader to be able to find.
  Widget _getAboutList() {
    final appLocalizations = context.appLocalizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        generateSection(
          items: [
            ListItem.open(
              title: Text('${appLocalizations.about} $appName'),
              widget: const AboutView(),
            ),
            const _VersionItem(),
          ],
        ),
        const _CopyrightNotice(),
      ],
    );
  }

  Widget _getSettingList(bool enableDeveloperMode) {
    final appLocalizations = context.appLocalizations;
    return generateSection(
      items: [
        const _SettingsSearchItem(),
        const _LocaleItem(),
        const _ThemeItem(),
        const _BackupItem(),
        const _StorageItem(),
        const _DiagnosticsItem(),
        if (system.isDesktop) const _HotkeyItem(),
        if (system.isAndroid) const _AccessItem(),
        const _AdvancedConfigItem(),
        const _CustomResourcesItem(),
        const _GeneralItem(),
        if (enableDeveloperMode) const _DeveloperItem(),
      ],
      footer: [
        if (system.isAndroid) appLocalizations.accessControlDesc,
        appLocalizations.advancedConfigDesc,
        appLocalizations.customProfileResourcesDesc,
      ].join('\n'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final developerMode = ref.watch(
      appSettingProvider.select((state) => state.developerMode),
    );
    final items = [
      Consumer(
        builder: (_, ref, _) {
          final state = ref.watch(moreToolsSelectorStateProvider);
          if (state.navigationItems.isEmpty) {
            return Container();
          }
          return generateSection(
            items: state.navigationItems.map(_buildNavigationMenuItem),
          );
        },
      ),
      _getSettingList(developerMode),
      _getAboutList(),
    ];
    return CommonScaffold(
      title: context.appLocalizations.tools,
      body: Builder(
        builder: (context) => ListView.builder(
          key: toolsStoreKey,
          itemCount: items.length,
          itemBuilder: (_, index) => items[index],
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: context.sectionTopPadding,
            bottom: 20 + context.bottomInset,
          ),
        ),
      ),
    );
  }
}

enum _VersionCheck { checking, latest, found, failed }

/// The build a reader is running, and the way to ask for the next one: the
/// version sits on the right where a value belongs, and the chevron after it
/// says the row does something. While a check runs -- or a found package
/// downloads -- the version is what is no longer the news, so the row carries
/// the check's own word there instead, and goes back to naming the build once
/// that word has been read.
class _VersionItem extends ConsumerStatefulWidget {
  const _VersionItem();

  @override
  ConsumerState<_VersionItem> createState() => _VersionItemState();
}

class _VersionItemState extends ConsumerState<_VersionItem> {
  /// How long a finished check keeps the right-hand side: long enough to be
  /// read once, not so long that the version stays hidden behind it.
  static const _hold = Duration(seconds: 4);

  _VersionCheck? _check;
  Timer? _holdTimer;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  /// Puts [check] on the row. A finished check is left there for [_hold] and
  /// then gives the row back to the version; "checking" stays until it lands.
  void _show(_VersionCheck check) {
    _holdTimer?.cancel();
    if (check != _VersionCheck.checking) {
      _holdTimer = Timer(_hold, () {
        if (!mounted) return;
        setState(() => _check = null);
      });
    }
    setState(() => _check = check);
  }

  /// The check runs in place, the way it did on the about page it was moved
  /// from: no dialog, no banner over the page. A release found starts its
  /// download in the background, and the row says so for as long as it lasts.
  Future<void> _checkUpdate() async {
    // One check at a time, and none over the top of a download already
    // running: the row would go back to naming a release it is fetching.
    if (_check == _VersionCheck.checking ||
        ref.read(commonActionProvider.notifier).isDownloadingUpdate) {
      return;
    }
    _show(_VersionCheck.checking);
    final Map<String, dynamic>? release;
    try {
      release = await request.checkForUpdate();
    } catch (_) {
      if (!mounted) return;
      _show(_VersionCheck.failed);
      return;
    }
    if (!mounted) return;
    if (release == null) {
      _show(_VersionCheck.latest);
      return;
    }
    _show(_VersionCheck.found);
    unawaited(
      ref
          .read(commonActionProvider.notifier)
          .checkUpdateResultHandle(data: release, silent: true),
    );
  }

  String? _checkText(AppLocalizations appLocalizations) => switch (_check) {
    _VersionCheck.checking => appLocalizations.versionUpdateChecking,
    _VersionCheck.latest => appLocalizations.versionUpdateLatest,
    _VersionCheck.found => appLocalizations.versionUpdateFound,
    _VersionCheck.failed => appLocalizations.versionUpdateFailed,
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    // A package on its way is not a find to announce: once the release has
    // been handed to the download, the row says what is happening instead of
    // naming the version for the minutes that takes.
    final downloading = ref.watch(loadingProvider(LoadingTag.updateDownload));
    final version = globalState.hasPackageInfo
        ? globalState.packageInfo.displayVersion
        : null;
    final text = downloading
        ? appLocalizations.versionUpdateDownloading
        : _checkText(appLocalizations) ?? version;
    return ListItem(
      title: Text(appLocalizations.currentVersion),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (text != null) ...[
            Text(
              text,
              style: context.listSubtitleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 8),
          ],
          const GlyphIcon(AppGlyphs.chevronForward),
        ],
      ),
      onTap: _checkUpdate,
    );
  }
}

class _LocaleItem extends ConsumerWidget {
  const _LocaleItem();

  String _getLocaleString(BuildContext context, Locale? locale) {
    if (locale == null) return context.appLocalizations.defaultText;
    return locale.label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(
      appSettingProvider.select((state) => state.locale),
    );
    final currentLocale = getLocaleForString(locale);
    return ListItem<Locale?>.options(
      leading: const IconWell(AppGlyphs.language),
      title: Text(context.appLocalizations.language),
      options: [null, ...AppLocalizations.delegate.supportedLocales],
      onChanged: (Locale? locale) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(locale: locale?.toString()));
      },
      textBuilder: (locale) => _getLocaleString(context, locale),
      value: currentLocale,
    );
  }
}

class _ThemeItem extends StatelessWidget {
  const _ThemeItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const IconWell(AppGlyphs.paintbrush),
      title: Text(context.appLocalizations.theme),
      widget: const ThemeView(),
    );
  }
}

class _StorageItem extends StatelessWidget {
  const _StorageItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const IconWell(AppGlyphs.dataUsage),
      title: Text(context.appLocalizations.storage),
      widget: const StorageView(),
    );
  }
}

class _DiagnosticsItem extends StatelessWidget {
  const _DiagnosticsItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const IconWell(AppGlyphs.status),
      title: Text(context.appLocalizations.diagnostics),
      widget: const DiagnosticsView(),
    );
  }
}

class _BackupItem extends StatelessWidget {
  const _BackupItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const IconWell(AppGlyphs.cloudSync),
      title: Text(context.appLocalizations.backupAndRestore),
      widget: const BackupAndRestore(),
    );
  }
}

class _SettingsSearchItem extends StatelessWidget {
  const _SettingsSearchItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const IconWell(AppGlyphs.search),
      title: Text(context.appLocalizations.search),
      widget: const SettingsSearchView(),
    );
  }
}

class _HotkeyItem extends StatelessWidget {
  const _HotkeyItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const IconWell(AppGlyphs.keyboard),
      title: Text(context.appLocalizations.hotkeyManagement),
      widget: const HotKeyView(),
    );
  }
}

class _AccessItem extends StatelessWidget {
  const _AccessItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const IconWell(AppGlyphs.appsList),
      title: Text(context.appLocalizations.accessControl),
      widget: const AccessView(),
    );
  }
}

class _GeneralItem extends StatelessWidget {
  const _GeneralItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const IconWell(AppGlyphs.settings),
      title: Text(context.appLocalizations.general),
      widget: const GeneralView(),
    );
  }
}

class _AdvancedConfigItem extends StatelessWidget {
  const _AdvancedConfigItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const IconWell(AppGlyphs.wrench),
      title: Text(context.appLocalizations.advancedConfig),
      widget: const AdvancedConfigView(),
    );
  }
}

class _CustomResourcesItem extends StatelessWidget {
  const _CustomResourcesItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const IconWell(AppGlyphs.customize),
      title: Text(context.appLocalizations.customProfileResources),
      widget: const CustomResourcesView(),
    );
  }
}

/// The two lines a build owes the reader: who ships it, and the licence it
/// travels under. Set apart from the card above by air, the way the system
/// settings pages end.
class _CopyrightNotice extends StatelessWidget {
  const _CopyrightNotice();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyle.caption1
        .of(context)
        .copyWith(color: context.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Text('Copyright © ${DateTime.now().year} threely', style: style),
          const SizedBox(height: 2),
          Text('GPL-3.0', style: style),
        ],
      ),
    );
  }
}

class _DeveloperItem extends StatelessWidget {
  const _DeveloperItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const IconWell(AppGlyphs.cpu),
      title: Text(context.appLocalizations.developerMode),
      widget: const DeveloperView(),
    );
  }
}
