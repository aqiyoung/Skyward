import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/theme.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Everything about how the app looks, on one page: the language, the theme
/// and the parts of it that used to live a page deeper. Every choice is a row
/// that opens a menu, so nothing here leads to a third level.
class AppearanceView extends ConsumerWidget {
  const AppearanceView({super.key});

  Future<void> _resetColors(BuildContext context, WidgetRef ref) async {
    final res = await dialogs.showMessage(
      message: TextSpan(text: context.appLocalizations.resetTip),
      destructive: true,
      confirmText: context.appLocalizations.reset,
    );
    if (res != true || !context.mounted) {
      return;
    }
    ref
        .read(themeSettingProvider.notifier)
        .update(
          (state) => state.copyWith(
            primaryColors: defaultPrimaryColors,
            primaryColor: defaultPrimaryColor,
            colorStyle: ColorStyle.vivid,
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final theme = ref.watch(themeSettingProvider);
    return BaseScaffold(
      rowSeparators: false,
      title: appLocalizations.preferences,
      body: ListView(
        padding: EdgeInsets.only(
          top: context.cardTopPadding,
          bottom: 24 + context.bottomInset,
        ),
        children: [
          const _Section(
            items: [
              _LiquidGlassItem(),
              _LanguageItem(),
              _ThemeModeItem(),
              _PureBlackItem(),
            ],
          ),
          _Section(
            title: appLocalizations.colorsSection,
            actions: [
              if (!themeColorsAreDefault(theme))
                IconButtonData(
                  glyph: AppGlyphs.reset,
                  tooltip: appLocalizations.reset,
                  onPressed: () => _resetColors(context, ref),
                ),
            ],
            items: const [
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: ThemeColorItem(),
              ),
              ColorStyleItem(),
            ],
          ),
          _Section(
            title: appLocalizations.navigationSection,
            items: const [
              _NavigationBarItem(),
              _DockScaleItem(),
              _DockLabelItem(),
            ],
          ),
          _Section(
            title: appLocalizations.motionSection,
            items: [
              const _TabAnimationItem(),
              const _HapticFeedbackItem(),
              if (system.isMacOS || system.isWindows) const _SidebarBlurItem(),
            ],
          ),
          _Section(
            title: appLocalizations.textSection,
            items: const [FontFamilyRow(), TextScaleCard()],
          ),
        ],
      ),
    );
  }
}

/// One card of rows, set in from the page edge, with an optional title that
/// also carries the section's action.
class _Section extends StatelessWidget {
  const _Section({this.title, this.actions = const [], required this.items});

  final String? title;
  final List<IconButtonData> actions;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: generateSection(
          title: title,
          actions: actions,
          leadingGap: false,
          items: items,
        ),
      ),
    );
  }
}

class _LanguageItem extends ConsumerWidget {
  const _LanguageItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final locale = ref.watch(
      appSettingProvider.select((state) => state.locale),
    );
    final currentLocale = getLocaleForString(locale);
    return ListItem<Locale?>.options(
      title: Text(appLocalizations.language),
      options: [null, ...AppLocalizations.delegate.supportedLocales],
      onChanged: (Locale? locale) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(locale: locale?.toString()));
      },
      textBuilder: (Locale? locale) =>
          locale == null ? appLocalizations.defaultText : locale.label,
      value: currentLocale,
    );
  }
}

class _ThemeModeItem extends ConsumerWidget {
  const _ThemeModeItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final themeMode = ref.watch(
      themeSettingProvider.select((state) => state.themeMode),
    );
    return ListItem<ThemeMode>.options(
      title: Text(appLocalizations.theme),
      options: ThemeMode.values,
      onChanged: (ThemeMode mode) {
        ref
            .read(themeSettingProvider.notifier)
            .update((state) => state.copyWith(themeMode: mode));
      },
      textBuilder: (ThemeMode mode) => switch (mode) {
        ThemeMode.system => appLocalizations.auto,
        ThemeMode.light => appLocalizations.light,
        ThemeMode.dark => appLocalizations.dark,
      },
      value: themeMode,
    );
  }
}

class _PureBlackItem extends ConsumerWidget {
  const _PureBlackItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pureBlack = ref.watch(
      themeSettingProvider.select((state) => state.pureBlack),
    );
    final isDark = ref.watch(currentBrightnessProvider) == Brightness.dark;
    return ListItem.toggle(
      title: Text(context.appLocalizations.pureBlackMode),
      value: pureBlack,
      onChanged: (value) {
        ref
            .read(themeSettingProvider.notifier)
            .update(
              (state) => state.copyWith(
                pureBlack: value,
                // Pure black only paints a dark theme; switching it on from a
                // light one would otherwise change nothing on screen.
                themeMode: value && !isDark ? ThemeMode.dark : state.themeMode,
              ),
            );
      },
    );
  }
}

