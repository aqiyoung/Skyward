import 'package:flutter/foundation.dart';

/// A place the route map can pin, keyed by its ISO 3166-1 alpha-2 code.
///
/// The coordinates are the city a subscription's nodes usually sit in rather
/// than the country's centroid: traffic lands in the capital or the datacentre
/// belt, and a marker there reads as the right place at a glance.
@immutable
final class GeoCountry {
  const GeoCountry(
    this.code,
    this.latitude,
    this.longitude,
    this.englishName,
    this.chineseName,
  );

  final String code;
  final double latitude;
  final double longitude;
  final String englishName;
  final String chineseName;

  String label({required bool chinese}) => chinese ? chineseName : englishName;

  @override
  bool operator ==(Object other) => other is GeoCountry && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'GeoCountry($code)';
}

const _countries = <String, GeoCountry>{
  'CN': GeoCountry('CN', 31.23, 121.47, 'China', '中国'),
  'HK': GeoCountry('HK', 22.32, 114.17, 'Hong Kong, China', '中国香港'),
  'MO': GeoCountry('MO', 22.20, 113.54, 'Macao, China', '中国澳门'),
  'TW': GeoCountry('TW', 25.03, 121.57, 'Taiwan, China', '中国台湾'),
  'JP': GeoCountry('JP', 35.68, 139.69, 'Japan', '日本'),
  'KR': GeoCountry('KR', 37.57, 126.98, 'South Korea', '韩国'),
  'SG': GeoCountry('SG', 1.35, 103.82, 'Singapore', '新加坡'),
  'MY': GeoCountry('MY', 3.14, 101.69, 'Malaysia', '马来西亚'),
  'TH': GeoCountry('TH', 13.76, 100.50, 'Thailand', '泰国'),
  'VN': GeoCountry('VN', 10.82, 106.63, 'Vietnam', '越南'),
  'PH': GeoCountry('PH', 14.60, 120.98, 'Philippines', '菲律宾'),
  'ID': GeoCountry('ID', -6.21, 106.85, 'Indonesia', '印度尼西亚'),
  'IN': GeoCountry('IN', 19.08, 72.88, 'India', '印度'),
  'PK': GeoCountry('PK', 24.86, 67.01, 'Pakistan', '巴基斯坦'),
  'BD': GeoCountry('BD', 23.81, 90.41, 'Bangladesh', '孟加拉国'),
  'LK': GeoCountry('LK', 6.93, 79.86, 'Sri Lanka', '斯里兰卡'),
  'NP': GeoCountry('NP', 27.72, 85.32, 'Nepal', '尼泊尔'),
  'MM': GeoCountry('MM', 16.87, 96.20, 'Myanmar', '缅甸'),
  'KH': GeoCountry('KH', 11.56, 104.92, 'Cambodia', '柬埔寨'),
  'LA': GeoCountry('LA', 17.97, 102.63, 'Laos', '老挝'),
  'MN': GeoCountry('MN', 47.89, 106.91, 'Mongolia', '蒙古'),
  'KZ': GeoCountry('KZ', 43.24, 76.89, 'Kazakhstan', '哈萨克斯坦'),
  'UZ': GeoCountry('UZ', 41.30, 69.24, 'Uzbekistan', '乌兹别克斯坦'),
  'AF': GeoCountry('AF', 34.53, 69.17, 'Afghanistan', '阿富汗'),
  'US': GeoCountry('US', 34.05, -118.24, 'United States', '美国'),
  'CA': GeoCountry('CA', 43.65, -79.38, 'Canada', '加拿大'),
  'MX': GeoCountry('MX', 19.43, -99.13, 'Mexico', '墨西哥'),
  'BR': GeoCountry('BR', -23.55, -46.63, 'Brazil', '巴西'),
  'AR': GeoCountry('AR', -34.60, -58.38, 'Argentina', '阿根廷'),
  'CL': GeoCountry('CL', -33.45, -70.67, 'Chile', '智利'),
  'CO': GeoCountry('CO', 4.71, -74.07, 'Colombia', '哥伦比亚'),
  'PE': GeoCountry('PE', -12.05, -77.04, 'Peru', '秘鲁'),
  'VE': GeoCountry('VE', 10.48, -66.90, 'Venezuela', '委内瑞拉'),
  'PA': GeoCountry('PA', 8.98, -79.52, 'Panama', '巴拿马'),
  'GB': GeoCountry('GB', 51.51, -0.13, 'United Kingdom', '英国'),
  'IE': GeoCountry('IE', 53.35, -6.26, 'Ireland', '爱尔兰'),
  'FR': GeoCountry('FR', 48.86, 2.35, 'France', '法国'),
  'DE': GeoCountry('DE', 50.11, 8.68, 'Germany', '德国'),
  'NL': GeoCountry('NL', 52.37, 4.90, 'Netherlands', '荷兰'),
  'BE': GeoCountry('BE', 50.85, 4.35, 'Belgium', '比利时'),
  'CH': GeoCountry('CH', 47.38, 8.54, 'Switzerland', '瑞士'),
  'AT': GeoCountry('AT', 48.21, 16.37, 'Austria', '奥地利'),
  'IT': GeoCountry('IT', 45.46, 9.19, 'Italy', '意大利'),
  'ES': GeoCountry('ES', 40.42, -3.70, 'Spain', '西班牙'),
  'PT': GeoCountry('PT', 38.72, -9.14, 'Portugal', '葡萄牙'),
  'GR': GeoCountry('GR', 37.98, 23.73, 'Greece', '希腊'),
  'SE': GeoCountry('SE', 59.33, 18.07, 'Sweden', '瑞典'),
  'NO': GeoCountry('NO', 59.91, 10.75, 'Norway', '挪威'),
  'DK': GeoCountry('DK', 55.68, 12.57, 'Denmark', '丹麦'),
  'FI': GeoCountry('FI', 60.17, 24.94, 'Finland', '芬兰'),
  'PL': GeoCountry('PL', 52.23, 21.01, 'Poland', '波兰'),
  'CZ': GeoCountry('CZ', 50.08, 14.44, 'Czechia', '捷克'),
  'HU': GeoCountry('HU', 47.50, 19.04, 'Hungary', '匈牙利'),
  'RO': GeoCountry('RO', 44.43, 26.10, 'Romania', '罗马尼亚'),
  'BG': GeoCountry('BG', 42.70, 23.32, 'Bulgaria', '保加利亚'),
  'RS': GeoCountry('RS', 44.79, 20.45, 'Serbia', '塞尔维亚'),
  'HR': GeoCountry('HR', 45.81, 15.98, 'Croatia', '克罗地亚'),
  'LT': GeoCountry('LT', 54.69, 25.28, 'Lithuania', '立陶宛'),
  'LV': GeoCountry('LV', 56.95, 24.11, 'Latvia', '拉脱维亚'),
  'EE': GeoCountry('EE', 59.44, 24.75, 'Estonia', '爱沙尼亚'),
  'BY': GeoCountry('BY', 53.90, 27.57, 'Belarus', '白俄罗斯'),
  'MD': GeoCountry('MD', 47.01, 28.86, 'Moldova', '摩尔多瓦'),
  'UA': GeoCountry('UA', 50.45, 30.52, 'Ukraine', '乌克兰'),
  'RU': GeoCountry('RU', 55.76, 37.62, 'Russia', '俄罗斯'),
  'TR': GeoCountry('TR', 41.01, 28.98, 'Türkiye', '土耳其'),
  'AE': GeoCountry('AE', 25.20, 55.27, 'United Arab Emirates', '阿联酋'),
  'SA': GeoCountry('SA', 24.71, 46.68, 'Saudi Arabia', '沙特阿拉伯'),
  'QA': GeoCountry('QA', 25.29, 51.53, 'Qatar', '卡塔尔'),
  'KW': GeoCountry('KW', 29.38, 47.99, 'Kuwait', '科威特'),
  'BH': GeoCountry('BH', 26.23, 50.59, 'Bahrain', '巴林'),
  'OM': GeoCountry('OM', 23.59, 58.41, 'Oman', '阿曼'),
  'JO': GeoCountry('JO', 31.95, 35.93, 'Jordan', '约旦'),
  'LB': GeoCountry('LB', 33.89, 35.50, 'Lebanon', '黎巴嫩'),
  'IL': GeoCountry('IL', 32.09, 34.78, 'Israel', '以色列'),
  'IQ': GeoCountry('IQ', 33.31, 44.36, 'Iraq', '伊拉克'),
  'IR': GeoCountry('IR', 35.69, 51.39, 'Iran', '伊朗'),
  'GE': GeoCountry('GE', 41.72, 44.79, 'Georgia', '格鲁吉亚'),
  'AM': GeoCountry('AM', 40.18, 44.51, 'Armenia', '亚美尼亚'),
  'AZ': GeoCountry('AZ', 40.41, 49.87, 'Azerbaijan', '阿塞拜疆'),
  'EG': GeoCountry('EG', 30.04, 31.24, 'Egypt', '埃及'),
  'ZA': GeoCountry('ZA', -26.20, 28.05, 'South Africa', '南非'),
  'NG': GeoCountry('NG', 6.52, 3.38, 'Nigeria', '尼日利亚'),
  'KE': GeoCountry('KE', -1.29, 36.82, 'Kenya', '肯尼亚'),
  'MA': GeoCountry('MA', 33.57, -7.59, 'Morocco', '摩洛哥'),
  'TN': GeoCountry('TN', 36.81, 10.18, 'Tunisia', '突尼斯'),
  'DZ': GeoCountry('DZ', 36.75, 3.06, 'Algeria', '阿尔及利亚'),
  'AU': GeoCountry('AU', -33.87, 151.21, 'Australia', '澳大利亚'),
  'NZ': GeoCountry('NZ', -36.85, 174.76, 'New Zealand', '新西兰'),
};

