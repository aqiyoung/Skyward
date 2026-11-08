import 'dart:typed_data';

import 'package:skyward/common/leak_probe.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _dnsResponse(int transactionId, String address) {
  final builder = BytesBuilder()
    ..addByte((transactionId >> 8) & 0xFF)
    ..addByte(transactionId & 0xFF)
    ..add([0x81, 0x80, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00])
    ..add([
      3,
      ...'www'.codeUnits,
      4,
      ...'bing'.codeUnits,
      3,
      ...'com'.codeUnits,
      0,
      0x00,
      0x01,
      0x00,
      0x01,
    ])
    ..add([
      0xC0,
      0x0C,
      0x00,
      0x01,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x3C,
      0x00,
      0x04,
    ])
    ..add(address.split('.').map(int.parse).toList());
  return builder.takeBytes();
}

Uint8List _stunResponse(
  Uint8List transactionId, {
  required int type,
  required Uint8List value,
}) {
  final padded = (value.length + 3) & ~3;
  final messageLength = 4 + padded;
  final builder = BytesBuilder()
    ..add([
      0x01,
      0x01,
      (messageLength >> 8) & 0xFF,
      messageLength & 0xFF,
      0x21,
      0x12,
      0xA4,
      0x42,
    ])
    ..add(transactionId)
    ..addByte((type >> 8) & 0xFF)
    ..addByte(type & 0xFF)
    ..addByte((value.length >> 8) & 0xFF)
    ..addByte(value.length & 0xFF)
    ..add(value)
    ..add(Uint8List(padded - value.length));
  return builder.takeBytes();
}

Uint8List _xorMappedV4(String address) {
  final bytes = Uint8List(8)..[1] = 0x01;
  final parts = address.split('.').map(int.parse).toList();
  for (var i = 0; i < 4; i++) {
    bytes[4 + i] = parts[i] ^ ((stunMagicCookie >> (24 - 8 * i)) & 0xFF);
  }
  return bytes;
}

void main() {
  final transactionId = Uint8List.fromList(
    List<int>.generate(12, (index) => index + 1),
  );

  group('DNS probe wire format', () {
    test('query carries the transaction id and every label', () {
      final query = buildDnsQuery('www.bing.com', 0x1234);
      expect(query[0], 0x12);
      expect(query[1], 0x34);
      expect(query.sublist(12, 15), [3, 119, 119]);
      expect(query.sublist(query.length - 5), [0, 0, 1, 0, 1]);
    });

    test('an A answer with a compressed name is read back', () {
      final response = _dnsResponse(0x1234, '93.184.216.34');
      expect(firstDnsAddress(response, 0x1234), '93.184.216.34');
    });

    test('a response for another query is ignored', () {
      final response = _dnsResponse(0x1234, '93.184.216.34');
      expect(firstDnsAddress(response, 0x9999), isNull);
    });

    test('a query, an error and a truncated answer are rejected', () {
      final response = _dnsResponse(0x1234, '93.184.216.34');
      final query = Uint8List.fromList(response)..[2] = 0x01;
      expect(firstDnsAddress(query, 0x1234), isNull);
      final failed = Uint8List.fromList(response)..[3] = 0x83;
      expect(firstDnsAddress(failed, 0x1234), isNull);
      expect(
        firstDnsAddress(
          Uint8List.fromList(response.sublist(0, response.length - 2)),
          0x1234,
        ),
        isNull,
      );
      expect(firstDnsAddress(Uint8List(8), 0x1234), isNull);
    });

    test('a malformed name cannot run off the packet', () {
      final response = _dnsResponse(0x1234, '93.184.216.34');
      final broken = Uint8List.fromList(response)..[12] = 0x40;
      expect(firstDnsAddress(broken, 0x1234), isNull);
      expect(skipDnsName(Uint8List(2)..[0] = 10, 0), -1);
    });
  });

  group('STUN probe wire format', () {
    test('binding request is 20 bytes with the cookie and transaction id', () {
      final request = buildStunBindingRequest(transactionId);
      expect(request.length, 20);
      expect(request.sublist(0, 4), [0x00, 0x01, 0x00, 0x00]);
      expect(request.sublist(4, 8), [0x21, 0x12, 0xA4, 0x42]);
      expect(request.sublist(8), transactionId);
    });

    test('a wrong transaction id is not a binding request', () {
      expect(() => buildStunBindingRequest(Uint8List(4)), throwsArgumentError);
    });

    test('XOR-MAPPED-ADDRESS is decoded', () {
      final response = _stunResponse(
        transactionId,
        type: 0x0020,
        value: _xorMappedV4('203.0.113.7'),
      );
      expect(parseStunBindingResponse(response, transactionId), '203.0.113.7');
    });

    test('MAPPED-ADDRESS is the un-xored fallback', () {
      final value = Uint8List(8)
        ..[1] = 0x01
        ..setRange(4, 8, [198, 51, 100, 9]);
      final response = _stunResponse(transactionId, type: 0x0001, value: value);
      expect(parseStunBindingResponse(response, transactionId), '198.51.100.9');
    });

    test('attributes before the address are skipped with padding', () {
      final builder = BytesBuilder()
        ..add([0x01, 0x01, 0x00, 0x14, 0x21, 0x12, 0xA4, 0x42])
        ..add(transactionId)
        ..add([0x80, 0x22, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00])
        ..add([0x00, 0x20, 0x00, 0x08])
        ..add(_xorMappedV4('203.0.113.7'));
      expect(
        parseStunBindingResponse(builder.takeBytes(), transactionId),
        '203.0.113.7',
      );
    });

    test('IPv6 XOR-MAPPED-ADDRESS is decoded against cookie plus id', () {
      final mask = Uint8List(16)
        ..[0] = 0x21
        ..[1] = 0x12
        ..[2] = 0xA4
        ..[3] = 0x42
        ..setRange(4, 16, transactionId);
      final plain = Uint8List.fromList([
        0x20,
        0x01,
        0x0D,
        0xB8,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1,
      ]);
      for (var i = 0; i < 16; i++) {
        plain[i] ^= mask[i];
      }
      final value = Uint8List(20)
        ..[1] = 0x02
        ..setRange(4, 20, plain);
      final response = _stunResponse(transactionId, type: 0x0020, value: value);
      expect(parseStunBindingResponse(response, transactionId), '2001:db8::1');
    });

    test('a mismatched id, cookie, error or short body is ignored', () {
      final response = _stunResponse(
        transactionId,
        type: 0x0020,
        value: _xorMappedV4('203.0.113.7'),
      );
      final otherId = Uint8List.fromList(transactionId)..[0] = 0xFF;
      expect(parseStunBindingResponse(response, otherId), isNull);
      final badCookie = Uint8List.fromList(response)..[4] = 0x00;
      expect(parseStunBindingResponse(badCookie, transactionId), isNull);
      final error = Uint8List.fromList(response)..[1] = 0x11;
      expect(parseStunBindingResponse(error, transactionId), isNull);
      expect(
        parseStunBindingResponse(
          Uint8List.fromList(response.sublist(0, 24)),
          transactionId,
        ),
        isNull,
      );
      expect(parseStunBindingResponse(Uint8List(12), transactionId), isNull);
    });

    test('a response without an address attribute stays unknown', () {
      final response = _stunResponse(
        transactionId,
        type: 0x8022,
        value: Uint8List(1),
      );
      expect(parseStunBindingResponse(response, transactionId), isNull);
    });
  });
}
