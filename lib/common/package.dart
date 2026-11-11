import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import 'common.dart';

/// The channel the running build came from -- `DEV`, `Beta`, empty for a
/// release. This is the whole of the channel's vocabulary in the UI: the home
/// pill wears it, and [PackageInfoExtension.labeledVersion] prints it after the
/// number.
///
/// Both sources are asked, version first: a package from the pipeline names its
/// channel in the version (`1.0.1.07-dev`), while a build made by hand has only
/// the env it was built with. A release has neither.
String buildChannelLabel() =>
    _channelLabel(channelOf(buildVersion) ?? buildChannel);

String _channelLabel(String? channel) {
  switch (channel?.toLowerCase()) {
    case 'dev':
      return 'DEV';
    // `pre` is the name the retired preview channel stamped into versions a
    // phone may still be running; those builds are betas in all but name.
    case 'beta':
    case 'pre':
      return 'Beta';
    default:
      return '';
  }
}

/// The channel a version names as a suffix, lowercased: `pre`, `dev`, `beta`.
/// A release carries none, which is what makes it a release.
String? channelOf(String version) {
  final core = version.split('+').first;
  final dash = core.indexOf('-');
  if (dash < 0) return null;
  final channel = core.substring(dash + 1).trim().toLowerCase();
  return channel.isEmpty ? null : channel;
}

/// Where a channel sits when two builds share a version number. A release is
/// the newest thing on its number, then the beta that was verified for it, then
/// the snapshots cut before either existed.
int _channelRank(String? channel) {
  switch (channel) {
    case null:
      return 3;
    case 'beta':
      return 2;
    case 'pre':
      return 1;
    default:
      return 0;
  }
}

extension PackageInfoExtension on PackageInfo {
  /// The version users see and updates are compared against. The packages only
  /// carry upstream's three components, so the injected [buildVersion] supplies
  /// the revision our release adds on top.
  String get displayVersion => buildVersion.isNotEmpty ? buildVersion : version;

  /// The version as the screens print it: the number, then the channel in the
  /// same word the home pill wears -- `1.0.1.03 DEV`. The stored version says
  /// the channel in lowercase (`-dev`) because it also names files and tags; a
  /// release carries none and reads as its bare number.
  String get labeledVersion {
    final built = displayVersion;
    if (channelOf(built) == null) return built;
    final core = built.split('+').first;
    final number = core.substring(0, core.indexOf('-'));
    final label = buildChannelLabel();
    return label.isEmpty ? number : '$number $label';
  }

  /// Who this build says it is when it fetches a profile. Providers choose the
  /// format they answer in from this string, and only a `clash.meta/<version>`
  /// prefix asks for mihomo YAML -- without it a provider may answer with a
  /// share-link list, which loses whatever the links cannot carry. The core's
  /// own version goes in, so the claim stays true when the pin moves; an empty
  /// [coreVersion] (a host that never asked the core) simply leaves it out.
  String uaFor(String coreVersion) => [
    if (coreVersion.isNotEmpty) 'clash.meta/$coreVersion',
    '$appName/v$version',
    'clash-verge',
    'Platform/${Platform.operatingSystem}',
  ].join(' ');

  String get ua => uaFor('');
}