/// The place names subscriptions put in node names, in the two languages they
/// are written in. Tags like `IEPL` or `BGP` are deliberately absent: they say
/// how the link is sold, not where it lands.
const _aliases = <String, List<String>>{
  'CN': ['中国', 'china', 'mainland', '上海', '北京', '广州', '深圳', '杭州', '镇江', '徐州'],
  'HK': ['香港', 'hong kong', 'hongkong', 'hkg', 'hkt', 'hkbn', 'pccw', 'cmi'],
  'MO': ['澳门', 'macao', 'macau'],
  'TW': ['台湾', '台北', '新北', '彰化', 'taiwan', 'taipei', 'hinet', 'chunghwa'],
  'JP': [
    '日本',
    '东京',
    '大阪',
    '埼玉',
    '沪日',
    'japan',
    'tokyo',
    'osaka',
    'saitama',
    'ntt',
    'iij',
    'kddi',
    'softbank',
  ],
  'KR': ['韩国', '南韩', '首尔', 'korea', 'seoul', 'kt', 'skbroadband'],
  'SG': ['新加坡', '狮城', 'singapore', 'singtel'],
  'MY': ['马来西亚', '马来', '吉隆坡', 'malaysia', 'kuala lumpur'],
  'TH': ['泰国', '曼谷', 'thailand', 'bangkok'],
  'VN': ['越南', '胡志明', '河内', 'vietnam', 'hanoi'],
  'PH': ['菲律宾', '马尼拉', 'philippines', 'manila'],
  'ID': ['印尼', '印度尼西亚', '雅加达', 'indonesia', 'jakarta'],
  'IN': ['印度', '孟买', '班加罗尔', 'india', 'mumbai', 'bangalore'],
  'PK': ['巴基斯坦', 'pakistan'],
  'BD': ['孟加拉', 'bangladesh'],
  'LK': ['斯里兰卡', 'sri lanka'],
  'NP': ['尼泊尔', 'nepal'],
  'MM': ['缅甸', 'myanmar'],
  'KH': ['柬埔寨', 'cambodia'],
  'LA': ['老挝', 'laos'],
  'MN': ['蒙古', 'mongolia'],
  'KZ': ['哈萨克', 'kazakhstan'],
  'UZ': ['乌兹别克', 'uzbekistan'],
  'AF': ['阿富汗', 'afghanistan'],
  'US': [
    '美国',
    '洛杉矶',
    '圣何塞',
    '硅谷',
    '西雅图',
    '纽约',
    '达拉斯',
    '芝加哥',
    '迈阿密',
    '凤凰城',
    '波特兰',
    '亚特兰大',
    'united states',
    'america',
    'usa',
    'los angeles',
    'san jose',
    'silicon valley',
    'seattle',
    'new york',
    'dallas',
    'chicago',
    'miami',
    'phoenix',
    'ashburn',
    'portland',
  ],
  'CA': ['加拿大', '多伦多', '温哥华', '蒙特利尔', 'canada', 'toronto', 'vancouver'],
  'MX': ['墨西哥', 'mexico'],
  'BR': ['巴西', '圣保罗', 'brazil', 'sao paulo'],
  'AR': ['阿根廷', 'argentina'],
  'CL': ['智利', 'chile'],
  'CO': ['哥伦比亚', 'colombia'],
  'PE': ['秘鲁', 'peru'],
  'VE': ['委内瑞拉', 'venezuela'],
  'PA': ['巴拿马', 'panama'],
  'GB': ['英国', '伦敦', 'united kingdom', 'britain', 'england', 'london', 'uk'],
  'IE': ['爱尔兰', '都柏林', 'ireland', 'dublin'],
  'FR': ['法国', '巴黎', '马赛', 'france', 'paris', 'marseille'],
  'DE': ['德国', '法兰克福', '柏林', 'germany', 'frankfurt', 'berlin'],
  'NL': ['荷兰', '阿姆斯特丹', 'netherlands', 'amsterdam'],
  'BE': ['比利时', 'brussels', 'belgium'],
  'CH': ['瑞士', '苏黎世', 'switzerland', 'zurich'],
  'AT': ['奥地利', 'austria', 'vienna'],
  'IT': ['意大利', '米兰', 'italy', 'milan'],
  'ES': ['西班牙', '马德里', 'spain', 'madrid'],
  'PT': ['葡萄牙', 'portugal', 'lisbon'],
  'GR': ['希腊', 'greece', 'athens'],
  'SE': ['瑞典', 'sweden', 'stockholm'],
  'NO': ['挪威', 'norway', 'oslo'],
  'DK': ['丹麦', 'denmark', 'copenhagen'],
  'FI': ['芬兰', 'finland', 'helsinki'],
  'PL': ['波兰', 'poland', 'warsaw'],
  'CZ': ['捷克', 'czech', 'prague'],
  'HU': ['匈牙利', 'hungary', 'budapest'],
  'RO': ['罗马尼亚', 'romania', 'bucharest'],
  'BG': ['保加利亚', 'bulgaria', 'sofia'],
  'RS': ['塞尔维亚', 'serbia', 'belgrade'],
  'HR': ['克罗地亚', 'croatia', 'zagreb'],
  'LT': ['立陶宛', 'lithuania', 'vilnius'],
  'LV': ['拉脱维亚', 'latvia', 'riga'],
  'EE': ['爱沙尼亚', 'estonia', 'tallinn'],
  'BY': ['白俄罗斯', 'belarus', 'minsk'],
  'MD': ['摩尔多瓦', 'moldova'],
  'UA': ['乌克兰', 'ukraine', 'kyiv'],
  'RU': ['俄罗斯', '莫斯科', '圣彼得堡', 'russia', 'moscow'],
  'TR': ['土耳其', '伊斯坦布尔', 'turkiye', 'turkey', 'istanbul'],
  'AE': ['阿联酋', '迪拜', 'emirates', 'dubai'],
  'SA': ['沙特', 'saudi', 'riyadh'],
  'QA': ['卡塔尔', 'qatar', 'doha'],
  'KW': ['科威特', 'kuwait'],
  'BH': ['巴林', 'bahrain'],
  'OM': ['阿曼', 'oman', 'muscat'],
  'JO': ['约旦', 'jordan', 'amman'],
  'LB': ['黎巴嫩', 'lebanon', 'beirut'],
  'IL': ['以色列', 'israel', 'tel aviv'],
  'IQ': ['伊拉克', 'iraq', 'baghdad'],
  'IR': ['伊朗', 'iran', 'tehran'],
  'GE': ['格鲁吉亚', 'georgia', 'tbilisi'],
  'AM': ['亚美尼亚', 'armenia', 'yerevan'],
  'AZ': ['阿塞拜疆', 'azerbaijan', 'baku'],
  'EG': ['埃及', 'egypt', 'cairo'],
  'ZA': ['南非', 'south africa', 'johannesburg'],
  'NG': ['尼日利亚', 'nigeria', 'lagos'],
  'KE': ['肯尼亚', 'kenya', 'nairobi'],
  'MA': ['摩洛哥', 'morocco', 'casablanca'],
  'TN': ['突尼斯', 'tunisia'],
  'DZ': ['阿尔及利亚', 'algeria'],
  'AU': ['澳大利亚', '澳洲', '悉尼', '墨尔本', 'australia', 'sydney', 'melbourne'],
  'NZ': ['新西兰', 'new zealand', 'auckland'],
};

