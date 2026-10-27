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

/// Where the release notes carry the build number, as a comment: the prose in
/// the notes says the same thing in words, and words are not something the app
/// should be parsing.
const releaseBuildNumberMarker = 'skyward:build-number:';

/// The build number a release was cut with. Every channel draws from that one
/// counter -- a preview and the release that follows it are neighbours in it --
/// so two numbers read from it are directly comparable. Releases published
/// before the comment existed still state the number in their notes.
int? releaseBuildNumber(Object? body) {
  if (body is! String) return null;
  final marked = RegExp(
    '<!--\\s*$releaseBuildNumberMarker(\\d+)\\s*-->',
  ).firstMatch(body)?.group(1);
  final noted = RegExp(r'构建号：`(\d+)`').firstMatch(body)?.group(1);
  final value = marked ?? noted;
  return value == null ? null : int.tryParse(value);
}

/// Whether [remoteVersion] should be offered to someone running
/// [installedVersion].
///
/// A preview carries its build number in the fourth slot (`1.0.0.2090029702`)
/// where a release carries a revision, and both draw from the same build
/// counter -- so those two numbers are comparable, and the release replaces the
/// preview exactly while it is the larger one. Comparing version names instead
/// offers a preview a release its own build already outranks, and Android
/// refuses a downgrade: the app would promise an update it cannot install.
/// Every other build keeps the version comparison, where that slot counts
/// releases.
bool shouldOfferUpdate({
  required String remoteVersion,
  required int? remoteBuildNumber,
  required String installedVersion,
  int? installedBuildNumber,
}) {
  final parts = installedVersion.split('+')[0].split('.');
  // A release build does not carry its build number in its version -- the
  // fourth slot is its revision -- so a caller that found this build's own
  // release (its notes carry the number) may pass it in. When both sides sit
  // on the shared counter, the counter decides across every channel: a
  // stable, beta or preview build is newer exactly when its number is
  // larger, whatever its version name says.
  installedBuildNumber ??= _isPreviewBuild(parts)
      ? (parts.length > 3 ? int.tryParse(parts[3]) : null)
      : null;
  if (installedBuildNumber != null && remoteBuildNumber != null) {
    return remoteBuildNumber > installedBuildNumber;
  }
  if (_isPreviewBuild(parts)) {
    // A release that does not state its number cannot be placed on the
    // counter, and the version names are not comparable across the two
    // conventions -- the preview's fourth slot always reads larger. That is
    // every answer taken from the release page redirect, which carries the tag
    // and nothing else: the fallback the API drops to once its quota is spent.
    // Saying nothing is the only honest answer there. Guessing by name would
    // promise a preview the update it cannot install. (Both numbers present
    // is already handled above.)
    return false;
  }
  return compareVersions(remoteVersion, installedVersion) > 0;
}

/// The newest release in [releases] that should be offered to someone running
/// [installedVersion], across every channel: stable, beta and preview.
///
/// The releases list is what makes this possible at all. A single latest
/// release can only ever be the latest stable, and a stable build's version
/// does not carry its build number -- so the installed build's number is
/// read from its own release in the same list, whose notes carry it. A
/// preview's number is its version's fourth slot. With both numbers on the
/// shared counter, the largest number wins, whatever channel it belongs to;
/// without numbers, only a non-preview release compared by version counts,
/// because a preview cannot be placed on the counter that way. Drafts are
/// never offered. Returns the original release map, or null.
Map<String, dynamic>? newestOfferableRelease(
  List<dynamic> releases, {
  required String installedVersion,
}) {
  final parsed = <Map<String, dynamic>>[];
  for (final release in releases) {
    if (release is! Map<String, dynamic>) continue;
    if (release['draft'] == true) continue;
    final tag = release['tag_name'];
    if (tag is! String) continue;
    parsed.add(release);
  }
  int? installedBuildNumber;
  final parts = installedVersion.split('+')[0].split('.');
  if (_isPreviewBuild(parts)) {
    installedBuildNumber = parts.length > 3 ? int.tryParse(parts[3]) : null;
  } else {
    for (final release in parsed) {
      final tag = release['tag_name'] as String;
      if (releaseVersionOf(tag, release['name'] as String?) !=
          installedVersion) {
        continue;
      }
      installedBuildNumber = releaseBuildNumber(release['body']);
      if (installedBuildNumber != null) break;
    }
  }
  Map<String, dynamic>? best;
  String? bestVersion;
  int? bestBuildNumber;
  for (final release in parsed) {
    final tag = release['tag_name'] as String;
    final remoteVersion = releaseVersionOf(tag, release['name'] as String?);
    final remoteParts = remoteVersion.split('+')[0].split('.');
    final remoteBuildNumber =
        releaseBuildNumber(release['body']) ??
        (_isPreviewBuild(remoteParts)
            ? (remoteParts.length > 3 ? int.tryParse(remoteParts[3]) : null)
            : null);
    if (!shouldOfferUpdate(
      remoteVersion: remoteVersion,
      remoteBuildNumber: remoteBuildNumber,
      installedVersion: installedVersion,
      installedBuildNumber: installedBuildNumber,
    )) {
      continue;
    }
    if (best == null) {
      best = release;
      bestVersion = remoteVersion;
      bestBuildNumber = remoteBuildNumber;
    } else if (remoteBuildNumber != null &&
        bestBuildNumber != null &&
        remoteBuildNumber != bestBuildNumber) {
      if (remoteBuildNumber > bestBuildNumber) {
        best = release;
        bestVersion = remoteVersion;
        bestBuildNumber = remoteBuildNumber;
      }
    } else if (compareVersions(remoteVersion, bestVersion!) > 0) {
      best = release;
      bestVersion = remoteVersion;
      bestBuildNumber = remoteBuildNumber;
    }
  }
  return best;
}

/// A release tag names its version behind a `v`. Only that first character is
/// the prefix -- anything else in the tag is part of the version it carries.
/// A preview tag names no version at all, only its build number, so its
/// version is rebuilt from the release name when one is given (the name
/// carries the full version), falling back to the current upstream base.
String releaseVersionOf(String tag, [String? name]) {
  if (tag.startsWith('v')) return tag.substring(1);
  final preview = RegExp(r'^preview-(\d+)$').firstMatch(tag);
  if (preview != null) {
    final named = name == null
        ? null
        : RegExp(r'\d+\.\d+\.\d+\.\d+').firstMatch(name)?.group(0);
    return named ?? '1.0.0.${preview.group(1)}';
  }
  return tag;
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
