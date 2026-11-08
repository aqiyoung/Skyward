import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const dnsProbeTimeout = Duration(seconds: 3);
const dnsProbeAttempts = 2;
const stunLookupTimeout = Duration(seconds: 3);
const stunResponseTimeout = Duration(seconds: 2);
const stunAttempts = 2;
const stunOverallTimeout = Duration(seconds: 6);
const leakProbeOverallTimeout = Duration(seconds: 12);

const stunMagicCookie = 0x2112A442;

/// Ports here are the ones the WebRTC guard rejects, so reaching one is also
/// the signal that the guard is not in force.
const stunEndpoints = <String, int>{
  'stun.l.google.com': 19302,
  'stun.cloudflare.com': 3478,
  'stun.services.mozilla.com': 3478,
};

class StunProbeResult {
  const StunProbeResult({
    required this.resolved,
    required this.answered,
    this.reflected,
    this.server,
  });

  /// Whether any STUN host resolved at all. A dead network is not a pass.
  final bool resolved;

  /// Whether a matching Binding Success Response came back.
  final bool answered;
  final String? reflected;
  final String? server;
}

typedef StunProbe = Future<StunProbeResult> Function();

typedef _StunTarget = ({String host, int port, InternetAddress address});
typedef _StunAnswer = ({String host, String reflected});

Future<StunProbeResult> probeStun() async {
  final targets = await _resolveStunEndpoints();
  if (targets.isEmpty) {
    return const StunProbeResult(resolved: false, answered: false);
  }
  final attempts = <Future<_StunAnswer?>>[
    for (final target in targets) _bindingRequest(target),
  ];
  final completer = Completer<_StunAnswer?>();
  for (final attempt in attempts) {
    unawaited(
      attempt.then((answer) {
        if (answer != null && !completer.isCompleted) {
          completer.complete(answer);
        }
      }),
    );
  }
  unawaited(
    Future.wait(attempts).then((_) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }),
  );
  final first = await completer.future.timeout(
    stunOverallTimeout,
    onTimeout: () => null,
  );
  if (first == null) {
    return const StunProbeResult(resolved: true, answered: false);
  }
  return StunProbeResult(
    resolved: true,
    answered: true,
    reflected: first.reflected,
    server: first.host,
  );
}

Future<List<_StunTarget>> _resolveStunEndpoints() async {
  final groups = await Future.wait([
    for (final endpoint in stunEndpoints.entries)
      _resolveOne(endpoint.key, endpoint.value),
  ]).timeout(stunLookupTimeout, onTimeout: () => <List<_StunTarget>>[]);
  return [for (final group in groups) ...group];
}

Future<List<_StunTarget>> _resolveOne(String host, int port) async {
  try {
    final addresses = await InternetAddress.lookup(
      host,
      type: InternetAddressType.IPv4,
    ).timeout(stunLookupTimeout, onTimeout: () => <InternetAddress>[]);
    return [
      for (final address in addresses.take(1))
        (host: host, port: port, address: address),
    ];
  } catch (_) {
    return const [];
  }
}

Future<_StunAnswer?> _bindingRequest(_StunTarget target) async {
  RawDatagramSocket? socket;
  StreamSubscription<RawSocketEvent>? subscription;
  try {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final bound = socket;
    final transactionId = randomTransactionId();
    final request = buildStunBindingRequest(transactionId);
    Completer<String?>? pending;
    subscription = bound.listen((event) {
      if (event != RawSocketEvent.read) return;
      final completer = pending;
      if (completer == null || completer.isCompleted) return;
      for (
        var datagram = bound.receive();
        datagram != null;
        datagram = bound.receive()
      ) {
        final address = parseStunBindingResponse(datagram.data, transactionId);
        if (address != null) {
          completer.complete(address);
          break;
        }
      }
    });
    for (var attempt = 0; attempt < stunAttempts; attempt++) {
      pending = Completer<String?>();
      bound.send(request, target.address, target.port);
      final address = await pending.future.timeout(
        stunResponseTimeout,
        onTimeout: () => null,
      );
      if (address != null) {
        return (host: target.host, reflected: address);
      }
    }
    return null;
  } catch (_) {
    return null;
  } finally {
    await subscription?.cancel();
    socket?.close();
  }
}

Uint8List randomTransactionId() {
  final random = Random.secure();
  return Uint8List.fromList(List<int>.generate(12, (_) => random.nextInt(256)));
}