final _aliasIndex = <String, GeoCountry>{
  for (final entry in _aliases.entries)
    if (_countries[entry.key] case final country?)
      for (final alias in entry.value) alias: country,
};

/// `UK` is the one tag subscriptions use that ISO does not.
const _codeAliases = <String, String>{'UK': 'GB'};

/// Tags that mean something else in a node name than they do in a GeoIP
/// answer. `LA` is Laos to the database and Los Angeles to a subscription,
/// and no subscription names a node after Laos in two letters.
const _nodeTags = <String, String>{'UK': 'GB', 'LA': 'US'};

/// A two letter tag standing on its own, so `IPLC` and `BGP` stay out of it.
final _codeTag = RegExp(r'(?<![A-Za-z])([A-Z]{2})(?![A-Za-z])');

const _regionStart = 0x1F1E6;
const _regionEnd = 0x1F1FF;
const _letterA = 0x41;

GeoCountry? geoCountryOf(String? code) {
  if (code == null || code.isEmpty) {
    return null;
  }
  final upper = code.toUpperCase();
  return _countries[upper] ?? _countries[_codeAliases[upper]];
}

/// Reads the country a Clash node name points at.
///
/// Subscriptions name a node after its flag, an ISO tag or a place, and a
/// relay is named after both of its ends. The last one mentioned wins, because
/// that is the end the traffic leaves from.
GeoCountry? geoCountryOfNode(String name) {
  final countries = geoCountriesOfNode(name);
  return countries.isEmpty ? null : countries.last;
}

