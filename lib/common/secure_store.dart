import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Reverted: PR #41 (flutter_secure_storage broke flutter pub get). Re-added
// here: the WebDAV password now lives in the platform keystore instead of the
// plaintext shared_preferences file.
//
// Pinned to ^11.x: 9.x pulls win32 ^5.0.0, which conflicts with the repo's
// locked win32 ^6.4.0 and fails `flutter pub get` (seen in CI). 11.x resolves
// cleanly against win32 ^6.x. The store only uses the stable read/write/delete
// core API, so cross-major upgrades are safe.

/// Stores the WebDAV password in the OS keystore so it is not readable from the
/// plaintext `shared_preferences` XML/JSON that any app with storage access or a
/// backup extract can read.
///
/// Supported backends: Android Keystore (EncryptedSharedPreferences), iOS/macOS
/// Keychain, Linux Secret Service, Windows Credential Manager.
class DavSecretStore {
  const DavSecretStore._();

  static const _key = 'skyward.dav.password';

  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Persists [password]. Call before saving the config that drops it to a
  /// sentinel in plaintext storage.
  static Future<void> writePassword(String password) =>
      _storage.write(key: _key, value: password);

  /// Reads the persisted password, or null if absent/unavailable.
  static Future<String?> readPassword() => _storage.read(key: _key);

  /// Removes the persisted password (e.g. when WebDAV is disabled).
  static Future<void> deletePassword() => _storage.delete(key: _key);
}
