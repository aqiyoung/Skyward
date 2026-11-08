import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:skyward/common/common.dart';
import 'package:skyward/common/window.dart';
import 'package:skyward/bootstrap.dart';
import 'package:skyward/common/system_dns.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/manager/hotkey_manager.dart';
import 'package:skyward/manager/manager.dart';
import 'package:skyward/plugins/app.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/pages.dart';

Widget buildManagerStack({
  required bool isDesktop,
  required Future<void> Function(List<ConnectivityResult> results)
  onConnectivityChanged,
  Stream<ProcessSignal>? terminateSignals,
  required Widget child,
}) {
  final platformApp = isDesktop
      ? WindowHeaderContainer(child: child)
      : VpnManager(child: child);
  final state = AppStateManager(
    child: CoreManager(
      child: ConnectivityManager(
        onConnectivityChanged: onConnectivityChanged,
        child: platformApp,
      ),
    ),
  );
  final platformState = isDesktop
      ? WindowManager(
          terminateSignals: terminateSignals,
          child: TrayManager(
            child: HotKeyManager(child: ProxyManager(child: state)),
          ),
        )
      : AndroidManager(child: TileManager(child: state));
  return AppEnvManager(
    child: LocaleManager(
      child: StatusManager(child: ThemeManager(child: platformState)),
    ),
  );
}

class Application extends ConsumerStatefulWidget {
  const Application({super.key});

  @override
  ConsumerState<Application> createState() => ApplicationState();
}

class ApplicationState extends ConsumerState<Application>
    with WidgetsBindingObserver {
  Timer? _autoUpdateProfilesTaskTimer;
  bool _preHasVpn = false;
  // Windows can only watch SIGINT and SIGHUP.
  final _terminateSignals = system.isDesktop && !system.isWindows
      ? ProcessSignal.sigterm.watch()
      : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemNavigator.setFrameworkHandlesBack(true);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (globalState.navigatorKey.currentContext != null) {
        await bootstrap.attach();
      } else {
        exit(0);
      }
      _autoUpdateProfilesTask();
      _initLink();
      unawaited(_checkSharedText());
      if (!safeModeBuild) {
        unawaited(app?.initShortcuts());
      }
    });
  }

  void _initLink() {
    linkManager.initAppLinksListen(_confirmAddProfile);
  }

  /// A link that arrived from outside the app, whether through a deep link or
  /// the share sheet, is still the reader's to accept.
  Future<void> _confirmAddProfile(String url) async {
    unawaited(window?.show());
    final message = currentAppLocalizations.createProfileFromUrlTip(url);
    final parts = message.split(url);
    final res = await dialogs.showMessage(
      title: currentAppLocalizations.addProfile,
      message: TextSpan(
        children: [
          TextSpan(text: parts.first),
          TextSpan(
            text: url,
            style: TextStyle(
              color: context.colorScheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: context.colorScheme.primary,
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts.last),
        ],
      ),
    );
    if (res != true) return;
    unawaited(
      ref.read(profilesActionProvider.notifier).addProfileFromLink(url),
    );
  }

  /// Android holds a shared link until we ask for it, so the check runs again
  /// whenever the app comes back to the foreground.
  Future<void> _checkSharedText() async {
    if (!system.isAndroid) {
      return;
    }
    final text = await app?.takeSharedText();
    final url = profileUrlFromQrCodes([text]);
    if (url == null) {
      return;
    }
    await _confirmAddProfile(url);
  }

  void _autoUpdateProfilesTask() {
    _autoUpdateProfilesTaskTimer = Timer(const Duration(minutes: 20), () async {
      await ref.read(profilesActionProvider.notifier).autoUpdateProfiles();
      await ref.read(resourcesActionProvider.notifier).autoUpdate();
      if (!mounted) {
        return;
      }
      _autoUpdateProfilesTask();
    });
  }

  Future<void> _handleConnectivityChanged(
    List<ConnectivityResult> results,
  ) async {
    commonPrint.log('connectivityChanged ${results.toString()}');
    unawaited(systemDnsCoordinator?.resync() ?? Future.value());
    unawaited(ref.read(systemActionProvider.notifier).updateLocalIp());
    final hasVpn = results.contains(ConnectivityResult.vpn);
    if (_preHasVpn == hasVpn) {
      ref.read(routeTrackerProvider.notifier).bumpHostEpoch();
      // Android's NetworkObserver tells the Core about a new network itself.
      if (system.isDesktop) {
        debouncer.call(
          FunctionTag.clearDnsCache,
          ref.read(coreActionProvider.notifier).clearDnsCacheOnNetworkChange,
          duration: const Duration(milliseconds: 200),
        );
      }
    }
    _preHasVpn = hasVpn;
  }

  @override
  Widget build(context) {
    return Consumer(
      builder: (_, ref, child) {
        final locale = ref.watch(
          appSettingProvider.select((state) => state.locale),
        );
        final themeProps = ref.watch(themeSettingProvider);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: globalState.navigatorKey,
          onNavigationNotification: (_) => true,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            AppUiLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          builder: (context, child) {
            return ThemeCrossFade(
              child: buildManagerStack(
                isDesktop: system.isDesktop,
                onConnectivityChanged: _handleConnectivityChanged,
                terminateSignals: _terminateSignals,
                child: RemoteFocusAdapter(
                  enabled: system.isTV,
                  floatingKeyboard: app?.floatingKeyboard,
                  child: child!,
                ),
              ),
            );
          },
          scrollBehavior: const BaseScrollBehavior(),
          title: appName,
          locale: getLocaleForString(locale),
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          themeMode: themeProps.themeMode,
          theme: watchAppTheme(ref, Brightness.light),
          darkTheme: watchAppTheme(ref, Brightness.dark),
          themeAnimationStyle: AnimationStyle.noAnimation,
          home: KeyboardInsetHold(child: child!),
        );
      },
      child: const HomePage(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_checkSharedText());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // Nobody is looking at those icons once the app is away, and Android
        // picks this moment to decide whether the process is worth keeping.
        // Dropping the decoded bitmaps costs a re-decode on the way back.
        PaintingBinding.instance.imageCache.clear();
      case AppLifecycleState.inactive:
        // A notification shade or a call: the app is still on screen behind it.
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    linkManager.destroy();
    _autoUpdateProfilesTaskTimer?.cancel();
    super.dispose();
  }
}
