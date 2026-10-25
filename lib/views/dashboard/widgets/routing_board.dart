import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/common/service_probe.dart';
import 'package:skyward/core/controller.dart';
import 'package:skyward/core/method.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/outbound_ip.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';
import 'current_outbound.dart';
import 'routing_detail.dart';
import 'routing_map.dart';

/// The way out: the address the traffic leaves home by, the hops the
/// subscription puts in the way, and what it was addressed to.
///
/// Clash's connection list carries all three. `chains` names the hops from the
/// way out back, and its names hold the regions a subscription puts there;
/// `sourceGeoIP` says where the near end is, and the Core resolves it to a
/// country and no further, so the province is looked up to make the dot land on
/// the right part of the map.
///
/// The far end needs the same help twice over: `destinationGeoIP` is empty on
/// most connections, and a route that stops at the node is only half of what
/// the map is for, so the host the traffic asked for is put to a GeoIP provider
/// of its own.
class RoutingBoardCard extends ConsumerStatefulWidget {
  const RoutingBoardCard({super.key});

  @override
  ConsumerState<RoutingBoardCard> createState() => _RoutingBoardCardState();
}

class _RoutingBoardCardState extends ConsumerState<RoutingBoardCard>
    with WidgetsBindingObserver, ActivePollingMixin<RoutingBoardCard> {
  late final OutboundIpProbe _probe;
  List<TrackerInfo> _connections = const [];

  /// The one connection worth drawing, picked when the list arrived rather than
  /// when it is drawn: every rebuild -- a settings toggle, a probe answering --
  /// otherwise walked the whole list again for the same answer.
  TrackerInfo? _liveConnection;

  /// Where the traffic leaves home by, asked of a provider that names a
  /// province. Held for as long as the address does not change.
  IpLocation? _location;
  DateTime? _locationAskedAt;
  bool _locationPending = false;
  Duration _locationWait = const Duration(minutes: 15);

  /// What the live connection is headed for, when the Core did not say: kept
  /// for the connection it belongs to, so the map never shows the previous
  /// request's destination under the current one.
  _Target? _target;
  String? _targetQuery;
  bool _targetPending = false;

  /// Answers outlive the connection that asked for them — an address does not
  /// move — but not the session: a host seen once an hour ago is worth asking
  /// about again, and a browser tab leaves a lot of hosts behind it.
  final Map<String, _Target> _targets = {};
  final Map<String, DateTime> _targetAskedAt = {};
  static const _targetCacheLimit = 128;
  static const _targetRetry = Duration(minutes: 2);

  CoreController get _core => ref.read(coreHandlerProvider);

  // A route changes when the group does; the hops behind it move far less than
  // the traffic that rides them.
  @override
  Duration get pollInterval => const Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    // The province needs a provider that names one, but the country does not:
    // a plain address lookup answers that even when the richer ones are
    // unreachable from where the phone is.
    _probe = ref.read(outboundIpProbeProvider.notifier)..watch(directOutbound);
  }

  @override
  void dispose() {
    _probe.unwatch(directOutbound);
    super.dispose();
  }

  @override
  Future<void> poll(PollGuard isCurrent) async {
    if (ref.read(coreStatusProvider) != CoreStatus.connected) {
      _locationAskedAt = null;
      if ((_connections.isNotEmpty || _location != null || _target != null) &&
          isCurrent() &&
          mounted) {
        setState(() {
          _connections = const [];
          _liveConnection = null;
          _location = null;
          _target = null;
        });
      }
      _targetQuery = null;
      return;
    }
    try {
      final next = await _core.getConnections();
      if (!isCurrent() || !mounted) {
        return;
      }
      setState(() {
        _connections = next;
        _liveConnection = _liveOf(next);
      });
    } catch (error) {
      commonPrint.log(
        'routing board error: $error',
        logLevel: coreFailureLogLevel(error),
      );
    }
    unawaited(_askLocation());
    unawaited(_askTarget());
  }

  /// A province does not change while the phone stays where it is, and the
  /// lookup costs a round trip through the Core. Fifteen minutes is long
  /// enough to survive a carrier reassignment and short enough to follow one;
  /// a lookup that failed is worth retrying in a minute.
  Future<void> _askLocation() async {
    if (_locationPending) {
      return;
    }
    final askedAt = _locationAskedAt;
    if (askedAt != null && DateTime.now().difference(askedAt) < _locationWait) {
      return;
    }
    _locationPending = true;
    _locationAskedAt = DateTime.now();
    try {
      final location = await lookupIpLocation(_core, directOutbound);
      if (!mounted) {
        return;
      }
      if (location == null) {
        _locationWait = const Duration(minutes: 1);
        return;
      }
      _locationWait = const Duration(minutes: 15);
      setState(() => _location = location);
    } catch (error) {
      _locationWait = const Duration(minutes: 1);
      commonPrint.log(
        'routing board location error: $error',
        logLevel: coreFailureLogLevel(error),
      );
    } finally {
      _locationPending = false;
    }
  }

  /// Where the live request is headed, when the Core named no country for it.
  ///
  /// A new connection is a new question, and the answer to the old one is
  /// dropped before it is asked: the map is read in one glance, and a
  /// destination that belonged to the last request would be read as this one's.
  /// The answer is kept per host, so a page that opens a dozen connections to
  /// one site is asked about once.
  Future<void> _askTarget() async {
    final live = _live();
    final query = _targetQueryOf(live);
    if (query != _targetQuery) {
      _targetQuery = query;
      final cached = query == null ? null : _targets[query];
      if (_target != cached) {
        setState(() => _target = cached);
      }
    }
    if (query == null || _target != null || _targetPending) {
      return;
    }
    final askedAt = _targetAskedAt[query];
    if (askedAt != null && DateTime.now().difference(askedAt) < _targetRetry) {
      return;
    }
    _targetPending = true;
    _targetAskedAt[query] = DateTime.now();
    if (_targetAskedAt.length > _targetCacheLimit * 4) {
      final now = DateTime.now();
      _targetAskedAt.removeWhere(
        (_, at) => now.difference(at) >= _targetRetry,
      );
    }
    try {
      final location = await lookupTargetLocation(
        _core,
        query,
        proxyName: _exitOf(live) ?? '',
        timeout: const Duration(seconds: 4),
      );
      final country = geoCountryOf(location?.countryCode);
      if (country == null) {
        return;
      }
      final target = _Target(country, _placeOf(location!, country));
      if (_targets.length >= _targetCacheLimit) {
        _targets.remove(_targets.keys.first);
      }
      _targets[query] = target;
      if (!mounted || _targetQuery != query) {
        return;
      }
      setState(() => _target = target);
    } catch (error) {
      commonPrint.log(
        'routing board target error: $error',
        logLevel: coreFailureLogLevel(error),
      );
    } finally {
      _targetPending = false;
    }
  }

  /// The connection worth drawing: the one moving the most right now.
  ///
  /// Counting bytes since the connection opened picks whichever download
  /// started earliest and keeps it for the session, which is why the board
  /// used to point at something the phone was not doing. Resolvers and the
  /// reachability pings every platform runs are skipped: they are short,
  /// frequent, and never the answer.
  TrackerInfo? _live() => _liveConnection;

  static TrackerInfo? _liveOf(List<TrackerInfo> connections) {
    TrackerInfo? fastest;
    var bestSpeed = 0;
    TrackerInfo? newest;
    for (final item in connections) {
      if (_isNoise(item)) {
        continue;
      }
      final speed = (item.downloadSpeed ?? 0) + (item.uploadSpeed ?? 0);
      if (speed > bestSpeed) {
        bestSpeed = speed;
        fastest = item;
      }
      if (newest == null || item.start.isAfter(newest.start)) {
        newest = item;
      }
    }
    return fastest ?? newest;
  }

  /// Nothing here is live: the board behind the sheet already follows the
  /// connection, and the sheet is the reading of the moment it opened.
  Future<void> _showDetail(RoutingDetail detail) {
    return showSheet<void>(
      context: context,
      builder: (_) => RoutingDetailSheet(detail: detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final chinese = Localizations.localeOf(context).languageCode == 'zh';
    final mobile = !DashboardDensityScope.of(context).isDesktop;
    final hideIp = ref.watch(appSettingProvider.select((state) => state.hideIp));
    final active = _live();
    final location = _location;
    final direct = ref
        .watch(
          outboundIpProbeProvider.select(
            (state) => state.entryOf(directOutbound),
          ),
        )
        .value;
    final localCountry =
        geoCountryOfGeoIps(active?.metadata.sourceGeoIP ?? const <String>[]) ??
        geoCountryOf(location?.countryCode) ??
        geoCountryOf(direct?.countryCode);
    // Named down to the province when the provider says which one, and to the
    // city when the address is somewhere the province list does not cover.
    final localPlace = _placeIn(
      localCountry,
      geoPlaceOfRegion(location?.region) ??
          geoCityOfNode(location?.city ?? ''),
    );
    final exit = _exitOf(active);
    final relays = _relaysOf(active, chinese);
    // The Core names a destination's country on some connections and none on
    // others; when it does not, the lookup the poll loop runs fills the gap.
    final target = _target;
    final destinationCountry =
        geoCountryOfGeoIps(
          active?.metadata.destinationGeoIP ?? const <String>[],
        ) ??
        _countryOfRule(active) ??
        target?.country;
    final destinationPlace = _placeIn(destinationCountry, target?.place);
    final destinationRegion = _regionOf(
      destinationCountry,
      destinationPlace,
      chinese: chinese,
    );
    final stops = _stopsOf(
      active,
      localCountry,
      localPlace,
      destinationCountry,
      destinationPlace,
    );
    final detail = RoutingDetail(
      stops: stops,
      localIp: switch (location?.ip ?? direct?.ip) {
        final ip? => hideIp ? ipMask : ip,
        null => null,
      },
      localRegion: _regionOf(localCountry, localPlace, chinese: chinese),
      carrier: location?.org,
      exit: exit,
      chain: active == null || active.chains.isEmpty
          ? null
          : active.chains.reversed.join(' → '),
      relays: relays,
      host: active?.metadata.host,
      endpoint: _endpointOf(active),
      destinationRegion: destinationRegion,
      network: active?.metadata.network,
      process: active?.progressText,
      rule: _ruleOf(active),
      upload: active?.upload ?? 0,
      download: active?.download ?? 0,
      since: active?.start,
    );
    final openable = !detail.isEmpty;
    final openDetail = openable ? () => _showDetail(detail) : null;
    return DashboardCard(
      semanticLabel: appLocalizations.routeBoard,
      onTap: mobile ? openDetail : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.proxies,
            title: appLocalizations.routeBoard,
            chevron: mobile && openable,
            trailing: [
              if (!mobile && openDetail != null)
                Transform.translate(
                  offset: const Offset(8, 0),
                  child: DashboardIconButton(
                    glyph: AppGlyphs.chevronForward,
                    tooltip: appLocalizations.details(
                      appLocalizations.routeBoard,
                    ),
                    onPressed: openDetail,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          RouteMap(stops: stops),
          const SizedBox(height: 16),
          Row(
            spacing: 6,
            children: [
              Expanded(
                child: _Legend(
                  label: appLocalizations.routeFrom,
                  value: localPlace?.label(chinese: chinese) ??
                      localCountry?.label(chinese: chinese),
                  detail: detail.localIp,
                ),
              ),
              const _LegendArrow(),
              Expanded(
                child: _Legend(
                  label: appLocalizations.routeVia,
                  value: exit ?? (active == null ? null : appLocalizations.direct),
                  detail: relays,
                ),
              ),
              const _LegendArrow(),
              Expanded(
                child: _Legend(
                  label: appLocalizations.routeTo,
                  value: active?.title,
                  detail: destinationRegion,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The regions the hops pass through, innermost first, as one line.
  ///
  /// `chains` runs from the way out back towards the device, so reading it
  /// backwards is the order the traffic takes. A name that mentions one region
  /// says nothing the middle column does not already, so the line is left out
  /// rather than repeated.
  String? _relaysOf(TrackerInfo? active, bool chinese) {
    final seen = <GeoCountry>[];
    for (final chain in (active?.chains ?? const <String>[]).reversed) {
      for (final country in geoCountriesOfNode(chain)) {
        if (seen.isEmpty || seen.last != country) {
          seen.add(country);
        }
      }
    }
    if (seen.length < 2) {
      return null;
    }
    return seen.map((country) => country.label(chinese: chinese)).join(' · ');
  }

  /// The device, every region the hops pass through, then the destination.
  ///
  /// `chains` runs from the way out back towards the device, so it is walked
  /// backwards. A node name can name both of its ends, and a relay that does
  /// contributes two dots; two stops in one region would stack on the same
  /// dot, so the second is dropped.
  List<RouteStop> _stopsOf(
    TrackerInfo? active,
    GeoCountry? local,
    GeoPlace? localPlace,
    GeoCountry? destination,
    GeoPlace? destinationPlace,
  ) {
    final stops = <RouteStop>[
      if (local != null)
        RouteStop(local, RouteStopRole.local, place: localPlace),
    ];
    void add(GeoCountry country, GeoPlace? place) {
      if (stops.isNotEmpty && stops.last.country == country) {
        return;
      }
      stops.add(RouteStop(country, RouteStopRole.relay, place: place));
    }

    for (final chain in (active?.chains ?? const <String>[]).reversed) {
      final countries = geoCountriesOfNode(chain);
      if (countries.isEmpty) {
        continue;
      }
      // Only the last end of the name is the one the traffic leaves from, so
      // only it is worth pinning to a city — and only when the city is in that
      // country: `东京 02 | 中转 美国` names both, and the dot belongs in the
      // United States.
      final city = _placeIn(countries.last, geoCityOfNode(chain));
      for (var i = 0; i < countries.length; i++) {
        add(countries[i], i == countries.length - 1 ? city : null);
      }
    }
    if (destination == null) {
      return stops;
    }
    if (stops.isNotEmpty &&
        stops.last.country == destination &&
        stops.last.role == RouteStopRole.relay) {
      // The node and what was asked for are in one country, and one dot says
      // so; the place the node is named after is the exact end of it.
      stops[stops.length - 1] = RouteStop(
        destination,
        RouteStopRole.destination,
        place: stops.last.place ?? destinationPlace,
      );
    } else {
      stops.add(
        RouteStop(
          destination,
          RouteStopRole.destination,
          place: destinationPlace,
        ),
      );
    }
    return stops;
  }

  /// The hop the traffic leaves by, which is the first name in `chains` that a
  /// user could have chosen.
  String? _exitOf(TrackerInfo? active) {
    for (final name in active?.chains ?? const <String>[]) {
      if (!isBuiltinOutbound(name)) {
        return name;
      }
    }
    return null;
  }

  /// The name or address worth asking a GeoIP provider about, or null when the
  /// Core has already answered or has nothing to ask about.
  ///
  /// A host is asked about first and survives fake-ip, where `destinationIP` is
  /// a stand-in from a reserved range and geolocates to nowhere; a bare address
  /// is only worth asking about when it is a public one, for the same reason.
  String? _targetQueryOf(TrackerInfo? active) {
    final metadata = active?.metadata;
    if (metadata == null) {
      return null;
    }
    if (geoCountryOfGeoIps(metadata.destinationGeoIP) != null) {
      return null;
    }
    final host = metadata.host;
    if (host.isNotEmpty && ipAddressOf(host) == null) {
      return host;
    }
    final address = ipAddressOf(host) ?? metadata.destinationIP;
    return _isPublicAddress(address) ? address : null;
  }

  /// The country a matched `GEOIP` rule names, which is the Core's own reading
  /// of where the connection goes and costs no request. A payload like `LAN` or
  /// a list of two letter tags names no single country and is left alone.
  GeoCountry? _countryOfRule(TrackerInfo? active) {
    if (active == null || !active.rule.toUpperCase().contains('GEOIP')) {
      return null;
    }
    return geoCountryOfGeoIps([active.rulePayload]);
  }

  /// The finest point an answer supports: a city the map already knows how to
  /// name in both languages, else the province, else the coordinate itself
  /// under whatever the provider calls it.
  GeoPlace? _placeOf(IpLocation location, GeoCountry country) {
    final city = _placeIn(country, geoCityOfNode(location.city ?? ''));
    if (city != null) {
      return city;
    }
    final region = _placeIn(country, geoPlaceOfRegion(location.region));
    if (region != null) {
      return region;
    }
    final latitude = location.latitude;
    final longitude = location.longitude;
    final label = location.city ?? location.region;
    if (latitude == null || longitude == null || label == null) {
      return null;
    }
    return GeoPlace(latitude, longitude, label, label, country.code);
  }
}

/// What a lookup made of the far end.
final class _Target {
  const _Target(this.country, this.place);

  final GeoCountry country;
  final GeoPlace? place;
}

/// Reserved ranges: the stand-ins a fake-ip resolver hands out for a name, and
/// the private ones that never had a country to begin with.
bool _isPublicAddress(String address) {
  final parts = ipAddressOf(address)?.split('.');
  if (parts == null || parts.length != 4) {
    // A V6 address is public unless it is loopback or link-local.
    return address.isNotEmpty &&
        address != '::1' &&
        !address.toLowerCase().startsWith('fe80');
  }
  final first = int.parse(parts[0]);
  final second = int.parse(parts[1]);
  if (first == 0 || first == 10 || first == 127 || first >= 224) {
    return false;
  }
  if (first == 172 && second >= 16 && second <= 31) {
    return false;
  }
  if (first == 192 && second == 168) {
    return false;
  }
  if (first == 169 && second == 254) {
    return false;
  }
  if (first == 100 && second >= 64 && second <= 127) {
    return false;
  }
  return !(first == 198 && (second == 18 || second == 19));
}

/// A place is only worth pinning when it sits in the country the address
/// resolved to; a mismatch means the name mentioned somewhere else.
GeoPlace? _placeIn(GeoCountry? country, GeoPlace? place) {
  if (place == null || place.countryCode.isEmpty || country == null) {
    return place;
  }
  return place.countryCode == country.code ? place : null;
}

/// Country first, then the province or city inside it: the province alone
/// would leave an address outside the mainland with no country named.
String? _regionOf(
  GeoCountry? country,
  GeoPlace? place, {
  required bool chinese,
}) {
  final parts = <String>[
    if (country != null) country.label(chinese: chinese),
    if (place != null) place.label(chinese: chinese),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

String? _endpointOf(TrackerInfo? active) {
  final metadata = active?.metadata;
  if (metadata == null || metadata.destinationIP.isEmpty) {
    return null;
  }
  return metadata.destinationPort.isEmpty
      ? metadata.destinationIP
      : '${metadata.destinationIP}:${metadata.destinationPort}';
}

String? _ruleOf(TrackerInfo? active) {
  if (active == null || active.rule.isEmpty) {
    return null;
  }
  return active.rulePayload.isEmpty
      ? active.rule
      : '${active.rule}(${active.rulePayload})';
}

/// Hosts that answer their own question: a resolver's lookups, the
/// reachability probes each platform runs on a timer, and the GeoIP providers
/// this card asks about itself. The last three are the reason this list exists
/// twice over — a lookup is a burst of a few kilobytes, and a burst is what
/// `_live` is looking for.
const _noiseHosts = [
  'connectivitycheck',
  'connectivity-check',
  'captive.apple.com',
  'clients3.google.com',
  'generate_204',
  'msftconnecttest',
  'msftncsi',
  'time.android.com',
  'time.windows.com',
  'dns.alidns',
  'dns.qq.com',
  'doh.pub',
  'ip-api.com',
  'ipwho.is',
  'api.ip.sb',
  'ipinfo.io',
  'geojs.io',
  'country.is',
  'ipquery.io',
  'ident.me',
  'qifu-api.baidubce.com',
];

bool _isNoise(TrackerInfo item) {
  final metadata = item.metadata;
  // Every request the Core makes for itself — delay tests, service checks, the
  // GeoIP lookups this card runs — carries the Core's own name as its process.
  if (metadata.process == 'mihomo') {
    return true;
  }
  if (metadata.network == 'udp' && metadata.destinationPort == '53') {
    return true;
  }
  final host = metadata.host.toLowerCase();
  if (host.isEmpty) {
    return false;
  }
  return _noiseHosts.any(host.contains);
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, this.value, this.detail});

  final String label;
  final String? value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DashboardText.label(context),
        ),
        const SizedBox(height: 2),
        Text(
          value ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DashboardText.value(context, AppTextStyle.subheadline),
        ),
        // The line is always there, empty or not, so the three columns keep
        // their values on one baseline.
        Text(
          detail ?? ' ',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DashboardText.label(context),
        ),
      ],
    );
  }
}

/// Points at the next stop rather than saying anything, so it stays quiet.
class _LegendArrow extends StatelessWidget {
  const _LegendArrow();

  @override
  Widget build(BuildContext context) {
    final scale = DashboardDensityScope.scaleOf(context);
    return GlyphIcon(
      AppGlyphs.chevronForward,
      size: 12 * scale,
      color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    );
  }
}
