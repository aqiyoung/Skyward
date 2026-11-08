import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

String _androidAttribute(String source, String element, String attribute) {
  final elementTag = RegExp('<$element\\b[^>]*>').firstMatch(source)!.group(0)!;
  return RegExp(
    'android:$attribute="([^"]+)"',
  ).firstMatch(elementTag)!.group(1)!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TV launcher icons meet density-specific minimum sizes', () async {
    const expectedSizes = {
      'mdpi': 80,
      'hdpi': 120,
      'xhdpi': 160,
      'xxhdpi': 240,
      'xxxhdpi': 320,
    };

    for (final MapEntry(key: density, value: size) in expectedSizes.entries) {
      final file = File(
        'android/app/src/main/res/'
        'mipmap-television-$density/ic_launcher.webp',
      );
      expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');

      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      final frame = await codec.getNextFrame();
      expect(
        (frame.image.width, frame.image.height),
        (size, size),
        reason: file.path,
      );
      frame.image.dispose();
      codec.dispose();
    }
  });

  test('the adaptive launcher art stays in the safe zone', () async {
    // Both launchers draw the same tile; only the raster sizes differ.
    for (final path in const [
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      'android/app/src/main/res/mipmap-television-anydpi-v26/ic_launcher.xml',
    ]) {
      final adaptiveIcon = File(path).readAsStringSync();
      expect(
        _androidAttribute(adaptiveIcon, 'foreground', 'drawable'),
        '@drawable/ic_launcher_foreground',
        reason: path,
      );
      expect(
        _androidAttribute(adaptiveIcon, 'background', 'drawable'),
        '@drawable/ic_launcher_background',
        reason: path,
      );
    }

    final file = File(
      'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
    );
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    final image = (await codec.getNextFrame()).image;
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final side = image.width;
    var left = side, top = side, right = -1, bottom = -1;
    for (var y = 0; y < side; y++) {
      for (var x = 0; x < side; x++) {
        if (pixels!.getUint8((y * side + x) * 4 + 3) == 0) {
          continue;
        }
        if (x < left) left = x;
        if (y < top) top = y;
        if (x > right) right = x;
        if (y > bottom) bottom = y;
      }
    }
    image.dispose();
    codec.dispose();

    // The mark sits on the adaptive icon's plate, whose mask may crop
    // everything outside the middle 72 dp of the 108 dp canvas.
    const safeZone = ui.Rect.fromLTWH(18, 18, 72, 72);
    final bounds = ui.Rect.fromLTRB(
      left / side * 108,
      top / side * 108,
      (right + 1) / side * 108,
      (bottom + 1) / side * 108,
    );

    expect(bounds.left, greaterThanOrEqualTo(safeZone.left));
    expect(bounds.top, greaterThanOrEqualTo(safeZone.top));
    expect(bounds.right, lessThanOrEqualTo(safeZone.right));
    expect(bounds.bottom, lessThanOrEqualTo(safeZone.bottom));
  });

  test('themed launcher icon is a dedicated pure-white drawable', () async {
    // Android 13 tints the monochrome layer; pointing it at the coloured
    // foreground would render a flat disc instead of the S mark.
    for (final path in const [
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml',
    ]) {
      final adaptiveIcon = File(path).readAsStringSync();
      expect(
        _androidAttribute(adaptiveIcon, 'monochrome', 'drawable'),
        '@drawable/ic_launcher_monochrome',
        reason: path,
      );
    }

    final file = File(
      'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_monochrome.png',
    );
    expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    final image = (await codec.getNextFrame()).image;
    final pixels =
        (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    var opaque = 0;
    var tinted = 0;
    for (var i = 0; i < pixels.lengthInBytes; i += 4) {
      if (pixels.getUint8(i + 3) < 200) continue;
      opaque++;
      if (pixels.getUint8(i) != 255 ||
          pixels.getUint8(i + 1) != 255 ||
          pixels.getUint8(i + 2) != 255) {
        tinted++;
      }
    }
    image.dispose();
    codec.dispose();
    expect(opaque, greaterThan(0), reason: 'themed icon is empty');
    expect(tinted, 0,
        reason: 'themed icon must be pure white; the system applies the tint');
  });

}
