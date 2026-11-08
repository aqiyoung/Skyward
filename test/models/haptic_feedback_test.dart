import 'package:skyward/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('haptic feedback setting', () {
    test('is on by default', () {
      expect(defaultAppSettingProps.hapticFeedback, isTrue);
    });

    test('can be turned off without mutating the default', () {
      final off = defaultAppSettingProps.copyWith(hapticFeedback: false);
      expect(off.hapticFeedback, isFalse);
      expect(defaultAppSettingProps.hapticFeedback, isTrue);
    });

    test('a stored config without the key keeps the default', () {
      final stored = defaultAppSettingProps.toJson()..remove('hapticFeedback');
      expect(AppSettingProps.fromJson(stored).hapticFeedback, isTrue);
    });
  });
}
