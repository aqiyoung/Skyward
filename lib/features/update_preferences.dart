import 'dart:convert';

import 'package:skyward/common/common.dart';

/// Which release line the update check should look at. Mirrors ReClash's
/// `UpdateChannel`; the default follows the build (preview builds default to
/// `pre`, stable ones to `release`) unless the reader picked one explicitly.
enum UpdateChannel { release, pre }

const _key = 'update-preferences';

UpdateChannel defaultUpdateChannel({required bool isPreBuild}) =>
    isPreBuild ? UpdateChannel.pre : UpdateChannel.release;

UpdateChannel effectiveUpdateChannel({
  required UpdateChannel? configured,
  required bool isPreBuild,
}) =>
    configured ?? defaultUpdateChannel(isPreBuild: isPreBuild);

/// The three extra update preferences that do not need a full config field.
/// `autoCheckUpdate` itself lives in AppSettingProps and is read from there.
class UpdatePreferencesData {
  const UpdatePreferencesData({
    required this.preloadWifi,
    required this.autoInstall,
    this.channel,
  });

  final bool preloadWifi;
  final bool autoInstall;
  final UpdateChannel? channel;

  static const defaults = UpdatePreferencesData(
    preloadWifi: false,
    autoInstall: false,
  );

  Map<String, dynamic> toJson() => {
    'preloadWifi': preloadWifi,
    'autoInstall': autoInstall,
    if (channel != null) 'channel': channel!.name,
  };

  factory UpdatePreferencesData.fromJson(Map<String, dynamic> json) =>
      UpdatePreferencesData(
        preloadWifi: json['preloadWifi'] == true,
        autoInstall: json['autoInstall'] == true,
        channel: json['channel'] == null
            ? null
            : UpdateChannel.values.asNameMap()[json['channel'] as String],
      );
}

Future<UpdatePreferencesData> loadUpdatePreferences() async {
  final raw = await Preferences().getString(_key);
  if (raw == null || raw.isEmpty) return UpdatePreferencesData.defaults;
  try {
    return UpdatePreferencesData.fromJson(
      json.decode(raw) as Map<String, dynamic>,
    );
  } catch (_) {
    return UpdatePreferencesData.defaults;
  }
}

Future<void> storeUpdatePreferences(UpdatePreferencesData data) async {
  await Preferences().setString(_key, json.encode(data.toJson()));
}
