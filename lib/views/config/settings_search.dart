import 'package:skyward/common/common.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/config/settings_index.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Every row the index knows about, narrowed by what the reader typed.
///
/// A row names itself and the list it lives in, so typing a list's name finds
/// everything on it and typing a row's name points at where it lives.
class SettingsSearchView extends StatefulWidget {
  const SettingsSearchView({super.key});

  @override
  State<SettingsSearchView> createState() => _SettingsSearchViewState();
}

class _SettingsSearchViewState extends State<SettingsSearchView> {
  var _query = SearchQuery('');

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = Theme.of(context).colorScheme;
    final entries = settingsEntries
        .where(
          (entry) => _query.matches(entry.fieldsOf(appLocalizations).toList()),
        )
        .toList();

    return BaseScaffold(
      rowSeparators: false,
      title: appLocalizations.search,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, context.contentTopPadding, 16, 8),
            child: InputDecorationTheme(
              data: searchPillTheme(context),
              child: SearchField(
                onChanged: (value) =>
                    setState(() => _query = SearchQuery(value)),
                // The pill theme cannot dress the field: SearchField pins
                // `filled` in its own decoration, so the pill carries an
                // explicit fill, as the bar's search field does.
                fill: SurfaceLevel.floatingOf(
                  colorScheme,
                ).colorOf(colorScheme),
              ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? EmptyState(
                    glyph: AppGlyphs.search,
                    title: appLocalizations.none,
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ).copyWith(bottom: 16),
                    children: [
                      generateSection(
                        items: [
                          for (final entry in entries)
                            ListItem.open(
                              title: Text(entry.title(appLocalizations)),
                              subtitle: Text(entry.page(appLocalizations)),
                              widget: entry.view(context),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
