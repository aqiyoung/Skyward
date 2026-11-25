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
    final prefs = await loadUpdatePreferences();
    final channel = effectiveUpdateChannel(
      configured: prefs.channel,
      isPreBuild: globalState.isPre,
    );
    final Map<String, dynamic>? res;
    try {
      res = await request.checkForUpdate(channel);
      // Announcing it needs a mounted navigator, and startup does not always
      // have one yet. The handler steps aside in that case; the check itself
      // is best effort, so a failed announcement must not travel out of an
      // unawaited future.
      await checkUpdateResultHandle(
        data: res,
        autoInstall: prefs.autoInstall,
        preloadWifi: prefs.preloadWifi,
        notifyOnUpdate: prefs.notifyOnUpdate,
      );
    } catch (error) {
      commonPrint.log(
        'checkForUpdate failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      return false;
    }
    return res != null;
  }

  /// The language the interface is in: the app's own choice, or the platform
  /// locale when the setting follows the system. The in-app update log uses it
  /// so a Chinese user reads the Chinese entry the commit carried.
  String get _interfaceLanguageCode =>
      (getLocaleForString(ref.read(appSettingProvider).locale) ??
              PlatformDispatcher.instance.locale)
          .languageCode;

  TextSpan _releaseSpan(BuildContext context, String tagName, String? body) {
    final version = parseReleaseChangelog(
      body,
      languageCode: _interfaceLanguageCode,
    );
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

  /// Whether an update package is on its way right now: a second tap while one
  /// runs must not set off another check over the top of it.
  bool _ongoingUpdateDownload = false;
  CancelToken? _updateCancelToken;

  bool _isZh() {
    final context = globalState.navigatorKey.currentContext;
    return context != null &&
        Localizations.maybeLocaleOf(context)?.languageCode == 'zh';
  }

  /// One-shot query for the Wi-Fi gate. A VPN can be reported alongside
  /// Wi-Fi, so membership is the test, not an exact list length.
  Future<bool> _isOnWifi() async {
    final results = await Connectivity().checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  /// Startup checks can finish before the first frame mounts the navigator.
  /// Wait briefly for it so an announced update is not silently dropped.
  Future<BuildContext?> _readyNavigatorContext() async {
    for (var attempt = 0; attempt < 30; attempt++) {
      final context = globalState.navigatorKey.currentContext;
      if (context != null && context.mounted) return context;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  /// Downloads the matching APK into the app-private `app-updates` directory,
  /// verifies it, then hands it to the native PackageInstaller for a silent
  /// self-update. The native verifier only accepts APKs from that directory
  /// with a matching name and certificate. On desktop the release page opens.
  Future<void> _downloadRelease(
    Map<String, dynamic> release, {
    bool wifiOnly = false,
    bool automatic = false,
  }) async {
    if (_ongoingUpdateDownload) return;
    if (systemDownloader == null) {
      // Desktop: replace this installation in place when it is an installer
      // build we can write; otherwise fall back to the release page.
      await _downloadDesktopUpdate(release, automatic: automatic);
      return;
    }
    final abi = await systemDownloader!.supportedAbi();
    final asset = abi == null ? null : _apkAssetOf(release, abi);
    // Preview releases list only a generic arm64 APK and publish their hash
    // in a SHA256SUMS asset instead of a comment in the notes. Resolve both
    // before deciding there is no installable package for this device.
    final sha256 =
        asset?.sha256 ??
        (asset == null ? null : await _sha256FromSums(release, asset.name));
    if (asset == null || sha256 == null) {
      // No installable package for this device: let the reader download by hand.
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
    // A hands-free download must not spend mobile data. The user-confirmed
    // path keeps the old permissive behaviour.
    if (wifiOnly && !await _isOnWifi()) {
      commonPrint.log('Skipping automatic update download on mobile data');
      return;
    }
    final tag = release['tag_name'] as String?;
    final version = releaseVersionOf(tag ?? '', release['name'] as String?);
    _ongoingUpdateDownload = true;
    final cancelToken = CancelToken();
    _updateCancelToken = cancelToken;
    try {
      final directory = Directory(
        join(await appPath.homeDirPath, 'app-updates'),
      );
      await directory.create(recursive: true);
      final safeTag =
          tag?.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_') ?? 'update';
      final target = File(join(directory.path, 'update-$safeTag.apk'));
      final size = _apkAssetSize(release, asset.name);
      ref.read(loadingProvider(LoadingTag.updateDownload).notifier).start();
      ref.read(updateDownloadProgressProvider.notifier).set(0);
      final error = await request.downloadUpdateFile(
        Uri.parse(asset.url),
        target.path,
        cancelToken: cancelToken,
        onProgress: (received, total) {
          if (total <= 0) return;
          final fraction = (received / total).clamp(0.0, 1.0);
          ref.read(updateDownloadProgressProvider.notifier).set(fraction);
        },
        expectedSha256: sha256,
        expectedSize: size,
      );
      if (error == '') return; // canceled
      if (error != null) throw StateError(error);
      await _installDownloadedApk(
        target.path,
        version: version,
        sha256: sha256,
        automatic: automatic,
      );
    } catch (error) {
      commonPrint.log(
        'download release failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      dialogs.showNotifier(error.toString(), level: MessageLevel.error);
    } finally {
      _ongoingUpdateDownload = false;
      _updateCancelToken = null;
      unawaited(
        ref.read(loadingProvider(LoadingTag.updateDownload).notifier).stop(),
      );
    }
  }

  /// Downloads the desktop installer/AppImage/DMG for this release and starts
  /// the detached replacement. Portable and package-manager installs cannot
  /// replace themselves, so those fall back to the release page.
  Future<void> _downloadDesktopUpdate(
    Map<String, dynamic> release, {
    required bool automatic,
  }) async {
    final updater = detectDesktopUpdater();
    // A hands-free desktop replacement exits the app, so only do it while the
    // reader has been away. The manual path happens on their explicit tap.
    if (automatic) {
      final idle = updater?.systemIdle();
      if (updater == null ||
          idle == null ||
          idle < const Duration(minutes: 15)) {
        return;
      }
    }
    final tag = release['tag_name'] as String?;
    final asset = updater?.selectAsset(release['assets'], tag ?? '');
    if (updater == null || asset == null || asset.sha256 == null) {
      final page = release['html_url'];
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
    _ongoingUpdateDownload = true;
    final cancelToken = CancelToken();
    _updateCancelToken = cancelToken;
    try {
      final directory = Directory(
        join(await appPath.homeDirPath, 'app-updates'),
      );
      await directory.create(recursive: true);
      final target = File(join(directory.path, asset.name));
      ref.read(loadingProvider(LoadingTag.updateDownload).notifier).start();
      final error = await request.downloadUpdateFile(
        Uri.parse(asset.url),
        target.path,
        cancelToken: cancelToken,
        onProgress: (received, total) {},
        expectedSha256: asset.sha256!,
        expectedSize: asset.size,
      );
      if (error == '') return;
      if (error != null) throw StateError(error);
      final logPath = join(directory.path, 'desktop-update.log');
      await updater.launch(target.path, relaunch: automatic, logPath: logPath);
      // The replacement waits for this process to exit before swapping files.
      exit(0);
    } catch (error) {
      commonPrint.log(
        'desktop update failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      dialogs.showNotifier(error.toString(), level: MessageLevel.error);
    } finally {
      _ongoingUpdateDownload = false;
      _updateCancelToken = null;
      ref.read(updateDownloadProgressProvider.notifier).set(null);
      unawaited(
        ref.read(loadingProvider(LoadingTag.updateDownload).notifier).stop(),
      );
    }
  }

  /// Hands a verified APK to the native PackageInstaller. Only the ROM's own
  /// confirmation fallback needs a navigator; the silent path does not.
  Future<void> _installDownloadedApk(
    String path, {
    required String version,
    required String sha256,
    required bool automatic,
  }) async {
    final installer = app;
    if (installer == null) {
      await launchUrl(Uri.parse('https://github.com/$repository/releases'));
      return;
    }
    installer.onUpdateInstallStatus = (status) {
      if (status == ApkInstallStatus.awaitingConfirmation && !automatic) {
        unawaited(installer.continueUpdateInstall());
      }
    };
    final started = await installer.installApk(
      path,
      expectedVersion: version,
      expectedSha256: sha256,
      automatic: automatic,
    );
    final zh = _isZh();
    switch (started) {
      case ApkInstallResult.permissionRequired:
        unawaited(
          dialogs.showMessage(
            title: zh ? '无法安装更新' : 'Cannot install update',
            message: TextSpan(
              text: zh
                  ? '需要授予安装未知应用权限后才能自动更新'
                  : 'Allow installing unknown apps to update',
            ),
          ),
        );
      case ApkInstallResult.vpnActive:
        unawaited(
          dialogs.showMessage(
            title: zh ? '无法安装更新' : 'Cannot install update',
            message: TextSpan(
              text: zh
                  ? 'VPN 运行时无法安装更新，请先断开 VPN 再点安装'
                  : 'Disconnect the VPN before installing an update',
            ),
          ),
        );
      case ApkInstallResult.started:
        break;
    }
  }

  /// Whether an update package is on its way right now.
  bool get isDownloadingUpdate => _ongoingUpdateDownload;

  int? _apkAssetSize(Map<String, dynamic> release, String name) {
    final assets = release['assets'];
    if (assets is! List) return null;
    for (final asset in assets) {
      if (asset is! Map) continue;
      if (asset['name'] == name && asset['size'] is int) {
        return asset['size'] as int;
      }
    }
    return null;
  }

  ({String url, String name, String? sha256})? _apkAssetOf(
    Map<String, dynamic> release,
    String abi,
  ) {
    final assets = release['assets'];
    if (assets is! List) {
      return null;
    }
    ({String url, String name, String? sha256})? generic;
    for (final asset in assets) {
      if (asset is! Map) {
        continue;
      }
      final name = asset['name'];
      final url = asset['browser_download_url'];
      if (name is! String || url is! String || !name.endsWith('.apk')) {
        continue;
      }
      final entry = (
        url: url,
        name: name,
        sha256: releaseApkSha256(release['body'], name),
      );
      if (name.contains(abi)) return entry;
      // A preview only ships one arm64 APK, named `...-android.apk` rather
      // than after its ABI. Keep it as a fallback, never ahead of an exact
      // ABI build when a release carries both.
      if (abi == 'arm64-v8a' && name.endsWith('-android.apk')) {
        generic ??= entry;
      }
    }
    return generic;
  }

  /// Reads the hash a release publishes in its SHA256SUMS asset. Releases
  /// from this repository do not put an inline `skyward:apk-sha256:` comment
  /// in the notes, so the body-only lookup would send the reader to GitHub
  /// instead of installing the verified package.
  Future<String?> _sha256FromSums(
    Map<String, dynamic> release,
    String apkName,
  ) async {
    final assets = release['assets'];
    if (assets is! List) return null;
    for (final asset in assets) {
      if (asset is! Map || asset['name'] != 'SHA256SUMS') continue;
      final url = asset['browser_download_url'];
      if (url is! String) return null;
      try {
        final response = await request.getUpdateTextResponseForUrl(url);
        for (final line in (response.data ?? '').split('\n')) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length < 2) continue;
          final name = parts.last.replaceFirst(RegExp(r'^\./'), '');
          if (name == apkName &&
              RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(parts.first)) {
            return parts.first.toLowerCase();
          }
        }
      } catch (error) {
        commonPrint.log(
          'read SHA256SUMS failed: ${compactError(error)}',
          logLevel: LogLevel.warning,
        );
      }
      return null;
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
    // With auto-install on, skip the confirmation and go straight to the
    // download (the system installer still opens at the end -- Android does
    // not let a normal app install silently).
    bool autoInstall = false,
    // With Wi-Fi pre-download on, a confirmed download stays on Wi-Fi.
    bool preloadWifi = false,
    // The switch in Update preferences: off means an automatic check stays
    // quiet and does not download anything until the reader checks by hand.
    bool notifyOnUpdate = true,
  }) async {
    if (data != null) {
      if (!notifyOnUpdate) return;
      // The popup is the announcement; auto-install and pre-download decide
      // what happens after it is confirmed, not whether it appears.
      final context = await _readyNavigatorContext();
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
        unawaited(
          _downloadRelease(data, wifiOnly: preloadWifi, automatic: autoInstall),
        );
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
