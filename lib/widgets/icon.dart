import 'dart:async';

import 'package:skyward/common/cache.dart';
import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/plugins/app.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/svg.dart';

const _maxCachedIconBytes = 16 << 20;

// The precache and the widget must resolve equal providers to share one
// ImageCache entry; 192 physical pixels cover a 48 dp icon box at 4x.
const _iconDecodeExtent = 192;

ImageProvider _iconImage(Uint8List bytes) {
  return ResizeImage(
    MemoryImage(bytes),
    width: _iconDecodeExtent,
    height: _iconDecodeExtent,
    policy: ResizeImagePolicy.fit,
  );
}

class _IconBytesCache {
  _IconBytesCache(this.maxBytes);

  final int maxBytes;
  final _entries = <String, Uint8List?>{};
  var _bytes = 0;

  bool contains(String key) => _entries.containsKey(key);

  Uint8List? operator [](String key) {
    if (!_entries.containsKey(key)) {
      return null;
    }
    return _entries[key] = _entries.remove(key);
  }

  void operator []=(String key, Uint8List? value) {
    remove(key);
    final size = value?.lengthInBytes ?? 0;
    if (size > maxBytes) {
      return;
    }
    _entries[key] = value;
    _bytes += size;
    while (_bytes > maxBytes) {
      remove(_entries.keys.first);
    }
  }

  void remove(String key) {
    _bytes -= _entries.remove(key)?.lengthInBytes ?? 0;
  }

  void clear() {
    _entries.clear();
    _bytes = 0;
  }
}

final _decodedIcons = _IconBytesCache(_maxCachedIconBytes);
final _remoteIcons = _IconBytesCache(_maxCachedIconBytes);

/// Drop the icon bytes held for the lifetime of the process. Icons re-decode
/// on demand, so this is safe to call whenever the platform asks for memory
/// back; it is the UI side of the trim the service already does for the Core.
void clearIconCaches() {
  _decodedIcons.clear();
  _remoteIcons.clear();
}

Uint8List? _decodeIcon(String src) {
  if (!src.contains('base64,')) {
    return null;
  }
  if (_decodedIcons.contains(src)) {
    return _decodedIcons[src];
  }
  return _decodedIcons[src] = src.getBase64;
}

class CommonTargetIcon extends StatelessWidget {
  final String src;

  /// Shown while [src] is empty, loading or unreadable.
  final Widget? fallback;

  const CommonTargetIcon({super.key, required this.src, this.fallback});

  Widget _defaultIcon() {
    return fallback ?? const _ImagePlaceholder();
  }

  Widget _buildIcon(BuildContext context) {
    if (src.isEmpty) {
      return _defaultIcon();
    }

    final base64 = _decodeIcon(src);
    if (base64 != null) {
      return _BytesImage(
        bytes: base64,
        isSvg: src.isSvg,
        fallback: _defaultIcon(),
      );
    }

    if (src.isBundleAsset) {
      final size = IconTheme.of(context).size ?? 24;
      return Image.asset(
        src,
        width: size,
        height: size,
        cacheWidth: _iconDecodeExtent,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _defaultIcon(),
      );
    }

    return ImageCacheWidget(src: src, defaultWidget: _defaultIcon());
  }

  @override
  Widget build(BuildContext context) {
    return _buildIcon(context);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final size = IconTheme.of(context).size ?? 24;
    final colorScheme = context.colorScheme;
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: GlyphIcon(
          AppGlyphs.photos,
          size: size * 0.7,
          color: Color.alphaBlend(
            colorScheme.onSurfaceVariant.opacity50,
            colorScheme.surface,
          ),
        ),
      ),
    );
  }
}

/// Stands for a proxy group without an icon: the first letter or digit of
/// its name, past any leading emoji the name already shows. [GroupName.GLOBAL]
/// is the Core's own group, so it wears [globeMark] -- or, whenever the caller
/// knows it, the flag of the country traffic leaves by.
class GroupMonogram extends StatelessWidget {
  final String name;

  /// The two-letter code of the country traffic leaves by, for callers that
  /// have it at hand.
  final String? exitCountryCode;

