import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (input.userDefines['build_assets'] == false) {
      stdout.writeln('Skipping the Rust build: user-define build_assets=false');
      return;
    }
    await FlutterRustBridgeNativeAssetsBuilder(
      cratePath: 'rust',
      extraCargoEnvironmentVariables: _bindgenEnvironment(input),
    ).run(input: input, output: output);
  });
}

// rquickjs runs bindgen on Android, which must load the NDK's libclang; Linux
// NDKs before r26 keep it under lib64, later ones and every macOS NDK under lib.
Map<String, String> _bindgenEnvironment(BuildInput input) {
  if (!input.config.buildCodeAssets ||
      input.config.code.targetOS != OS.android) {
    return const {};
  }
  final compiler = input.config.code.cCompiler?.compiler;
  if (compiler == null) {
    return const {};
  }
  final llvmRoot = File.fromUri(compiler).parent.parent.path;
  // NDK r30's cdefs.h rejects unversioned target triples. bindgen derives its
  // --target from the Rust TARGET (aarch64-linux-android), so give it the
  // versioned triple explicitly along with the sysroot includes it needs.
  // Use forward slashes: bindgen passes these to clang, which rejects
  // backslashes on Windows hosts.
  final sysroot = '$llvmRoot/sysroot';
  final bindgenArgs =
      '--target=aarch64-linux-android35 '
      '--sysroot=$sysroot '
      '-I$sysroot/usr/include/aarch64-linux-android';
  for (final name in const ['lib', 'lib64']) {
    final directory = Directory('$llvmRoot/$name');
    if (directory.existsSync() && directory.listSync().any(_isLibclang)) {
      return {
        'LIBCLANG_PATH': directory.path,
        'BINDGEN_EXTRA_CLANG_ARGS_aarch64_linux_android': bindgenArgs,
      };
    }
  }
  throw StateError(
    'No libclang under $llvmRoot (lib or lib64); the NDK Flutter '
    'passed cannot run bindgen for rquickjs',
  );
}

bool _isLibclang(FileSystemEntity entity) {
  return entity.path.split(Platform.pathSeparator).last.startsWith('libclang.');
}
