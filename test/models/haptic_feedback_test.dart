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
  });
}
