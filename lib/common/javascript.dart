import 'dart:convert';

import 'package:skyward/common/exception.dart';
import 'package:flutter/foundation.dart';
import 'package:rust_api/rust_api.dart';

typedef ScriptEvaluator =
    Future<String> Function({required String script, required String config});

/// Hands the UI language to the script as `globalThis.__skywardLocale`.
///
/// A profile script runs in a bare QuickJS context — no locale, no environment —
/// so a script that wants to match the interface has to be told. It goes in
/// front of the script rather than in the config because a script may read it at
/// the top level, while `main()` only runs afterwards.
String withLocale(String script, String? locale) {
  if (locale == null || locale.isEmpty) return script;
  return 'globalThis.__skywardLocale = ${json.encode(locale)};\n$script';
}

@visibleForTesting
ScriptEvaluator scriptEvaluator = evaluateScript;

Future<Map<String, dynamic>> handleEvaluate(
  String scriptContent,
  Map<String, dynamic> config, {
  String? locale,
}) async {
  if (config['proxy-providers'] == null) {
    config['proxy-providers'] = {};
  }
  final String result;
  try {
    result = await scriptEvaluator(
      script: withLocale(scriptContent, locale),
      config: json.encode(config),
    );
  } catch (e) {
    throw MessageException(e.toString());
  }
  final decoded = json.decode(result);
  if (decoded is! Map<String, dynamic>) {
    throw const MessageException(
      'script did not return a configuration object',
    );
  }
  return decoded;
}