/// Every country a node name mentions, in the order it mentions them.
///
/// `香港中转 洛杉矶 01` is one node with two ends: the traffic crosses Hong
/// Kong on its way to Los Angeles, and the map says so.
List<GeoCountry> geoCountriesOfNode(String name) {
  if (name.isEmpty) {
    return const [];
  }
  final hits = <(int, GeoCountry)>[];
  final lower = name.toLowerCase();
  for (final entry in _aliasIndex.entries) {
    var at = lower.indexOf(entry.key);
    while (at >= 0) {
      hits.add((at, entry.value));
      at = lower.indexOf(entry.key, at + entry.key.length);
    }
  }
  for (final match in _codeTag.allMatches(name)) {
    final tag = match.group(1)!;
    final country = geoCountryOf(_nodeTags[tag] ?? tag);
    if (country != null) {
      hits.add((match.start, country));
    }
  }
  for (final (at, country) in _flagHits(name)) {
    hits.add((at, country));
  }
  if (hits.isEmpty) {
    return const [];
  }
  hits.sort((a, b) => a.$1.compareTo(b.$1));
  final countries = <GeoCountry>[];
  for (final (_, country) in hits) {
    // The aliases overlap — `HK`, `Hong Kong` and the flag all name the same
    // end — so a repeat next to its twin is the same mention.
    if (countries.isEmpty || countries.last != country) {
      countries.add(country);
    }
  }
  return countries;
}

