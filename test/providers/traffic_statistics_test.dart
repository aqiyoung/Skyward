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
