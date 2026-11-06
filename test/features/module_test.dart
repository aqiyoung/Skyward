import 'package:skyward/features/module/module.dart';
import 'package:skyward/models/models.dart';
import 'package:test/test.dart';

const _surgeModule = '''
#!name=去广告合集
#!system=ios, macos
#!desc=把常见广告域名丢进黑洞
#!author=nobody
#!version=1.2.0
#!homepage=https://example.com/module

[Rule]
DOMAIN-SUFFIX,doubleclick.net,REJECT
DOMAIN,ads.example.com,REJECT-TINYGIF
IP-CIDR,10.0.0.0/8,DIRECT,no-resolve
USER-AGENT,TencentVideo*,REJECT
RULE-SET,https://example.com/ads.list,REJECT
FINAL,PROXY

[URL Rewrite]
^https?://example.com/ads url reject

[Script]
http-response ^https?://example.com script-path=ads.js

[MITM]
hostname = %APPEND% example.com

[General]
skip-proxy = 192.168.0.0/16, 10.0.0.0/8
dns-server = 8.8.8.8
''';

const _qxConf = '''
[filter_local]
host-suffix, doubleclick.net, reject
host, ads.example.com, reject
ip6-cidr, 2001:db8::/32, direct
user-agent, %E4%BC%98%E9%85%B7%, reject
final, proxy

[rewrite_local]
^https?://example.com/ads url reject

[mitm]
hostname = example.com
''';

void main() {
  group('parseModule', () {
    test('reads the surge header', () {
      final module = parseModule(_surgeModule);
      expect(module.format, ModuleFormat.surge);
      expect(module.name, '去广告合集');
      expect(module.description, '把常见广告域名丢进黑洞');
      expect(module.author, 'nobody');
      expect(module.version, '1.2.0');
      expect(module.homepage, 'https://example.com/module');
    });

    test('translates the rules it can express', () {
      final module = parseModule(_surgeModule);
      expect(module.rules.map((rule) => rule.toRawValue('PROXY')), [
        'DOMAIN-SUFFIX,doubleclick.net,REJECT',
        'DOMAIN,ads.example.com,REJECT',
        'IP-CIDR,10.0.0.0/8,DIRECT,no-resolve',
        'MATCH,PROXY',
      ]);
    });

    test('keeps what it cannot express next to the reason', () {
      final module = parseModule(_surgeModule);
      final reasons = module.skipped.map((item) => item.reason).toSet();
      expect(reasons, contains(ModuleSkipReason.unsupportedRule));
      expect(reasons, contains(ModuleSkipReason.httpsDecryption));
      expect(reasons, contains(ModuleSkipReason.scriptRuntime));
      expect(reasons, contains(ModuleSkipReason.unsupportedGeneral));
      expect(
        module.skipped.any((item) => item.content.contains('RULE-SET')),
        isTrue,
      );
    });

    test('maps the general keys it has a field for', () {
      final module = parseModule(_surgeModule);
      expect(module.general, hasLength(1));
      expect(module.general.single.key, 'skip-proxy');
    });

    test('leaves a PROXY target for the reader to name', () {
      final module = parseModule(_qxConf);
      expect(module.format, ModuleFormat.quantumultX);
      expect(module.rules.map((rule) => rule.toRawValue('节点组')), [
        'DOMAIN-SUFFIX,doubleclick.net,REJECT',
        'DOMAIN,ads.example.com,REJECT',
        'IP-CIDR6,2001:db8::/32,DIRECT',
        'MATCH,节点组',
      ]);
      expect(module.rules.first.target, 'REJECT');
      expect(module.rules.last.needsTarget, isTrue);
    });

    test('drops a rule that still has no policy', () {
      final module = parseModule(_qxConf);
      expect(module.resolveRules(null), isNot(contains('MATCH')));
      expect(module.resolveRules('节点组').last, 'MATCH,节点组');
    });

    test('reads arguments from the header', () {
      final module = parseModule('''
#!name=带参数
#!arguments=policy:REJECT,mode:lite
[Rule]
DOMAIN-SUFFIX,a.com,REJECT
''');
      expect(module.arguments, {'policy': 'REJECT', 'mode': 'lite'});
    });

    test('falls back to the given name', () {
      final module = parseModule(
        '[Rule]\nDOMAIN,a.com,REJECT\n',
        fallbackName: 'ads.sgmodule',
      );
      expect(module.name, 'ads.sgmodule');
      expect(module.format, ModuleFormat.unknown);
      expect(module.rules.single.toRawValue(null), 'DOMAIN,a.com,REJECT');
    });
  });

  group('withModuleRules', () {
    test('puts the module in front and keeps one copy of each rule', () {
      const module = Module(
        id: 1,
        label: 'ads',
        content: '[Rule]\nDOMAIN,a.com,REJECT\nFINAL,PROXY\n',
        policy: 'Proxy',
      );
      final existing = [Rule.parse('DOMAIN,b.com,DIRECT')];

      final rules = withModuleRules(modules: [module], rules: existing);

      expect(rules.map((rule) => rule.rawValue), [
        'DOMAIN,a.com,REJECT',
        'MATCH,Proxy',
        'DOMAIN,b.com,DIRECT',
      ]);
    });

    test('leaves a switched-off module out', () {
      const module = Module(
        id: 2,
        label: 'ads',
        content: '[Rule]\nDOMAIN,a.com,REJECT\n',
        enabled: false,
      );
      final existing = [Rule.parse('DOMAIN,b.com,DIRECT')];

      expect(
        withModuleRules(
          modules: [module],
          rules: existing,
        ).map((rule) => rule.rawValue),
        ['DOMAIN,b.com,DIRECT'],
      );
    });

    test('drops a PROXY rule that has no policy yet', () {
      const module = Module(
        id: 3,
        label: 'ads',
        content: '[Rule]\nDOMAIN,a.com,REJECT\nFINAL,PROXY\n',
      );

      expect(
        withModuleRules(
          modules: [module],
          rules: const [],
        ).map((rule) => rule.rawValue),
        ['DOMAIN,a.com,REJECT'],
      );
    });

    test('drops a rule whose policy the config cannot route to', () {
      const module = Module(
        id: 4,
        label: 'ads',
        content: '[Rule]\nDOMAIN,a.com,SomeGroup\nDOMAIN,b.com,REJECT\n',
      );

      final rules = withModuleRules(
        modules: [module],
        rules: const [],
        policies: {'REJECT', 'DIRECT'},
      );

      expect(rules.map((rule) => rule.rawValue), ['DOMAIN,b.com,REJECT']);
    });
  });

  group('modulePoliciesOf', () {
    test('reads the group and proxy names the config carries', () {
      final policies = modulePoliciesOf({
        'proxy-groups': [
          {'name': 'Proxy'},
        ],
        'proxies': [
          {'name': 'HK-01'},
        ],
      });

      expect(policies, containsAll(['Proxy', 'HK-01', 'DIRECT', 'REJECT']));
    });

    test('has nothing to check when the config has no policies', () {
      expect(modulePoliciesOf(const {}), isNull);
    });
  });
}
