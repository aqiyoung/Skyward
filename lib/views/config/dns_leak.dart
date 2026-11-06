import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/providers/config.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// What the device's own resolver answers with when asked twice: once through
/// the ordinary lookup path, once straight at a plain resolver on port 53.
///
/// The second answer is the one that carries meaning. With the TUN hijack in
/// place, a query addressed to 223.5.5.5 is captured before it leaves and the
/// core answers it with a fake address; a real address in that slot means the
/// packet went out on its own.
class DnsProbeResult {
  const DnsProbeResult({this.lookup, this.direct, this.globalIpv6 = const []});

  /// The address the system resolver returned for the probe name.
  final String? lookup;

  /// The address a plain UDP query to a public resolver returned, or null when
  /// nothing came back in time.
  final String? direct;

  /// Global (non-link-local, non-unique-local) IPv6 addresses this device
  /// holds. Any entry is a path around an IPv4-only capture.
  final List<String> globalIpv6;
}

/// Runs the probes. Injected so a widget test can answer without a socket.
typedef DnsProbe = Future<DnsProbeResult> Function();

enum _Level { pass, warn, fail, unknown }

typedef _Finding = ({String title, String? detail, _Level level});

/// The name asked in both probes. Any name works under fake-IP, so this only
/// has to be one that a plain resolver can answer.
const _probeName = 'www.bing.com';

/// The resolver the direct probe addresses. Reachable without DNS itself,
/// which is the point: a hostname here would need the path under test.
const _probeResolver = '223.5.5.5';

const _dnsLeakUrl = 'https://browserleaks.com/dns';

class DnsLeakCheck extends ConsumerStatefulWidget {
  const DnsLeakCheck({super.key, this.probe});

  final DnsProbe? probe;

  @override
  ConsumerState<DnsLeakCheck> createState() => _DnsLeakCheckState();
}

