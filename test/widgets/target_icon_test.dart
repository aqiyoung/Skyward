import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/glyph_finders.dart';
import '../helpers/test_app.dart';

Future<void> _pump(WidgetTester tester, Widget icon) {
  return tester.pumpWidget(
    TestApp(
      child: Center(
        child: IconTheme(data: const IconThemeData(size: 32), child: icon),
      ),
    ),
  );
}

void main() {
  testWidgets('a group without an icon shows the first letter of its name, '
      'past a leading emoji', (tester) async {
    for (final (name, mark) in [
      ('🚀 节点选择', '节'),
      ('proxy', 'P'),
      ('♻️ 9 Auto', '9'),
      ('🇭🇰', '🇭🇰'),
    ]) {
      await _pump(
        tester,
        CommonTargetIcon(src: '', fallback: GroupMonogram(name)),
      );

      expect(find.text(mark), findsOne, reason: name);
    }
  });

  testWidgets('the Core GLOBAL wears the exit flag it was handed, and its '
      'globe when it was handed none', (tester) async {
    await _pump(tester, const GroupMonogram('GLOBAL', exitCountryCode: 'HK'));

    expect(find.text('🇭🇰'), findsOne);

    await _pump(tester, const GroupMonogram('GLOBAL'));

    expect(find.text(GroupMonogram.globeMark), findsOne);
    expect(find.text('G'), findsNothing);
  });

  testWidgets('any other group keeps its letter, whatever exit it is handed', (
    tester,
  ) async {
    await _pump(tester, const GroupMonogram('自动选择', exitCountryCode: 'HK'));

    expect(find.text('自'), findsOne);
  });

  testWidgets('a missing image shows a placeholder, as does an empty name', (
    tester,
  ) async {
    await _pump(tester, const CommonTargetIcon(src: ''));

    expect(find.byGlyph(AppGlyphs.photos), findsOne);

    await _pump(tester, const GroupMonogram(''));

    expect(find.byGlyph(AppGlyphs.photos), findsOne);
  });

  testWidgets('the placeholder glyph is opaque, so a grid of icons that '
      'cannot load paints no offscreen layer per tile', (tester) async {
    await _pump(tester, const CommonTargetIcon(src: ''));

    final glyph = tester.widget<GlyphIcon>(find.byGlyph(AppGlyphs.photos));
    expect(glyph.color!.a, 1);
  });

  group('a remote icon', () {
    late List<String> reads;

    setUp(() {
      reads = [];
      readRemoteIcon = (src) {
        reads.add(src);
        return Stream.value(_onePixelPng);
      };
    });

    tearDown(() => readRemoteIcon = null);

    testWidgets('loads at once on a page that sits still', (tester) async {
      const src = 'https://example.com/still.png';
      await _pump(tester, const CommonTargetIcon(src: src));
      await tester.pump();

      expect(reads, [src]);
      expect(find.byType(Image), findsOne);
    });

    testWidgets('loads while the route bringing it in arrives', (tester) async {
      const src = 'https://example.com/pushed.png';
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Center(
                    child: IconTheme(
                      data: IconThemeData(size: 32),
                      child: CommonTargetIcon(src: src),
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(reads, [src]);
      expect(find.byGlyph(AppGlyphs.photos), findsNothing);
      expect(find.byType(Image), findsOne);
      await tester.pumpAndSettle();
    });

    testWidgets('a page pushed again shows a whole set it loaded before '
        'from its first frame', (tester) async {
      readRemoteIcon = (src) {
        reads.add(src);
        return Stream.value(Uint8List.fromList(_onePixelPng));
      };
      final icons = Wrap(
        children: [
          for (var i = 0; i < 340; i++)
            CommonTargetIcon(src: 'https://example.com/set/$i.png'),
        ],
      );
      await _pump(tester, icons);
      await tester.pump();
      await tester.pumpWidget(
        TestApp(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => IconTheme(
                    data: const IconThemeData(size: 32),
                    child: icons,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Image), findsNWidgets(340));
    });

    testWidgets('an oversized icon decodes at icon size, into the one cache '
        'entry its precache filled', (tester) async {
      final png = (await tester.runAsync(() => _squarePng(512)))!;
      readRemoteIcon = (_) => Stream.value(png);
      const src = 'https://example.com/large.png';
      imageCache.clear();
      await tester.runAsync(() => precacheTargetIcons([src]));

      expect(imageCache.currentSize, 1);

      await _pump(tester, const CommonTargetIcon(src: src));
      await tester.pump();

      expect(tester.widget<RawImage>(find.byType(RawImage)).image!.width, 192);
      expect(imageCache.currentSize, 1);
    });

    testWidgets('shows the fallback once a load ends without an image', (
      tester,
    ) async {
      readRemoteIcon = (_) => const Stream.empty();
      await _pump(
        tester,
        const CommonTargetIcon(
          src: 'https://example.com/missing.png',
          fallback: GroupMonogram('proxy'),
        ),
      );

      expect(find.text('P'), findsNothing);

      await tester.pump();

      expect(find.text('P'), findsOne);
    });

    testWidgets('a bundled group icon never asks for a download', (
      tester,
    ) async {
      await _pump(
        tester,
        const CommonTargetIcon(src: 'assets/images/groups/hong_kong.png'),
      );
      await tester.pump();

      expect(reads, isEmpty);
      expect(find.byType(Image), findsOne);
    });
  });

  group('a group that carries no icon', () {
    const own = 'https://example.com/own.png';

    test('takes the picture, the flag or the mark its name is known by', () {
      expect(
        GroupIconSource.of(name: '香港', icon: ''),
        '${_groupDir}hong_kong.png',
      );
      expect(
        GroupIconSource.of(name: '香港-自动选择', icon: ''),
        '${_groupDir}auto.png',
      );
      expect(
        GroupIconSource.of(name: 'YouTube', icon: ''),
        '${_groupDir}youtube.png',
      );
      expect(GroupIconSource.of(name: 'mine', icon: ''), GroupIconSource.logo);
    });

    test('reads the words a subscription actually writes', () {
      for (final (name, file) in [
        ('🇭🇰 香港 01', 'hong_kong.png'),
        ('香港节点', 'hong_kong.png'),
        ('🇭🇰', 'hong_kong.png'),
        ('US-01', 'united_states.png'),
        ('日本 IEPL', 'japan.png'),
        ('🚀 节点选择', 'rocket.png'),
        ('♻️ 自动选择', 'auto.png'),
        ('Netflix 媒体', 'netflix.png'),
        ('OpenAI', 'chatgpt.png'),
        ('广告拦截', 'adblock.png'),
        ('剩余流量', 'world_map.png'),
        ('🌍 国外媒体', 'netflix.png'),
        ('🎮 游戏', 'steam.png'),
        ('手动切换', 'rocket.png'),
        ('巴哈姆特', 'area.png'),
        ('哔哩哔哩', 'youtube.png'),
        ('游戏平台', 'steam.png'),
        ('网易音乐', 'spotify.png'),
        ('全球直连', 'direct.png'),
        ('应用净化', 'adblock.png'),
      ]) {
        expect(
          GroupIconSource.of(name: name, icon: ''),
          '$_groupDir$file',
          reason: name,
        );
      }
    });

    test('a two-letter code is a word, not a fragment', () {
      expect(GroupIconSource.of(name: 'Rush', icon: ''), GroupIconSource.logo);
    });

    test('a region the bundle has no picture for wears its flag', () {
      expect(GroupIconSource.of(name: '韩国', icon: ''), '');
      expect(GroupIconSource.flagOf('韩国'), '🇰🇷');
      expect(GroupIconSource.flagOf('英国 01'), '🇬🇧');
      expect(GroupIconSource.flagOf('国内媒体'), '🇨🇳');
      expect(GroupIconSource.flagOf('mine'), '');
    });

    test('a code carries the node number behind it', () {
      expect(
        GroupIconSource.of(name: 'US01', icon: ''),
        '${_groupDir}united_states.png',
      );
      expect(
        GroupIconSource.of(name: '美国 01', icon: ''),
        '${_groupDir}united_states.png',
      );
    });

    test('the picture its config names wins over the name it is known by', () {
      expect(GroupIconSource.of(name: '自动选择', icon: own), own);
      expect(GroupIconSource.of(name: '美国', icon: own), own);
      // a group the profile leaves bare still wears the name it is known by
      expect(
        GroupIconSource.of(name: '漏网之鱼', icon: ''),
        '${_groupDir}final.png',
      );
      expect(
        GroupIconSource.of(name: '自动选择', icon: ''),
        '${_groupDir}auto.png',
      );
    });

    test('a config icon wins for a group the set does not know, and the '
        'Core GLOBAL wears its globe whatever it is handed', () {
      expect(GroupIconSource.of(name: 'mine', icon: own), own);
      expect(
        GroupIconSource.of(name: 'GLOBAL', icon: ''),
        GroupIconSource.global,
      );
      expect(
        GroupIconSource.of(name: 'GLOBAL', icon: own),
        GroupIconSource.global,
      );
    });

    testWidgets('the badge shows the app mark, and the exit flag on GLOBAL', (
      tester,
    ) async {
      await _pump(tester, const GroupBadge(name: 'mine'));

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as ResizeImage).imageProvider,
        const AssetImage(GroupIconSource.logo),
      );

      await _pump(
        tester,
        const GroupBadge(name: 'GLOBAL', exitCountryCode: 'HK'),
      );

      expect(find.text('🇭🇰'), findsOne);
    });

    testWidgets('the badge wears the flag of a region without a picture', (
      tester,
    ) async {
      await _pump(tester, const GroupBadge(name: '韩国'));

      expect(find.text('🇰🇷'), findsOne);
    });
  });
}

const _groupDir = 'assets/images/groups/';

Future<Uint8List> _squarePng(int size) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = const Color(0xFF2196F3),
  );
  final image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

final _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);
