import 'dart:io';

import 'package:skyward/common/common.dart';

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
    DirectOverrides(),
  );
}

/// An empty [HttpOverrides] whose default [createHttpClient] builds a plain
/// [HttpClient] that verifies certificates and connects directly, without the
/// app-wide proxy / skip-certificate behaviour.
///
/// Wrap a network call in [HttpOverrides.runWithHttpOverrides] with this to
/// isolate it from the global override (used for update checks, which must not
/// inherit the user's "skip certificate verification" toggle).
class DirectOverrides extends HttpOverrides {}

/// A client for security-sensitive requests that may still use the app's own
/// local proxy: unlike the global override it never disables certificate
/// verification, so the user's "skip certificate verification" toggle cannot
/// forge an update. The proxy is where GitHub is reachable from networks that
/// cannot connect directly.
class SecureUpdateOverrides extends HttpOverrides {
  final ProviderReader read;

  SecureUpdateOverrides(this.read);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (url) => SkywardHttpOverrides.findProxyForReader(read, url);
    return client;
  }
}