int compareVersions(String version1, String version2) {
  // The channel is a suffix (`1.0.1.07-pre`), so the numbers come off first:
  // `int.parse('07-pre')` would throw and take the update check with it.
  final List<String> v1 = version1.split('+')[0].split('-')[0].split('.');
  final List<String> v2 = version2.split('+')[0].split('-')[0].split('.');
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
  // A snapshot can carry the day's build number in the fourth slot
  // (`1.0.0.2090029702`) where a release puts its revision (`1.0.0.14`). Read
  // as numbers the snapshot always wins, so it never learns that a release
  // exists -- and the release is where its user belongs. A snapshot is a
  // capture of the line it was cut from, so it is the earlier side.
  final preview1 = _isSnapshot(version1);
  final preview2 = _isSnapshot(version2);
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
  // Same number: the release outranks the beta that was verified for it. Left
  // out, `1.0.1.6-beta` and `1.0.1.6` would be a tie and a beta user would
  // never be offered the release.
  final int rank1 = _channelRank(channelOf(version1));
  final int rank2 = _channelRank(channelOf(version2));
  if (rank1 != rank2) {
    return rank1.compareTo(rank2);
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
/// A build number shares the slot only in older builds, and those start in
/// the billions (a day's prefix times a hundred), so nothing on the release
/// line can reach this.
const _revisionCeiling = 1000000;

/// Whether [version] is a snapshot -- a preview or a dev build -- rather than a
/// beta or a release. The channel says so in the version; builds from before it
/// did are recognised by the day's build number in the fourth slot.
bool _isSnapshot(String version) {
  final channel = channelOf(version);
  if (channel == 'pre' || channel == 'dev') return true;
  return _legacyBuildNumber(version) != null;
}

/// The versionCode an older build wrote into its version's fourth slot. Those
/// builds carried no separate number, so the version is the only place to read
/// it from; anything below the ceiling is a revision, not a build number.
int? _legacyBuildNumber(String version) {
  final parts = version.split('+')[0].split('-')[0].split('.');
  if (parts.length <= 3) return null;
  final revision = int.tryParse(parts[3]);
  return revision != null && revision >= _revisionCeiling ? revision : null;
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

/// Where the release notes carry a published SHA-256 for an APK asset, as a
/// comment: `<!-- skyward:apk-sha256:<asset-name>:<hex> -->`. The publish
/// workflow writes one per APK asset; the downloader refuses to install a
/// file whose hash does not match, and skips verification when the release
/// carries no hash (older releases).
const releaseApkSha256Marker = 'skyward:apk-sha256:';

String? releaseApkSha256(Object? body, String assetName) {
  if (body is! String) return null;
  final match = RegExp(
    '<!--\\s*$releaseApkSha256Marker${RegExp.escape(assetName)}:([0-9a-fA-F]{64})\\s*-->',
  ).firstMatch(body);
  return match?.group(1)?.toLowerCase();
}

/// Whether [remoteVersion] should be offered to someone running
/// [installedVersion].
///
/// Every channel draws its build number from one counter, and Android orders
/// installs by exactly that number -- so where both sides have one, the counter
/// decides and the version name is decoration. Comparing names instead offers a
/// build a release its own number already outranks, and Android refuses a
/// downgrade: the app would promise an update it cannot install.
///
/// Without numbers on both sides the version names are all there is, and they
/// are not comparable across the two conventions -- a snapshot's fourth
/// component counts the day, a release's counts releases. A snapshot is
/// therefore never offered anything by name; silence is the honest answer.
bool shouldOfferUpdate({
  required String remoteVersion,
  required int? remoteBuildNumber,
  required String installedVersion,
  int? installedBuildNumber,
}) {
  // A build knows the versionCode it was made with, injected by the build; a
  // caller that found this build's own release may also read it from the notes.
  // Builds old enough to carry neither wrote it into the version instead.
  installedBuildNumber ??=
      int.tryParse(buildNumber) ?? _legacyBuildNumber(installedVersion);
  if (installedBuildNumber != null && remoteBuildNumber != null) {
    return remoteBuildNumber > installedBuildNumber;
  }
  if (_isSnapshot(installedVersion)) {
    // A release that does not state its number cannot be placed on the
    // counter, and the version names are not comparable across the two
    // conventions -- the snapshot's fourth component always reads larger. That
    // is every answer taken from the release page redirect, which carries the
    // tag and nothing else: the fallback the API drops to once its quota is
    // spent. (Both numbers present is already handled above.)
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
  // The build knows the versionCode it was made with, so it does not have to be
  // found in a release first. The search below stays for builds old enough to
  // carry neither: theirs is only in their own release's notes.
  int? installedBuildNumber =
      int.tryParse(buildNumber) ?? _legacyBuildNumber(installedVersion);
  if (installedBuildNumber == null) {
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
    final remoteBuildNumber = releaseBuildNumber(release['body']);
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