Uint8List buildStunBindingRequest(Uint8List transactionId) {
  if (transactionId.length != 12) {
    throw ArgumentError.value(transactionId.length, 'transactionId', 'want 12');
  }
  final bytes = Uint8List(20);
  final view = ByteData.sublistView(bytes);
  view.setUint16(0, 0x0001);
  view.setUint16(2, 0);
  view.setUint32(4, stunMagicCookie);
  bytes.setRange(8, 20, transactionId);
  return bytes;
}

String? parseStunBindingResponse(Uint8List data, Uint8List transactionId) {
  if (data.length < 20 || transactionId.length != 12) return null;
  final view = ByteData.sublistView(data);
  if (view.getUint16(0) != 0x0101 || view.getUint32(4) != stunMagicCookie) {
    return null;
  }
  for (var i = 0; i < 12; i++) {
    if (data[8 + i] != transactionId[i]) return null;
  }
  final end = 20 + view.getUint16(2);
  if (end > data.length) return null;
  String? mapped;
  var offset = 20;
  while (offset + 4 <= end) {
    final type = view.getUint16(offset);
    final size = view.getUint16(offset + 2);
    final valueStart = offset + 4;
    final valueEnd = valueStart + size;
    if (valueEnd > end) return null;
    if (type == 0x0020 || type == 0x0001) {
      final address = _mappedAddress(
        data,
        valueStart,
        size,
        xor: type == 0x0020,
        transactionId: transactionId,
      );
      if (address != null) {
        if (type == 0x0020) return address;
        mapped ??= address;
      }
    }
    offset = valueStart + ((size + 3) & ~3);
  }
  return mapped;
}

String? _mappedAddress(
  Uint8List data,
  int start,
  int size, {
  required bool xor,
  required Uint8List transactionId,
}) {
  if (size < 4) return null;
  final family = data[start + 1];
  final width = switch (family) {
    0x01 => 4,
    0x02 => 16,
    _ => 0,
  };
  if (width == 0 || size < width + 4) return null;
  final bytes = Uint8List.fromList(data.sublist(start + 4, start + 4 + width));
  if (xor) {
    final mask = Uint8List(width)
      ..[0] = (stunMagicCookie >> 24) & 0xFF
      ..[1] = (stunMagicCookie >> 16) & 0xFF
      ..[2] = (stunMagicCookie >> 8) & 0xFF
      ..[3] = stunMagicCookie & 0xFF;
    if (width == 16) {
      mask.setRange(4, 16, transactionId);
    }
    for (var i = 0; i < width; i++) {
      bytes[i] ^= mask[i];
    }
  }
  return InternetAddress.fromRawAddress(bytes).address;
}

int randomDnsTransactionId() => Random.secure().nextInt(0xFFFE) + 1;

Uint8List buildDnsQuery(String name, int transactionId) {
  final builder = BytesBuilder()
    ..addByte((transactionId >> 8) & 0xFF)
    ..addByte(transactionId & 0xFF)
    ..add([0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
  for (final label in name.split('.')) {
    if (label.isEmpty) continue;
    final bytes = utf8.encode(label);
    if (bytes.isEmpty || bytes.length > 63) continue;
    builder.addByte(bytes.length);
    builder.add(bytes);
  }
  builder
    ..addByte(0)
    ..add([0x00, 0x01, 0x00, 0x01]);
  return builder.takeBytes();
}

String? firstDnsAddress(Uint8List data, int transactionId) {
  if (data.length < 12) return null;
  if (((data[0] << 8) | data[1]) != transactionId) return null;
  if ((data[2] & 0x80) == 0 || (data[3] & 0x0F) != 0) return null;
  final questions = (data[4] << 8) | data[5];
  final answers = (data[6] << 8) | data[7];
  var offset = 12;
  for (var i = 0; i < questions; i++) {
    offset = skipDnsName(data, offset);
    if (offset < 0 || offset + 4 > data.length) return null;
    offset += 4;
  }
  for (var i = 0; i < answers; i++) {
    offset = skipDnsName(data, offset);
    if (offset < 0 || offset + 10 > data.length) return null;
    final type = (data[offset] << 8) | data[offset + 1];
    final length = (data[offset + 8] << 8) | data[offset + 9];
    offset += 10;
    if (offset + length > data.length) return null;
    if (type == 1 && length == 4) {
      return '${data[offset]}.${data[offset + 1]}.'
          '${data[offset + 2]}.${data[offset + 3]}';
    }
    offset += length;
  }
  return null;
}

int skipDnsName(Uint8List data, int offset) {
  while (offset < data.length) {
    final length = data[offset];
    if (length == 0) return offset + 1;
    if ((length & 0xC0) == 0xC0) return offset + 2;
    if ((length & 0xC0) != 0) return -1;
    offset += length + 1;
  }
  return -1;
}
