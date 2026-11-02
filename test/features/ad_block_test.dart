import 'package:skyward/features/ad_block/ad_block.dart';
import 'package:skyward/models/clash_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('adBlockRules', () {
    test('every raw rule round-trips through Rule.parse', () {
      for (final raw in adBlockRules) {
        final rule = Rule.parse(raw);
        expect(rule.rawValue, raw);
        expect(rule.payloadError, isNull, reason: raw);
      }
    });

    test('every rule rejects', () {
      for (final rule in adBlockRuleList) {
        expect(rule.ruleTarget, 'REJECT', reason: rule.rawValue);
      }
    });

    test('no rule is listed twice', () {
      expect(adBlockRules.toSet(), hasLength(adBlockRules.length));
    });
  });

  group('withAdBlockRules', () {
    test('a profile with no added rules gets the module alone', () {
      final merged = withAdBlockRules(const []);
      expect(merged.map((rule) => rule.rawValue).toList(), adBlockRules);
    });

    test('a line the profile already carries is not added twice', () {
      final own = Rule.parse('DOMAIN-SUFFIX,hotjar.com,REJECT');
      final merged = withAdBlockRules([own]);

      expect(merged, hasLength(adBlockRules.length));
      expect(
        merged.where((rule) => rule.rawValue == own.rawValue),
        hasLength(1),
      );
      // The profile's own rules stay last, behind the module.
      expect(merged.last.rawValue, own.rawValue);
    });
  });
}