  const GroupMonogram(this.name, {super.key, this.exitCountryCode});

  static final _letter = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// What GLOBAL shows when nothing says where it exits.
  static const globeMark = '🌐';

  /// Whether [name] is the Core's own GLOBAL group.
  static bool isGlobal(String name) => name == GroupName.GLOBAL.name;

  String get _mark {
    if (isGlobal(name)) {
      final code = exitCountryCode;
      return code == null || code.isEmpty ? globeMark : code.countryFlagEmoji;
    }
    final letter = _letter.firstMatch(name)?.group(0);
    if (letter != null) {
      return letter.toUpperCase();
    }
    return name.characters.firstOrNull ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? 24;
    final mark = _mark;
    if (mark.isEmpty) {
      return const _ImagePlaceholder();
    }
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: EmojiText(
          mark,
          maxLines: 1,
          style: AppTextStyle.custom(
            context,
            size: size * 0.62,
            leading: size * 0.62,
            weight: FontWeight.w600,
          ).copyWith(color: iconTheme.color),
        ),
      ),
    );
  }
}

/// The pictures a group wears when its config names none of its own, carried
/// in the bundle so a bare group still wears the face its name is known by,
/// whether the network is up and whether the cache survived a reinstall. A
/// profile's own `icon` is always authoritative — it wins before any of these.
abstract final class GroupIconSource {
  static const _dir = 'assets/images/groups/';

  /// The app's own mark, which stands in for a group no picture suits.
  static const logo = 'assets/images/icon.png';

  /// The routing groups the default config builds, by the name it gives them:
  /// each wears the picture that says what it does.
  static const _routing = {
    '默认代理': 'rocket.png',
    '自动选择': 'auto.png',
    '故障转移': 'round_robin.png',
    '负载均衡': 'stack.png',
    '漏网之鱼': 'final.png',
    '直连': 'direct.png',
    '其他节点': 'world_map.png',
  };

  /// Region groups, by the name the default config gives them: each wears the
  /// flag of its region.
  static const _regions = {
    '香港': 'hong_kong.png',
    '日本': 'japan.png',
    '美国': 'united_states.png',
    '新加坡': 'singapore.png',
    '台湾': 'taiwan.png',
  };

  /// Service groups, by the name the default config gives them: each wears its
  /// service's mark.
  static const _services = {
    // GoogleFCM is deliberately absent: its bundled mark was a paper plane,
    // which reads as Telegram's. Without an entry the group falls through to
    // the icon its config names, so a profile can dress it as it likes.
    'YouTube': 'youtube.png',
    'Google': 'google_search.png',
    'ChatGPT': 'chatgpt.png',
    'GitHub': 'github.png',
    'OneDrive': 'onedrive.png',
    'Microsoft': 'microsoft.png',
    'APPLE': 'apple.png',
    'Telegram': 'telegram.png',
    'Steam': 'steam.png',
    'Twitter': 'twitter.png',
    'Meta': 'meta.png',
    'Line': 'line.png',
    'TikTok': 'tiktok.png',
    'NETFLIX': 'netflix.png',
    'Disney': 'disney.png',
    'Spotify': 'spotify.png',
    'PikPak': 'pikpak.png',
    'Crypto': 'crypto.png',
    'AdBlock': 'adblock.png',
  };

  /// The entry a group wears, or empty for a [GroupBadge] to stand in.
  ///
  /// The profile's own picture wins whenever it names one: a bundled mark is
  /// only the face a group wears when its config leaves it bare. That keeps a
  /// subscription's icons authoritative — the same fix [262523e0] first gave
  /// GoogleFCM, now extended to every group.
  static String of({required String name, required String icon}) {
    if (icon.isNotEmpty) {
      return icon;
    }
    final known = _routing[name] ?? _regions[name] ?? _regionAuto(name);
    if (known != null) {
      return '$_dir$known';
    }
    final service = _services[name];
    if (service != null) {
      return '$_dir$service';
    }
    if (GroupMonogram.isGlobal(name)) {
      return '';
    }
    final guessed = _guess(name, _serviceKeywords);
    if (guessed != null) {
      return '$_dir$guessed';
    }
    final country = _country(name);
    if (country != null) {
      final picture = _countryPictures[country];
      if (picture != null) {
        return '$_dir$picture';
      }
      // The flag stands in for a picture the bundle lacks.
      return '';
    }
    final kind = _guess(name, _kindKeywords);
    if (kind != null) {
      return '$_dir$kind';
    }
    return logo;
  }

