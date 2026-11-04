import 'package:skyward/common/common.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/theme.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Language and theme together: the two personalization rows that used to
/// sit as separate entries in More, now on one page.
class AppearanceView extends ConsumerWidget {
  const AppearanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final locale = ref.watch(
      appSettingProvider.select((state) => state.locale),
    );
    final currentLocale = getLocaleForString(locale);
    return BaseScaffold(
      title: appLocalizations.appearance,
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
              ListItem.open(
                leading: const IconWell(AppGlyphs.paintbrush),
                title: Text(appLocalizations.theme),
                widget: const ThemeView(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
