import 'dart:convert';

import 'package:skyward/enum/enum.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/models/changelog.dart';

import 'common.dart';

const releaseChangelogJsonMarker = '<!-- flclash:changelog:json';

const _releaseChangelogJsonEndMarker = '-->';

String changelogGroupTitle(
  AppLocalizations appLocalizations,
  ChangelogType type,
) => switch (type) {
  ChangelogType.breaking => appLocalizations.changelogBreaking,
  ChangelogType.feat => appLocalizations.changelogFeatures,
  ChangelogType.fix => appLocalizations.changelogFixes,
  ChangelogType.perf => appLocalizations.changelogPerformance,
  ChangelogType.revert => appLocalizations.changelogReverts,
  ChangelogType.unknown => '',
};

ChangelogVersion? parseReleaseChangelog(
  String? body, {
  String? languageCode,
}) {
  if (body == null) {
    return null;
  }
  final begin = body.indexOf(releaseChangelogJsonMarker);
  if (begin < 0) {
    return null;
  }
  final start = begin + releaseChangelogJsonMarker.length;
  final end = body.indexOf(_releaseChangelogJsonEndMarker, start);
  if (end < 0) {
    return null;
  }
  try {
    final json = jsonDecode(body.substring(start, end)) as Map<String, dynamic>;
    final changelog = Changelog.fromJson(
      languageCode == null ? json : _withLocale(json, languageCode),
    );
    if (!changelog.isSupported) {
      commonPrint.log(
        'changelog schema ${changelog.schemaVersion} is not supported',
        logLevel: LogLevel.warning,
      );
      return null;
    }
    return changelog.versions.firstOrNull;
  } catch (error) {
    commonPrint.log(
      'changelog decode failed ${compactError(error)}',
      logLevel: LogLevel.warning,
    );
    return null;
  }
}

/// Swaps each entry's `text` for its `textZh` translation when the app runs in
/// Chinese, before the model is built.
///
/// Doing it on the raw JSON keeps a single `text` field in the generated model
/// and keeps older builds — which ignore `textZh` entirely — reading the
/// English text instead of failing to parse.
Map<String, dynamic> _withLocale(
  Map<String, dynamic> json,
  String languageCode,
) {
  if (languageCode != 'zh') {
    return json;
  }
  final versions = json['versions'];
  if (versions is! List) {
    return json;
  }
  for (final version in versions) {
    if (version is! Map<String, dynamic>) {
      continue;
    }
    final groups = version['groups'];
    if (groups is! List) {
      continue;
    }
    for (final group in groups) {
      if (group is! Map<String, dynamic>) {
        continue;
      }
      final entries = group['entries'];
      if (entries is! List) {
        continue;
      }
      for (final entry in entries) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final zh = entry['textZh'];
        if (zh is String && zh.isNotEmpty) {
          entry['text'] = zh;
        }
      }
    }
  }
  return json;
}