/// A pair of regional indicators spells the code, which is how most
/// subscriptions bake the region into the name.
Iterable<(int, GeoCountry)> _flagHits(String name) sync* {
  final runes = name.runes.toList();
  for (var i = 0; i + 1 < runes.length; i++) {
    final high = runes[i];
    final low = runes[i + 1];
    if (high < _regionStart ||
        high > _regionEnd ||
        low < _regionStart ||
        low > _regionEnd) {
      continue;
    }
    final flag = String.fromCharCodes([high, low]);
    final country = geoCountryOf(
      String.fromCharCodes([
        _letterA + high - _regionStart,
        _letterA + low - _regionStart,
      ]),
    );
    if (country != null) {
      yield (name.indexOf(flag), country);
    }
  }
}

/// Clash answers a GeoIP lookup with the country first and the AS number
/// after it, so the first code that names a place is the answer.
GeoCountry? geoCountryOfGeoIps(List<String> geoIps) {
  for (final item in geoIps) {
    final country = geoCountryOf(item);
    if (country != null) {
      return country;
    }
  }
  return null;
}

/// Turns a longitude into the map's x, left to right.
double geoMapX(double longitude) => (longitude + 180) / 360;

/// A named point finer than a country: the city a node is named after, or the
/// province an address is registered in.
///
/// A country's stand-in coordinate is its capital, which is right to within a
/// few hundred kilometres and wrong in a way that shows: two hops in one
/// country stack, and a node in Los Angeles sits off the east coast.
@immutable
final class GeoPlace {
  const GeoPlace(
    this.latitude,
    this.longitude,
    this.chineseName,
    this.englishName, [
    this.countryCode = '',
  ]);

  final double latitude;
  final double longitude;
  final String chineseName;
  final String englishName;

  /// The country the place sits in, so a city cannot be pinned to an address
  /// that resolved somewhere else.
  final String countryCode;

  String label({required bool chinese}) => chinese ? chineseName : englishName;

  @override
  bool operator ==(Object other) =>
      other is GeoPlace &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPlace($englishName)';
}

/// The province an answer names, read from the `region` field of an IP
/// lookup.
///
/// Every provider spells a province its own way: `Shaanxi`, `Shaanxi Sheng`,
/// `CN-SN`, `Shenzhen`, `陕西省`. Matching runs on letters and characters only
/// so the suffixes cancel out, then on containment so a city name reaches its
/// province, and finally on the ISO subdivision code for the answers that
/// carry nothing else.
GeoPlace? geoPlaceOfRegion(String? region) {
  if (region == null || region.isEmpty) {
    return null;
  }
  final key = _regionKey(region);
  if (key.isEmpty) {
    return null;
  }
  final direct = _provinceIndex[key];
  if (direct != null) {
    return direct;
  }
  if (key.length == 4 && key.startsWith('cn')) {
    return _provincePlaces[_provinceCodes[key.substring(2).toUpperCase()]];
  }
  // A city name stands for the province it sits in, and `Shaanxi Sheng`
  // carries the province with a suffix attached.
  GeoPlace? winner;
  var winnerLength = 0;
  for (final entry in _provinceIndex.entries) {
    if (entry.key.length > winnerLength && key.contains(entry.key)) {
      winner = entry.value;
      winnerLength = entry.key.length;
    }
  }
  return winner;
}

