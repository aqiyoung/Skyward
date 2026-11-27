import 'package:drift/native.dart';
import 'package:skyward/core/core.dart';
import 'package:skyward/core/interface.dart';
import 'package:skyward/database/database.dart' as db;
import 'package:skyward/enum/enum.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/providers/core.dart';
import 'package:skyward/providers/traffic_statistics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ISO week number and week-numbering year handle the year boundary', () {
    // 2021-01-01 is a Friday in week 53 of 2020.
    expect(isoWeekNumber(DateTime(2021, 1, 1)), 53);
    expect(isoWeekYear(DateTime(2021, 1, 1)), 2020);
    // 2021-01-04 is the Monday starting week 1 of 2021.
    expect(isoWeekNumber(DateTime(2021, 1, 4)), 1);
    expect(isoWeekYear(DateTime(2021, 1, 4)), 2021);
    // 2019-12-30 is the Monday starting week 1 of 2020.
    expect(isoWeekNumber(DateTime(2019, 12, 30)), 1);
    expect(isoWeekYear(DateTime(2019, 12, 30)), 2020);
    // A mid-year date keeps its calendar year.
    expect(isoWeekNumber(DateTime(2026, 11, 23)), 48);
    expect(isoWeekYear(DateTime(2026, 11, 23)), 2026);
  });

  test('a period cannot advance past the period containing today', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final range = container.read(trafficRangeProvider.notifier);

    for (final period in TrafficPeriod.values) {
      range.setPeriod(period);
      final current = container.read(trafficRangeProvider);
      // At the current period there is no future period to advance to.
      expect(
        range.canShift(period, 1),
        isFalse,
        reason: '$period at its current period must not advance',
      );
      range.shift(period, 1);
      expect(
        container.read(trafficRangeProvider),
        current,
        reason: '$period shift must not cross into the future',
      );
      // One period back is still reachable and can return forward.
      expect(range.canShift(period, -1), isTrue);
      range.shift(period, -1);
      expect(range.canShift(period, 1), isTrue);
    }
  });

  test(
    'switching from a month back to a week anchors on today, not the month first',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final range = container.read(trafficRangeProvider.notifier);

      // A month view leaves the state at that month's first day.
      range.setPeriod(TrafficPeriod.month);
      final monthStart = container.read(trafficRangeProvider);
      expect(monthStart.day, 1);

      // Switching to a week must count from today's Monday, not the Monday
      // of the month's first day.
      range.setPeriod(TrafficPeriod.week);
      final weekStart = container.read(trafficRangeProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expectedMonday = today.subtract(
        Duration(days: today.weekday - DateTime.monday),
      );
      expect(weekStart, expectedMonday);
      expect(weekStart.isBefore(monthStart), isFalse);
    },
  );

  test(
    'native snapshots are idempotent and selected dates use matching traffic and duration',
    () async {
      await AppLocalizations.load(const Locale('en'));
      final previousDatabase = db.database;
      final database = db.Database(NativeDatabase.memory());
      db.database = database;
      final core = _HistoryCore();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      Map<String, Object?> row(
        String id,
        DateTime hour,
        int bytes,
        int runtime,
      ) => {
        'id': id,
        'hour': hour.millisecondsSinceEpoch,
        'host': 'example.com',
        'rule': 'Match',
        'rulePayload': '',
        'node': 'DIRECT',
        'network': 'tcp',
        'process': 'com.facebook.katana',
        'upload': 0,
        'download': bytes,
        'runtime': runtime,
        'connections': runtime == 0 ? 1 : 0,
      };
      final rows = [
        row('yesterday', yesterday, 100, 0),
        row('today', today, 50, 0),
        row('runtime/yesterday', yesterday, 0, 3600000),
        row('runtime/today', today, 0, 60000),
      ];
      await database.trafficRecordsDao.upsert(
        db.TrafficRecord(
          connectionId: 'legacy-across-midnight',
          startedAt: yesterday,
          endedAt: today.add(const Duration(minutes: 1)),
          host: 'old.example.com',
          rule: 'Match',
          rulePayload: '',
          node: 'DIRECT',
          network: 'tcp',
          upload: 0,
          download: 9999,
        ),
      );
      for (final (hour, bytes) in [(yesterday, 20), (today, 10)]) {
        await database.trafficHourlyDao.add(
          hour: hour,
          download: bytes,
          upload: 0,
          proxied: false,
        );
        await database.appTrafficHourlyDao.add(
          hour: hour,
          process: '',
          download: bytes,
          upload: 0,
        );
      }
      when(
        () => core.getTrafficHistory(any()),
      ).thenAnswer((_) async => {'rows': rows, 'revision': 4});
      final container = ProviderContainer(
        overrides: [
          nativeTrafficHistoryEnabledProvider.overrideWithValue(true),
          coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
        ],
      );
      final sampler = container.read(trafficSamplerProvider.notifier);
      addTearDown(() async {
        container.dispose();
        db.database = previousDatabase;
        await database.close();
      });
      sampler.capture([
        TrackerInfo(
          id: 'must-not-double-count',
          start: today,
          metadata: const Metadata(),
          chains: const [],
          rule: 'Match',
          rulePayload: '',
          download: 999,
        ),
      ]);
      await sampler.sample();
      await sampler.sample();
      verify(() => core.getTrafficHistory(0)).called(1);
      verify(() => core.getTrafficHistory(4)).called(1);
      final stats = trafficStatisticsProvider(
        TrafficPeriod.day,
        TrafficRankKind.domain,
      );
      container.listen(stats, (_, _) {});
      final current = await container.read(stats.future);
      expect(current.totalDownload, 60);
      expect(current.ranking.fold(0, (sum, row) => sum + row.download), 10049);
      expect(
        current.ranking.firstWhere((row) => row.key == 'example.com').download,
        50,
      );
      expect(
        current.ranking
            .firstWhere((row) => row.key == 'old.example.com')
            .download,
        9999,
      );
      expect(current.runtimeMs, 60000);
      expect(current.connectionCount, 2);
      container.read(trafficRangeProvider.notifier).set(yesterday);
      final previous = await container.read(stats.future);
      expect(previous.totalDownload, 120);
      expect(previous.ranking.fold(0, (sum, row) => sum + row.download), 10099);
      expect(previous.runtimeMs, 3600000);
      final appUsage = await container.read(
        appUsageProvider(AppUsagePeriod.last7Days).future,
      );
      expect(appUsage.totalDownload, 180);
    },
  );

  TrackerInfo request(int download) => TrackerInfo(
    id: 'short-request',
    start: DateTime.now(),
    metadata: const Metadata(process: 'com.facebook.katana', network: 'tcp'),
    chains: const ['DIRECT'],
    rule: 'Match',
    rulePayload: '',
    upload: 10,
    download: download,
  );

  test(
    'first sample counts bytes and refreshes both cached statistics views',
    () async {
      await AppLocalizations.load(const Locale('en'));
      final previousDatabase = db.database;
      final database = db.Database(NativeDatabase.memory());
      db.database = database;
      final container = ProviderContainer();
      final sampler = container.read(trafficSamplerProvider.notifier);
      await sampler.sample();
      addTearDown(() async {
        await sampler.sample();
        container.dispose();
        db.database = previousDatabase;
        await database.close();
      });
      final usage = appUsageProvider(AppUsagePeriod.today);
      final statistics = trafficStatisticsProvider(
        TrafficPeriod.day,
        TrafficRankKind.domain,
      );
      container.listen(usage, (_, _) {});
      container.listen(statistics, (_, _) {});
      expect((await container.read(usage.future)).totalDownload, 0);
      expect((await container.read(statistics.future)).totalDownload, 0);
      sampler.capture([request(200)]);
      final write = sampler.sample();
      expect(identical(write, sampler.sample()), isTrue);
      await write;
      expect((await container.read(usage.future)).totalDownload, 200);
      expect((await container.read(statistics.future)).totalDownload, 200);
      sampler.capture([request(350)]);
      await sampler.sample();
      expect((await container.read(usage.future)).totalDownload, 350);
      expect((await container.read(statistics.future)).totalDownload, 350);
    },
  );

  test('timer keeps accumulating while the app is not visible', () async {
    final previousDatabase = db.database;
    final database = db.Database(NativeDatabase.memory());
    db.database = database;
    final container = ProviderContainer(
      overrides: [
        coreStatusProvider.overrideWithBuild((_, _) => CoreStatus.connected),
        appVisibleProvider.overrideWithBuild((_, _) => false),
        trafficSampleIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 10),
        ),
      ],
    );
    final sampler = container.read(trafficSamplerProvider.notifier);
    await sampler.sample();
    addTearDown(() async {
      container.read(coreStatusProvider.notifier).value =
          CoreStatus.disconnected;
      await sampler.sample();
      container.dispose();
      db.database = previousDatabase;
      await database.close();
    });
    final written = (database.select(database.appTrafficHourly))
        .watch()
        .firstWhere(
          (rows) => rows.any((row) => row.direction == 0 && row.bytes == 300),
        )
        .timeout(const Duration(seconds: 5));
    sampler.capture([request(300)]);
    await written;
    expect(container.read(appVisibleProvider), isFalse);
    await sampler.sample();
  });

  test('app names refresh when installed packages finish loading', () async {
    await AppLocalizations.load(const Locale('en'));
    final previousDatabase = db.database;
    final database = db.Database(NativeDatabase.memory());
    db.database = database;
    final container = ProviderContainer(
      overrides: [trafficSamplerProvider.overrideWith(_IdleSampler.new)],
    );
    addTearDown(() async {
      container.dispose();
      db.database = previousDatabase;
      await database.close();
    });
    final now = DateTime.now();
    await database.appTrafficHourlyDao.add(
      hour: DateTime(now.year, now.month, now.day, now.hour),
      process: 'com.facebook.katana',
      download: 1024,
      upload: 128,
    );
    final provider = appUsageProvider(AppUsagePeriod.today);
    container.listen(provider, (_, _) {});
    final before = await container.read(provider.future);
    expect(before.apps.single.label, 'com.facebook.katana');

    container.read(packagesProvider.notifier).value = const [
      Package(
        packageName: 'com.facebook.katana',
        label: 'Facebook',
        system: false,
        internet: true,
        lastUpdateTime: 0,
      ),
    ];
    final after = await container.read(provider.future);
    expect(after.apps.single.label, 'Facebook');
    expect(after.apps.single.packageName, 'com.facebook.katana');
    expect(after.totalDownload, before.totalDownload);
    expect(after.totalUpload, before.totalUpload);
  });
}

class _IdleSampler extends TrafficSampler {
  @override
  void build() {}
}

class _HistoryCore extends Mock implements CoreHandlerInterface {}
