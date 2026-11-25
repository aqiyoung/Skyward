import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/features/features.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/about.dart';
import 'package:skyward/views/appearance.dart';
import 'package:skyward/views/backup_and_restore.dart';
import 'package:skyward/views/config/diagnostics.dart';
import 'package:skyward/views/config/general.dart';
import 'package:skyward/views/hotkey.dart';
import 'package:skyward/views/page_large_title.dart';
import 'package:skyward/views/update_sheet.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/advanced.dart';
import 'config/network.dart';
import 'developer.dart';

class ToolsView extends ConsumerStatefulWidget {
  const ToolsView({super.key, this.label = PageLabel.tools});

  /// Which dock label this page was opened under. The dashboard's mobile
  /// fourth tab calls it "Mine", so the heading follows that label instead of
  /// the old "More". Desktop keeps the default. Global search now lives in
  /// its own tab, so this page no longer carries a settings-only search
  /// button in the bar.
  final PageLabel label;

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

  /// Settings, as upstream groups them: everything that changes how the app
  /// behaves, in one card under one caption. The footnote explains the rows
  /// that sit inside it.
  Widget _getSettingList(bool enableDeveloperMode) {
    final appLocalizations = context.appLocalizations;
    return generateSection(
      title: appLocalizations.settings,
      items: [
        const _PreferencesItem(),
        const _NetworkItem(),
        if (system.isDesktop) const _HotkeyItem(),
        const _BackupItem(),
        const _GeneralItem(),
        const _AdvancedConfigItem(),
        const _DiagnosticsItem(),
        if (enableDeveloperMode) const _DeveloperItem(),
      ],
      footer: appLocalizations.advancedConfigDesc,
    );
  }

  /// What the tab ends on: one way into the about page, and the build it is —
  /// the row that also asks whether a newer one exists.
  Widget _getAboutList() {
    final appLocalizations = context.appLocalizations;
    return generateSection(
      items: [
        ListItem.open(
          title: Text('${appLocalizations.about} $appName'),
          widget: const AboutView(),
        ),
        const _VersionItem(),
      ],
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
            leadingGap: false,
            items: state.navigationItems.map(_buildNavigationMenuItem),
          );
        },
      ),
      _getSettingList(developerMode),
      _getAboutList(),
    ];
    // On a phone the heading moves into the page and the bar is left empty.
    // Desktop and compact sheets keep the ordinary bar title and layout.
    final largeTitle =
        ViewScope.isMobileOf(context) && !context.isInCompactSheet;
    final statusBarTop = MediaQuery.paddingOf(context).top;
    final body = Builder(
      builder: (context) => ListView.builder(
        key: toolsStoreKey,
        itemCount: items.length,
        itemBuilder: (_, index) => items[index],
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: context.cardTopPadding,
          bottom: 20 + context.bottomInset,
        ),
      ),
    );
    return CommonScaffold(
      rowSeparators: false,
      title: widget.label.label,
      largeTitle: largeTitle,
      body: largeTitle
          ? PageLargeTitle(
              title: widget.label.label,
              statusBarTop: statusBarTop,
              body: body,
            )
          : body,
    );
  }
}

/// The build a reader is running. Tapping it opens the animated update sheet,
/// where the check, result and next action all live.
class _VersionItem extends ConsumerWidget {
  const _VersionItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final downloading = ref.watch(loadingProvider(LoadingTag.updateDownload));
    final version = globalState.hasPackageInfo
        ? globalState.packageInfo.labeledVersion
        : null;
    final text = downloading
        ? appLocalizations.versionUpdateDownloading
        : version;
    Future<void> checkUpdate() async {
      if (ref.read(commonActionProvider.notifier).isDownloadingUpdate) {
        return;
      }
      final prefs = await loadUpdatePreferences();
      final channel = effectiveUpdateChannel(
        configured: prefs.channel,
        isPreBuild: globalState.isPre,
      );
      await showUpdateSheet(
        context,
        check: () => request.checkForUpdate(channel),
      );
    }

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
      onTap: checkUpdate,
    );
  }
}

class _PreferencesItem extends StatelessWidget {
  const _PreferencesItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const IconWell(AppGlyphs.sliders),
      title: Text(context.appLocalizations.preferences),
      widget: const AppearanceView(),
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

class _NetworkItem extends StatelessWidget {
  const _NetworkItem();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return ListItem.open(
      leading: const IconWell(AppGlyphs.key),
      title: Text(appLocalizations.network),
      widget: BaseScaffold(
        rowSeparators: false,
        title: appLocalizations.network,
        body: const NetworkListView(),
      ),
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
