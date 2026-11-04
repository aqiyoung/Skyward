import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/views/config/ad_block.dart';
import 'package:skyward/views/config/advanced.dart';
import 'package:skyward/views/config/diagnostics.dart';
import 'package:skyward/views/config/dns.dart';
import 'package:skyward/views/config/general.dart';
import 'package:skyward/views/config/network.dart';
import 'package:skyward/views/config/rules.dart';
import 'package:skyward/views/config/scripts.dart';
import 'package:skyward/views/config/storage.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// One row a reader can find by typing part of its name.
///
/// [page] names the list the row sits in, and [view] builds that list, so a
/// hit opens the page the row lives on without the index knowing where the row
/// sits inside it. A row missing here cannot be found by settings search, so a
/// new row should come with its entry.
class SettingsEntry {
  const SettingsEntry({
    required this.title,
    required this.page,
    required this.view,
  });

  final ConfigLabel title;
  final ConfigLabel page;
  final Widget Function(BuildContext context) view;

  Iterable<String?> fieldsOf(AppLocalizations appLocalizations) => [
    title(appLocalizations),
    page(appLocalizations),
  ];
}

/// Rows of the lists that carry enough of them to be worth searching.
final settingsEntries = <SettingsEntry>[
  ..._generalEntries,
  ..._networkEntries,
  ..._dnsEntries,
  ..._advancedEntries,
  ..._maintenanceEntries,
];

final _generalEntries = <SettingsEntry>[
  SettingsEntry(
    title: (l) => l.autoLaunch,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.silentLaunch,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.autoRun,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.minimizeOnExit,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.allowLan,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.externalController,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.externalControllerSecret,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.authentication,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.account,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.password,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.port,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.unifiedDelay,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.tcpConcurrent,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.findProcessMode,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.autoCloseConnections,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.onlyStatisticsProxy,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.checkCertificate,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.autoCheckUpdate,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.appendSystemDns,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.geodataLoader,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.logLevel,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.logcat,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.testUrl,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.userAgent,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => 'Hosts',
    page: (l) => l.general,
    view: _generalView,
  ),
];

final _networkEntries = <SettingsEntry>[
  SettingsEntry(
    title: (l) => 'VPN',
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.tun,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.stackMode,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => 'MTU',
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.allowBypass,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.bypassPrivateRoute,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.bypassDomain,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.routeAddress,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.routeExcludeAddress,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.systemProxy,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => 'IPv6',
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.autoSetSystemDns,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.dnsHijacking,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.interfaceNameMode,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.interfaceName,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.disableKeepAlive,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.keepAliveIdle,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.routingMark,
    page: (l) => l.network,
    view: _networkView,
  ),
];

/// DNS is one switch after another, so every key it can override is a row a
/// reader may look for by name.
final _dnsEntries = <SettingsEntry>[
  for (final key in DnsOverrideKey.values)
    SettingsEntry(title: key.label, page: (l) => 'DNS', view: _dnsView),
];

/// The advanced page's rows open other lists rather than change a value, but
/// they are still settings a reader looks for by name.
final _advancedEntries = <SettingsEntry>[
  SettingsEntry(
    title: (l) => l.network,
    page: (l) => l.advancedConfig,
    view: _advancedView,
  ),
  SettingsEntry(
    title: (l) => 'DNS',
    page: (l) => l.advancedConfig,
    view: _dnsView,
  ),
  SettingsEntry(
    title: (l) => l.rulePresetAdBlock,
    page: (l) => l.advancedConfig,
    view: _adBlockView,
  ),
  SettingsEntry(
    title: (l) => l.addedRules,
    page: (l) => l.advancedConfig,
    view: _rulesView,
  ),
  SettingsEntry(
    title: (l) => l.script,
    page: (l) => l.advancedConfig,
    view: _scriptsView,
  ),
];

/// The two pages that read the app's own state rather than change a setting.
final _maintenanceEntries = <SettingsEntry>[
  SettingsEntry(
    title: (l) => l.storage,
    page: (l) => l.settings,
    view: _storageView,
  ),
  SettingsEntry(
    title: (l) => l.diagnostics,
    page: (l) => l.settings,
    view: _diagnosticsView,
  ),
];

/// Kept as tear-offs so the entries stay const.
Widget _generalView(BuildContext context) => const GeneralView();

Widget _networkView(BuildContext context) => BaseScaffold(
  title: context.appLocalizations.network,
  body: const NetworkListView(),
);

Widget _dnsView(BuildContext context) => const DnsView();

Widget _advancedView(BuildContext context) => const AdvancedConfigView();

Widget _adBlockView(BuildContext context) => const AdBlockView();

Widget _rulesView(BuildContext context) => const AddedRulesView();

Widget _scriptsView(BuildContext context) => const ScriptsView();

Widget _storageView(BuildContext context) => const StorageView();

Widget _diagnosticsView(BuildContext context) => const DiagnosticsView();
