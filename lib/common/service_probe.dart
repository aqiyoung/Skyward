import 'dart:async';
import 'dart:convert';

import 'package:skyward/common/constant.dart';
import 'package:skyward/core/controller.dart';
import 'package:skyward/models/models.dart';
import 'package:flutter/foundation.dart';

const directOutbound = 'DIRECT';
const routedOutbound = '';

/// [id] must match the checker name registered in core/service_check.go.
enum ServiceTarget {
  google('google', 'Google', 'google'),
  github('github', 'GitHub', 'github'),
  youtube('youtube', 'YouTube', 'youtube'),
  chatgpt('chatgpt', 'ChatGPT', 'openai'),
  claude('claude', 'Claude', 'claude'),
  gemini('gemini', 'Gemini', 'gemini'),
  netflix('netflix', 'Netflix', 'netflix'),
  disneyPlus('disney-plus', 'Disney+', 'disneyplus'),
  primeVideo('prime-video', 'Prime Video', 'primevideo'),
  spotify('spotify', 'Spotify', 'spotify'),
  tiktok('tiktok', 'TikTok', 'tiktok'),
  discord('discord', 'Discord', 'discord'),
  bilibili('bilibili', 'Bilibili', 'bilibili');

  const ServiceTarget(this.id, this.label, this.icon);

  final String id;
  final String label;
  final String icon;

  static ServiceTarget? byId(String id) {
    for (final target in values) {
      if (target.id == id) return target;
    }
    return null;
  }
}

enum ServiceProbeStatus {
  available('available'),
  unavailable('unavailable'),
  restricted('restricted'),
  disallowedIsp('disallowed-isp'),
  blocked('blocked'),
  unsupportedRegion('unsupported-region'),
  originalsOnly('originals-only'),
  comingSoon('coming-soon'),
  timeout('timeout'),
  failed('failed');

  const ServiceProbeStatus(this.id);

  final String id;

  static ServiceProbeStatus byId(String id) {
    for (final status in values) {
      if (status.id == id) return status;
    }
    return ServiceProbeStatus.failed;
  }
}

List<ServiceTarget> orderServiceTargets(List<String> order) {
  return {
    for (final id in order) ?ServiceTarget.byId(id),
    ...ServiceTarget.values,
  }.toList();
}

class ServiceCheck {
  const ServiceCheck(
    this.status, {
    this.delay,
    this.chains = const [],
    this.region,
    this.checkedAt,
    this.coreEpoch = 0,
    this.picksVersion = 0,
  });

  factory ServiceCheck.of(ServiceCheckItem item) {
    return ServiceCheck(
      ServiceProbeStatus.byId(item.status),
      delay: item.delay > 0 ? item.delay : null,
      chains: item.chains,
      region: item.region.isEmpty ? null : item.region,
      checkedAt: item.checkedAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(item.checkedAt)
          : null,
      coreEpoch: item.coreEpoch,
      picksVersion: item.picksVersion,
    );
  }

  final ServiceProbeStatus status;
  final int? delay;
  final List<String> chains;
  final String? region;
  final DateTime? checkedAt;
  final int coreEpoch;
  final int picksVersion;

  String? get node => chains.firstOrNull;

  @override
  bool operator ==(Object other) =>
      other is ServiceCheck &&
      other.status == status &&
      other.delay == delay &&
      listEquals(other.chains, chains) &&
      other.region == region &&
      other.checkedAt == checkedAt &&
      other.coreEpoch == coreEpoch &&
      other.picksVersion == picksVersion;

  @override
  int get hashCode => Object.hash(
    status,
    delay,
    Object.hashAll(chains),
    region,
    checkedAt,
    coreEpoch,
    picksVersion,
  );

  @override
  String toString() =>
      'ServiceCheck(${status.id}, delay: $delay, node: $node, region: $region)';
}

