import 'package:package_info_plus/package_info_plus.dart';
import 'package:skyward/common/package.dart';
import 'package:skyward/state.dart';
import 'package:test/test.dart';

void main() {
  final info = PackageInfo(
    appName: 'Skyward',
    packageName: 'io.github.aqiyoung.skyward',
    version: '1.0.0.50',
    buildNumber: '1',
  );

  group('PackageInfoExtension.uaFor', () {
    test('announces the core first, in the shape providers parse', () {
      expect(
        info.uaFor('1.19.33'),
        startsWith('clash.meta/1.19.33 Skyward/v1.0.0.50 clash-verge '),
      );
    });

    test('names the platform it runs on', () {
      expect(info.uaFor('1.19.33'), contains('Platform/'));
    });

    test('leaves the core out when it never answered', () {
      expect(info.uaFor(''), startsWith('Skyward/v1.0.0.50 clash-verge '));
    });
  });

  group('GlobalState.coreUaVersion', () {
    tearDown(() => globalState.coreVersion = '');

    test('drops the tag prefix and this fork round', () {
      globalState.coreVersion = 'v1.19.33-skyward.2';
      expect(globalState.coreUaVersion, '1.19.33');
    });

    test('keeps a plain upstream version as it is', () {
      globalState.coreVersion = 'v1.19.32';
      expect(globalState.coreUaVersion, '1.19.32');
    });

    test('is empty before the core answers', () {
      globalState.coreVersion = '';
      expect(globalState.coreUaVersion, isEmpty);
    });
  });
}