/// Lowercase, letters and Han characters only: `Shaanxi Sheng` and
/// `陕西省` both keep just the part that names the place.
String _regionKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z\u4e00-\u9fff]'), '');

/// The city a node name points at, when it names one.
///
/// A subscription writes `洛杉矶`, `Los Angeles`, `LAX`, `us-lax-01` and a
/// dozen other ways. Place names match anywhere in the string, because they
/// are distinctive; three letter airport codes have to stand alone, because
/// `SEA` is Seattle in a node name and part of a word everywhere else. A relay
/// carries both ends, so the last mention wins, matching [geoCountryOfNode].
GeoPlace? geoCityOfNode(String name) {
  if (name.isEmpty) {
    return null;
  }
  final lower = name.toLowerCase();
  GeoPlace? winner;
  var winnerAt = -1;
  for (final entry in _cityNames.entries) {
    final at = lower.lastIndexOf(entry.key);
    if (at > winnerAt) {
      winnerAt = at;
      winner = entry.value;
    }
  }
  for (final match in _airportCode.allMatches(name)) {
    if (_cityCodes[match.group(1)!] case final place?
        when match.start > winnerAt) {
      winnerAt = match.start;
      winner = place;
    }
  }
  return winner;
}

final _airportCode = RegExp(r'(?<![A-Za-z])([A-Z]{3})(?![A-Za-z])');

const _tokyo = GeoPlace(35.68, 139.69, '东京', 'Tokyo', 'JP');
const _osaka = GeoPlace(34.69, 135.50, '大阪', 'Osaka', 'JP');
const _seoul = GeoPlace(37.57, 126.98, '首尔', 'Seoul', 'KR');
const _taipei = GeoPlace(25.03, 121.57, '台北', 'Taipei', 'TW');
const _losAngeles = GeoPlace(34.05, -118.24, '洛杉矶', 'Los Angeles', 'US');
const _sanJose = GeoPlace(37.34, -121.89, '圣何塞', 'San Jose', 'US');
const _seattle = GeoPlace(47.61, -122.33, '西雅图', 'Seattle', 'US');
const _dallas = GeoPlace(32.78, -96.80, '达拉斯', 'Dallas', 'US');
const _chicago = GeoPlace(41.88, -87.63, '芝加哥', 'Chicago', 'US');
const _newYork = GeoPlace(40.71, -74.01, '纽约', 'New York', 'US');
const _miami = GeoPlace(25.76, -80.19, '迈阿密', 'Miami', 'US');
const _ashburn = GeoPlace(39.04, -77.49, '阿什本', 'Ashburn', 'US');
const _london = GeoPlace(51.51, -0.13, '伦敦', 'London', 'GB');
const _frankfurt = GeoPlace(50.11, 8.68, '法兰克福', 'Frankfurt', 'DE');
const _amsterdam = GeoPlace(52.37, 4.90, '阿姆斯特丹', 'Amsterdam', 'NL');
const _paris = GeoPlace(48.86, 2.35, '巴黎', 'Paris', 'FR');
const _moscow = GeoPlace(55.76, 37.62, '莫斯科', 'Moscow', 'RU');
const _sydney = GeoPlace(-33.87, 151.21, '悉尼', 'Sydney', 'AU');
const _toronto = GeoPlace(43.65, -79.38, '多伦多', 'Toronto', 'CA');
const _dubai = GeoPlace(25.20, 55.27, '迪拜', 'Dubai', 'AE');
const _mumbai = GeoPlace(19.08, 72.88, '孟买', 'Mumbai', 'IN');
const _bangkok = GeoPlace(13.76, 100.50, '曼谷', 'Bangkok', 'TH');
const _kualaLumpur = GeoPlace(3.14, 101.69, '吉隆坡', 'Kuala Lumpur', 'MY');