/// An empty [proxyName] lets the Core route by its rules; an empty [targets]
/// checks every service.
Future<Map<ServiceTarget, ServiceCheck>> checkServices(
  CoreController core, {
  String proxyName = '',
  List<ServiceTarget> targets = const [],
  Duration timeout = probeTimeoutDuration,
}) async {
  final items = await core.serviceCheck(
    ServiceCheckParams(
      proxyName: proxyName,
      names: targets.map((target) => target.id).toList(),
      timeout: timeout.inMilliseconds,
    ),
  );
  return {
    for (final item in items)
      ?ServiceTarget.byId(item.name): ServiceCheck.of(item),
  };
}

IpInfo Function(String) _json(IpInfo Function(Map<String, dynamic>) parse) {
  return (body) => parse(jsonDecode(body) as Map<String, dynamic>);
}

final Map<String, IpInfo Function(String)> ipInfoSources = {
  'https://www.cloudflare.com/cdn-cgi/trace': IpInfo.fromCloudflareTrace,
  'https://api.ip.sb/geoip': _json(IpInfo.fromIpSbJson),
  'https://ipinfo.io/json': _json(IpInfo.fromIpInfoIoJson),
  'https://ipwho.is': _json(IpInfo.fromIpWhoIsJson),
  'https://get.geojs.io/v1/ip/geo.json': _json(IpInfo.fromGeoJsJson),
  'https://api.country.is': _json(IpInfo.fromCountryIsJson),
  'https://api.ipquery.io/?format=json': _json(IpInfo.fromIpQueryJson),
  'https://ident.me/json': _json(IpInfo.fromIdentMeJson),
};

/// Raw so the route stamp survives; [parseOutboundIp] reads the address.
Future<OutboundIpResult?> lookupOutboundIp(
  CoreController core,
  String proxyName, {
  List<String>? urls,
  Duration timeout = outboundIpTimeoutDuration,
}) {
  return core.outboundIp(
    OutboundIpParams(
      proxyName: proxyName,
      urls: urls ?? ipInfoSources.keys.toList(),
      timeout: timeout.inMilliseconds,
    ),
  );
}

IpInfo? parseOutboundIp(OutboundIpResult? result) {
  if (result == null || result.error != null || result.body.isEmpty) {
    return null;
  }
  final parse = ipInfoSources[result.url];
  if (parse == null) return null;
  try {
    return parse(result.body);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

/// Where an address sits, to the province when the provider says so.
///
/// [IpInfo] carries what the status card needs and no more, and every provider
/// it asks answers with a country. The board wants the region, so it asks a
/// narrower set of providers that name one.
@immutable
final class IpLocation {
  const IpLocation({
    required this.ip,
    required this.countryCode,
    this.region,
    this.city,
    this.org,
    this.latitude,
    this.longitude,
  });

  factory IpLocation.fromIpInfoIo(Map<String, dynamic> json) => IpLocation(
    ip: _text(json['ip']) ?? '',
    countryCode: _text(json['country']) ?? '',
    region: _text(json['region']),
    city: _text(json['city']),
    org: _text(json['org']),
  );

  factory IpLocation.fromIpSb(Map<String, dynamic> json) => IpLocation(
    ip: _text(json['ip']) ?? '',
    countryCode: _text(json['country_code']) ?? '',
    region: _text(json['region']),
    city: _text(json['city']),
    org: _text(json['isp']),
    latitude: _decimal(json['latitude']),
    longitude: _decimal(json['longitude']),
  );

  factory IpLocation.fromIpApiCom(Map<String, dynamic> json) => IpLocation(
    ip: _text(json['query']) ?? '',
    countryCode: _text(json['countryCode']) ?? '',
    region: _text(json['regionName']),
    city: _text(json['city']),
    org: _text(json['isp']),
    latitude: _decimal(json['lat']),
    longitude: _decimal(json['lon']),
  );

  factory IpLocation.fromIpWhoIs(Map<String, dynamic> json) => IpLocation(
    ip: _text(json['ip']) ?? '',
    countryCode: _text(json['country_code']) ?? '',
    region: _text(json['region']),
    city: _text(json['city']),
    org: switch (json['connection']) {
      {'isp': final isp} => _text(isp),
      _ => null,
    },
    latitude: _decimal(json['latitude']),
    longitude: _decimal(json['longitude']),
  );

  factory IpLocation.fromGeoJs(Map<String, dynamic> json) => IpLocation(
    ip: _text(json['ip']) ?? '',
    countryCode: _text(json['country_code']) ?? '',
    region: _text(json['region']),
    city: _text(json['city']),
    org: _text(json['organization']),
    latitude: _decimal(json['latitude']),
    longitude: _decimal(json['longitude']),
  );

  /// Baidu's lookup answers in Chinese and is reachable from the mainland
  /// without a proxy, which is the case that matters: the other providers are
  /// asked for the same thing over a connection that may not reach them.
  factory IpLocation.fromBaidu(Map<String, dynamic> json) {
    final data = json['data'];
    final fields = data is Map ? data : const {};
    return IpLocation(
      ip: _text(json['ip']) ?? '',
      countryCode: switch (_text(fields['country'])) {
        '中国' => 'CN',
        '中国香港' => 'HK',
        '中国澳门' => 'MO',
        '中国台湾' => 'TW',
        _ => '',
      },
      region: _text(fields['prov']),
      city: _text(fields['city']),
      org: _text(fields['isp']),
    );
  }

  final String ip;
  final String countryCode;
  final String? region;
  final String? city;
  final String? org;

  /// Where the answer points on the map, when the provider says so. A country
  /// code alone has to fall back to the country's stand-in coordinate, which
  /// puts a datacentre in the capital.
  final double? latitude;
  final double? longitude;

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  /// Providers send a coordinate as a number or as a string of one.
  static double? _decimal(Object? value) => switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text),
    _ => null,
  };
}

