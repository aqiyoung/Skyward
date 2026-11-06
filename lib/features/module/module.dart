library;

import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';

/// The five module dialects the clients in this space ship, plus whatever a
/// reader pasted that we could not place.
enum ModuleFormat {
  surge('sgmodule'),
  shadowrocket('module'),
  loon('plugin'),
  stash('stoverride'),
  quantumultX('conf'),
  unknown('txt');

  final String extension;

  const ModuleFormat(this.extension);

  String get label => switch (this) {
    ModuleFormat.surge => 'Surge',
    ModuleFormat.shadowrocket => 'Shadowrocket',
    ModuleFormat.loon => 'Loon',
    ModuleFormat.stash => 'Stash',
    ModuleFormat.quantumultX => 'Quantumult X',
    ModuleFormat.unknown => 'Module',
  };
}

/// Why a line of a module was left out.
///
/// Everything here is a limit of the core, not of the import: mihomo decides
/// what a config can say, so the module page owes the reader a reason rather
/// than a silent hole.
enum ModuleSkipReason {
  /// URL/Header/Body rewrite and MITM need a certificate the core does not
  /// hold. mihomo never decrypts, so none of these can ever run.
  httpsDecryption,

  /// Scripts, panels and the parameters they read need a JavaScript runtime
  /// inside the core. mihomo has none.
  scriptRuntime,

  /// A rule type mihomo has no equivalent for, such as `USER-AGENT`.
  unsupportedRule,

  /// A rule that points at a remote list. Turning it into a rule-provider
  /// needs a download and a name of its own, which a module cannot hand us.
  remoteRuleSet,

  /// A rule whose target is the module's own `PROXY` keyword. mihomo only
  /// accepts a policy that exists in the config, so this waits for the reader
  /// to name one.
  unresolvedPolicy,

  /// A `[General]` key with no honest mihomo counterpart.
  unsupportedGeneral,
}

/// One rule, already translated to mihomo's spelling.
class ModuleRule {
  final RuleAction action;
  final String? payload;
  final String? target;
  final bool noResolve;
  final bool src;

  /// A rule that named `PROXY` and so has no policy until the reader picks
  /// one; [target] stays null meanwhile.
  final bool needsTarget;

  const ModuleRule({
    required this.action,
    this.payload,
    this.target,
    this.noResolve = false,
    this.src = false,
    this.needsTarget = false,
  });

  String toRawValue(String? policy) {
    final resolved = target ?? policy;
    return [
      action.value,
      if (payload?.isNotEmpty == true) payload!,
      if (resolved?.isNotEmpty == true) resolved!,
      if (action.hasParams) ...[if (src) 'src', if (noResolve) 'no-resolve'],
    ].join(',');
  }
}

/// A line the import had to drop, kept with the reason so the detail page can
/// say what the module asked for and why it did not survive.
class ModuleSkip {
  final String section;
  final String content;
  final ModuleSkipReason reason;

  const ModuleSkip({
    required this.section,
    required this.content,
    required this.reason,
  });
}

/// A `[General]` entry that maps onto a config field.
class ModuleGeneral {
  final String key;
  final String value;

  const ModuleGeneral({required this.key, required this.value});
}

class ParsedModule {
  final ModuleFormat format;
  final String name;
  final String? description;
  final String? author;
  final String? version;
  final String? homepage;
  final List<ModuleRule> rules;
  final List<ModuleSkip> skipped;
  final List<ModuleGeneral> general;
  final Map<String, String> arguments;

  const ParsedModule({
    required this.format,
    required this.name,
    this.description,
    this.author,
    this.version,
    this.homepage,
    this.rules = const [],
    this.skipped = const [],
    this.general = const [],
    this.arguments = const {},
  });

  /// The module rules as config lines, with [policy] standing in for the
  /// `PROXY` keyword. Rules still without a policy are dropped, and the
  /// caller is expected to have counted them as skipped.
  List<String> resolveRules(String? policy) {
    return [
      for (final rule in rules)
        if (!rule.needsTarget || (policy?.trim().isNotEmpty ?? false))
          rule.toRawValue(policy),
    ];
  }
}

/// Section names that mean "rules", across the dialects.
const _ruleSections = {
  'rule',
  'rules',
  'filter_local',
  'filter_remote',
  'filter',
};

/// Sections whose whole point is a certificate the core cannot present.
const _rewriteSections = {
  'url rewrite',
  'header rewrite',
  'body rewrite',
  'map local',
  'map remote',
  'rewrite_local',
  'rewrite_remote',
  'mitm',
  'https',
};