/// Place names, matched as substrings of the lowercased node name.
final _cityNames = <String, GeoPlace>{
  '东京': _tokyo,
  '東京': _tokyo,
  'tokyo': _tokyo,
  '成田': _tokyo,
  '大阪': _osaka,
  'osaka': _osaka,
  '首尔': _seoul,
  '서울': _seoul,
  'seoul': _seoul,
  '台北': _taipei,
  'taipei': _taipei,
  '新北': _taipei,
  '洛杉矶': _losAngeles,
  'los angeles': _losAngeles,
  '圣何塞': _sanJose,
  'san jose': _sanJose,
  '旧金山': _sanJose,
  'san francisco': _sanJose,
  '西雅图': _seattle,
  'seattle': _seattle,
  '达拉斯': _dallas,
  'dallas': _dallas,
  '芝加哥': _chicago,
  'chicago': _chicago,
  '纽约': _newYork,
  'new york': _newYork,
  '迈阿密': _miami,
  'miami': _miami,
  '阿什本': _ashburn,
  'ashburn': _ashburn,
  '伦敦': _london,
  'london': _london,
  '法兰克福': _frankfurt,
  'frankfurt': _frankfurt,
  '阿姆斯特丹': _amsterdam,
  'amsterdam': _amsterdam,
  '巴黎': _paris,
  'paris': _paris,
  '莫斯科': _moscow,
  'moscow': _moscow,
  '悉尼': _sydney,
  'sydney': _sydney,
  '多伦多': _toronto,
  'toronto': _toronto,
  '迪拜': _dubai,
  'dubai': _dubai,
  '孟买': _mumbai,
  'mumbai': _mumbai,
  '曼谷': _bangkok,
  'bangkok': _bangkok,
  '吉隆坡': _kualaLumpur,
  'kuala lumpur': _kualaLumpur,
};

/// Airport codes, matched only when they stand alone.
const _cityCodes = <String, GeoPlace>{
  'NRT': _tokyo,
  'KIX': _osaka,
  'ICN': _seoul,
  'TPE': _taipei,
  'LAX': _losAngeles,
  'SJC': _sanJose,
  'SFO': _sanJose,
  'SEA': _seattle,
  'DFW': _dallas,
  'ORD': _chicago,
  'JFK': _newYork,
  'NYC': _newYork,
  'MIA': _miami,
  'IAD': _ashburn,
  'LHR': _london,
  'FRA': _frankfurt,
  'AMS': _amsterdam,
  'CDG': _paris,
  'SVO': _moscow,
  'SYD': _sydney,
  'YYZ': _toronto,
  'DXB': _dubai,
  'BOM': _mumbai,
  'BKK': _bangkok,
  'KUL': _kualaLumpur,
};

/// The provinces of China, with the city an address in each is usually
/// registered to. `region` comes back as an English name from most providers,
/// so the keys are the romanisations in use rather than the Chinese names, and
/// the major cities are here because a lookup that resolves to `Shenzhen` has
/// told us the province without naming it.
const _provinceAliases = <String, List<String>>{
  'anhui': ['安徽', '合肥', 'hefei'],
  'beijing': ['北京'],
  'chongqing': ['重庆'],
  'fujian': ['福建', '福州', '厦门', 'fuzhou', 'xiamen'],
  'gansu': ['甘肃', '兰州', 'lanzhou'],
  'guangdong': [
    '广东',
    '广州',
    '深圳',
    '东莞',
    '佛山',
    'guangzhou',
    'shenzhen',
    'dongguan',
    'foshan',
  ],
  'guangxi': ['广西', '南宁', 'nanning'],
  'guizhou': ['贵州', '贵阳', 'guiyang'],
  'hainan': ['海南', '海口', '三亚', 'haikou', 'sanya'],
  'hebei': ['河北', '石家庄', 'shijiazhuang'],
  'heilongjiang': ['黑龙江', '哈尔滨', 'harbin'],
  'henan': ['河南', '郑州', 'zhengzhou'],
  'hubei': ['湖北', '武汉', 'wuhan'],
  'hunan': ['湖南', '长沙', 'changsha'],
  'jiangsu': ['江苏', '南京', '苏州', '无锡', 'nanjing', 'suzhou', 'wuxi'],
  'jiangxi': ['江西', '南昌', 'nanchang'],
  'jilin': ['吉林', '长春', 'changchun'],
  'liaoning': ['辽宁', '沈阳', '大连', 'shenyang', 'dalian'],
  'neimongol': ['内蒙古', '呼和浩特', 'inner mongolia', 'hohhot'],
  'ningxia': ['宁夏', '银川', 'yinchuan'],
  'qinghai': ['青海', '西宁', 'xining'],
  'shaanxi': ['陕西', '西安', 'xian'],
  'shandong': ['山东', '济南', '青岛', 'jinan', 'qingdao'],
  'shanghai': ['上海'],
  'shanxi': ['山西', '太原', 'taiyuan'],
  'sichuan': ['四川', '成都', 'chengdu'],
  'tianjin': ['天津'],
  'xinjiang': ['新疆', '乌鲁木齐', 'urumqi'],
  'xizang': ['西藏', '拉萨', 'tibet', 'lhasa'],
  'yunnan': ['云南', '昆明', 'kunming'],
  'zhejiang': ['浙江', '杭州', '宁波', '温州', 'hangzhou', 'ningbo', 'wenzhou'],
};

