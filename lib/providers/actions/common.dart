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
  /// which keeps it in the Downloads folder, while the app itself polls
  /// that manager and shows the progress in a persistent dialog, and
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
      final downloadId = await downloader.download(
        url: asset.url,
        fileName: asset.name,
      );
      if (downloadId == null) {
        throw StateError('download did not start');
      }
      // The download's progress lives here, in the app, not in a banner
      // that flashes away or in the system notification: the dialog below
      // stays open until the download finishes, fails, or is cancelled,
      // and only then does the system installer open.
      await _showAndroidDownloadProgress(downloader, downloadId, asset.name);
    } catch (error) {
      commonPrint.log(
        'download release failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      dialogs.showNotifier(error.toString(), level: MessageLevel.error);
    }
  }

  /// Polls the system download manager every half second and drives a
  /// persistent in-app progress dialog. The dialog is not dismissible by
  /// tapping outside it, so a download cannot silently disappear behind a
  /// flashing banner: it ends only in a finished download, a failure, or
  /// an explicit cancel, which also cancels the manager's download.
  /// Reusing the existing download and cancel labels keeps this free of a
  /// new localization key; the numbers in the dialog need no translation.
  Future<void> _showAndroidDownloadProgress(
    SystemDownloader downloader,
    int downloadId,
    String fileName,
  ) async {
    final progress = ValueNotifier<DownloadStatus>(
      const DownloadStatus(state: 'pending', downloadedBytes: 0, totalBytes: -1),
    );
    var finished = false;
    var failed = false;
    var cancelled = false;
    var dialogOpen = false;
    var dialogDone = false;
    BuildContext? dialogContext;
    final dialogFuture = dialogs.showCommonDialog<void>(
      dismissible: false,
      child: Builder(
        builder: (context) {
          dialogContext = context;
          // Set here, not after the wait loop: if the user cancels while
          // the loop is still waiting, the dialog's own close handler
          // clears this, and the loop must not set it back and then pop
          // whatever page is underneath.
          dialogOpen = true;
          final appLocalizations = context.appLocalizations;
          return CommonDialog(
            title: appLocalizations.download,
            actions: [
              TextButton(
                onPressed: () {
                  cancelled = true;
                  Navigator.of(context).pop();
                },
                child: Text(appLocalizations.cancel),
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(fileName, textAlign: TextAlign.center),
                ValueListenableBuilder<DownloadStatus>(
                  valueListenable: progress,
                  builder: (context, status, _) {
                    final total = status.totalBytes;
                    final downloaded = status.downloadedBytes;
                    final percent = status.progress;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        LinearProgressIndicator(value: percent),
                        Text(
                          total > 0
                              ? '${_formatMegabytes(downloaded)} / '
                                  '${_formatMegabytes(total)}'
                                  '${percent == null ? '' : ' • ${(percent * 100).toStringAsFixed(0)}%'}'
                              : _formatMegabytes(downloaded),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
    unawaited(
      dialogFuture.then((_) {
        dialogOpen = false;
        dialogDone = true;
        if (!finished) {
          // The dialog closed some other way: stop polling with it.
          cancelled = true;
        }
      }),
    );
    // The dialog future resolves only after the route is pushed, so wait
    // for the builder to capture its context before polling can pop it.
    while (dialogContext == null && !cancelled && !dialogDone) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    try {
      while (!cancelled) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (cancelled) {
          break;
        }
        final status = await downloader.status(downloadId);
        if (status == null) {
          failed = true;
          finished = true;
          break;
        }
        progress.value = status;
        if (status.isSuccessful) {
          finished = true;
          break;
        }
        if (status.isFailed) {
          failed = true;
          finished = true;
          break;
        }
      }
    } catch (error) {
      commonPrint.log(
        'download progress poll failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      failed = true;
      finished = true;
    }
    if (cancelled) {
      await downloader.cancel(downloadId);
    }
    if (dialogOpen && dialogContext != null) {
      Navigator.of(dialogContext!).pop();
    }
    await dialogFuture;
    progress.dispose();
    if (cancelled) {
      return;
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

  String _formatMegabytes(int bytes) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
