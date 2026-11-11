import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const _allTargets = <String, String>{
  'android': 'apk',
  'linux': 'deb,appimage,rpm',
  'macos': 'dmg',
  'windows': 'exe,zip',
};

const _androidFlutterTarget = {
  'arm': 'android-arm',
  'arm64': 'android-arm64',
  'amd64': 'android-x64',
};

const _hostPlatform = {
  'linux': 'linux',
  'macos': 'macos',
  'windows': 'windows',
};

Future<void> main(List<String> args) async {
  final parser = createSetupArgParser();

  if (args.contains('--help') || args.contains('-h')) {
    _showHelp(parser);
    exit(0);
  }

  final results = parser.parse(args);
  final rest = results.rest;

  final hostOs = Platform.operatingSystem;
  final host = _hostPlatform[hostOs];
  if (host == null) {
    stderr.writeln('Unsupported host platform: $hostOs');
    exit(1);
  }

  final platform = rest.isNotEmpty ? rest.first : host;

  if (platform != host && platform != 'android') {
    stderr.writeln(
      'Cannot build "$platform" on $hostOs. Allowed: $host, android',
    );
    _showHelp(parser);
    exit(1);
  }

  final env = results['env'] as String;
  final rootDir = Directory.current.path;
  final skipped = packagesNotBuildingAssets(
    File(p.join(rootDir, 'pubspec.yaml')).readAsStringSync(),
  );
  if (skipped.isNotEmpty) {
    stderr.writeln(
      'pubspec.yaml sets hooks.user_defines.<package>.build_assets: false '
      'for ${skipped.join(', ')}; a package built this way would ship '
      'whatever is left in libclash/ and no Rust library. '
      'Restore "build_assets: true".',
    );
    exit(1);
  }
  final arch = _detectArch();
  final targets = createPackageTargets(platform, results['targets']);
  final androidArch = results['arch'] as String?;
  final verbose = results['verbose'] as bool;

  final exitCode = await _package(
    platform,
    env,
    targets,
    rootDir,
    arch,
    androidArch: androidArch,
    verbose: verbose,
  );
  exit(exitCode);
}

ArgParser createSetupArgParser() {
  return ArgParser()
    ..addOption(
      'env',
      defaultsTo: 'pre',
      allowed: ['dev', 'pre', 'stable'],
      help: 'Application environment',
    )
    ..addOption(
      'targets',
      valueHelp: 'exe,zip,dmg,apk,...',
      help: 'Package targets (default: all for platform)',
    )
    ..addOption(
      'arch',
      valueHelp: 'arm,arm64,amd64',
      allowed: ['arm', 'arm64', 'amd64'],
      help: 'Target architecture (Android only); builds one APK for it',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Enable verbose Flutter build output',
    );
}

List<String> createFlutterBuildArgs({
  required String platform,
  required bool verbose,
  bool splitAbi = true,
}) {
  final flutterBuildArgs = <String>[
    if (verbose) 'verbose',
    'dart-define-from-file=env.json',
  ];
  // Splitting is what puts an APK for every ABI in `dist/`. A build that has
  // already named one (`--arch arm64`) has nothing left to split: its single
  // APK is the one that architecture installs.
  if (platform == 'android' && splitAbi) {
    flutterBuildArgs.add('split-per-abi');
  }
  // Whenever it is not splitting, the Flutter plugin rewrites the app's
  // abiFilters to its whole supported list -- so a package built for one
  // architecture ends up holding every ABI's libraries, three of which can
  // never load. Turning that off leaves the filtering to the app module,
  // which reads the same `target-platform` property.
  if (platform == 'android' && !splitAbi) {
    flutterBuildArgs.add('android-project-arg=disable-abi-filtering=true');
  }
  return flutterBuildArgs;
}

Map<String, String> createBuildEnvironment(
  String env, {
  String? appVersion,
  String? channel,
  String? buildNumber,
}) {
  return {
    'APP_ENV': env,
    if (appVersion != null && appVersion.isNotEmpty) 'APP_VERSION': appVersion,
    if (channel != null && channel.isNotEmpty) 'APP_CHANNEL': channel,
    // The versionCode the build was made with. The version string no longer
    // carries it -- the fourth component counts the day's snapshots and the
    // suffix names the channel -- so the update check reads the number that
    // Android actually orders installs by.
    if (buildNumber != null && buildNumber.isNotEmpty)
      'APP_BUILD_NUMBER': buildNumber,
  };
}

/// Packages whose build hook `pubspec.yaml` turns into a no-op.
List<String> packagesNotBuildingAssets(String pubspec) {
  final document = loadYaml(pubspec);
  if (document is! Map) return const [];
  final defines = (document['hooks'] as Map?)?['user_defines'];
  if (defines is! Map) return const [];
  return [
    for (final MapEntry(:key, :value) in defines.entries)
      if (value is Map && value['build_assets'] == false) key.toString(),
  ]..sort();
}

String createPackageTargets(String platform, String? customTargets) {
  return customTargets ?? _allTargets[platform]!;
}