/// ISO 3166-2 subdivision codes, for the providers that answer `CN-SN` and
/// leave the name out. `SX` is Shanxi and `SN` is Shaanxi; the pair that looks
/// like a typo is the standard.
const _provinceCodes = <String, String>{
  'BJ': 'beijing',
  'TJ': 'tianjin',
  'HE': 'hebei',
  'SX': 'shanxi',
  'NM': 'neimongol',
  'LN': 'liaoning',
  'JL': 'jilin',
  'HL': 'heilongjiang',
  'SH': 'shanghai',
  'JS': 'jiangsu',
  'ZJ': 'zhejiang',
  'AH': 'anhui',
  'FJ': 'fujian',
  'JX': 'jiangxi',
  'SD': 'shandong',
  'HA': 'henan',
  'HB': 'hubei',
  'HN': 'hunan',
  'GD': 'guangdong',
  'GX': 'guangxi',
  'HI': 'hainan',
  'CQ': 'chongqing',
  'SC': 'sichuan',
  'GZ': 'guizhou',
  'YN': 'yunnan',
  'XZ': 'xizang',
  'SN': 'shaanxi',
  'GS': 'gansu',
  'QH': 'qinghai',
  'NX': 'ningxia',
  'XJ': 'xinjiang',
};

const _provincePlaces = <String, GeoPlace>{
  'anhui': GeoPlace(31.86, 117.28, '安徽', 'Anhui', 'CN'),
  'beijing': GeoPlace(39.90, 116.41, '北京', 'Beijing', 'CN'),
  'chongqing': GeoPlace(29.56, 106.55, '重庆', 'Chongqing', 'CN'),
  'fujian': GeoPlace(26.07, 119.30, '福建', 'Fujian', 'CN'),
  'gansu': GeoPlace(36.06, 103.83, '甘肃', 'Gansu', 'CN'),
  'guangdong': GeoPlace(23.13, 113.26, '广东', 'Guangdong', 'CN'),
  'guangxi': GeoPlace(22.82, 108.32, '广西', 'Guangxi', 'CN'),
  'guizhou': GeoPlace(26.65, 106.63, '贵州', 'Guizhou', 'CN'),
  'hainan': GeoPlace(20.04, 110.32, '海南', 'Hainan', 'CN'),
  'hebei': GeoPlace(38.04, 114.51, '河北', 'Hebei', 'CN'),
  'heilongjiang': GeoPlace(45.80, 126.53, '黑龙江', 'Heilongjiang', 'CN'),
  'henan': GeoPlace(34.75, 113.63, '河南', 'Henan', 'CN'),
  'hubei': GeoPlace(30.59, 114.31, '湖北', 'Hubei', 'CN'),
  'hunan': GeoPlace(28.23, 112.94, '湖南', 'Hunan', 'CN'),
  'jiangsu': GeoPlace(32.06, 118.80, '江苏', 'Jiangsu', 'CN'),
  'jiangxi': GeoPlace(28.68, 115.86, '江西', 'Jiangxi', 'CN'),
  'jilin': GeoPlace(43.82, 125.32, '吉林', 'Jilin', 'CN'),
  'liaoning': GeoPlace(41.81, 123.43, '辽宁', 'Liaoning', 'CN'),
  'neimongol': GeoPlace(40.84, 111.75, '内蒙古', 'Inner Mongolia', 'CN'),
  'ningxia': GeoPlace(38.49, 106.23, '宁夏', 'Ningxia', 'CN'),
  'qinghai': GeoPlace(36.62, 101.78, '青海', 'Qinghai', 'CN'),
  'shaanxi': GeoPlace(34.34, 108.94, '陕西', 'Shaanxi', 'CN'),
  'shandong': GeoPlace(36.65, 117.12, '山东', 'Shandong', 'CN'),
  'shanghai': GeoPlace(31.23, 121.47, '上海', 'Shanghai', 'CN'),
  'shanxi': GeoPlace(37.87, 112.55, '山西', 'Shanxi', 'CN'),
  'sichuan': GeoPlace(30.57, 104.07, '四川', 'Sichuan', 'CN'),
  'tianjin': GeoPlace(39.08, 117.20, '天津', 'Tianjin', 'CN'),
  'xinjiang': GeoPlace(43.83, 87.62, '新疆', 'Xinjiang', 'CN'),
  'xizang': GeoPlace(29.65, 91.14, '西藏', 'Xizang', 'CN'),
  'yunnan': GeoPlace(25.04, 102.72, '云南', 'Yunnan', 'CN'),
  'zhejiang': GeoPlace(30.27, 120.16, '浙江', 'Zhejiang', 'CN'),
};

final _provinceIndex = <String, GeoPlace>{
  for (final entry in _provincePlaces.entries) entry.key: entry.value,
  for (final entry in _provinceAliases.entries)
    if (_provincePlaces[entry.key] case final place?)
      for (final alias in entry.value) _regionKey(alias): place,
};
