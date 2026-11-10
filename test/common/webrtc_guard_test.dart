import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ports = ['3478', '5349', '19302'];

  test('blocking keeps the four refusals unchanged', () {
    expect(webrtcRulesFor(WebrtcGuard.block), webrtcGuardRules);
    for (final port in ports) {
      expect(
        webrtcRulesFor(WebrtcGuard.block),
        contains('DST-PORT,$port,REJECT'),
      );
    }
  });

  test('routing sends the same rows to the group a profile matches to', () {
    final rules = webrtcRulesFor(WebrtcGuard.proxy, proxyTarget: 'Auto');
    expect(rules, hasLength(webrtcGuardRules.length));
    for (final port in ports) {
      expect(rules, contains('DST-PORT,$port,Auto'));
    }
    expect(rules, contains('DOMAIN-KEYWORD,stun,Auto'));
    expect(rules.any((rule) => rule.endsWith(',REJECT')), isFalse);
  });

  test('routing without a group still refuses, because DIRECT would leak', () {
    expect(
      webrtcRulesFor(WebrtcGuard.proxy, proxyTarget: null),
      webrtcGuardRules,
    );
    expect(
      webrtcRulesFor(WebrtcGuard.proxy, proxyTarget: '   '),
      webrtcGuardRules,
    );
  });

  test('leaving it alone prepends nothing', () {
    expect(webrtcRulesFor(WebrtcGuard.off), isEmpty);
  });
}