void _showHelp(ArgParser parser) {
  stderr.writeln('Usage: dart setup.dart [platform] [options]');
  stderr.writeln('Platform: current host platform (default) or android');
  stderr.writeln();
  stderr.writeln('Default package targets:');
  _allTargets.forEach((p, t) => stderr.writeln('  $p: $t'));
  stderr.writeln();
  stderr.writeln(parser.usage);
}

Future<int> _package(
  String platform,
  String env,
  String targets,
  String rootDir,
  String arch, {
  String? androidArch,
  required bool verbose,
}) async {
  final file = File(p.join(rootDir, 'env.json'));
  await file.writeAsString(
    jsonEncode(
      createBuildEnvironment(
        env,
        appVersion: Platform.environment['APP_VERSION_NAME'],
        channel: Platform.environment['APP_CHANNEL_NAME'],
        buildNumber: Platform.environment['APP_BUILD_NUMBER'],
      ),
    ),
  );

  final flutterBuildArgs = createFlutterBuildArgs(
    platform: platform,
    verbose: verbose,
    // One architecture asked for means one APK: splitting would only produce
    // that same build under a longer name, plus two ABIs nobody requested.
    splitAbi: androidArch == null,
  );
  final descriptionArgs = <String>[];
  if (platform != 'android') {
    descriptionArgs.addAll(['--description', arch]);
  }

  final depExit = await _ensureDependencies(platform);
  if (depExit != 0) return depExit;

  final activateResult = await Process.run('dart', [
    'pub',
    'global',
    'activate',
    '-s',
    'git',
    'https://github.com/aqiyoung/flutter_distributor.git',
    '--git-ref',
    'v0.6.11-flclash.4',
    '--git-path',
    'packages/flutter_distributor',
  ]);
  if (activateResult.exitCode != 0) {
    stderr.write(activateResult.stderr);
    return activateResult.exitCode;
  }

  final process = await Process.start(
    'flutter_distributor',
    [
      'package',
      '--skip-clean',
      '--platform',
      platform,
      '--targets',
      targets,
      if (androidArch != null)
        '--build-target-platform=${_androidFlutterTarget[androidArch]!}',
      if (flutterBuildArgs.isNotEmpty)
        '--flutter-build-args=${flutterBuildArgs.join(',')}',
      ...descriptionArgs,
    ],
    includeParentEnvironment: true,
    runInShell: Platform.isWindows,
  );

  process.stdout.listen((data) {
    stdout.write(utf8.decode(data));
  });
  process.stderr.listen((data) {
    stderr.write(utf8.decode(data));
  });
  final exitCode = await process.exitCode;
  return exitCode;
}

String _detectArch() {
  if (Platform.isWindows) {
    final pa = Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'AMD64';
    return pa.toUpperCase() == 'ARM64' ? 'arm64' : 'amd64';
  }
  final result = Process.runSync('uname', ['-m']);
  final machine = (result.stdout as String).trim();
  if (machine == 'aarch64') return 'arm64';
  if (machine == 'x86_64') return 'amd64';
  return machine;
}

Future<bool> _hasCommand(String cmd) async {
  final which = Platform.isWindows ? 'where' : 'command';
  final args = Platform.isWindows ? [cmd] : ['-v', cmd];
  final result = await Process.run(which, args);
  return result.exitCode == 0;
}

Future<int> _ensureDependencies(String platform) async {
  switch (platform) {
    case 'macos':
      return _ensureMacosDependencies();
    case 'linux':
      return _ensureLinuxDependencies();
    default:
      return 0;
  }
}

Future<int> _ensureMacosDependencies() async {
  if (await _hasCommand('appdmg')) {
    stdout.writeln('appdmg already installed, skipping.');
    return 0;
  }
  stdout.writeln('Installing appdmg (DMG creator)...');
  // Pinned: an unpinned `npm install -g appdmg` pulls whatever the registry
  // serves today, so a compromised publish would run during our build.
  final result = await Process.run('npm', ['install', '-g', 'appdmg@0.6.6']);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
  }
  return result.exitCode;
}

