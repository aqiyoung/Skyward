import 'package:skyward/common/common.dart';
import 'package:skyward/providers/database.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/global_search.dart';
import 'package:skyward/views/tools.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/glyph_finders.dart';
import '../helpers/test_app.dart';
import '../helpers/test_database_providers.dart';
import '../helpers/test_profiles.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(TestProfiles.new),
        scriptsProvider.overrideWith(TestScripts.new),
        globalRulesProvider.overrideWith(TestGlobalRules.new),
        iconSetsProvider.overrideWith(TestIconSets.new),
        clashProvidersProvider.overrideWith(TestClashProviders.new),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(child: child),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpTools(WidgetTester tester) =>
      pump(tester, const ToolsView());

  testWidgets('the settings page carries no search of its own', (tester) async {
    await pumpTools(tester);
    final appLocalizations = tester
        .element(find.byType(ToolsView))
        .appLocalizations;

    // Global search moved to its own dock tab, so the settings page no longer
    // has a search button in the bar, nor a search entry among its cards.
    expect(find.byGlyph(AppGlyphs.search), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ToolsView),
        matching: find.text(appLocalizations.search),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('global search is its own page with a search field', (
    tester,
  ) async {
    await pump(tester, const GlobalSearchView());
    final appLocalizations = tester
        .element(find.byType(GlobalSearchView))
        .appLocalizations;

    // The one place to search now: the page names itself and carries the field.
    expect(find.text(appLocalizations.search), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
