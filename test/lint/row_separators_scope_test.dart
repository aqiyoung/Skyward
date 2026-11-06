import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Pages reached from "More", including the ones behind "Advanced": rows are
/// settings entries or short groups, so the hairline is redundant with the
/// icon and trailing control. Long, dense lists (proxies, connections,
/// requests, logs) keep the default instead.
const _separatorFreePages = {
  'lib/views/tools.dart',
  'lib/views/about.dart',
  'lib/views/access.dart',
  'lib/views/backup_and_restore.dart',
  'lib/views/appearance.dart',
  'lib/views/hotkey.dart',
  'lib/views/developer.dart',
  'lib/views/config/general.dart',
  'lib/views/config/advanced.dart',
  'lib/views/config/diagnostics.dart',
  'lib/views/config/settings_search.dart',
  // Advanced → Network and the sibling settings sheets. `override.dart` is the
  // shell shared by DNS, NTP, sniffer and TUN, so it covers them at once.
  'lib/views/config/settings_index.dart',
  'lib/views/config/override.dart',
  'lib/views/config/ad_block.dart',
  'lib/views/config/rules.dart',
  'lib/views/config/scripts.dart',
  'lib/views/config/storage.dart',
  'lib/views/config/dns_leak.dart',
  'lib/views/config/on_demand.dart',
  'lib/views/config/user_agents.dart',
};

const _optOut = 'rowSeparators: false';

void main() {
  test('settings pages opt out of row separators, dense lists do not', () {
    final offenders = <String>[];

    for (final path in _separatorFreePages) {
      final text = File(path).readAsStringSync();
      if (!text.contains(_optOut)) {
        offenders.add('$path — settings page still draws row separators');
      }
    }

    for (final entity in Directory('lib/views').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final path = p.normalize(entity.path).replaceAll(r'\', '/');
      if (_separatorFreePages.contains(path)) {
        continue;
      }
      final text = entity.readAsStringSync();
      if (text.contains(_optOut)) {
        offenders.add(
          '$path — a dense/non-settings page must keep the default separators',
        );
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
