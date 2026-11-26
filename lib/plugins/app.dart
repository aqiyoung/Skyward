import 'dart:async';
import 'dart:io';

import 'package:skyward/common/boot_record.dart';
import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

const _platformProbeTimeout = Duration(seconds: 2);

/// Why a silent self-update could not start.
enum ApkInstallResult { started, permissionRequired, vpnActive }

/// The stages a PackageInstaller session moves through, reported by native.
enum ApkInstallStatus {
  none,
  preparing,
  awaitingConfirmation,
  installing,
  success,
  failed,
  cancelled,
}

class App {
  static App? _instance;
  late MethodChannel methodChannel;
  Function()? onExit;
  Function()? onPackagesChanged;
  Function(ApkInstallStatus)? onUpdateInstallStatus;
  final floatingKeyboard = ValueNotifier(false);

  App._internal() {
    methodChannel = const MethodChannel('$packageName/app');
    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'exit':
          if (onExit != null) {
            await onExit!();
          }
        case 'packagesChanged':
          onPackagesChanged?.call();
        case 'floatingImeChanged':
          floatingKeyboard.value = call.arguments as bool;
        case 'updateInstallChanged':
          onUpdateInstallStatus?.call(_apkInstallStatus(call.arguments));
        default:
          throw MissingPluginException();
      }
    });
  }

  factory App() {
    _instance ??= App._internal();
    return _instance!;
  }

  Future<bool?> moveTaskToBack() async {
    return methodChannel.invokeMethod<bool>('moveTaskToBack');
  }

  /// The link another app handed over through the share sheet, if one is
  /// waiting. Only Android has that hand-off; elsewhere the answer is null.
  Future<String?> takeSharedText() async {
    try {
      return await methodChannel.invokeMethod<String>('takeSharedText');
    } on MissingPluginException {
      return null;
    }
  }

  Future<List<Package>> getPackages() async {
    final packagesString = await methodChannel.invokeMethod<String>(
      'getPackages',
    );
    final List<dynamic> packagesRaw =
        (await packagesString?.decodeJson<List<dynamic>>()) ?? [];
    return packagesRaw.map((e) => Package.fromJson(e)).toSet().toList();
  }

  Future<bool> isInstalledAppsPermissionGranted() async {
    return await methodChannel.invokeMethod<bool>(
          'isInstalledAppsPermissionGranted',
        ) ??
        true;
  }

  Future<bool> requestInstalledAppsPermission() async {
    return await methodChannel.invokeMethod<bool>(
          'requestInstalledAppsPermission',
        ) ??
        false;
  }

  /// Android 17 drops traffic between the app and the local network until the
  /// user grants this; earlier versions answer true.
  Future<bool> requestLocalNetworkPermission() async {
    return await methodChannel.invokeMethod<bool>(
          'requestLocalNetworkPermission',
        ) ??
        false;
  }

  Future<List<String>> getChinaPackageNames() async {
    final packageNamesString = await methodChannel.invokeMethod<String>(
      'getChinaPackageNames',
    );
    final List<dynamic> packageNamesRaw =
        await packageNamesString?.decodeJson<List<dynamic>>() ?? [];
    return packageNamesRaw.map((e) => e.toString()).toList();
  }

  final Map<String, ImageProvider?> _packageIcons = {};
  final Map<String, Future<ImageProvider?>> _packageIconTasks = {};
  final TaskPool _packageIconPool = TaskPool(maxConcurrentIconLoads);

  ImageProvider? getCachedPackageIcon(String packageName) {
    return _packageIcons[packageName];
  }

  Future<ImageProvider?> getPackageIcon(String packageName) {
    if (_packageIcons.containsKey(packageName)) {
      return Future.value(_packageIcons[packageName]);
    }
    return _packageIconTasks[packageName] ??= _loadPackageIcon(packageName);
  }

  Future<ImageProvider?> _loadPackageIcon(String packageName) async {
    var icon = await _requestPackageIcon(packageName);
    if (icon == null && packageName.isNotEmpty) {
      icon = await getPackageIcon('');
    }
    _packageIcons[packageName] = icon;
    unawaited(_packageIconTasks.remove(packageName));
    return icon;
  }

  Future<ImageProvider?> _requestPackageIcon(String packageName) async {
    try {
      final path = await _packageIconPool.run(
        () => methodChannel.invokeMethod<String>('getPackageIcon', {
          'packageName': packageName,
        }),
      );
      if (path == null || path.isEmpty) {
        return null;
      }
      return FileImage(File(path));
    } catch (error) {
      commonPrint.log('getPackageIcon error: $error');
      return null;
    }
  }

  @visibleForTesting
  void clearPackageIconCache() {
    _packageIcons.clear();
    _packageIconTasks.clear();
  }

  Future<bool?> tip(String? message) async {
    return methodChannel.invokeMethod<bool>('tip', {'message': '$message'});
  }

  Future<bool?> initShortcuts() async {
    return methodChannel.invokeMethod<bool>('initShortcuts', {
      'start': currentAppLocalizations.start,
      'stop': currentAppLocalizations.stop,
      'toggle': currentAppLocalizations.toggle,
    });
  }

  Future<bool?> updateExcludeFromRecents(bool value) async {
    return methodChannel.invokeMethod<bool>('updateExcludeFromRecents', {
      'value': value,
    });
  }

  Future<bool?> openAppSettings() async {
    if (!Platform.isAndroid) return false;
    return methodChannel.invokeMethod<bool>('openAppSettings');
  }

  /// Verified self-update via PackageInstaller. The APK must already sit in
  /// the app-private `app-updates` directory with a matching name and hash;
  /// native re-checks both plus the signing certificate.
  Future<bool> canRequestPackageInstalls() async =>
      await methodChannel.invokeMethod<bool>('canRequestPackageInstalls') ?? false;

  Future<bool> updateInstallBlockedByVpn() async =>
      await methodChannel.invokeMethod<bool>('updateInstallBlockedByVpn') ?? true;

  Future<bool> openUpdateInstallPermission() async =>
      await methodChannel.invokeMethod<bool>('openUpdateInstallPermission') ?? false;

  Future<void> verifyUpdateApk(
    String path, {
    required String expectedVersion,
    required String expectedSha256,
  }) => methodChannel.invokeMethod<void>('verifyUpdateApk', {
    'path': path,
    'version': expectedVersion,
    'sha256': expectedSha256,
  });

  Future<ApkInstallResult> installApk(
    String path, {
    required String expectedVersion,
    required String expectedSha256,
    bool automatic = false,
  }) async {
    final result = await methodChannel.invokeMethod<String>('installApk', {
      'path': path,
      'version': expectedVersion,
      'sha256': expectedSha256,
      'automatic': automatic,
    });
    return switch (result) {
      'started' => ApkInstallResult.started,
      'permissionRequired' => ApkInstallResult.permissionRequired,
      'vpnActive' => ApkInstallResult.vpnActive,
      _ => throw PlatformException(
          code: 'INVALID_INSTALL_RESULT',
          message: 'Android returned an invalid APK install result',
        ),
    };
  }

  Future<String> updateInstalledVersion() async {
    final version = await methodChannel.invokeMethod<String>('updateInstalledVersion');
    if (version == null || version.isEmpty) {
      throw PlatformException(code: 'INVALID_INSTALLED_VERSION');
    }
    return version;
  }

  Future<ApkInstallStatus> updateInstallStatus() async =>
      _apkInstallStatus(await methodChannel.invokeMethod<String>('updateInstallStatus'));

  Future<bool> continueUpdateInstall() async =>
      await methodChannel.invokeMethod<bool>('continueUpdateInstall') ?? false;

  ApkInstallStatus _apkInstallStatus(Object? value) => switch (value) {
    'none' => ApkInstallStatus.none,
    'preparing' => ApkInstallStatus.preparing,
    'awaitingConfirmation' => ApkInstallStatus.awaitingConfirmation,
    'installing' => ApkInstallStatus.installing,
    'success' => ApkInstallStatus.success,
    'failed' => ApkInstallStatus.failed,
    'cancelled' => ApkInstallStatus.cancelled,
    _ => throw PlatformException(
        code: 'INVALID_INSTALL_STATUS',
        message: 'Android returned an invalid APK install status',
      ),
  };

  Future<AppExitInfo?> getLastExitInfo() async {
    try {
      final raw = await methodChannel
          .invokeMapMethod<String, Object?>('getLastExitInfo')
          .timeout(_platformProbeTimeout);
      return AppExitInfo.fromJson(raw);
    } catch (error) {
      commonPrint.log(
        'Failed to read the last process exit info: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }
}

final app = system.isAndroid ? App() : null;
