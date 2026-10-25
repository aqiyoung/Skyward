import 'dart:io';

import 'package:skyward/common/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('file_test');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  group('safeDeletePath', () {
    test('removes a file', () async {
      final path = join(root.path, 'config.yaml');
      File(path).writeAsStringSync('mixed-port: 7890');

      await safeDeletePath(path);

      expect(File(path).existsSync(), isFalse);
    });

    test('removes a directory along with everything under it', () async {
      final path = join(root.path, '42');
      File(join(path, 'proxies', 'abc'))
        ..createSync(recursive: true)
        ..writeAsStringSync('proxies: []');

      await safeDeletePath(path);

      expect(Directory(path).existsSync(), isFalse);
    });

    test('accepts a path that is already gone', () async {
      await expectLater(safeDeletePath(join(root.path, 'missing')), completes);
    });
  });

  group('safeCopy', () {
    test('copies the file and creates the directory it lands in', () async {
      final source = File(join(root.path, 'home', '1.yaml'))
        ..createSync(recursive: true)
        ..writeAsStringSync('mixed-port: 7890');

      expect(await source.safeCopy(join(root.path, 'next', '1.yaml')), isTrue);

      expect(
        File(join(root.path, 'next', '1.yaml')).readAsStringSync(),
        'mixed-port: 7890',
      );
    });

    test('reports a missing source instead of writing one', () async {
      final source = File(join(root.path, 'home', '2.yaml'));
      final target = join(root.path, 'next', '2.yaml');

      // Whoever keeps a record of the copy goes on naming a file either way, so
      // a blank one would be worse than none: nothing is created on either side.
      expect(await source.safeCopy(target), isFalse);
      expect(source.existsSync(), isFalse);
      expect(File(target).existsSync(), isFalse);
    });
  });

  group('writeAsStringAtomically', () {
    test('replaces the file and leaves nothing beside it', () async {
      final file = File(join(root.path, 'config.yaml'))
        ..writeAsStringSync('mixed-port: 7890');

      await file.writeAsStringAtomically('mixed-port: 7891');

      expect(file.readAsStringSync(), 'mixed-port: 7891');
      expect(root.listSync().map((entry) => basename(entry.path)), [
        'config.yaml',
      ]);
    });

    test('creates the directory a first write needs', () async {
      final file = File(join(root.path, 'home', 'config.yaml'));

      await file.writeAsStringAtomically('mode: rule');

      expect(file.readAsStringSync(), 'mode: rule');
    });

    test('keeps the old file when the new one cannot be written', () async {
      final file = File(join(root.path, 'config.yaml'))
        ..writeAsStringSync('mode: rule');
      Directory('${file.path}.$pid.tmp').createSync();

      await expectLater(
        file.writeAsStringAtomically('mode: global'),
        throwsA(isA<FileSystemException>()),
      );
      expect(file.readAsStringSync(), 'mode: rule');
    });
  });

  group('pathSize', () {
    test('counts a file', () async {
      final path = join(root.path, 'config.yaml');
      File(path).writeAsStringSync('mixed-port: 7890');

      expect(await pathSize(path), 16);
    });

    test('adds up everything under a directory', () async {
      final path = join(root.path, 'profiles');
      File(join(path, '1.yaml'))
        ..createSync(recursive: true)
        ..writeAsStringSync('a' * 10);
      File(join(path, 'nested', '2.yaml'))
        ..createSync(recursive: true)
        ..writeAsStringSync('b' * 30);

      expect(await pathSize(path), 40);
    });

    test('a path that is not there is nothing to count', () async {
      expect(await pathSize(join(root.path, 'missing')), 0);
    });
  });
}