class _NavigationBarItem extends ConsumerWidget {
  const _NavigationBarItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final style = ref.watch(
      appSettingProvider.select((state) => state.navigationBarStyle),
    );
    return ListItem<NavigationBarStyle>.options(
      title: Text(appLocalizations.navigationBarStyle),
      options: NavigationBarStyle.values,
      value: style,
      textBuilder: (value) => switch (value) {
        NavigationBarStyle.docked => appLocalizations.docked,
        NavigationBarStyle.floating => appLocalizations.floating,
        NavigationBarStyle.capsule => appLocalizations.capsule,
      },
      onChanged: (value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(navigationBarStyle: value));
      },
    );
  }
}

class _DockScaleItem extends ConsumerStatefulWidget {
  const _DockScaleItem();

  static const _minScale = 0.8;
  static const _maxScale = 1.2;
  static const _step = 0.05;

  @override
  ConsumerState<_DockScaleItem> createState() => _DockScaleItemState();
}

class _DockScaleItemState extends ConsumerState<_DockScaleItem> {
  double? _draft;

  void _update(double scale) {
    setState(() => _draft = null);
    ref
        .read(themeSettingProvider.notifier)
        .update((state) => state.copyWith(dockScale: scale));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final dockScale = ref.watch(
      themeSettingProvider.select((state) => state.dockScale),
    );
    final scale = _draft ?? dockScale;
    final percent = '${(scale * 100).round()}%';
    final divisions =
        ((_DockScaleItem._maxScale - _DockScaleItem._minScale) /
                _DockScaleItem._step)
            .round();
    return ListItem(
      title: Text(context.appLocalizations.dockScale),
      padding: const EdgeInsets.only(left: 16, right: 8),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            percent,
            style: AppTextStyle.subheadline
                .of(context, emphasized: true)
                .copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          SizedBox(
            width: 120,
            child: SliderTheme(
              data: SliderDefaultsM3(context),
              child: Slider(
                key: const ValueKey('dockScaleSlider'),
                padding: EdgeInsets.zero,
                min: _DockScaleItem._minScale,
                max: _DockScaleItem._maxScale,
                divisions: divisions,
                value: scale,
                label: percent,
                onChanged: (value) => setState(() => _draft = value),
                onChangeEnd: _update,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockLabelItem extends ConsumerWidget {
  const _DockLabelItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final hideLabelOnScroll = ref.watch(
      themeSettingProvider.select((state) => state.dockHideLabelOnScroll),
    );
    return ListItem.toggle(
      title: Text(appLocalizations.hideLabelOnScroll),
      subtitle: Text(appLocalizations.hideLabelOnScrollDesc),
      value: hideLabelOnScroll,
      onChanged: (value) {
        ref
            .read(themeSettingProvider.notifier)
            .update((state) => state.copyWith(dockHideLabelOnScroll: value));
      },
    );
  }
}

class _TabAnimationItem extends ConsumerWidget {
  const _TabAnimationItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final tabAnimation = ref.watch(
      appSettingProvider.select((state) => state.tabAnimation),
    );
    return ListItem<TabAnimation>.options(
      title: Text(appLocalizations.tabAnimation),
      options: TabAnimation.values,
      value: tabAnimation,
      textBuilder: (animation) => switch (animation) {
        TabAnimation.slide => appLocalizations.slide,
        TabAnimation.fade => appLocalizations.fade,
      },
      onChanged: (value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(tabAnimation: value));
      },
    );
  }
}

class _LiquidGlassItem extends ConsumerWidget {
  const _LiquidGlassItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final mode = ref.watch(
      themeSettingProvider.select((state) => state.liquidGlass),
    );
    return ListItem<LiquidGlassMode>.options(
      title: Text(appLocalizations.liquidGlass),
      options: LiquidGlassMode.values,
      value: mode,
      textBuilder: (mode) => switch (mode) {
        LiquidGlassMode.none => appLocalizations.none,
        LiquidGlassMode.standard => appLocalizations.standard,
        LiquidGlassMode.ultra => appLocalizations.ultra,
      },
      onChanged: (value) {
        ref
            .read(themeSettingProvider.notifier)
            .update((state) => state.copyWith(liquidGlass: value));
      },
    );
  }
}

class _SidebarBlurItem extends ConsumerWidget {
  const _SidebarBlurItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blur = ref.watch(
      themeSettingProvider.select((state) => state.sidebarBlur),
    );
    return ListItem.toggle(
      title: Text(context.appLocalizations.backgroundBlur),
      subtitle: Text(context.appLocalizations.sidebarBlurDesc),
      value: blur,
      onChanged: (value) {
        ref
            .read(themeSettingProvider.notifier)
            .update((state) => state.copyWith(sidebarBlur: value));
      },
    );
  }
}

class _HapticFeedbackItem extends ConsumerWidget {
  const _HapticFeedbackItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      appSettingProvider.select((state) => state.hapticFeedback),
    );
    return ListItem.toggle(
      title: Text(context.appLocalizations.hapticFeedback),
      subtitle: Text(context.appLocalizations.hapticFeedbackDesc),
      value: enabled,
      onChanged: (value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(hapticFeedback: value));
      },
    );
  }
}