Future<int> _ensureLinuxDependencies() async {
  const pkgGroups = <List<String>>[
    ['ninja-build', 'libgtk-3-dev'],
    ['libayatana-appindicator3-dev'],
    ['libsecret-1-dev'],
    ['locate'],
    ['rpm', 'patchelf'],
    ['libfuse2'],
  ];

  final missingGroups = <List<String>>[];
  for (final group in pkgGroups) {
    final missingPkgs = <String>[];
    for (final pkg in group) {
      if (!await _isDebianPackageInstalled(pkg)) {
        missingPkgs.add(pkg);
      }
    }
    if (missingPkgs.isNotEmpty) {
      missingGroups.add(missingPkgs);
    }
  }

  if (missingGroups.isEmpty) {
    stdout.writeln('All Linux build dependencies already installed, skipping.');
  } else {
    stdout.writeln('Updating apt package lists...');
    final updateExit = await _runLinuxDependencyCommand([
      'apt-get',
      'update',
      '-y',
    ]);
    if (updateExit != 0) {
      stderr.writeln(
        'apt-get update exited with $updateExit; continuing and verifying '
        'dependency installation directly.',
      );
    }

    for (final missingPkgs in missingGroups) {
      stdout.writeln(
        'Installing Linux build dependencies: ${missingPkgs.join(', ')}...',
      );
      final installExit = await _installLinuxPackages(missingPkgs);
      if (installExit != 0) return installExit;
    }
  }

  const appimagetool = '/usr/local/bin/appimagetool';
  if (File(appimagetool).existsSync()) {
    stdout.writeln('appimagetool already installed, skipping.');
    return 0;
  }
  stdout.writeln('Downloading appimagetool...');
  final downloadName =
      'appimagetool-${appImageToolArch(_detectArch())}.AppImage';
  final dlResult = await Process.run('wget', [
    '-O',
    appimagetool,
    'https://github.com/AppImage/AppImageKit/releases/download/continuous/$downloadName',
  ]);
  if (dlResult.exitCode != 0) {
    stderr.write(dlResult.stderr);
    return dlResult.exitCode;
  }
  // The `continuous` tag is rebuilt on every upstream commit with no
  // versioning, so the download is verified against a pinned SHA-256
  // before it is ever executed. A mismatch fails the build instead of
  // running an unknown binary; update the pinned hash only when
  // intentionally taking a newer upstream build.
  if (!await _verifyAppimagetool(appimagetool)) {
    return 1;
  }
  await Process.run('chmod', ['+x', appimagetool]);
  return 0;
}

/// Pinned SHA-256 of the appimagetool `continuous` build, per arch,
/// taken 2026-10-30. See `_ensureLinuxDependencies`.
const _appimagetoolSha256 = {
  'x86_64': 'b90f4a8b18967545fda78a445b27680a1642f1ef9488ced28b65398f2be7add2',
  'aarch64': 'a48972e5ae91c944c5a7c80214e7e0a42dd6aa3ae979d8756203512a74ff574d',
};

Future<bool> _verifyAppimagetool(String path) async {
  final expected = _appimagetoolSha256[appImageToolArch(_detectArch())];
  if (expected == null) {
    stderr.writeln('No pinned appimagetool hash for this arch; refusing.');
    await File(path).delete();
    return false;
  }
  final hashResult = await Process.run('sha256sum', [path]);
  if (hashResult.exitCode != 0) {
    stderr.write(hashResult.stderr);
    await File(path).delete();
    return false;
  }
  final actual = (hashResult.stdout as String).split(RegExp(r'\s+')).first;
  if (actual != expected) {
    stderr.writeln(
      'appimagetool SHA-256 mismatch: upstream rebuilt the continuous tag. '
      'Expected $expected, got $actual. '
      'Review the upstream change, then update _appimagetoolSha256.',
    );
    await File(path).delete();
    return false;
  }
  stdout.writeln('appimagetool SHA-256 verified.');
  return true;
}

String appImageToolArch(String arch) {
  return arch == 'arm64' ? 'aarch64' : 'x86_64';
}

/// Ubuntu 24.04 ships libfuse2 under its time64 name, which `dpkg -s libfuse2` cannot see.
const _debianPackageAliases = <String, List<String>>{
  'libfuse2': ['libfuse2t64'],
};

Future<bool> _isDebianPackageInstalled(String pkg) async {
  for (final name in [pkg, ...?_debianPackageAliases[pkg]]) {
    final result = await Process.run('dpkg', ['-s', name]);
    if (result.exitCode == 0 &&
        (result.stdout as String).contains('Status: install ok installed')) {
      return true;
    }
  }
  return false;
}

Future<bool> _areDebianPackagesInstalled(List<String> pkgs) async {
  for (final pkg in pkgs) {
    if (!await _isDebianPackageInstalled(pkg)) {
      return false;
    }
  }
  return true;
}

Future<int> _installLinuxPackages(List<String> pkgs) async {
  final exitCode = await _runLinuxDependencyCommand([
    'apt-get',
    'install',
    '-y',
    ...pkgs,
  ]);
  if (exitCode == 0) return 0;

  if (await _areDebianPackagesInstalled(pkgs)) {
    stderr.writeln(
      'apt-get install exited with $exitCode, but all requested packages are '
      'installed; continuing.',
    );
    return 0;
  }

  return exitCode;
}

Future<int> _runLinuxDependencyCommand(List<String> command) async {
  final sudoCommand = [
    'env',
    'DEBIAN_FRONTEND=noninteractive',
    'NEEDRESTART_MODE=a',
    ...command,
  ];
  stdout.writeln('exec: sudo ${sudoCommand.join(' ')}');
  final result = await Process.start('sudo', sudoCommand);
  result.stdout.listen((data) {
    stdout.write(utf8.decode(data));
  });
  result.stderr.listen((data) {
    stderr.write(utf8.decode(data));
  });
  final exitCode = await result.exitCode;
  if (exitCode != 0) {
    stderr.writeln('Linux dependency command failed with exit code $exitCode.');
  }
  return exitCode;
}