  /// `<地区>-自动选择` is how the default config names the url-test group it
  /// builds beside each region, and it wears the same picture as the rest.
  static String? _regionAuto(String name) =>
      name.endsWith('-自动选择') ? 'auto.png' : null;

  /// The same pictures for the names a subscription actually writes: the lists
  /// above are the fork's own default config, a provider writes its own. A
  /// service wins over a region, a region over the group's kind.
  static const _serviceKeywords = <String, List<String>>{
    'youtube.png': ['youtube', '油管', 'yt', '哔哩哔哩', 'bilibili'],
    'netflix.png': ['netflix', '奈飞', '网飞', '影视', '国外媒体', '电影'],
    'disney.png': ['disney', '迪士尼'],
    'spotify.png': ['spotify', '音乐'],
    'chatgpt.png': ['chatgpt', 'openai', 'gpt', 'ai', '人工智能'],
    'github.png': ['github'],
    'telegram.png': ['telegram', '电报', '纸飞机', 'tg'],
    'twitter.png': ['twitter', '推特'],
    'meta.png': ['meta', 'facebook', 'instagram', '社交', '脸书', 'fb'],
    'line.png': ['line', '连我'],
    'tiktok.png': ['tiktok', '抖音'],
    'pikpak.png': ['pikpak'],
    'crypto.png': ['crypto', 'binance', 'okx', 'coinbase', '加密', '数字货币'],
    'adblock.png': ['adblock', 'adguard', '广告', '拦截', '去广告', '屏蔽', '净化'],
    'apple.png': ['apple', 'icloud', '苹果', 'itunes'],
    'microsoft.png': ['microsoft', '微软', 'office'],
    'onedrive.png': ['onedrive'],
    'google_search.png': ['google', '谷歌', '搜索', 'gmail'],
    'spark.png': ['fcm', 'gcm', '推送'],
    'steam.png': ['steam', '游戏', 'game'],
    'area.png': ['巴哈姆特', 'bahamut', '资讯站', '门户'],
  };

  /// The kinds of group, by the words a config writes for them.
  static const _kindKeywords = <String, List<String>>{
    'auto.png': ['自动', 'auto', 'urltest', '测速', '速度'],
    'round_robin.png': ['故障转移', 'failover', 'fallback', '容错'],
    'stack.png': ['负载', 'balance', '轮询'],
    'final.png': ['漏网', 'final', '兜底'],
    'direct.png': ['直连', 'direct', '绕过'],
    'world_map.png': ['其他', 'other', '剩余', 'world', '全球', '全部', '所有'],
    'rocket.png': ['选择', 'select', 'proxy', '节点', '手动', 'manual', '策略', '默认'],
  };