class _DnsLeakCheckState extends ConsumerState<DnsLeakCheck> {
  DnsProbeResult? _result;
  var _running = false;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    if (_running) {
      return;
    }
    setState(() => _running = true);
    DnsProbeResult? result;
    try {
      result = await (widget.probe ?? probeDns)();
    } catch (_) {
      result = null;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _result = result;
      _running = false;
    });
  }

  String _statusText(AppLocalizations l, _Level level) {
    return switch (level) {
      _Level.pass => l.dnsLeakPass,
      _Level.warn => l.dnsLeakWarn,
      _Level.fail => l.dnsLeakFail,
      _Level.unknown => l.dnsLeakUnknown,
    };
  }

  Color _statusColor(ColorScheme scheme, _Level level) {
    return switch (level) {
      _Level.pass => scheme.primary,
      _Level.warn => scheme.tertiary,
      _Level.fail => scheme.error,
      _Level.unknown => scheme.onSurfaceVariant,
    };
  }

  Glyph _statusGlyph(_Level level) {
    return switch (level) {
      _Level.pass => AppGlyphs.check,
      _Level.warn => AppGlyphs.warning,
      _Level.fail => AppGlyphs.error,
      _Level.unknown => AppGlyphs.info,
    };
  }

  List<_Finding> _findings(
    AppLocalizations l,
    PatchClashConfig config,
    CoreStatus status,
  ) {
    final result = _result;
    final running = status == CoreStatus.connected;
    final vpnOn = system.isAndroid
        ? ref.read(vpnSettingProvider).enable
        : config.tun.enable;
    final captured = running && vpnOn;

    final hijack = config.tunOverrideKeys.contains(TunOverrideKey.dnsHijack)
        ? config.tunOverride.dnsHijack
        : defaultDnsHijack;
    final hijackOn = hijack.any((e) => e.startsWith('any:53'));

    final nameservers = config.dns.nameserver;
    // An empty set means nothing was overridden, so the built-in encrypted
    // upstreams are what the core uses.
    final encrypted =
        nameservers.isEmpty ||
        nameservers.any(
          (e) => e.startsWith('https://') || e.startsWith('tls://'),
        );

    final lookup = result?.lookup;
    final direct = result?.direct;
    final ipv6 = result?.globalIpv6 ?? const <String>[];

    return [
      (
        title: l.dnsLeakTunnel,
        detail: captured ? null : l.dnsLeakTunnelBad,
        level: captured ? _Level.pass : _Level.fail,
      ),
      (
        title: l.dnsLeakHijack,
        detail: hijackOn ? null : l.dnsLeakHijackBad,
        level: hijackOn ? _Level.pass : _Level.fail,
      ),
      (
        title: l.dnsLeakEncrypted,
        detail: encrypted ? null : l.dnsLeakEncryptedBad,
        level: encrypted ? _Level.pass : _Level.warn,
      ),
      (
        title: l.dnsLeakFakeIp,
        // The address itself is the finding: 198.18.x.x says the core answered,
        // anything else is what the device was told without it.
        detail: lookup ?? l.dnsLeakUnknown,
        level: result == null
            ? _Level.unknown
            : isFakeIp(lookup)
            ? _Level.pass
            : _Level.warn,
      ),
      (
        title: l.dnsLeakDirect,
        detail: direct ?? l.dnsLeakUnknown,
        level: result == null
            ? _Level.unknown
            : direct == null
            ? _Level.unknown
            : isFakeIp(direct)
            ? _Level.pass
            : _Level.fail,
      ),
      (
        title: l.dnsLeakIpv6,
        detail: result == null
            ? l.dnsLeakUnknown
            : ipv6.isEmpty
            ? null
            : ipv6.join(', '),
        level: result == null
            ? _Level.unknown
            : ipv6.isEmpty
            ? _Level.pass
            : _Level.warn,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final config = ref.watch(patchClashConfigProvider);
    final status = ref.watch(coreStatusProvider);
    final findings = _findings(l, config, status);
    return Column(
      children: [
        generateSection(
          leadingGap: false,
          items: [
            for (final finding in findings)
              ListItem(
                leading: IconWell(_statusGlyph(finding.level), side: 24),
                title: Text(finding.title),
                subtitle: finding.detail == null
                    ? null
                    : Text(finding.detail!),
                trailing: Text(
                  _statusText(l, finding.level),
                  style: context.listSubtitleStyle.copyWith(
                    color: _statusColor(context.colorScheme, finding.level),
                  ),
                ),
              ),
          ],
          footer: l.dnsLeakAdvice,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TonalButton(
                label: _running ? l.dnsLeakRunning : l.dnsLeakRerun,
                glyph: AppGlyphs.refresh,
                onPressed: _running ? null : _run,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TonalButton(
                label: l.dnsLeakExternal,
                glyph: AppGlyphs.link,
                onPressed: () => unawaited(launchUrl(Uri.parse(_dnsLeakUrl))),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// True for the 198.18.0.0/15 block the core hands out under fake-IP.
bool isFakeIp(String? address) {
  if (address == null) {
    return false;
  }
  final parts = address.split('.');
  if (parts.length != 4) {
    return false;
  }
  return parts[0] == '198' && (parts[1] == '18' || parts[1] == '19');
}

/// Runs both probes against the running system.
Future<DnsProbeResult> probeDns() async {
  final lookup = await _lookupAddress();
  final direct = await _queryPlainResolver();
  final ipv6 = await _globalIpv6();
  return DnsProbeResult(lookup: lookup, direct: direct, globalIpv6: ipv6);
}

Future<String?> _lookupAddress() async {
  try {
    final addresses = await InternetAddress.lookup(
      _probeName,
      type: InternetAddressType.IPv4,
    );
    return addresses.isEmpty ? null : addresses.first.address;
  } catch (_) {
    return null;
  }
}

/// Asks a plain resolver on port 53 through a socket of our own, which is the
/// path the TUN hijack has to intercept for the answer to come back fake.
Future<String?> _queryPlainResolver() async {
  RawDatagramSocket? socket;
  StreamSubscription<RawSocketEvent>? subscription;
  try {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final bound = socket;
    final query = _buildQuery(_probeName);
    final completer = Completer<String?>();
    subscription = bound.listen((event) {
      if (event != RawSocketEvent.read) {
        return;
      }
      final datagram = bound.receive();
      if (datagram == null || completer.isCompleted) {
        return;
      }
      completer.complete(_firstAddress(datagram.data));
    });
    bound.send(query, InternetAddress(_probeResolver), 53);
    return await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => null,
    );
  } catch (_) {
    return null;
  } finally {
    await subscription?.cancel();
    socket?.close();
  }
}

Uint8List _buildQuery(String name) {
  final builder = BytesBuilder();
  // One question, recursion desired, no answers or authority expected.
  builder.add([0x12, 0x34, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
  for (final label in name.split('.')) {
    builder.addByte(label.length);
    builder.add(label.codeUnits);
  }
  builder.addByte(0);
  builder.add([0x00, 0x01, 0x00, 0x01]);
  return builder.toBytes();
}

/// Walks to the first A record. Enough of the format to read an answer, not a
/// resolver: no caching, no follow-up queries.
String? _firstAddress(Uint8List data) {
  if (data.length < 12) {
    return null;
  }
  final questions = (data[4] << 8) | data[5];
  final answers = (data[6] << 8) | data[7];
  var offset = 12;
  for (var i = 0; i < questions; i++) {
    offset = _skipName(data, offset);
    offset += 4;
  }
  for (var i = 0; i < answers; i++) {
    offset = _skipName(data, offset);
    if (offset + 10 > data.length) {
      return null;
    }
    final type = (data[offset] << 8) | data[offset + 1];
    final length = (data[offset + 8] << 8) | data[offset + 9];
    offset += 10;
    if (type == 1 && length == 4 && offset + 4 <= data.length) {
      return '${data[offset]}.${data[offset + 1]}.'
          '${data[offset + 2]}.${data[offset + 3]}';
    }
    offset += length;
  }
  return null;
}

int _skipName(Uint8List data, int offset) {
  while (offset < data.length) {
    final length = data[offset];
    if (length == 0) {
      return offset + 1;
    }
    if ((length & 0xC0) == 0xC0) {
      return offset + 2;
    }
    offset += length + 1;
  }
  return offset;
}

Future<List<String>> _globalIpv6() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv6,
    );
    final global = <String>[];
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final raw = address.rawAddress;
        if (raw.length != 16 || address.isLoopback || address.isLinkLocal) {
          continue;
        }
        // fc00::/7 is the unique-local block, which never leaves the LAN.
        if ((raw[0] & 0xFE) == 0xFC) {
          continue;
        }
        global.add(address.address);
      }
    }
    return global;
  } catch (_) {
    return const [];
  }
}

/// Page wrapper around [DnsLeakCheck], kept so the standalone entry and
/// the widget test can still open it as a full screen.
class DnsLeakView extends StatelessWidget {
  const DnsLeakView({super.key, this.probe});

  final DnsProbe? probe;

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    return BaseScaffold(
      rowSeparators: false,
      title: l.dnsLeakCheck,
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(top: context.cardTopPadding, bottom: 16),
        children: [DnsLeakCheck(probe: probe)],
      ),
    );
  }
}