/// Providers that name a province. The Core races them and takes the first
/// usable answer, so every entry has to name one: a provider that answers with
/// a country alone would win the race and leave the board without it.
final Map<String, IpLocation Function(String)> ipLocationSources = {
  'https://qifu-api.baidubce.com/ip/local/geo/v1/district': _location(
    IpLocation.fromBaidu,
  ),
  'https://ipinfo.io/json': _location(IpLocation.fromIpInfoIo),
  'https://api.ip.sb/geoip': _location(IpLocation.fromIpSb),
  'https://get.geojs.io/v1/ip/geo.json': _location(IpLocation.fromGeoJs),
  'https://ipwho.is': _location(IpLocation.fromIpWhoIs),
};

IpLocation Function(String) _location(
  IpLocation Function(Map<String, dynamic>) parse,
) {
  return (body) => parse(jsonDecode(body) as Map<String, dynamic>);
}

/// Asks the Core to leave by [proxyName] and read the address back with the
/// providers that name a province.
Future<IpLocation?> lookupIpLocation(
  CoreController core,
  String proxyName, {
  Duration timeout = outboundIpTimeoutDuration,
}) async {
  final result = await lookupOutboundIp(
    core,
    proxyName,
    urls: ipLocationSources.keys.toList(),
    timeout: timeout,
  );
  if (result == null || result.error != null || result.body.isEmpty) {
    return null;
  }
  final parse = ipLocationSources[result.url];
  if (parse == null) {
    return null;
  }
  try {
    return parse(result.body);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

/// A provider that answers for a target instead of for the caller.
final class _TargetSource {
  const _TargetSource(this.url, this.parse, {this.addressesOnly = false});

  /// `{}` is where the target goes.
  final String url;
  final IpLocation Function(Map<String, dynamic>) parse;

  /// The provider indexes addresses only, so a name has to be turned into one
  /// before it can be asked.
  final bool addressesOnly;
}

/// In order: the one provider that resolves a name, then two that take an
/// address. `ip-api.com` is plain HTTP — its free tier does not speak TLS —
/// which is why the address form does not stop at it.
final _targetSources = <_TargetSource>[
  _TargetSource(
    'http://ip-api.com/json/{}?fields=status,countryCode,regionName,city,lat,lon,query,isp',
    IpLocation.fromIpApiCom,
  ),
  _TargetSource(
    'https://ipwho.is/{}',
    IpLocation.fromIpWhoIs,
    addressesOnly: true,
  ),
  _TargetSource(
    'https://api.ip.sb/geoip/{}',
    IpLocation.fromIpSb,
    addressesOnly: true,
  ),
];

/// Where [target] sits, asked of a provider that takes the target in its path.
///
/// [ipLocationSources] answer "where am I", which is the wrong question about a
/// destination. Of the providers that do take the target, only `ip-api.com`
/// reads a name, and only it answers over plain HTTP, so a name is put to it
/// alone. An address can be put to all three, and there the three are
/// interchangeable -- so they are asked at once and the first usable answer
/// wins. One at a time, a provider that hangs held the card for its whole
/// timeout before the next was tried, which was the difference between a
/// destination and a blank reading.
///
/// [proxyName] is tried first so the question leaves by the same hop the traffic
/// does; an answer that never comes is asked again over whatever the rules
/// decide.
Future<IpLocation?> lookupTargetLocation(
  CoreController core,
  String target, {
  String proxyName = '',
  Duration timeout = outboundIpTimeoutDuration,
}) async {
  final address = ipAddressOf(target) != null;
  final sources = <_TargetSource>[
    for (final source in _targetSources)
      if (address || !source.addressesOnly) source,
  ];
  final proxies = proxyName.isEmpty ? const [''] : [proxyName, ''];
  for (final proxy in proxies) {
    final location = await _firstTargetAnswer(
      core,
      sources,
      target,
      proxy: proxy,
      timeout: timeout,
    );
    if (location != null) {
      return location;
    }
  }
  return null;
}

/// The first of [sources] to name a place, or null when none of them does.
///
/// Each source carries its own timeout and answers null rather than throwing,
/// so this ends at the first answer or at the slowest timeout, never at their
/// sum.
Future<IpLocation?> _firstTargetAnswer(
  CoreController core,
  List<_TargetSource> sources,
  String target, {
  required String proxy,
  required Duration timeout,
}) {
  if (sources.length == 1) {
    return _askTargetSource(
      core,
      sources.single,
      target,
      proxy: proxy,
      timeout: timeout,
    );
  }
  final completer = Completer<IpLocation?>();
  var pending = sources.length;
  for (final source in sources) {
    unawaited(
      _askTargetSource(
        core,
        source,
        target,
        proxy: proxy,
        timeout: timeout,
      ).then((location) {
        if (location != null && !completer.isCompleted) {
          completer.complete(location);
        }
        if (--pending == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      }),
    );
  }
  return completer.future;
}

Future<IpLocation?> _askTargetSource(
  CoreController core,
  _TargetSource source,
  String target, {
  required String proxy,
  required Duration timeout,
}) async {
  final url = source.url.replaceFirst(
    '{}',
    // An address is already a path segment; a name could carry anything.
    ipAddressOf(target) != null ? target : Uri.encodeComponent(target),
  );
  ProbeResult? result;
  try {
    result = await core.probe(
      ProbeParams(
        url: url,
        proxyName: proxy,
        timeout: timeout.inMilliseconds,
        maxBody: 8192,
      ),
    );
  } catch (_) {
    return null;
  }
  if (result == null || result.error != null || result.statusCode != 200) {
    return null;
  }
  Object? json;
  try {
    json = jsonDecode(result.body);
  } on FormatException {
    return null;
  }
  if (json is! Map<String, dynamic>) {
    return null;
  }
  IpLocation location;
  try {
    location = source.parse(json);
  } on TypeError {
    return null;
  }
  return location.countryCode.isEmpty ? null : location;
}

final _ipv4Pattern = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');

/// The address [value] is, or null when it is a name.
///
/// A name and an address are asked of different providers, and the difference
/// cannot be guessed from a failure: `ipwho.is` answers 404 for a name it could
/// have resolved.
String? ipAddressOf(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final match = _ipv4Pattern.firstMatch(trimmed);
  if (match != null) {
    for (var group = 1; group <= 4; group++) {
      if (int.parse(match.group(group)!) > 255) {
        return null;
      }
    }
    return trimmed;
  }
  // V6 is only worth telling apart from a name, not reading.
  return trimmed.contains(':') ? trimmed : null;
}