  /// The countries a subscription names its region groups after. The bundle has
  /// a picture for a few; the rest wear the flag the app already has the font
  /// for.
  static const _countries = <String, String>{
    '香港': 'HK',
    'hk': 'HK',
    'hongkong': 'HK',
    '深港': 'HK',
    '沪港': 'HK',
    '京港': 'HK',
    '日本': 'JP',
    'jp': 'JP',
    'japan': 'JP',
    '东京': 'JP',
    'tokyo': 'JP',
    '大阪': 'JP',
    'osaka': 'JP',
    '美国': 'US',
    'us': 'US',
    'usa': 'US',
    'unitedstates': 'US',
    'america': 'US',
    '洛杉矶': 'US',
    '硅谷': 'US',
    '西雅图': 'US',
    '纽约': 'US',
    '美西': 'US',
    '美东': 'US',
    '新加坡': 'SG',
    'sg': 'SG',
    'singapore': 'SG',
    '狮城': 'SG',
    '沪新': 'SG',
    '京新': 'SG',
    '深新': 'SG',
    '台湾': 'TW',
    'tw': 'TW',
    'taiwan': 'TW',
    '台北': 'TW',
    '台中': 'TW',
    '新北': 'TW',
    '韩国': 'KR',
    'kr': 'KR',
    'korea': 'KR',
    'southkorea': 'KR',
    '首尔': 'KR',
    '春川': 'KR',
    '英国': 'GB',
    'uk': 'GB',
    'gb': 'GB',
    'england': 'GB',
    'unitedkingdom': 'GB',
    '伦敦': 'GB',
    '德国': 'DE',
    'de': 'DE',
    'germany': 'DE',
    '法兰克福': 'DE',
    '法国': 'FR',
    'fr': 'FR',
    'france': 'FR',
    '巴黎': 'FR',
    '加拿大': 'CA',
    'ca': 'CA',
    'canada': 'CA',
    '多伦多': 'CA',
    '澳大利亚': 'AU',
    'au': 'AU',
    'australia': 'AU',
    '悉尼': 'AU',
    '墨尔本': 'AU',
    '俄罗斯': 'RU',
    'ru': 'RU',
    'russia': 'RU',
    '莫斯科': 'RU',
    '圣彼得堡': 'RU',
    '印度': 'IN',
    'in': 'IN',
    'india': 'IN',
    '孟买': 'IN',
    '荷兰': 'NL',
    'nl': 'NL',
    'netherlands': 'NL',
    'holland': 'NL',
    '阿姆斯特丹': 'NL',
    '土耳其': 'TR',
    'tr': 'TR',
    'turkey': 'TR',
    '伊斯坦布尔': 'TR',
    '巴西': 'BR',
    'br': 'BR',
    'brazil': 'BR',
    '圣保罗': 'BR',
    '里约热内卢': 'BR',
    '阿根廷': 'AR',
    'ar': 'AR',
    'argentina': 'AR',
    '布宜诺斯艾利斯': 'AR',
    '泰国': 'TH',
    'th': 'TH',
    'thailand': 'TH',
    '曼谷': 'TH',
    '越南': 'VN',
    'vn': 'VN',
    'vietnam': 'VN',
    '胡志明': 'VN',
    '马来西亚': 'MY',
    'my': 'MY',
    'malaysia': 'MY',
    '吉隆坡': 'MY',
    '印尼': 'ID',
    'id': 'ID',
    'indonesia': 'ID',
    '雅加达': 'ID',
    '菲律宾': 'PH',
    'ph': 'PH',
    'philippines': 'PH',
    '马尼拉': 'PH',
    '意大利': 'IT',
    'it': 'IT',
    'italy': 'IT',
    '米兰': 'IT',
    '罗马': 'IT',
    '西班牙': 'ES',
    'es': 'ES',
    'spain': 'ES',
    '马德里': 'ES',
    '瑞士': 'CH',
    'ch': 'CH',
    'switzerland': 'CH',
    '苏黎世': 'CH',
    '瑞典': 'SE',
    'se': 'SE',
    'sweden': 'SE',
    '挪威': 'NO',
    'no': 'NO',
    'norway': 'NO',
    '芬兰': 'FI',
    'fi': 'FI',
    'finland': 'FI',
    '丹麦': 'DK',
    'dk': 'DK',
    'denmark': 'DK',
    '波兰': 'PL',
    'pl': 'PL',
    'poland': 'PL',
    '乌克兰': 'UA',
    'ua': 'UA',
    'ukraine': 'UA',
    '爱尔兰': 'IE',
    'ie': 'IE',
    'ireland': 'IE',
    '都柏林': 'IE',
    '奥地利': 'AT',
    'at': 'AT',
    'austria': 'AT',
    '维也纳': 'AT',
    '捷克': 'CZ',
    'cz': 'CZ',
    'czechia': 'CZ',
    '布拉格': 'CZ',
    '匈牙利': 'HU',
    'hu': 'HU',
    'hungary': 'HU',
    '布达佩斯': 'HU',
    '葡萄牙': 'PT',
    'pt': 'PT',
    'portugal': 'PT',
    '里斯本': 'PT',
    '希腊': 'GR',
    'gr': 'GR',
    'greece': 'GR',
    '雅典': 'GR',
    '南非': 'ZA',
    'za': 'ZA',
    'southafrica': 'ZA',
    '开普敦': 'ZA',
    '墨西哥': 'MX',
    'mx': 'MX',
    'mexico': 'MX',
    '以色列': 'IL',
    'il': 'IL',
    'israel': 'IL',
    '特拉维夫': 'IL',
    '阿联酋': 'AE',
    'ae': 'AE',
    'dubai': 'AE',
    '迪拜': 'AE',
    '沙特': 'SA',
    'sa': 'SA',
    'saudiarabia': 'SA',
    '新西兰': 'NZ',
    'nz': 'NZ',
    'newzealand': 'NZ',
    '哈萨克斯坦': 'KZ',
    'kz': 'KZ',
    'kazakhstan': 'KZ',
    '蒙古': 'MN',
    'mn': 'MN',
    'mongolia': 'MN',
    '巴基斯坦': 'PK',
    'pk': 'PK',
    'pakistan': 'PK',
    '中国': 'CN',
    'cn': 'CN',
    'china': 'CN',
    '回国': 'CN',
    '国内': 'CN',
    '卢森堡': 'LU',
    'lu': 'LU',
    'luxembourg': 'LU',
    '爱沙尼亚': 'EE',
    'ee': 'EE',
    'estonia': 'EE',
    '拉脱维亚': 'LV',
    'lv': 'LV',
    'latvia': 'LV',
    '立陶宛': 'LT',
    'lt': 'LT',
    'lithuania': 'LT',
    '塞尔维亚': 'RS',
    'rs': 'RS',
    'serbia': 'RS',
    '保加利亚': 'BG',
    'bg': 'BG',
    'bulgaria': 'BG',
    '罗马尼亚': 'RO',
    'ro': 'RO',
    'romania': 'RO',
  };

