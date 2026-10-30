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

  /// The download id of an update that is already running in the
  /// background, if any: a second tap while one runs must not start a
  /// duplicate download, and there is no dialog to tell the user apart.
  int? _ongoingUpdateDownloadId;

  /// The package that fits the device goes to the system download manager,
  /// which keeps it in the Downloads folder, while the app itself polls
  /// that manager in the background and opens the system installer once
  /// the download completes -- the browser is never involved on Android.
  /// Nothing modal is shown while it downloads, so the app stays usable
  /// throughout. The desktop has no such manager, so the release page
  /// opens there.
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
    if (_ongoingUpdateDownloadId != null) {
      // A background download is already running: starting another one
      // would download the same file twice, and with no dialog there is
      // no place to ask which one to keep.
      return;
    }
    try {
      final downloadId = await downloader.download(
        url: asset.url,
        fileName: asset.name,
        expectedSha256: asset.sha256,
      );
      if (downloadId == null) {
        throw StateError('download did not start');
      }
      _ongoingUpdateDownloadId = downloadId;
      // No dialog, no banner while it downloads: the download runs in
      // the background through the system download manager, the app
      // stays fully usable, and only the installer opens at the end.
      // The manager's own notification is the progress view, and it
      // remains the fallback if the app is gone when the download ends.
      //
      // The tag is what the About row reads instead of offering the
      // release again: a package on its way is not a new find.
      ref.read(loadingProvider(LoadingTag.updateDownload).notifier).start();
      await _waitForAndroidDownload(downloader, downloadId, asset.name);
    } catch (error) {
      commonPrint.log(
        'download release failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      dialogs.showNotifier(error.toString(), level: MessageLevel.error);
    } finally {
      _ongoingUpdateDownloadId = null;
      unawaited(
        ref.read(loadingProvider(LoadingTag.updateDownload).notifier).stop(),
      );
    }
  }

  /// Whether an update package is on its way right now. The row that started
  /// it can be rebuilt by navigation while the download runs, and a second tap
  /// there must not set off another check over the top of it.
  bool get isDownloadingUpdate => _ongoingUpdateDownloadId != null;

  /// Polls the system download manager every half second in the
  /// background, with no dialog and no banner while it runs, so the user
  /// can keep using the app throughout the download. The only things
  /// that ever surface are the system installer's own window on success
  /// (opened by the download-complete receiver, with the install call
  /// below as backup) and a non-modal error banner on failure, which
  /// does not block the app either. Cancelling happens from the system
  /// download notification, since there is no dialog left to cancel from:
  /// a download that disappears from the manager is reported as failed.
  Future<void> _waitForAndroidDownload(
    SystemDownloader downloader,
    int downloadId,
    String fileName,
  ) async {
    var failed = false;
    try {
      while (true) {
        await Future.delayed(const Duration(milliseconds: 500));
        final status = await downloader.status(downloadId);
        if (status == null || status.isFailed) {
          failed = true;
          break;
        }
        if (status.isSuccessful) {
          break;
        }
      }
    } catch (error) {
      commonPrint.log(
        'download progress poll failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      failed = true;
    }
    if (failed) {
      dialogs.showNotifier(
        '${currentAppLocalizations.download}: $fileName',
        level: MessageLevel.error,
      );
      return;
    }
    // The download-complete receiver normally opens the installer the
    // moment the download finishes; this is only the backup for when it
    // did not, and the native side makes it a no-op when it already did.
    await downloader.install(downloadId);
  }

  ({String url, String name, String? sha256})? _apkAssetOf(
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
      return (
        url: url,
        name: name,
        sha256: releaseApkSha256(release['body'], name),
      );
    }
    return null;
  }

  Future<void> checkUpdateResultHandle({
    Map<String, dynamic>? data,
    bool isUser = false,
    // Silent callers (the version row on the tools tab) get no
    // "already latest" alert. A new release still asks for confirmation
    // before its background download starts, so a stray tap never pulls
    // an APK on its own. Startup auto-check is unaffected.
    bool silent = false,
  }) async {
    if (data != null) {
      final context = globalState.navigatorKey.currentContext;
      if (context == null) {
        return;
      }
      // Two buttons only, in this order: Cancel, then Update. The old
      // confirm text said "go to download", which no longer describes
      // what happens: Android downloads in-app through the system
      // download manager, and the desktop opens the release page. The
      // old auto-check cancel slot said "no longer remind", so tapping
      // it silently turned auto-check off; that toggle now lives only
      // in Settings, and Cancel here means just this once, not again.
      final res = await dialogs.showMessage(
        title: currentAppLocalizations.discoverNewVersion,
        message: _releaseSpan(
          context,
          data['tag_name'] as String,
          data['body'] as String?,
        ),
        confirmText: currentAppLocalizations.update,
      );
      if (res == true) {
        unawaited(_downloadRelease(data));
      }
    } else if (isUser && !silent) {
      unawaited(
        dialogs.showAlert(
          title: currentAppLocalizations.checkUpdate,
          message: TextSpan(text: currentAppLocalizations.checkUpdateError),
        ),
      );
    }
  }
}
