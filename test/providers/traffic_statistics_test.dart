import 'package:drift/native.dart';
import 'package:skyward/database/database.dart' as db;
import 'package:skyward/enum/enum.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/providers/traffic_statistics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
