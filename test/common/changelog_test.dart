import 'package:skyward/common/changelog.dart';
import 'package:skyward/models/changelog.dart';
import 'package:flutter_test/flutter_test.dart';

String _body(String payload) =>
    '<!-- flclash:changelog:begin -->\n'
    '### Features\n'
    '- Override scripts\n'
    '<!-- flclash:changelog:end -->\n'
    '\n'
    '$releaseChangelogJsonMarker\n'
    '$payload\n'
    '-->\n'
    '\n'
    '| Platform | Download |\n';

const _payload =
    '{"schemaVersion":2,"versions":[{"version":"0.8.96","tag":"v0.8.96",'
    '"date":"2026-08-16","prerelease":false,"groups":[{"type":"feat",'
    '"entries":[{"id":"1a2b3c4","scope":"profiles","text":'
    '"Override scripts"}]}]}]}';

void main() {
  group('parseReleaseChangelog', () {
    test('reads the payload embedded in a release body', () {
      final version = parseReleaseChangelog(_body(_payload));

      expect(version?.tag, 'v0.8.96');
      expect(version?.date, '2026-08-16');
      final entry = version!.visibleGroups.single.entries.single;
      expect(version.visibleGroups.single.type, ChangelogType.feat);
      expect(entry.scope, 'profiles');
      expect(entry.text, 'Override scripts');
    });

    test('decodes the escaped > the renderer writes for a `-->` entry', () {
      const payload =
          '{"schemaVersion":2,"versions":[{"version":"0.8.96",'
          '"tag":"v0.8.96","date":"","prerelease":false,"groups":'
          '[{"type":"fix","entries":[{"id":"1a2b3c4","text":'
          r'"Handle a --\u003e sequence"}]}]}]}';

      final version = parseReleaseChangelog(_body(payload));

      expect(
        version?.visibleGroups.single.entries.single.text,
        'Handle a --> sequence',
      );
    });

    test('shows the Chinese entry when the app runs in Chinese', () {
      const payload =
          '{"schemaVersion":2,"versions":[{"version":"0.8.96",'
          '"tag":"v0.8.96","date":"","prerelease":false,"groups":'
          '[{"type":"feat","entries":[{"id":"1a2b3c4",'
          '"text":"Override scripts","textZh":"覆盖脚本"}]}]}]}';

      final zh = parseReleaseChangelog(_body(payload), languageCode: 'zh');
      final en = parseReleaseChangelog(_body(payload), languageCode: 'en');

      expect(zh?.visibleGroups.single.entries.single.text, '覆盖脚本');
      expect(en?.visibleGroups.single.entries.single.text, 'Override scripts');
    });

    test('falls back to English for an entry with no translation', () {
      final zh = parseReleaseChangelog(_body(_payload), languageCode: 'zh');

      expect(zh?.visibleGroups.single.entries.single.text, 'Override scripts');
    });

    test('returns null for a body without the payload', () {
      expect(parseReleaseChangelog('- Override scripts'), isNull);
    });

    test('returns null for a null body', () {
      expect(parseReleaseChangelog(null), isNull);
    });

    test('returns null when the comment is never closed', () {
      expect(
        parseReleaseChangelog('$releaseChangelogJsonMarker\n$_payload\n'),
        isNull,
      );
    });

    test('returns null for a payload from a newer schema', () {
      expect(
        parseReleaseChangelog(
          _body(
            '{"schemaVersion":3,"versions":[{"version":"0.9.0",'
            '"tag":"v0.9.0","date":"","prerelease":false,"groups":[]}]}',
          ),
        ),
        isNull,
      );
    });

    test('returns null for a payload that is not valid json', () {
      expect(parseReleaseChangelog(_body('{oops')), isNull);
    });

    test('returns null when the payload carries no version', () {
      expect(
        parseReleaseChangelog(_body('{"schemaVersion":2,"versions":[]}')),
        isNull,
      );
    });

    test('returns null for the retired schema 1 payload shape', () {
      expect(
        parseReleaseChangelog(
          _body(
            '{"schemaVersion":1,"versions":[{"version":"0.8.96",'
            '"tag":"v0.8.96","date":"","prerelease":false,"groups":'
            '[{"type":"feat","entries":[{"id":"1a2b3c4","text":'
            '{"en":"Override scripts"}}]}]}]}',
          ),
        ),
        isNull,
      );
    });
  });
}
