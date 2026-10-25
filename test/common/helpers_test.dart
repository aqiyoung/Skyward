import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('getDateStringLast2', () {
    test('pads single digit', () {
      expect(getDateStringLast2(5), '05');
    });

    test('returns last 2 chars of double digit', () {
      expect(getDateStringLast2(12), '12');
    });

    test('handles zero', () {
      expect(getDateStringLast2(0), '00');
    });
  });

  group('uuidV4', () {
    test('produces valid UUID v4 format', () {
      final uuid = uuidV4;
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(uuid),
        isTrue,
      );
    });

    test('produces unique values', () {
      final uuid1 = uuidV4;
      final uuid2 = uuidV4;
      expect(uuid1, isNot(equals(uuid2)));
    });
  });

  group('getTimeText', () {
    test('returns 00:00:00 for null', () {
      expect(getTimeText(null), '00:00:00');
    });

    test('formats zero milliseconds', () {
      expect(getTimeText(0), '00:00:00');
    });

    test('formats seconds only', () {
      expect(getTimeText(5000), '00:00:05');
    });

    test('formats minutes and seconds', () {
      expect(getTimeText(125000), '00:02:05');
    });

    test('formats hours', () {
      expect(getTimeText(3661000), '01:01:01');
    });

    test('formats three digit hours', () {
      expect(getTimeText(100 * 3600 * 1000), '100:00:00');
    });

    test('caps at 999:59:59', () {
      expect(getTimeText(1000 * 3600 * 1000), '999:59:59');
    });
  });

  group('uniqueLabelFor', () {
    String unique(String name, Set<String> taken) =>
        uniqueLabelFor(name, fallback: 'Fallback', taken: taken.contains);

    test('keeps a free label', () {
      expect(unique('foo', {}), 'foo');
    });

    test('appends (1) to label without number', () {
      expect(unique('foo', {'foo'}), 'foo(1)');
    });

    test('increments existing number', () {
      expect(unique('foo(1)', {'foo(1)'}), 'foo(2)');
    });

    test('increments higher numbers', () {
      expect(unique('foo(9)', {'foo(9)'}), 'foo(10)');
    });

    test('increments a two-digit suffix into three digits', () {
      expect(unique('foo(99)', {'foo(99)'}), 'foo(100)');
    });

    test('increments an existing three-digit suffix', () {
      expect(unique('foo(100)', {'foo(100)'}), 'foo(101)');
    });

    test('increments a bare parenthesized number', () {
      expect(unique('(1)', {'(1)'}), '(2)');
    });

    test('increments a single-character label', () {
      expect(unique('a(1)', {'a(1)'}), 'a(2)');
    });

    test('steps past numbers already taken', () {
      expect(unique('foo', {'foo', 'foo(1)', 'foo(2)'}), 'foo(3)');
    });
  });

  group('compareVersions', () {
    test('equal versions', () {
      expect(compareVersions('1.0.0', '1.0.0'), 0);
    });

    test('major version difference', () {
      expect(compareVersions('2.0.0', '1.0.0'), greaterThan(0));
      expect(compareVersions('1.0.0', '2.0.0'), lessThan(0));
    });

    test('minor version difference', () {
      expect(compareVersions('1.2.0', '1.1.0'), greaterThan(0));
    });

    test('patch version difference', () {
      expect(compareVersions('1.0.2', '1.0.1'), greaterThan(0));
    });

    test('revision difference', () {
      expect(compareVersions('1.0.0.2', '1.0.0.1'), greaterThan(0));
      expect(compareVersions('1.0.0.1', '1.0.0.2'), lessThan(0));
      expect(compareVersions('1.0.0.2', '1.0.0.10'), lessThan(0));
      expect(compareVersions('1.0.1.1', '1.0.0.9'), greaterThan(0));
    });

    test('revision only counts when both sides carry one', () {
      expect(compareVersions('1.0.0.1', '1.0.0'), 0);
      expect(compareVersions('1.0.0', '1.0.0.1'), 0);
    });

    test('a preview build comes before the releases of its line', () {
      // A preview carries the day's build number, which outranks every revision
      // by orders of magnitude. Read literally it would be the newer of the
      // two forever, and the user of a preview would never be told a release
      // exists -- which is exactly how a preview stops receiving updates.
      expect(compareVersions('1.0.0.14', '1.0.0.2090029702'), greaterThan(0));
      expect(compareVersions('1.0.0.2090029702', '1.0.0.14'), lessThan(0));
    });

    test('a preview still compares on the components above the slot', () {
      expect(compareVersions('1.0.1.1', '1.0.0.2090029702'), greaterThan(0));
      expect(compareVersions('1.0.0.1', '1.0.1.2090029702'), lessThan(0));
    });

    test('handles build number', () {
      expect(compareVersions('1.0.0+1', '1.0.0+2'), lessThan(0));
      expect(compareVersions('1.0.0+2', '1.0.0+1'), greaterThan(0));
    });

    test('handles missing minor/patch', () {
      expect(compareVersions('1', '1.0.0'), 0);
    });
  });

  group('shouldOfferUpdate', () {
    const release = '1.0.0.14';
    const releaseBuild = 2090029703;

    test('a release is offered to the preview it postdates', () {
      expect(
        shouldOfferUpdate(
          remoteVersion: release,
          remoteBuildNumber: releaseBuild,
          installedVersion: '1.0.0.2090029702',
        ),
        isTrue,
      );
    });

    test('a release is withheld from a preview that already outranks it', () {
      // Android refuses a downgrade, so offering this one would be a promise
      // the install cannot keep.
      expect(
        shouldOfferUpdate(
          remoteVersion: release,
          remoteBuildNumber: releaseBuild,
          installedVersion: '1.0.0.2090029704',
        ),
        isFalse,
      );
    });

    test('a release compares by version on a build that is not a preview', () {
      expect(
        shouldOfferUpdate(
          remoteVersion: '1.0.0.15',
          remoteBuildNumber: releaseBuild,
          installedVersion: '1.0.0.14',
        ),
        isTrue,
      );
      expect(
        shouldOfferUpdate(
          remoteVersion: release,
          remoteBuildNumber: releaseBuild,
          installedVersion: release,
        ),
        isFalse,
      );
    });

    test('falls back to the version when the notes carry no number', () {
      expect(
        shouldOfferUpdate(
          remoteVersion: '1.0.0.15',
          remoteBuildNumber: null,
          installedVersion: '1.0.0.14',
        ),
        isTrue,
      );
    });

    test('withholds a release it cannot place on the build counter', () {
      // The release page redirect the API falls back to once its quota is
      // spent carries the tag alone. Without the number there is no way to say
      // whether this release outranks the preview that is installed, and
      // reading the names instead would always answer that it does.
      expect(
        shouldOfferUpdate(
          remoteVersion: release,
          remoteBuildNumber: null,
          installedVersion: '1.0.0.2090029702',
        ),
        isFalse,
      );
      expect(
        shouldOfferUpdate(
          remoteVersion: '1.0.0.15',
          remoteBuildNumber: null,
          installedVersion: '1.0.0.2090029702',
        ),
        isFalse,
      );
    });
  });

  group('releaseVersionOf', () {
    test('drops the tag prefix and nothing else', () {
      expect(releaseVersionOf('v1.0.0.14'), '1.0.0.14');
      expect(releaseVersionOf('1.0.0.14'), '1.0.0.14');
      // A version that carries a `v` of its own keeps it.
      expect(releaseVersionOf('v1.0.0-dev'), '1.0.0-dev');
    });
  });

  group('releaseBuildNumber', () {
    test('reads the comment the release writes', () {
      expect(
        releaseBuildNumber('notes\n<!-- skyward:build-number:2090029703 -->\n'),
        2090029703,
      );
    });

    test('reads the number older releases state in prose', () {
      expect(
        releaseBuildNumber('- 构建号：`2090029703`（APK 的 versionCode）'),
        2090029703,
      );
    });

    test('null when the notes say nothing', () {
      expect(releaseBuildNumber('no number here'), isNull);
      expect(releaseBuildNumber(null), isNull);
      expect(releaseBuildNumber(42), isNull);
    });
  });

  group('getViewMode', () {
    test('mobile for small width', () {
      expect(getViewMode(400).name, 'mobile');
    });

    test('laptop for medium width', () {
      expect(getViewMode(700).name, 'laptop');
    });

    test('desktop for large width', () {
      expect(getViewMode(1000).name, 'desktop');
    });
  });

  group('canExpandSidebar', () {
    test('expands only in the desktop view mode', () {
      expect(canExpandSidebar(getViewMode(maxLaptopWidth + 1)), isTrue);
      expect(canExpandSidebar(getViewMode(maxLaptopWidth.toDouble())), isFalse);
      expect(canExpandSidebar(ViewMode.mobile), isFalse);
    });
  });

  group('windowControlsOverSidebar', () {
    test('only macOS 11 and later draw the traffic lights over it', () {
      expect(
        windowControlsOverSidebar(isMacOS: true, version: 15),
        macOSTrafficLightsArea,
      );
      expect(windowControlsOverSidebar(isMacOS: true, version: 10), Size.zero);
      expect(windowControlsOverSidebar(isMacOS: false, version: 11), Size.zero);
    });
  });

  group('windowControlsOverPage', () {
    test('a wide macOS window meets the traffic lights at its top left', () {
      expect(
        windowControlsOverPage(isMacOS: true, version: 15, isMobileView: false),
        macOSTrafficLightsArea,
      );
    });

    test('a window header or a native title bar keeps them off the page', () {
      for (final (isMacOS, version, isMobileView) in [
        (true, 15, true),
        (true, 10, false),
        (false, 11, false),
      ]) {
        expect(
          windowControlsOverPage(
            isMacOS: isMacOS,
            version: version,
            isMobileView: isMobileView,
          ),
          Size.zero,
          reason: 'macOS=$isMacOS $version mobileView=$isMobileView',
        );
      }
    });
  });

  group('getProxiesColumns', () {
    test('minimum 2 columns', () {
      expect(getProxiesColumns(100, ProxiesLayout.standard), 2);
    });

    test('scales with width', () {
      expect(getProxiesColumns(500, ProxiesLayout.standard), 2);
      expect(getProxiesColumns(800, ProxiesLayout.standard), 4);
    });

    test('tight layout adds column', () {
      final standard = getProxiesColumns(500, ProxiesLayout.standard);
      final tight = getProxiesColumns(500, ProxiesLayout.tight);
      expect(tight, standard + 1);
    });

    test('loose layout removes column', () {
      final standard = getProxiesColumns(800, ProxiesLayout.standard);
      final loose = getProxiesColumns(800, ProxiesLayout.loose);
      expect(loose, standard - 1);
    });
  });

  group('getProfilesColumns', () {
    test('minimum 1 column', () {
      expect(getProfilesColumns(100), 1);
    });

    test('scales with width', () {
      expect(getProfilesColumns(300), 1);
      expect(getProfilesColumns(700), 2);
      expect(getProfilesColumns(960), 3);
    });

    test('caps at three columns', () {
      expect(getProfilesColumns(1300), 3);
      expect(getProfilesColumns(2400, spacing: 14), 3);
    });

    test('spacing costs a column at the breakpoint', () {
      expect(getProfilesColumns(600), 2);
      expect(getProfilesColumns(600, spacing: 14), 1);
    });

    test('fits two padded cards, not three, near 900 dp', () {
      expect(getProfilesColumns(868, spacing: 12), 2);
    });

    test('every card keeps at least the minimum width', () {
      const spacing = 14.0;
      for (var viewWidth = 200.0; viewWidth <= 4000; viewWidth += 1) {
        final columns = getProfilesColumns(viewWidth, spacing: spacing);
        if (columns == 1) continue;
        final itemWidth = (viewWidth + spacing) / columns - spacing;
        expect(
          itemWidth,
          greaterThanOrEqualTo(profileItemMinWidth),
          reason: 'viewWidth $viewWidth gave $columns columns',
        );
      }
    });

    test('a larger minimum yields fewer columns', () {
      expect(getProfilesColumns(1000, minItemWidth: 320), 3);
      expect(getProfilesColumns(1000, minItemWidth: 480), 2);
    });
  });

  group('parseReleaseBody', () {
    test('extracts bullet points', () {
      const body = '- Feature 1\n- Feature 2\n- Bug fix';
      final result = parseReleaseBody(body);
      expect(result, ['Feature 1', 'Feature 2', 'Bug fix']);
    });

    test('returns empty for null', () {
      expect(parseReleaseBody(null), isEmpty);
    });

    test('ignores non-bullet lines', () {
      const body = 'Header\n- Item 1\nFooter\n- Item 2';
      final result = parseReleaseBody(body);
      expect(result, ['Item 1', 'Item 2']);
    });

    test('stops at the changelog markers', () {
      const body =
          '$releaseNotesBeginMarker\n'
          '### Features\n'
          '- Item 1\n'
          '$releaseNotesEndMarker\n'
          '<a href="FlClash-0.8.96-android-arm64-v8a.apk">APK</a>\n'
          '- Not part of the notes\n';

      expect(parseReleaseBody(body), ['Item 1']);
    });

    test('ignores inline dashes in the download template', () {
      const body =
          '- Item 1\n'
          '<img src="https://img.shields.io/badge/APK-ARMv8-168039.svg">\n'
          '<td>Windows</td>\n';

      expect(parseReleaseBody(body), ['Item 1']);
    });
  });

  group('generateRandomString', () {
    test('respects the requested length bounds', () {
      for (var attempt = 0; attempt < 20; attempt++) {
        final value = generateRandomString(minLength: 5, maxLength: 9);
        expect(value.length, inInclusiveRange(5, 9));
      }
    });

    test('can produce a fixed length', () {
      expect(generateRandomString(minLength: 7, maxLength: 7).length, 7);
    });

    test('produces different values across calls', () {
      final values = List.generate(
        8,
        (_) => generateRandomString(minLength: 30, maxLength: 30),
      ).toSet();
      expect(values.length, greaterThan(1));
    });
  });

  group('getLocaleForString', () {
    test('returns null for null input', () {
      expect(getLocaleForString(null), isNull);
    });

    test('parses a bare language code', () {
      expect(getLocaleForString('en'), const Locale('en'));
    });

    test('parses language and country', () {
      expect(getLocaleForString('zh_CN'), const Locale('zh', 'CN'));
    });

    test('parses language, script and country', () {
      expect(
        getLocaleForString('zh_Hans_CN'),
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        ),
      );
    });

    test('returns null for more subtags than it understands', () {
      expect(getLocaleForString('a_b_c_d'), isNull);
    });
  });

  group('getFileNameForDisposition', () {
    test('returns null for null input', () {
      expect(getFileNameForDisposition(null), isNull);
    });

    test('reads a plain filename parameter', () {
      expect(
        getFileNameForDisposition('attachment; filename="profile.yaml"'),
        'profile.yaml',
      );
    });

    test('prefers the encoded filename* parameter', () {
      expect(
        getFileNameForDisposition(
          "attachment; filename=\"fallback.yaml\"; filename*=UTF-8''%E9%85%8D%E7%BD%AE.yaml",
        ),
        '配置.yaml',
      );
    });

    test('falls back to filename when filename* is malformed', () {
      expect(
        getFileNameForDisposition(
          'attachment; filename*=broken; filename="fallback.yaml"',
        ),
        'fallback.yaml',
      );
    });

    test('returns null when no filename parameter is present', () {
      expect(getFileNameForDisposition('attachment'), isNull);
    });
  });
}
