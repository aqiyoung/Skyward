import 'dart:io';

/// An [HttpClient] that always verifies TLS certificates and never routes
/// through the user's proxy, regardless of the app-wide [HttpOverrides] and
/// the "skip certificate verification" setting.
///
/// Use it for security-sensitive traffic — WebDAV backup credentials, update
/// checks — so a user who turns off certificate verification for proxy traffic
/// cannot also expose their backup credentials or let a MITM forge an update.
///
/// [HttpOverrides.runWithHttpOverrides] with a null override makes the
/// [HttpClient] created inside use platform defaults: verified TLS and a
/// direct, non-proxied connection, instead of inheriting the global
/// skip-certificate / proxy logic.
HttpClient createSecureDirectClient() {
  return HttpOverrides.runWithHttpOverrides(
    () => HttpClient(),
    null,
  );
}
