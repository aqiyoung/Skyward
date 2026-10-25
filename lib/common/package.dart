import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import 'common.dart';

extension PackageInfoExtension on PackageInfo {
  /// The version users see and updates are compared against. The packages only
  /// carry upstream's three components, so the injected [buildVersion] supplies
  /// the revision our release adds on top.
  String get displayVersion => buildVersion.isNotEmpty ? buildVersion : version;

  String get ua => [
    '$appName/v$version',
    'clash-verge',
    'Platform/${Platform.operatingSystem}',
  ].join(' ');
}

int compareVersions(String version1, String version2) {
  final List<String> v1 = version1.split('+')[0].split('.');
  final List<String> v2 = version2.split('+')[0].split('.');
  final int major1 = int.parse(v1[0]);
  final int major2 = int.parse(v2[0]);
  if (major1 != major2) {
    return major1.compareTo(major2);
  }
  final int minor1 = v1.length > 1 ? int.parse(v1[1]) : 0;
  final int minor2 = v2.length > 1 ? int.parse(v2[1]) : 0;
  if (minor1 != minor2) {
    return minor1.compareTo(minor2);
  }
  final int patch1 = v1.length > 2 ? int.parse(v1[2]) : 0;
  final int patch2 = v2.length > 2 ? int.parse(v2[2]) : 0;
  if (patch1 != patch2) {
    return patch1.compareTo(patch2);
  }
  // A preview build stamps the day's build number into the fourth slot
  // (`1.0.0.2090029702`) where a release puts its revision (`1.0.0.14`). Read
  // as numbers the preview always wins, so a preview build never learns that a
  // release exists -- and the release is where its user belongs. A preview is
  // a snapshot of the line it was cut from, so it is the earlier side.
  final preview1 = _isPreviewBuild(v1);
  final preview2 = _isPreviewBuild(v2);
  if (preview1 != preview2) {
    return preview1 ? -1 : 1;
  }
  // This fork's releases carry a fourth component -- the revision we iterate
  // on top of upstream's version -- and their tags are exactly that version.
  // Upstream builds have no fourth component, and neither do this fork's
  // desktop builds (only Android's versionName can hold one), so a missing one
  // is not "zero": the two conventions are comparable only once both sides
  // carry one. Reading it as zero instead would make every desktop build see
  // its own release as newer than itself, forever.
  final int? revision1 = v1.length > 3 ? int.tryParse(v1[3]) : null;
  final int? revision2 = v2.length > 3 ? int.tryParse(v2[3]) : null;
  if (revision1 != null && revision2 != null && revision1 != revision2) {
    return revision1.compareTo(revision2);
  }
  final int build1 = version1.contains('+')
      ? int.parse(version1.split('+')[1])
      : 0;
  final int build2 = version2.contains('+')
      ? int.parse(version2.split('+')[1])
      : 0;
  return build1.compareTo(build2);
}

/// Every revision this fork will ever cut is a small count -- one per release.
/// A build number shares the slot only in preview builds, and those start in
/// the billions (a day's prefix times a hundred), so nothing on the release
/// line can reach this.
const _revisionCeiling = 1000000;

bool _isPreviewBuild(List<String> parts) {
  if (parts.length <= 3) return false;
  final revision = int.tryParse(parts[3]);
  return revision != null && revision >= _revisionCeiling;
}

const releaseNotesBeginMarker = '<!-- flclash:changelog:begin -->';
const releaseNotesEndMarker = '<!-- flclash:changelog:end -->';

List<String> parseReleaseBody(String? body) {
  if (body == null) return [];
  final regex = RegExp(r'^[ \t]*-[ \t]+(.*)$', multiLine: true);
  return regex
      .allMatches(scopeReleaseNotes(body))
      .map((match) => match.group(1)?.trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

String scopeReleaseNotes(String body) {
  final begin = body.indexOf(releaseNotesBeginMarker);
  if (begin < 0) return body;
  final start = begin + releaseNotesBeginMarker.length;
  final end = body.indexOf(releaseNotesEndMarker, start);
  return end < 0 ? body.substring(start) : body.substring(start, end);
}
