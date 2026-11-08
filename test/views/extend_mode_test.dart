import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/views/profiles/extend/extend.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_database_providers.dart';
import '../helpers/test_profiles.dart';

const _profileId = 1;

class _TestProfileRules extends ProfileRules {
  @override
  Stream<List<Rule>> build(int profileId) => Stream.value(const []);

  @override
  void order(int oldIndex, int newIndex) {}
}

class _RecordingSetupAction extends SetupAction {
  @override
  void autoApplyProfile() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppLocalizations.load(const Locale('en'));
  });

  late ProviderContainer container;

  ProviderContainer buildContainer({ExtendType type = ExtendType.standard}) {
    final profile = Profile.normal(
      label: 'p',
    ).copyWith(id: _profileId, extendType: type);
    final built = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(() => TestProfiles([profile])),
        currentProfileIdProvider.overrideWithBuild((_, _) => _profileId),
        profileRulesProvider.overrideWith2((_) => _TestProfileRules()),
        scriptsProvider.overrideWith(() => TestScripts([])),
        clashConfigProvider(_profileId).overrideWithValue(
          const AsyncData(
            ClashConfig(
              proxies: [Proxy(name: 'DIRECT', type: 'Direct')],
            ),
          ),
        ),
        setupActionProvider.overrideWith(_RecordingSetupAction.new),
      ],
    );
    addTearDown(built.dispose);
    globalState.container = built;
    return built;
  }

  Future<void> pumpExtend(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: ExtendView(profileId: _profileId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder checkIn(String label) => find.descendant(
    of: find.widgetWithText(DecorationListItem, label),
    matching: find.byType(SelectionBadge),
  );

  testWidgets('renders both modes as a grouped radio list', (tester) async {
    container = buildContainer();

    await pumpExtend(tester);

    expect(find.text(currentAppLocalizations.extendMode), findsOneWidget);
    expect(find.text(currentAppLocalizations.standard), findsOneWidget);
    expect(find.text(currentAppLocalizations.script), findsOneWidget);
    expect(find.text(currentAppLocalizations.standardModeDesc), findsOneWidget);
    expect(find.text(currentAppLocalizations.scriptModeDesc), findsOneWidget);
    expect(find.byType(DecorationListItem), findsNWidgets(2));
    expect(find.byType(SelectionBadge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('row separators are off on this page', (tester) async {
    container = buildContainer();

    await pumpExtend(tester);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ListRowSeparatorScope && !widget.separated,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('both section headers use the same list caption', (tester) async {
    container = buildContainer(type: ExtendType.script);

    await pumpExtend(tester);

    expect(
      find.widgetWithText(ListHeader, currentAppLocalizations.extendMode),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ListHeader, currentAppLocalizations.extendScript),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('only the selected mode carries the check badge', (tester) async {
    container = buildContainer();

    await pumpExtend(tester);

    expect(checkIn(currentAppLocalizations.standard), findsOneWidget);
    expect(checkIn(currentAppLocalizations.script), findsNothing);
  });

  testWidgets('tapping a mode moves the badge and keeps both descriptions', (
    tester,
  ) async {
    container = buildContainer();

    await pumpExtend(tester);
    await tester.tap(find.text(currentAppLocalizations.script));
    await tester.pumpAndSettle();

    expect(
      container.read(profilesProvider).getProfile(_profileId)?.extendType,
      ExtendType.script,
    );
    expect(checkIn(currentAppLocalizations.standard), findsNothing);
    expect(checkIn(currentAppLocalizations.script), findsOneWidget);
    expect(find.text(currentAppLocalizations.standardModeDesc), findsOneWidget);
    expect(find.text(currentAppLocalizations.scriptModeDesc), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a profile saved in script mode renders that row selected', (
    tester,
  ) async {
    container = buildContainer(type: ExtendType.script);

    await pumpExtend(tester);

    expect(checkIn(currentAppLocalizations.standard), findsNothing);
    expect(checkIn(currentAppLocalizations.script), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
