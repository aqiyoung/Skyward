import 'package:skyward/common/common.dart';
import 'package:skyward/providers/database.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/config/settings_search.dart';
import 'package:skyward/views/tools.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/glyph_finders.dart';
import '../helpers/test_app.dart';
import '../helpers/test_database_providers.dart';
import '../helpers/test_profiles.dart';

void main() {
  Future<void> pumpTools(WidgetTester tester) async {
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
        child: const TestApp(child: ToolsView()),
      ),
    );
    await tester.pump();
  }

  testWidgets('search sits in the app bar, not in the settings card', (
    tester,
  ) async {
    await pumpTools(tester);
    final appLocalizations = tester
        .element(find.byType(ToolsView))
        .appLocalizations;

    expect(find.byGlyph(AppGlyphs.search), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ToolsView),
        matching: find.text(appLocalizations.search),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the app bar search opens the settings search page', (
    tester,
  ) async {
    await pumpTools(tester);

    await tester.tap(find.byGlyph(AppGlyphs.search));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsSearchView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