/// Sections that need a JavaScript runtime inside the core.
const _scriptSections = {
  'script',
  'scripting',
  'task_local',
  'task_remote',
  'panel',
};

/// Targets that all mean "throw it away" in mihomo.
const _rejectTargets = {
  'REJECT',
  'REJECT-DROP',
  'REJECT-TINYGIF',
  'REJECT-NO-DROP',
  'REJECT-IMG',
  'REJECT-DICT',
  'REJECT-ARRAY',
  'REJECT-200',
};

/// Rule types mihomo knows under the same name.
const _directRuleTypes = {
  'DOMAIN',
  'DOMAIN-SUFFIX',
  'DOMAIN-KEYWORD',
  'DOMAIN-REGEX',
  'DOMAIN-WILDCARD',
  'GEOSITE',
  'IP-CIDR',
  'IP-CIDR6',
  'IP-SUFFIX',
  'IP-ASN',
  'GEOIP',
  'SRC-GEOIP',
  'SRC-IP-ASN',
  'SRC-IP-CIDR',
  'SRC-IP-SUFFIX',
  'DST-PORT',
  'SRC-PORT',
  'IN-PORT',
  'IN-TYPE',
  'IN-USER',
  'IN-NAME',
  'PROCESS-PATH',
  'PROCESS-PATH-REGEX',
  'PROCESS-PATH-WILDCARD',
  'PROCESS-NAME',
  'PROCESS-NAME-REGEX',
  'PROCESS-NAME-WILDCARD',
  'UID',
  'NETWORK',
  'DSCP',
  'AND',
  'OR',
  'NOT',
};

/// QuantumultX still spells the host matchers the old way.
const _typeAliases = {
  'HOST': 'DOMAIN',
  'HOST-SUFFIX': 'DOMAIN-SUFFIX',
  'HOST-KEYWORD': 'DOMAIN-KEYWORD',
  'HOST-WILDCARD': 'DOMAIN-WILDCARD',
  'IP6-CIDR': 'IP-CIDR6',
  'IP-CIDR6': 'IP-CIDR6',
  'GEOIP': 'GEOIP',
};

/// `[General]` keys that land on a field mihomo actually has, keyed by the
/// names the dialects use.
const generalKeyAliases = <String, String>{
  'skip-proxy': 'route-exclude-address',
  'bypass-tun': 'route-exclude-address',
  'bypass': 'route-exclude-address',
  'exclude-simple-hostnames': 'exclude-simple-hostnames',
};

