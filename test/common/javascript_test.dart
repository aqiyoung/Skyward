import 'dart:convert';

import 'package:skyward/common/exception.dart';
import 'package:skyward/common/javascript.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<({String script, String config})> calls;
  final engine = scriptEvaluator;

  setUp(() {
    calls = [];
  });

  tearDown(() {
    scriptEvaluator = engine;
  });

  void answerWith(String result) {
    scriptEvaluator = ({required String script, required String config}) async {
      calls.add((script: script, config: config));
      return result;
    };
  }

  test(
    'passes the profile as JSON and returns what the script produced',
    () async {
      answerWith(json.encode({'mode': 'global'}));

      final result = await handleEvaluate('main', {'mode': 'rule'});

      expect(result, {'mode': 'global'});
      expect(json.decode(calls.single.config)['mode'], 'rule');
      expect(calls.single.script, 'main');
    },
  );

  test('gives the script an empty proxy-providers map to work with', () async {
    answerWith(json.encode({'mode': 'rule'}));

    await handleEvaluate('main', {'mode': 'rule'});

    expect(json.decode(calls.single.config)['proxy-providers'], isEmpty);
  });

  test('reports what the engine threw', () async {
    scriptEvaluator = ({required String script, required String config}) async {
      throw Exception('ReferenceError: proxies is not defined');
    };

    await expectLater(
      handleEvaluate('main', {}),
      throwsA(
        isA<MessageException>().having(
          (error) => error.message,
          'message',
          contains('ReferenceError'),
        ),
      ),
    );
  });

  test('rejects a result that is not a configuration object', () async {
    answerWith(json.encode([1, 2, 3]));

    await expectLater(
      handleEvaluate('main', {}),
      throwsA(isA<MessageException>()),
    );
  });

  test('puts the interface language in front of the script', () {
    final script = withLocale('function main(config) {}', 'en_US');

    expect(script, startsWith('globalThis.__skywardLocale = "en_US";\n'));
    // The profile still comes last, so a script may read the locale itself.
    expect(script, endsWith('function main(config) {}'));
  });

  test('leaves the script alone when no language is set', () {
    expect(withLocale('main', null), 'main');
    expect(withLocale('main', ''), 'main');
  });
}
