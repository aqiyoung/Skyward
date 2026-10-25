import 'dart:io';

const _replaceAttempts = 10;
const _replaceRetryDelay = Duration(milliseconds: 50);

/// The prefix mihomo's `age.DecryptBytes` tells an encrypted config by.
const _ageArmorHeader = '-----BEGIN AGE ENCRYPTED FILE-----';

extension FileExt on File {
  /// Copies this file over [newPath], creating the directory it lands in.
  ///
  /// Answers whether there was anything to copy. A source that is already gone
  /// is not a copy to make: writing an empty file on either side of it would
  /// hand the caller a blank document where it expected a copy, and whoever
  /// keeps a record naming that file -- the profile list does -- would go on
  /// naming a document that says nothing.
  Future<bool> safeCopy(String newPath) async {
    if (!await exists()) {
      return false;
    }
    final targetFile = File(newPath);
    if (!await targetFile.exists()) {
      await targetFile.create(recursive: true);
    }
    await copy(newPath);
    return true;
  }

  Future<bool> get isAgeEncrypted async {
    final head = await openRead(
      0,
      _ageArmorHeader.length,
    ).expand((chunk) => chunk).toList();
    return String.fromCharCodes(head) == _ageArmorHeader;
  }

  Future<File> safeWriteAsString(String str) async {
    if (!await exists()) {
      await create(recursive: true);
    }
    return writeAsString(str);
  }

  Future<File> safeWriteAsBytes(List<int> bytes) async {
    if (!await exists()) {
      await create(recursive: true);
    }
    return writeAsBytes(bytes);
  }

  /// Writes to one file must not overlap: they share the temporary sibling.
  Future<void> writeAsStringAtomically(String content) async {
    final temp = File('$path.$pid.tmp');
    try {
      await temp.parent.create(recursive: true);
      await temp.writeAsString(content, flush: true);
      await temp._renameRetryingWhileHeldOpen(path);
    } catch (_) {
      await temp.delete().then((_) {}, onError: (_) {});
      rethrow;
    }
  }

  Future<void> _renameRetryingWhileHeldOpen(String target) async {
    for (var attempt = 1; ; attempt++) {
      try {
        await rename(target);
        return;
      } on FileSystemException {
        if (attempt == _replaceAttempts) rethrow;
        await Future<void>.delayed(_replaceRetryDelay);
      }
    }
  }
}

extension FileSystemEntityExt on FileSystemEntity {
  Future<void> safeDelete({bool recursive = false}) async {
    if (!await exists()) {
      return;
    }
    await delete(recursive: recursive);
  }
}

Future<void> safeDeletePath(String path) async {
  final entity = switch (FileSystemEntity.typeSync(path)) {
    FileSystemEntityType.directory => Directory(path),
    _ => File(path),
  };
  await entity.safeDelete(recursive: true);
}

/// Bytes a file, or everything under a directory, occupies. An entry that
/// cannot be read counts as zero, so one locked file cannot fail a whole
/// measurement.
Future<int> pathSize(String path) async {
  final type = await FileSystemEntity.type(path);
  if (type == FileSystemEntityType.file) {
    try {
      return await File(path).length();
    } catch (_) {
      return 0;
    }
  }
  if (type != FileSystemEntityType.directory) {
    return 0;
  }
  var total = 0;
  try {
    await for (final entity in Directory(
      path,
    ).list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      try {
        total += await entity.length();
      } catch (_) {}
    }
  } catch (_) {}
  return total;
}
