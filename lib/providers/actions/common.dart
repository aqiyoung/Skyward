part of '../action.dart';

@Riverpod(keepAlive: true)
class CommonAction extends _$CommonAction {
  CoreController get _core => ref.read(coreHandlerProvider);
  bool _isUpdatingTraffic = false;

  @override
  void build() {}

  void toggleRunning() {
    final running = !ref.read(isStartProvider);
    unawaited(
      globalState.safeRun(
        () => ref
            .read(setupActionProvider.notifier)
            .setRunning(
              running,
              initialize: running && !ref.read(initProvider),
            ),
      ),
    );
  }

  void updateSpeedStatistics() {
    ref
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(showTrayTitle: !state.showTrayTitle));
  }

  void updateMonochromeTrayIcon() {
    ref
        .read(appSettingProvider.notifier)
        .update(
          (state) =>
              state.copyWith(monochromeTrayIcon: !state.monochromeTrayIcon),
        );
  }

  void updateMode() {
    ref.read(patchClashConfigProvider.notifier).update((state) {
      final index = Mode.values.indexWhere((item) => item == state.mode);
      if (index == -1) return state;
      final nextIndex = index + 1 > Mode.values.length - 1 ? 0 : index + 1;
      return state.copyWith(mode: Mode.values[nextIndex]);
    });
  }

  Future<void> updateTraffic() async {
    if (_isUpdatingTraffic) {
      return;
    }
    _isUpdatingTraffic = true;
    try {
      final onlyStatisticsProxy = ref.read(
        appSettingProvider.select((state) => state.onlyStatisticsProxy),
      );
      final [traffic, totalTraffic] = await Future.wait([
        _readTraffic(() => _core.getTraffic(onlyStatisticsProxy)),
        _readTraffic(() => _core.getTotalTraffic(onlyStatisticsProxy)),
      ]);
      if (traffic != null) {
        ref.read(trafficsProvider.notifier).addTraffic(traffic);
      }
      if (totalTraffic != null) {
        ref.read(totalTrafficProvider.notifier).value = totalTraffic;
      }
    } finally {
      _isUpdatingTraffic = false;
    }
  }

  Future<Traffic?> _readTraffic(Future<Traffic> Function() request) async {
    try {
      return await request();
    } catch (error) {
      commonPrint.log(
        'updateTraffic error: $error',
        logLevel: coreFailureLogLevel(error),
      );
      return null;
    }
  }

  Future<bool> autoCheckUpdate() async {
    if (!ref.read(appSettingProvider).autoCheckUpdate) return false;
    final Map<String, dynamic>? res;
    try {
      res = await request.checkForUpdate();
      // Announcing it needs a mounted navigator, and startup does not always
      // have one yet. The handler steps aside in that case; the check itself
      // is best effort, so a failed announcement must not travel out of an
      // unawaited future.
      await checkUpdateResultHandle(data: res);
    } catch (error) {
      commonPrint.log(
        'checkForUpdate failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      return false;
    }
    return res != null;
  }

  TextSpan _releaseSpan(BuildContext context, String tagName, String? body) {
    final version = parseReleaseChangelog(body);
    return TextSpan(
      text: '$tagName \n',
      style: AppTextStyle.title2.of(context),
      children: version == null
          ? [
              TextSpan(text: '\n', style: AppTextStyle.subheadline.of(context)),
              for (final submit in parseReleaseBody(body))
                TextSpan(
                  text: '- $submit \n',
                  style: AppTextStyle.subheadline.of(context),
                ),
            ]
          : _changelogSpans(context, version),
    );
  }

  List<TextSpan> _changelogSpans(
    BuildContext context,
    ChangelogVersion version,
  ) {
    return [
      for (final group in version.visibleGroups) ...[
        TextSpan(
          text:
              '\n${changelogGroupTitle(currentAppLocalizations, group.type)}\n',
          style: AppTextStyle.subheadline
              .of(context, emphasized: true)
              .copyWith(
                color: group.type == ChangelogType.breaking
                    ? context.colorScheme.error
                    : context.colorScheme.primary,
              ),
        ),
        for (final entry in group.entries)
          TextSpan(
            text: '• ${entry.text}\n',
            style: AppTextStyle.subheadline.of(context),
          ),
      ],
    ];
  }

  /// The package that fits the device goes to the system download manager,
  /// which keeps it in the Downloads folder and shows its own progress, and
  /// opens the system installer once the download completes -- the browser
  /// is never involved on Android. The desktop has no such manager, so the
  /// release page opens there.
  Future<void> _downloadRelease(Map<String, dynamic> release) async {
    final downloader = systemDownloader;
    final abi = downloader == null ? null : await downloader.supportedAbi();
    final asset = abi == null ? null : _apkAssetOf(release, abi);
    if (downloader == null || asset == null) {
      // The offered release may be a beta or a preview, which the
      // /releases/latest page never points at -- open this release's own
      // page, falling back to the tag page, so the download offered is the
      // one that was actually found.
      final page = release['html_url'];
      final tag = release['tag_name'];
      await launchUrl(
        Uri.parse(
          page is String
              ? page
              : tag is String
                  ? 'https://github.com/$repository/releases/tag/$tag'
                  : 'https://github.com/$repository/releases/latest',
        ),
      );
      return;
    }
    try {
      await downloader.download(url: asset.url, fileName: asset.name);
      // The download itself is only announced here: its progress lives in
      // the system notification, and the installer opens on completion.
      // Reusing the existing download label keeps this free of a new
      // localization key.
      dialogs.showNotifier(
        '${currentAppLocalizations.download}: ${asset.name}',
      );
    } catch (error) {
      commonPrint.log(
        'download release failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      dialogs.showNotifier(error.toString(), level: MessageLevel.error);
    }
  }

  ({String url, String name})? _apkAssetOf(
    Map<String, dynamic> release,
    String abi,
  ) {
    final assets = release['assets'];
    if (assets is! List) {
      return null;
    }
    for (final asset in assets) {
      if (asset is! Map) {
        continue;
      }
      final name = asset['name'];
      final url = asset['browser_download_url'];
      if (name is! String || url is! String) {
        continue;
      }
      if (!name.endsWith('.apk') || !name.contains(abi)) {
        continue;
      }
      return (url: url, name: name);
    }
    return null;
  }

  Future<void> checkUpdateResultHandle({
    Map<String, dynamic>? data,
    bool isUser = false,
  }) async {
    if (data != null) {
      final context = globalState.navigatorKey.currentContext;
      if (context == null) {
        return;
      }
      final res = await dialogs.showMessage(
        title: currentAppLocalizations.discoverNewVersion,
        message: _releaseSpan(
          context,
          data['tag_name'] as String,
          data['body'] as String?,
        ),
        confirmText: currentAppLocalizations.goDownload,
        cancelText: isUser ? null : currentAppLocalizations.noLongerRemind,
      );
      if (res == true) {
        unawaited(_downloadRelease(data));
      } else if (!isUser && res == false) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(autoCheckUpdate: false));
      }
    } else if (isUser) {
      unawaited(
        dialogs.showAlert(
          title: currentAppLocalizations.checkUpdate,
          message: TextSpan(text: currentAppLocalizations.checkUpdateError),
        ),
      );
    }
  }
}
