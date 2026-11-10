import 'package:flutter_test/flutter_test.dart';
import 'package:skyward/common/subscription.dart';

void main() {
  group('vless links', () {
    // A Reality node that needs XTLS vision: the keys below are the ones a
    // server enforces, so losing them turns the node into a dead entry.
    const reality =
        'vless://11111111-2222-3333-4444-555555555555@example.com:443'
        '?encryption=none&security=reality&sni=www.example.com&fp=chrome'
        '&pbk=PUBKEY&sid=abcd&type=tcp&flow=xtls-rprx-vision#Reality';

    test('keeps flow, encryption and the TLS fingerprint', () {
      final config = convertToClashConfig(reality);

      expect(config, contains('type: vless'));
      expect(config, contains('flow: xtls-rprx-vision'));
      expect(config, contains('encryption: none'));
      expect(config, contains('client-fingerprint: chrome'));
      expect(config, contains('public-key: PUBKEY'));
      expect(config, contains('short-id: abcd'));
    });

    test('leaves a plain link without the keys it does not carry', () {
      const plain =
          'vless://11111111-2222-3333-4444-555555555555@a.example:80'
          '#Plain';
      final config = convertToClashConfig(plain);

      expect(config, contains('type: vless'));
      expect(config, isNot(contains('flow:')));
      expect(config, isNot(contains('encryption:')));
    });
  });
}
