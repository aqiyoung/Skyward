import 'package:skyward/common/common.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

import 'routing_map.dart';

/// The route the board draws, said in full.
///
/// The three columns under the map have one line each and a phone width, which
/// is enough for the shape of the answer and never for the whole of it: a node
/// named in two languages, a province, an operator, the rule that matched. This
/// is the same reading with nothing cut short, and the map again at a size that
/// makes the arc worth looking at.
@immutable
final class RoutingDetail {
  const RoutingDetail({
    required this.stops,
    this.localIp,
    this.localRegion,
    this.carrier,
    this.exit,
    this.chain,
    this.relays,
    this.host,
    this.endpoint,
    this.destinationRegion,
    this.network,
    this.process,
    this.rule,
    this.upload = 0,
    this.download = 0,
    this.since,
  });

  /// What the map draws, in the order the traffic takes.
  final List<RouteStop> stops;

  /// The address the traffic leaves home by.
  final String? localIp;

  /// Country, then the province or city inside it.
  final String? localRegion;

  /// Whoever the address belongs to.
  final String? carrier;

  /// The hop the traffic leaves by.
  final String? exit;

  /// Every hop the subscription puts in the way, in the order they are taken.
  final String? chain;

  /// The regions those hops sit in, as one line.
  final String? relays;

  /// What was asked for.
  final String? host;

  /// Where that resolved to.
  final String? endpoint;

  final String? destinationRegion;
  final String? network;
  final String? process;

  /// The rule that sent the request this way, with its payload.
  final String? rule;

  final int upload;
  final int download;
  final DateTime? since;

  /// Nothing worth opening: no connection to describe.
  bool get isEmpty => stops.isEmpty && _blank(host) && _blank(endpoint);
}

bool _blank(String? value) => value == null || value.trim().isEmpty;

/// The whole path as one line, from the phone to what it asked for. A stop
/// with no place of its own is only as exact as its country, and that is what
/// the line then says.
String routeSummary(List<RouteStop> stops, {required bool chinese}) => stops
    .map(
      (stop) =>
          stop.place?.label(chinese: chinese) ??
          stop.country.label(chinese: chinese),
    )
    .join(' → ');

class RoutingDetailSheet extends StatelessWidget {
  const RoutingDetailSheet({
    super.key,
    required this.detail,
    this.globe = false,
  });

  final RoutingDetail detail;

  /// The sheet shows the same view the card behind it was showing.
  final bool globe;

  /// A row is only worth its space when it says something.
  List<Widget> _rows(Iterable<(String, String?)> entries) => [
    for (final (title, value) in entries)
      if (!_blank(value)) DetailRow.text(title: title, value: value!.trim()),
  ];

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final chinese = Localizations.localeOf(context).languageCode == 'zh';
    return CommonScaffold(
      title: appLocalizations.details(appLocalizations.routeBoard),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.contentTopPadding,
          bottom: 20 + context.bottomInset,
        ),
        children: [
          if (detail.stops.isNotEmpty) ...[
            RouteMap(stops: detail.stops, globe: globe),
            const SizedBox(height: 10),
            Text(
              routeSummary(detail.stops, chinese: chinese),
              textAlign: TextAlign.center,
              style: AppTextStyle.subheadline
                  .of(context)
                  .copyWith(color: context.colorScheme.onSurfaceVariant),
            ),
          ],
          generateSection(
            title: appLocalizations.routeFrom,
            items: _rows([
              (appLocalizations.ipAddress, detail.localIp),
              (appLocalizations.country, detail.localRegion),
              (appLocalizations.routeCarrier, detail.carrier),
            ]),
          ),
          generateSection(
            title: appLocalizations.routeVia,
            items: _rows([
              (appLocalizations.outboundExit, detail.exit),
              (appLocalizations.proxyChains, detail.chain),
              (appLocalizations.country, detail.relays),
            ]),
          ),
          generateSection(
            title: appLocalizations.routeTo,
            items: _rows([
              (appLocalizations.domain, detail.host),
              (appLocalizations.destination, detail.endpoint),
              (appLocalizations.country, detail.destinationRegion),
              (appLocalizations.networkType, detail.network),
              (appLocalizations.process, detail.process),
              (appLocalizations.rule, detail.rule),
            ]),
          ),
          if (detail.since case final since?)
            generateSection(
              title: appLocalizations.basicInfo,
              items: _rows([
                (appLocalizations.upload, detail.upload.traffic.show),
                (appLocalizations.download, detail.download.traffic.show),
                (appLocalizations.creationTime, since.showFull),
              ]),
            ),
        ],
      ),
    );
  }
}
