import 'dart:async';
import 'dart:io';

import 'package:skyward/common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppPath {
  static AppPath? _instance;
  late ResolveOnce<Directory> _dataDir;
  late ResolveOnce<Directory?> _downloadDir;
  late ResolveOnce<Directory> _tempDir;
  Completer<Directory> cacheDir = Completer();

  @visibleForTesting
  static Future<Directory> Function() supportDirectory =
      _resolveSupportDirectory;

  @visibleForTesting
  static Future<Directory> Function() temporaryDirectory =
      getTemporaryDirectory;

  @visibleForTesting
  static Future<Directory> Function() cacheDirectory = _resolveCacheDirectory;

  @visibleForTesting
  static Future<Directory?> Function() downloadDirectory =
      getDownloadsDirectory;

  AppPath._internal() {
    _bind();
  }

  @visibleForTesting
  Future<void> rebind() async {
    cacheDir = Completer();
    _bind();
    await Future.wait([_dataDir.value, _downloadDir.value, _tempDir.value]);
  }

  void _bind() {
    _dataDir = ResolveOnce(supportDirectory);
    _downloadDir = ResolveOnce(downloadDirectory);
    _tempDir = ResolveOnce(temporaryDirectory);
    cacheDirectory().then(cacheDir.complete);
  }

  factory AppPath() {
    _instance ??= AppPath._internal();
    return _instance!;
  }

  String get executableExtension {
    return system.isWindows ? '.exe' : '';
  }

  String get executableDirPath {
    final currentExecutablePath = Platform.resolvedExecutable;
    return dirname(currentExecutablePath);
  }

  String get corePath {
    return join(executableDirPath, 'SkywardCore$executableExtension');
  }

  String get helperPath {
    return join(executableDirPath, '$appHelperService$executableExtension');
  }

  Future<String> get downloadDirPath async {
    final directory = await _downloadDir.value;
    return directory?.path ?? await homeDirPath;
  }

  Future<String> get homeDirPath async {
    final directory = await _dataDir.value;
    return directory.path;
  }

  Future<String> get databasePath async {
    final mHomeDirPath = await homeDirPath;
    return join(mHomeDirPath, 'database.sqlite');
  }

  Future<String> get tempFilePath async {
    final mTempDir = await _tempDir.value;
    return join(mTempDir.path, 'temp$uniqueId');
  }

  Future<String> get lockFilePath async {
    final homeDirPath = await appPath.homeDirPath;
    return join(homeDirPath, 'Skyward.lock');
  }

  Future<String> get configFilePath async {
    final mHomeDirPath = await homeDirPath;
    return join(mHomeDirPath, 'config.yaml');
  }

  Future<String> get sharedPreferencesPath async {
    final directory = await _dataDir.value;
    return join(directory.path, 'shared_preferences.json');
  }

  Future<String> get profilesPath async {
    final directory = await _dataDir.value;
    return join(directory.path, profilesDirectoryName);
  }

  Future<String> getProfilePath(String fileName) async {
    return join(await profilesPath, '$fileName.yaml');
  }

  Future<String> get scriptsDirPath async {
    final path = await homeDirPath;
    return join(path, 'scripts');
  }

  Future<String> getScriptPath(String fileName) async {
    final path = await scriptsDirPath;
    return join(path, '$fileName.js');
  }

  Future<String> get providerCacheRootPath async {
    final directory = await homeDirPath;
    return join(directory, providersDirectoryName);
  }

  Future<String> getProviderCachePath(String fileName) async {
    return join(
      await providerCacheRootPath,
      rulesProviderDirectoryName,
      fileName,
    );
  }

  Future<String> getProvidersRootPath() async {
    final directory = await profilesPath;
    return join(directory, providersDirectoryName);
  }

  Future<String> getProviderDirPath(int profileId, String type) async {
    final directory = await getProvidersRootPath();
    return join(directory, profileId.toString(), type);
  }

  Future<void> ensureProviderDirs(int profileId) async {
    for (final type in const [
      proxiesProviderDirectoryName,
      rulesProviderDirectoryName,
    ]) {
      final directory = Directory(await getProviderDirPath(profileId, type));
      if (await directory.exists()) {
        continue;
      }
      await directory.create(recursive: true);
    }
  }

  Future<String> get tempPath async {
    final directory = await _tempDir.value;
    return directory.path;
  }
}

final appPath = AppPath();

/// Adopts the `com.follow\clash` directory that FlClash's CompanyName and
/// ProductName pair produced, so the rename costs nobody their profiles.
Future<Directory> adoptWindowsDataDirectory(String roamingAppData) async {
  final directory = Directory(join(roamingAppData, appName));
  if (directory.existsSync()) {
    return directory;
  }
  final legacy = Directory(join(roamingAppData, 'com.follow', 'clash'));
  if (!legacy.existsSync()) {
    await directory.create(recursive: true);
    return directory;
  }
  try {
    return await legacy.rename(directory.path);
  } on FileSystemException {
    return legacy;
  }
}

String? _windowsBasePath(String variable) {
  final basePath = Platform.environment[variable];
  if (!system.isWindows || basePath == null || basePath.isEmpty) {
    return null;
  }
  return basePath;
}

Future<Directory> _resolveSupportDirectory() async {
  final basePath = _windowsBasePath('APPDATA');
  if (basePath == null) {
    return getApplicationSupportDirectory();
  }
  return adoptWindowsDataDirectory(basePath);
}

Future<Directory> _resolveCacheDirectory() async {
  final basePath = _windowsBasePath('LOCALAPPDATA');
  if (basePath == null) {
    return getApplicationCacheDirectory();
  }
  final directory = Directory(join(basePath, appName));
  await directory.create(recursive: true);
  return directory;
}

String getBackupFileName() {
  return '${appName}_backup_${DateTime.now().show}.zip';
}

String get logFileName {
  return '${appName}_${DateTime.now().show}.log';
}
