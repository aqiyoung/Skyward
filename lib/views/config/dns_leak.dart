import 'dart:async';
import 'dart:io';

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
const _webrtcLeakUrl = 'https://browserleaks.com/webrtc';

class DnsLeakCheck extends ConsumerStatefulWidget {
  const DnsLeakCheck({super.key, this.probe, this.stunProbe});

  final DnsProbe? probe;
  final StunProbe? stunProbe;

  @override
  ConsumerState<DnsLeakCheck> createState() => _DnsLeakCheckState();
}

class _DnsLeakCheckState extends ConsumerState<DnsLeakCheck> {
  DnsProbeResult? _result;
  StunProbeResult? _stun;
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
    final dnsFuture = _guard<DnsProbeResult>(widget.probe ?? probeDns);
    final stunFuture = _guard<StunProbeResult>(widget.stunProbe ?? probeStun);
    final dnsBounded = dnsFuture.timeout(
      leakProbeOverallTimeout,
      onTimeout: () => null,
    );
    final stunBounded = stunFuture.timeout(
      leakProbeOverallTimeout,
      onTimeout: () => null,
    );
    final dns = await dnsBounded;
    final stun = await stunBounded;
    if (!mounted) {
      return;
    }
    setState(() {
      _result = dns;
      _stun = stun;
      _running = false;
    });
  }

  Future<T?> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (_) {
      return null;
    }
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

  List<_Finding> _dnsFindings(
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

  List<_Finding> _stunFindings(AppLocalizations l, WebrtcGuard guard) {
    final stun = _stun;
    final resolved = stun?.resolved ?? false;
    final answered = stun?.answered ?? false;
    final reflected = stun?.reflected;

    final guardLevel = switch (guard) {
      WebrtcGuard.block => _Level.pass,
      WebrtcGuard.proxy => _Level.warn,
      WebrtcGuard.off => _Level.warn,
    };
    final guardDetail = switch (guard) {
      WebrtcGuard.block => null,
      WebrtcGuard.proxy => l.webrtcLeakGuardProxyBad,
      WebrtcGuard.off => l.webrtcLeakGuardOffBad,
    };

    final _Level stunLevel;
    final String? stunDetail;
    if (stun == null || !resolved) {
      stunLevel = _Level.unknown;
      stunDetail = l.webrtcLeakStunUnresolved;
    } else if (!answered) {
      stunLevel = guard == WebrtcGuard.block ? _Level.pass : _Level.unknown;
      stunDetail = guard == WebrtcGuard.block
          ? l.webrtcLeakStunBlocked
          : l.webrtcLeakStunSilent;
    } else {
      stunLevel = guard == WebrtcGuard.block ? _Level.fail : _Level.warn;
      stunDetail = l.webrtcLeakStunOpen;
    }

    final _Level reflectedLevel;
    if (reflected == null) {
      reflectedLevel = _Level.unknown;
    } else if (guard == WebrtcGuard.block) {
      reflectedLevel = _Level.fail;
    } else if (guard == WebrtcGuard.off) {
      reflectedLevel = _Level.warn;
    } else {
      reflectedLevel = _Level.pass;
    }

    return [
      (
        title: l.webrtcLeakGuard,
        detail: guardDetail ?? guard.label,
        level: guardLevel,
      ),
      (title: l.webrtcLeakStun, detail: stunDetail, level: stunLevel),
      (
        title: l.webrtcLeakReflected,
        detail: reflected ?? l.dnsLeakUnknown,
        level: reflectedLevel,
      ),
    ];
  }

  Widget _row(BuildContext context, _Finding finding) {
    return ListItem(
      leading: IconWell(_statusGlyph(finding.level), side: 24),
      title: Text(finding.title),
      subtitle: finding.detail == null ? null : Text(finding.detail!),
      trailing: Text(
        _statusText(context.appLocalizations, finding.level),
        style: context.listSubtitleStyle.copyWith(
          color: _statusColor(context.colorScheme, finding.level),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final config = ref.watch(patchClashConfigProvider);
    final status = ref.watch(coreStatusProvider);
    final guard = ref.watch(
      appSettingProvider.select((state) => state.webrtcGuard),
    );
    return Column(
      children: [
        generateSection(
          leadingGap: false,
          title: 'DNS',
          items: [
            for (final finding in _dnsFindings(l, config, status))
              _row(context, finding),
          ],
          footer: l.dnsLeakAdvice,
        ),
        const SizedBox(height: 16),
        generateSection(
          title: 'WebRTC',
          items: [
            for (final finding in _stunFindings(l, guard))
              _row(context, finding),
          ],
          footer: l.webrtcLeakAdvice,
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
                onPressed: () => unawaited(_openExternal(_dnsLeakUrl)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TonalButton(
            label: l.webrtcLeakExternal,
            glyph: AppGlyphs.link,
            onPressed: () => unawaited(_openExternal(_webrtcLeakUrl)),
          ),
        ),
      ],
    );
  }
}

Future<void> _openExternal(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    return;
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
  final lookup = _lookupAddress();
  final direct = _queryPlainResolver();
  final ipv6 = _globalIpv6();
  return DnsProbeResult(
    lookup: await lookup,
    direct: await direct,
    globalIpv6: await ipv6,
  );
}

Future<String?> _lookupAddress() async {
  try {
    final addresses = await InternetAddress.lookup(
      _probeName,
      type: InternetAddressType.IPv4,
    ).timeout(dnsProbeTimeout, onTimeout: () => <InternetAddress>[]);
    return addresses.isEmpty ? null : addresses.first.address;
  } catch (_) {
    return null;
  }
}

/// Asks a plain resolver on port 53 through a socket of our own, which is the
/// path the TUN hijack has to intercept for the answer to come back fake.
Future<String?> _queryPlainResolver() async {
  for (var attempt = 0; attempt < dnsProbeAttempts; attempt++) {
    final answer = await _plainResolverAttempt(
      name: _probeName,
      resolver: _probeResolver,
      timeout: dnsProbeTimeout ~/ dnsProbeAttempts,
    );
    if (answer != null) {
      return answer;
    }
  }
  return null;
}

Future<String?> _plainResolverAttempt({
  required String name,
  required String resolver,
  required Duration timeout,
}) async {
  RawDatagramSocket? socket;
  StreamSubscription<RawSocketEvent>? subscription;
  try {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final bound = socket;
    final transactionId = randomDnsTransactionId();
    final query = buildDnsQuery(name, transactionId);
    final completer = Completer<String?>();
    subscription = bound.listen((event) {
      if (event != RawSocketEvent.read || completer.isCompleted) {
        return;
      }
      for (
        var datagram = bound.receive();
        datagram != null;
        datagram = bound.receive()
      ) {
        final address = firstDnsAddress(datagram.data, transactionId);
        if (address != null) {
          completer.complete(address);
          break;
        }
      }
    });
    bound.send(query, InternetAddress(resolver), 53);
    return await completer.future.timeout(timeout, onTimeout: () => null);
  } catch (_) {
    return null;
  } finally {
    await subscription?.cancel();
    socket?.close();
  }
}

Future<List<String>> _globalIpv6() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv6,
    ).timeout(dnsProbeTimeout, onTimeout: () => <NetworkInterface>[]);
    final global = <String>[];
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final raw = address.rawAddress;
        if (raw.length != 16 ||
            address.isLoopback ||
            address.isLinkLocal ||
            address.isMulticast) {
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
  const DnsLeakView({super.key, this.probe, this.stunProbe});

  final DnsProbe? probe;
  final StunProbe? stunProbe;

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    return BaseScaffold(
      rowSeparators: false,
      title: l.leakCheck,
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(top: context.cardTopPadding, bottom: 16),
        children: [DnsLeakCheck(probe: probe, stunProbe: stunProbe)],
      ),
    );
  }
}