  /// The pictures the bundle carries for the countries above.
  static const _countryPictures = <String, String>{
    'HK': 'hong_kong.png',
    'JP': 'japan.png',
    'US': 'united_states.png',
    'SG': 'singapore.png',
    'TW': 'taiwan.png',
  };

  /// The flag a country group wears when the bundle has no picture for it.
  static String flagOf(String name) {
    final country = _country(name);
    if (country == null || _countryPictures.containsKey(country)) {
      return '';
    }
    return country.countryFlagEmoji;
  }

  static String? _country(String name) {
    final words = _words(name);
    for (final entry in _countries.entries) {
      if (_mentions(words, entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static String? _guess(String name, Map<String, List<String>> table) {
    final words = _words(name);
    for (final entry in table.entries) {
      if (entry.value.any((key) => _mentions(words, key))) {
        return entry.key;
      }
    }
    return null;
  }

  /// The words a name is worth matching on: a flag emoji becomes the two-letter
  /// code it stands for, everything that is not a letter or a digit splits words.
  static List<String> _words(String name) {
    final buffer = StringBuffer();
    for (final rune in name.runes) {
      if (rune >= 0x1F1E6 && rune <= 0x1F1FF) {
        buffer.writeCharCode(0x61 + rune - 0x1F1E6);
      } else if (_keeps(rune)) {
        buffer.writeCharCode(rune);
      } else {
        buffer.write(' ');
      }
    }
    return buffer
        .toString()
        .toLowerCase()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
  }

  static bool _keeps(int rune) =>
      (rune >= 0x30 && rune <= 0x39) ||
      (rune >= 0x41 && rune <= 0x5A) ||
      (rune >= 0x61 && rune <= 0x7A) ||
      (rune >= 0x4E00 && rune <= 0x9FFF) ||
      (rune >= 0x3040 && rune <= 0x30FF) ||
      (rune >= 0xAC00 && rune <= 0xD7AF);

  /// A one- or two-letter code (`us`, `hk`) only counts as its own word, so
  /// `Russia` does not read as `US`; longer keys match inside the word.
  static bool _mentions(List<String> words, String key) {
    final ascii = key.codeUnits.every((unit) => unit < 0x80);
    if (!ascii || key.length > 2) {
      return words.any((word) => word.contains(key));
    }
    return words.any(
      (word) =>
          word == key ||
          (word.startsWith(key) && _isNumber(word.substring(key.length))),
    );
  }

  static bool _isNumber(String text) =>
      text.isNotEmpty &&
      text.codeUnits.every((unit) => unit >= 0x30 && unit <= 0x39);
}

/// Stands in for a group whose picture is empty or unreadable: the app's own
/// mark. [GroupName.GLOBAL] keeps [GroupMonogram]'s flag, which says where
/// traffic leaves rather than what the group is.
class GroupBadge extends StatelessWidget {
  const GroupBadge({super.key, required this.name, this.exitCountryCode});

  final String name;
  final String? exitCountryCode;

  /// Fixed rather than seeded: the kinds have to stay apart whatever colour the
  /// theme takes. Each is a tone that reads on both a light and a dark surface.
  static Color colorOf(BuildContext context, GroupType type) {
    final dark = context.colorScheme.brightness == Brightness.dark;
    return switch (type) {
      GroupType.Selector =>
        dark ? const Color(0xFF8AB4F8) : const Color(0xFF1A63C7),
      GroupType.URLTest =>
        dark ? const Color(0xFF7BD8A4) : const Color(0xFF1D8A55),
      GroupType.Fallback =>
        dark ? const Color(0xFFF5B85E) : const Color(0xFFB26A0B),
      GroupType.LoadBalance =>
        dark ? const Color(0xFFC4A6F7) : const Color(0xFF7A45C9),
      GroupType.Relay =>
        dark ? const Color(0xFF6FD3D0) : const Color(0xFF0E8684),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (GroupMonogram.isGlobal(name)) {
      return GroupMonogram(name, exitCountryCode: exitCountryCode);
    }
    final size = IconTheme.of(context).size ?? 24;
    final flag = GroupIconSource.flagOf(name);
    if (flag.isNotEmpty) {
      return SizedBox.square(
        dimension: size,
        child: FittedBox(
          fit: BoxFit.contain,
          child: EmojiText(
            flag,
            maxLines: 1,
            style: AppTextStyle.custom(context, size: size, leading: size),
          ),
        ),
      );
    }
    return Image.asset(
      GroupIconSource.logo,
      width: size,
      height: size,
      cacheWidth: _iconDecodeExtent,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) =>
          GroupMonogram(name, exitCountryCode: exitCountryCode),
    );
  }
}

class _BytesImage extends StatelessWidget {
  const _BytesImage({
    required this.bytes,
    required this.isSvg,
    required this.fallback,
    this.onError,
  });

  final Uint8List bytes;
  final bool isSvg;
  final Widget fallback;
  final VoidCallback? onError;

  Widget _buildFallback() {
    onError?.call();
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return isSvg
        ? SvgPicture.memory(bytes, errorBuilder: (_, _, _) => _buildFallback())
        : Image(
            image: _iconImage(bytes),
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _buildFallback(),
          );
  }
}

final _cacheManager = CacheManager(
  Config(
    DefaultCacheManager.key,
    fileService: HttpFileService()..concurrentFetches = maxConcurrentIconLoads,
  ),
);

Stream<Uint8List> _readCachedIcon(String src) {
  return _cacheManager
      .getFileStreamV2(src)
      .asyncMap((data) => data.file.readAsBytes());
}

var _readRemoteIcon = _readCachedIcon;

@visibleForTesting
set readRemoteIcon(Stream<Uint8List> Function(String src)? value) {
  _readRemoteIcon = value ?? _readCachedIcon;
}

Stream<Uint8List> _loadRemoteIcon(String src) {
  return _readRemoteIcon(src).map((bytes) {
    final current = _remoteIcons[src];
    final next = current != null && listEquals(current, bytes)
        ? current
        : bytes;
    return _remoteIcons[src] = next;
  });
}

Future<void> _decodeAhead(Uint8List bytes) {
  final completer = Completer<void>();
  final stream = _iconImage(bytes).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  void finish() {
    stream.removeListener(listener);
    completer.complete();
  }

  listener = ImageStreamListener(
    (_, _) => finish(),
    onError: (_, _) => finish(),
  );
  stream.addListener(listener);
  return completer.future;
}

Future<void> precacheTargetIcons(Iterable<String> srcs) async {
  final pending = srcs
      .toSet()
      .where(
        (src) =>
            src.isNotEmpty &&
            !src.contains('base64,') &&
            !src.isBundleAsset &&
            !_remoteIcons.contains(src),
      )
      .map((src) async {
        try {
          await for (final bytes in _loadRemoteIcon(src)) {
            if (!src.isSvg) {
              await _decodeAhead(bytes);
            }
          }
        } catch (error) {
          commonPrint.log('Failed to precache icon $src: $error');
        }
      });
  await Future.wait(pending);
}

class ImageCacheWidget extends StatefulWidget {
  final String src;
  final Widget defaultWidget;

  const ImageCacheWidget({
    super.key,
    required this.src,
    required this.defaultWidget,
  });

  @override
  State<ImageCacheWidget> createState() => _ImageCacheWidgetState();
}

class _ImageCacheWidgetState extends State<ImageCacheWidget> {
  late final ValueNotifier<Uint8List?> _bytesNotifier;
  StreamSubscription? _streamSubscription;
  var _loadEnded = false;

  @override
  void initState() {
    super.initState();
    _bytesNotifier = ValueNotifier(_remoteIcons[widget.src]);
    _getImageFormCache();
  }

  @override
  void didUpdateWidget(covariant ImageCacheWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _bytesNotifier.value = _remoteIcons[widget.src];
      _loadEnded = false;
      _getImageFormCache();
    }
  }

  void _getImageFormCache() {
    final src = widget.src;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    if (src.isEmpty) {
      return;
    }
    _streamSubscription = _loadRemoteIcon(src).listen(
      (bytes) {
        if (mounted) {
          _bytesNotifier.value = bytes;
        }
      },
      onError: (Object error) {
        commonPrint.log('Failed to read icon $src: $error');
      },
      onDone: () {
        if (mounted && _bytesNotifier.value == null) {
          setState(() => _loadEnded = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _bytesNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: _bytesNotifier,
      builder: (context, bytes, _) {
        if (bytes == null) {
          return _loadEnded || widget.src.isEmpty
              ? widget.defaultWidget
              : SizedBox.square(dimension: IconTheme.of(context).size ?? 24);
        }
        return _BytesImage(
          bytes: bytes,
          isSvg: widget.src.isSvg,
          fallback: widget.defaultWidget,
          onError: () => _remoteIcons.remove(widget.src),
        );
      },
    );
  }
}

class PackageIcon extends StatefulWidget {
  final String packageName;
  final double size;

  const PackageIcon({super.key, required this.packageName, required this.size});

  @override
  State<PackageIcon> createState() => _PackageIconState();
}

class _PackageIconState extends State<PackageIcon> {
  ImageProvider? _icon;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _showCachedIcon();
    _loadIcon();
  }

  @override
  void didUpdateWidget(covariant PackageIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName) {
      _showCachedIcon();
      _loadIcon();
    }
  }

  void _showCachedIcon() {
    _generation++;
    _icon = app?.getCachedPackageIcon(widget.packageName);
  }

  void _loadIcon() {
    final generation = _generation;
    app?.getPackageIcon(widget.packageName).then((icon) {
      if (!mounted ||
          generation != _generation ||
          icon == null ||
          icon == _icon) {
        return;
      }
      setState(() {
        _icon = icon;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final icon = _icon;
    if (icon == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }
    return Image(
      image: icon,
      gaplessPlayback: true,
      width: widget.size,
      height: widget.size,
    );
  }
}
