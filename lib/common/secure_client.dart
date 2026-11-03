import 'dart:io';

/// An [HttpClient] that always verifies TLS certificates and never routes
/// through the user's proxy, regardless of the app-wide [HttpOverrides] and
/// the "skip certificate verification" setting.
///
/// Use it for security-sensitive traffic — WebDAV backup credentials, update
/// checks — so a user who turns off certificate verification for proxy traffic
/// cannot also expose their backup credentials or let a MITM forge an update.
HttpClient createSecureDirectClient() {
  return HttpOverrides.runWithHttpOverrides(
    () => HttpClient(),
    const _ForceSecureOverrides(),
  );
}

/// Restores the platform default for clients created inside it: verified TLS
/// (badCertificateCallback stays null) and direct, non-proxied connections.
///
/// `super.createHttpClient` constructs a standard `HttpClient` directly rather
/// than going through [HttpOverrides.current], so it deliberately does not
/// inherit the app-wide skip-certificate / proxy behaviour.
class _ForceSecureOverrides extends HttpOverrides {
  const _ForceSecureOverrides();

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context);
}