/// Reads any of the five dialects.
///
/// The shapes differ mostly in spelling; the section walk is shared, and the
/// per-dialect parts are the metadata header and the rule vocabulary.
ParsedModule parseModule(String content, {String fallbackName = 'Module'}) {
  final header = <String, String>{};
  final sections = <String, List<String>>{};
  final sectionOrder = <String>[];
  var current = '';
  var inHeader = true;

  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }
    if (line.startsWith('#!') || line.startsWith('//!')) {
      // The metadata block sits above the first section. A `#!` further down
      // is a comment, not a field.
      if (inHeader) {
        final body = line.substring(line.startsWith('#!') ? 2 : 3);
        final index = body.indexOf('=');
        if (index > 0) {
          header[body.substring(0, index).trim().toLowerCase()] = body
              .substring(index + 1)
              .trim();
        }
      }
      continue;
    }
    if (line.startsWith('#') || line.startsWith(';') || line.startsWith('//')) {
      continue;
    }
    if (line.startsWith('[') && line.endsWith(']')) {
      current = line.substring(1, line.length - 1).trim().toLowerCase();
      inHeader = false;
      if (!sections.containsKey(current)) {
        sections[current] = [];
        sectionOrder.add(current);
      }
      continue;
    }
    if (current.isEmpty) {
      // QX puts its metadata in a `[metadata]` block, which the section walk
      // already opened; anything before a section is not ours.
      continue;
    }
    sections[current]!.add(line);
  }

  // Loon keeps the same fields in `[Plugin]` that QX keeps in `[metadata]`.
  final metadata = _readMetadata([
    ...?sections['metadata'],
    ...?sections['plugin'],
  ]);
  final format = _detectFormat(sections, header);
  final rules = <ModuleRule>[];
  final skipped = <ModuleSkip>[];
  final general = <ModuleGeneral>[];
  final arguments = <String, String>{..._readArguments(header)};

  for (final section in sectionOrder) {
    final lines = sections[section]!;
    if (_ruleSections.contains(section)) {
      for (final line in lines) {
        final parsed = _parseRuleLine(line);
        if (parsed == null) {
          skipped.add(
            ModuleSkip(
              section: section,
              content: line,
              reason: ModuleSkipReason.unsupportedRule,
            ),
          );
        } else {
          rules.add(parsed);
        }
      }
      continue;
    }
    if (_rewriteSections.contains(section)) {
      for (final line in lines) {
        skipped.add(
          ModuleSkip(
            section: section,
            content: line,
            reason: ModuleSkipReason.httpsDecryption,
          ),
        );
      }
      continue;
    }
    if (_scriptSections.contains(section)) {
      for (final line in lines) {
        skipped.add(
          ModuleSkip(
            section: section,
            content: line,
            reason: ModuleSkipReason.scriptRuntime,
          ),
        );
      }
      continue;
    }
    if (section == 'plugin') {
      continue;
    }
    if (section == 'host') {
      // A host-to-address map is a DNS answer, and the core has no field for
      // one in a profile.
      for (final line in lines) {
        skipped.add(
          ModuleSkip(
            section: section,
            content: line,
            reason: ModuleSkipReason.unsupportedGeneral,
          ),
        );
      }
      continue;
    }
    if (section == 'general') {
      for (final line in lines) {
        final entry = _splitKeyValue(line);
        if (entry == null) {
          continue;
        }
        if (generalKeyAliases.containsKey(entry.key)) {
          general.add(ModuleGeneral(key: entry.key, value: entry.value));
        } else {
          skipped.add(
            ModuleSkip(
              section: section,
              content: line,
              reason: ModuleSkipReason.unsupportedGeneral,
            ),
          );
        }
      }
      continue;
    }
    if (section == 'argument' || section == 'arguments') {
      for (final line in lines) {
        final entry = _splitKeyValue(line);
        if (entry != null) {
          arguments[entry.key] = entry.value;
        }
      }
    }
  }

  final name =
      _firstNonEmpty([
        header['name'],
        metadata['name'],
        metadata['title'],
        fallbackName,
      ]) ??
      fallbackName;

  return ParsedModule(
    format: format,
    name: name,
    description: _firstNonEmpty([header['desc'], metadata['desc']]),
    author: _firstNonEmpty([header['author'], metadata['author']]),
    version: _firstNonEmpty([header['version'], metadata['version']]),
    homepage: _firstNonEmpty([
      header['homepage'],
      header['home'],
      metadata['homepage'],
      metadata['home'],
    ]),
    rules: rules,
    skipped: skipped,
    general: general,
    arguments: arguments,
  );
}

ModuleFormat _detectFormat(
  Map<String, List<String>> sections,
  Map<String, String> header,
) {
  if (sections.containsKey('filter_local') ||
      sections.containsKey('filter_remote') ||
      sections.containsKey('rewrite_local')) {
    return ModuleFormat.quantumultX;
  }
  if (sections.containsKey('plugin')) {
    return ModuleFormat.loon;
  }
  if (sections.containsKey('stoverride') ||
      sections.containsKey('meta') ||
      header.containsKey('stoverride')) {
    return ModuleFormat.stash;
  }
  // Surge names the systems it targets; Shadowrocket does not, and the two
  // are otherwise the same file.
  if (header.containsKey('system')) {
    return ModuleFormat.surge;
  }
  if (sections.containsKey('rule') && sections.containsKey('url rewrite')) {
    return ModuleFormat.shadowrocket;
  }
  if (sections.containsKey('mitm')) {
    return ModuleFormat.surge;
  }
  return ModuleFormat.unknown;
}

