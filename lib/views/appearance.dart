import 'package:skyward/common/common.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/theme.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The two things a reader is most likely to change, both picked in place:
/// language and theme open as menus on their own row instead of leading to
/// pages of their own. The rest of the theme settings stay one tap away.
class AppearanceView extends ConsumerWidget {
  const AppearanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final locale = ref.watch(
      appSettingProvider.select((state) => state.locale),
    );
    final currentLocale = getLocaleForString(locale);
    final themeMode = ref.watch(
      themeSettingProvider.select((state) => state.themeMode),
    );
    return BaseScaffold(
      title: appLocalizations.preferences,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.cardTopPadding,
          bottom: 16,
        ),
        children: [
          generateSection(
            leadingGap: false,
            items: [
              ListItem<Locale?>.options(
                leading: const IconWell(AppGlyphs.language),
                title: Text(appLocalizations.language),
                options: [null, ...AppLocalizations.delegate.supportedLocales],
                onChanged: (Locale? locale) {
                  ref
                      .read(appSettingProvider.notifier)
                      .update((state) => state.copyWith(locale: locale?.toString()));
                },
                textBuilder: (Locale? locale) => locale == null
                    ? appLocalizations.defaultText
                    : locale.label,
                value: currentLocale,
              ),
              ListItem<ThemeMode>.options(
                leading: const IconWell(AppGlyphs.paintbrush),
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
                extraItems: [
                  CommonPopupMenuItem(
                    label: appLocalizations.moreThemeSettings,
                    section: const CommonPopupMenuSection(),
                    onPressed: () => showExtend(
                      context,
                      builder: (_) => const ThemeView(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
