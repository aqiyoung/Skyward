/// A verified update package waiting for the reader to install it.
///
/// Upstream FlClash downloads first and only starts the platform installer
/// when the reader taps the ready banner; the same shape is used here so a
/// completed download never installs behind the reader's back.
class PreparedUpdate {
  const PreparedUpdate({
    required this.tag,
    required this.path,
    this.sha256,
    this.version,
    this.installData,
  });

  final String tag;
  final String path;
  final String? sha256;
  final String? version;

  /// Desktop replacement state; Android installs through the App plugin.
  final Object? installData;
}