Map<String, String> _readMetadata(List<String> lines) {
  final result = <String, String>{};
  for (final line in lines) {
    final entry = _splitKeyValue(line);
    if (entry != null) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}

/// `#!arguments=a:b,c:d` and its one-per-line variant.
Map<String, String> _readArguments(Map<String, String> header) {
  final raw = header['arguments'] ?? header['argument'];
  if (raw == null || raw.isEmpty) {
    return const {};
  }
  final result = <String, String>{};
  for (final item in raw.split(',')) {
    final entry = _splitKeyValue(item);
    if (entry != null) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}

({String key, String value})? _splitKeyValue(String line) {
  final index = line.indexOf(RegExp(r'[=:]'));
  if (index <= 0) {
    return null;
  }
  final key = line.substring(0, index).trim().toLowerCase();
  final value = line.substring(index + 1).trim();
  if (key.isEmpty) {
    return null;
  }
  return (key: key, value: value);
}

/// One rule line, or null when the core cannot express it.
ModuleRule? _parseRuleLine(String line) {
  final fields = line.split(',').map((item) => item.trim()).toList();
  if (fields.length < 2) {
    return null;
  }
  var type = fields.first.toUpperCase();
  type = _typeAliases[type] ?? type;

  // Surge's terminal rule has no payload.
  if (type == 'FINAL') {
    return _rule(
      RuleAction.MATCH,
      payload: null,
      target: fields.elementAtOrNull(1),
    );
  }
  if (type == 'RULE-SET' || type == 'DOMAIN-SET' || type == 'RULE-SET-URL') {
    return null;
  }
  if (type == 'PROTOCOL') {
    // mihomo says NETWORK and only knows tcp/udp.
    final protocol = fields.elementAtOrNull(1)?.toLowerCase();
    if (protocol != 'tcp' && protocol != 'udp') {
      return null;
    }
    return _rule(
      RuleAction.NETWORK,
      payload: protocol,
      target: fields.elementAtOrNull(2),
    );
  }
  if (!_directRuleTypes.contains(type)) {
    return null;
  }
  final action = RuleAction.values.firstWhere(
    (item) => item.value == type,
    orElse: () => RuleAction.DOMAIN,
  );
  if (action == RuleAction.MATCH) {
    return _rule(action, payload: null, target: fields.elementAtOrNull(1));
  }
  final params = fields.skip(2).map((item) => item.toLowerCase()).toList();
  return _rule(
    action,
    payload: fields.elementAtOrNull(1),
    target: fields.elementAtOrNull(2),
    noResolve: params.contains('no-resolve'),
    src: params.contains('src'),
  );
}

ModuleRule? _rule(
  RuleAction action, {
  String? payload,
  String? target,
  bool noResolve = false,
  bool src = false,
}) {
  final trimmed = target?.trim();
  final upper = trimmed?.toUpperCase();
  if (upper != null && _rejectTargets.contains(upper)) {
    return ModuleRule(
      action: action,
      payload: payload,
      target: 'REJECT',
      noResolve: noResolve,
      src: src,
    );
  }
  if (upper == 'DIRECT') {
    return ModuleRule(
      action: action,
      payload: payload,
      target: 'DIRECT',
      noResolve: noResolve,
      src: src,
    );
  }
  if (upper == 'PROXY' || upper == null || upper.isEmpty) {
    return ModuleRule(
      action: action,
      payload: payload,
      needsTarget: true,
      noResolve: noResolve,
      src: src,
    );
  }
  return ModuleRule(
    action: action,
    payload: payload,
    target: trimmed,
    noResolve: noResolve,
    src: src,
  );
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

/// [rules] with every enabled module's rules in front of them.
///
/// In front because a module is the reader's own addition and a profile's
/// list must not be able to undo it; a rule the list already carries is kept
/// once, so importing a module over a hand-copied rule does not double it.
List<Rule> withModuleRules({
  required Iterable<Module> modules,
  required List<Rule> rules,
  Set<String>? policies,
}) {
  final existing = rules.map((rule) => rule.rawValue).toSet();
  final added = <Rule>[];
  for (final module in modules) {
    if (!module.enabled) {
      continue;
    }
    final parsed = parseModule(module.content, fallbackName: module.label);
    for (final raw in parsed.resolveRules(module.policy)) {
      final rule = Rule.parse(raw);
      // A target the config does not carry makes the core refuse the whole
      // file, so a rule that names one is left out instead of taking the
      // connection down with it.
      final target = rule.ruleTarget;
      if (policies != null && target != null && !policies.contains(target)) {
        continue;
      }
      if (existing.add(raw)) {
        added.add(rule);
      }
    }
  }
  return [...added, ...rules];
}

/// Every policy name a config can route to, so a module rule can be checked
/// against it before it reaches the core.
///
/// Null when the config carries neither groups nor proxies: there is nothing
/// to check against, and a rule should not be dropped on a guess.
Set<String>? modulePoliciesOf(Map<String, dynamic> config) {
  final groups = config['proxy-groups'];
  final proxies = config['proxies'];
  if (groups is! List && proxies is! List) {
    return null;
  }
  final names = <String>{
    'DIRECT',
    'REJECT',
    'REJECT-DROP',
    'PASS',
    'COMPATIBLE',
    'GLOBAL',
  };
  for (final source in [groups, proxies]) {
    if (source is! List) {
      continue;
    }
    for (final item in source) {
      if (item is Map && item['name'] is String) {
        names.add(item['name'] as String);
      }
    }
  }
  return names;
}
