import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secrets that must not sit in plaintext (SharedPreferences/SQLite):
/// the external-controller secret and subscription credentials.
///
/// Backed by Android Keystore / iOS Keychain / desktop OS keychains.
/// All methods are best-effort: a platform failure returns null/false
/// rather than throwing, so a broken keychain never bricks the app —
/// callers fall back to their previous behavior.
class SecureStore {
  SecureStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }
}

/// Key for the external-controller secret (see `ensureControllerSecret`).
const secureKeyControllerSecret = 'skyward.controller_secret';
