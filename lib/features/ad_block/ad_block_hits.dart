import 'dart:isolate';

import 'package:skyward/database/database.dart';
import 'package:skyward/features/ad_block/ad_block.dart';

/// One blocked domain and how often it was hit in the selected period.
typedef AdBlockHit = ({String domain, int hits});

/// Only the fields the aggregation needs, sent to the isolate as plain records
/// rather than Drift rows.
typedef _PlainRow = ({String host, String payload, int connections});

/// Extracts the domain payloads of the module's REJECT rules. These are the
/// names that, when a connection matches one, mihomo records in `rulePayload`
/// (or in `host` for a plain domain match).
final Set<String> _adDomains = () {
  final domains = <String>{};
  for (final raw in adBlockRules) {
    final parts = raw.split(',');
    if (parts.length >= 2) {
      final payload = parts[1].trim().toLowerCase();
      if (payload.isNotEmpty) domains.add(payload);
    }
  }
  return domains;
}();

/// True when [name] is one of the blocked domains or a subdomain of one.
bool _isAdDomain(String name) {
  final value = name.trim().toLowerCase();
  if (value.isEmpty) return false;
  if (_adDomains.contains(value)) return true;
  for (final domain in _adDomains) {
    if (value.endsWith('.$domain')) return true;
  }
  return false;
}

List<AdBlockHit> _aggregate(List<_PlainRow> rows) {
  final counts = <String, int>{};
  for (final row in rows) {
    final connections = row.connections > 0 ? row.connections : 1;
    final host = row.host.toLowerCase();
    final payload = row.payload.toLowerCase();
    String? domain;
    if (_isAdDomain(host)) {
      domain = host;
    } else if (_isAdDomain(payload)) {
      domain = payload;
    }
    if (domain == null) continue;
    counts[domain] = (counts[domain] ?? 0) + connections;
  }
  return [
    for (final entry in counts.entries)
      (domain: entry.key, hits: entry.value),
  ]..sort((a, b) => b.hits.compareTo(a.hits));
}

/// Aggregates ad-rule hits from native traffic history rows in a background
/// isolate. A week of history can be tens of thousands of rows, and matching
/// each host against every blocked domain on the UI isolate made the dashboard
/// stutter whenever the history sync landed.
Future<List<AdBlockHit>> adBlockHits(List<NativeTrafficRow> rows) {
  final plain = [
    for (final row in rows)
      (
        host: row.host,
        payload: row.rulePayload,
        connections: row.connections,
      ),
  ];
  return Isolate.run(() => _aggregate(plain));
}
