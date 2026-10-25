import 'dart:async';
import 'dart:io';

import 'package:skyward/common/common.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' show join;

class _StorageArea {
  final String title;
  final String path;
  final int size;
  final bool isCache;

  const _StorageArea({
    required this.title,
    required this.path,
    required this.size,
    this.isCache = false,
  });
}

/// What the app keeps on disk, area by area, so a reader can see which one grew
/// and reclaim the two that are only ever a cache.
class StorageView extends StatefulWidget {
  const StorageView({super.key});

  @override
  State<StorageView> createState() => _StorageViewState();
}

class _StorageViewState extends State<StorageView> {
  List<_StorageArea>? _areas;
  String? _locale;

  /// Set while the caches are being emptied. A second tap would delete the
  /// directory the first one has already recreated, so the row steps out of the
  /// way until this one is done.
  var _clearing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    if (locale == _locale) {
      return;
    }
    _locale = locale;
    unawaited(_measure());
  }

  Future<void> _measure() async {
    final appLocalizations = context.appLocalizations;
    final homeDirPath = await appPath.homeDirPath;
    final paths = [
      (
        appLocalizations.profiles,
        join(homeDirPath, profilesDirectoryName),
        false,
      ),
      (appLocalizations.cache, join(homeDirPath, providersDirectoryName), true),
      (appLocalizations.script, await appPath.scriptsDirPath, false),
      (appLocalizations.database, await appPath.databasePath, false),
      (appLocalizations.temporary, await appPath.tempPath, true),
    ];
    final areas = await Future.wait([
      for (final (title, path, isCache) in paths)
        pathSize(path).then(
          (size) => _StorageArea(
            title: title,
            path: path,
            size: size,
            isCache: isCache,
          ),
        ),
    ]);
    if (!mounted) {
      return;
    }
    setState(() => _areas = areas);
  }

  Future<void> _clearCaches() async {
    final appLocalizations = context.appLocalizations;
    final areas = _areas?.where((area) => area.isCache).toList() ?? [];
    if (areas.isEmpty) {
      return;
    }
    final confirmed = await dialogs.showMessage(
      title: appLocalizations.clearCache,
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.cache),
      ),
      confirmText: appLocalizations.delete,
      destructive: true,
    );
    if (confirmed != true) {
      return;
    }
    await globalState.safeRun<void>(
      () async {
        for (final area in areas) {
          final directory = Directory(area.path);
          if (await directory.exists()) {
            await directory.delete(recursive: true);
          }
          await directory.create(recursive: true);
        }
      },
      title: appLocalizations.clearCache,
      onStart: () {
        if (mounted) setState(() => _clearing = true);
      },
      onEnd: () {
        if (mounted) setState(() => _clearing = false);
      },
    );
    if (!mounted) {
      return;
    }
    await _measure();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final areas = _areas;
    return BaseScaffold(
      title: appLocalizations.storage,
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(top: context.contentTopPadding, bottom: 16),
        children: [
          generateSection(
            items: [
              for (final area in areas ?? const <_StorageArea>[])
                ListItem(
                  title: Text(area.title),
                  trailing: Text(
                    area.size.traffic.show,
                    style: context.listSubtitleStyle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          generateSection(
            items: [
              ListItem(
                title: Text(appLocalizations.clearCache),
                leading: const GlyphIcon(AppGlyphs.broom),
                onTap: areas == null || _clearing ? null : _clearCaches,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
