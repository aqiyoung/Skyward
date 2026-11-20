import 'dart:io';

import 'package:drift/native.dart';
import 'package:skyward/database/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Database database;

  setUp(() {
    database = Database(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  TrafficRecord record({
    required String id,
    required DateTime started,
    required DateTime ended,
    String host = 'example.com',
    String rule = 'Match',
    String node = 'Proxy',
    int upload = 100,
    int download = 200,
  }) => TrafficRecord(
    connectionId: id,
    startedAt: started,
    endedAt: ended,
    host: host,
    rule: rule,
    rulePayload: '',
    node: node,
    network: 'tcp',
    upload: upload,
    download: download,
  );

  test('upsert keeps the first-seen start and updates totals', () async {
    final dao = database.trafficRecordsDao;
    final first = DateTime(2026, 11, 19, 8);
    await dao.upsert(record(id: 'a', started: first, ended: first));
    await dao.upsert(
      record(
        id: 'a',
        started: first.add(const Duration(hours: 2)),
        ended: first.add(const Duration(hours: 2)),
        upload: 999,
      ),
    );

    final rows = await dao.between(
      first.subtract(const Duration(days: 1)),
      first.add(const Duration(days: 1)),
    );
    expect(rows, hasLength(1));
    expect(rows.single.startedAt, first);
    expect(rows.single.upload, 999);
  });

  test(
    'hourly buckets accumulate deltas split by direction and proxy',
    () async {
      final dao = database.trafficHourlyDao;
      final hour = DateTime(2026, 11, 19, 8);
      await dao.add(hour: hour, download: 100, upload: 20, proxied: true);
      await dao.add(hour: hour, download: 50, upload: 10, proxied: true);
      await dao.add(hour: hour, download: 30, upload: 5, proxied: false);

      final rows = await dao.between(
        DateTime(2026, 11, 19),
        DateTime(2026, 11, 20),
      );
      final proxiedDown = rows.firstWhere(
        (r) => r.direction == 0 && r.proxied == 0,
      );
      final directDown = rows.firstWhere(
        (r) => r.direction == 0 && r.proxied == 1,
      );
      expect(proxiedDown.bytes, 150);
      expect(directDown.bytes, 30);
      expect(
        rows.firstWhere((r) => r.direction == 1 && r.proxied == 0).bytes,
        30,
      );
    },
  );

  test(
    'between filters by overlapping lifetime and prune removes old rows',
    () async {
      final dao = database.trafficRecordsDao;
      final now = DateTime(2026, 11, 19, 12);
      await dao.upsert(
        record(
          id: 'fresh',
          started: now,
          ended: now.add(const Duration(minutes: 5)),
        ),
      );
      await dao.upsert(
        record(
          id: 'old',
          started: now.subtract(const Duration(days: 10)),
          ended: now.subtract(const Duration(days: 10)),
        ),
      );

      final today = await dao.between(
        DateTime(2026, 11, 19),
        DateTime(2026, 11, 20),
      );
      expect(today.map((r) => r.connectionId), ['fresh']);

      final removed = await dao.pruneBefore(
        now.subtract(const Duration(days: 1)),
      );
      expect(removed, 1);
      expect(
        await dao.between(DateTime(2026, 1), DateTime(2027, 1)),
        hasLength(1),
      );
    },
  );

  test('app hourly buckets accumulate per process and direction', () async {
    final dao = database.appTrafficHourlyDao;
    final hour = DateTime(2026, 11, 19, 8);
    await dao.add(hour: hour, process: 'com.douyin', download: 100, upload: 20);
    await dao.add(hour: hour, process: 'com.douyin', download: 50, upload: 10);
    await dao.add(hour: hour, process: 'com.gallery', download: 30, upload: 5);

    final rows = await dao.between(
      DateTime(2026, 11, 19),
      DateTime(2026, 11, 20),
    );
    expect(rows, hasLength(4));
    final douyinDown = rows.firstWhere(
      (r) => r.process == 'com.douyin' && r.direction == 0,
    );
    expect(douyinDown.bytes, 150);
    expect(
      rows
          .firstWhere((r) => r.process == 'com.gallery' && r.direction == 1)
          .bytes,
      5,
    );
  });

  test(
    'samples survive database reopen without recounting or losing new bytes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'skyward-history-',
      );
      final file = File('${directory.path}/db.sqlite');
      var disk = Database(NativeDatabase(file));
      final hour = DateTime(2026, 11, 19, 8);
      final first = record(id: 'restart', started: hour, ended: hour);
      try {
        await disk.trafficRecordsDao.recordSample(
          record: first,
          process: 'com.facebook.katana',
          hour: hour,
        );
        await disk.close();
        disk = Database(NativeDatabase(file));
        expect(
          await disk.trafficRecordsDao.recordSample(
            record: first,
            process: 'com.facebook.katana',
            hour: hour,
          ),
          isFalse,
        );
        await disk.trafficRecordsDao.recordSample(
          record: first.copyWith(
            upload: 150,
            download: 450,
            endedAt: hour.add(const Duration(hours: 1)),
          ),
          process: 'com.facebook.katana',
          hour: hour.add(const Duration(hours: 1)),
        );
        await disk.trafficRecordsDao.recordSample(
          record: first,
          process: 'com.facebook.katana',
          hour: hour,
        );
        final hours = await disk.trafficHourlyDao.between(
          hour,
          hour.add(const Duration(days: 1)),
        );
        final apps = await disk.appTrafficHourlyDao.between(
          hour,
          hour.add(const Duration(days: 1)),
        );
        expect(
          hours.where((h) => h.direction == 0).fold(0, (n, h) => n + h.bytes),
          450,
        );
        expect(
          hours.where((h) => h.direction == 1).fold(0, (n, h) => n + h.bytes),
          150,
        );
        expect(apps.fold(0, (n, h) => n + h.bytes), 600);
        expect(
          hours
              .where(
                (h) =>
                    h.hour ==
                        hour
                            .add(const Duration(hours: 1))
                            .millisecondsSinceEpoch &&
                    h.direction == 0,
              )
              .single
              .bytes,
          250,
        );
        final rows = await disk.trafficRecordsDao.between(
          hour,
          hour.add(const Duration(days: 1)),
        );
        expect(rows.single.startedAt, hour);
        expect(rows.single.download, 450);
      } finally {
        await disk.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'checkpoint and both hourly tables roll back together on write failure',
    () async {
      final hour = DateTime(2026, 11, 19, 8);
      final sample = record(id: 'retry', started: hour, ended: hour);
      await database.customStatement(
        "CREATE TRIGGER fail_app_history BEFORE INSERT ON app_traffic_hourly BEGIN SELECT RAISE(ABORT, 'test write failure'); END",
      );
      await expectLater(
        database.trafficRecordsDao.recordSample(
          record: sample,
          process: 'com.twitter.android',
          hour: hour,
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        await database.trafficRecordsDao.between(
          hour,
          hour.add(const Duration(days: 1)),
        ),
        isEmpty,
      );
      expect(
        await database.trafficHourlyDao.between(
          hour,
          hour.add(const Duration(days: 1)),
        ),
        isEmpty,
      );
      await database.customStatement('DROP TRIGGER fail_app_history');
      await database.trafficRecordsDao.recordSample(
        record: sample,
        process: 'com.twitter.android',
        hour: hour,
      );
      final apps = await database.appTrafficHourlyDao.between(
        hour,
        hour.add(const Duration(days: 1)),
      );
      expect(apps.fold(0, (n, h) => n + h.bytes), 300);
    },
  );

  test(
    'concurrent increments are atomic and period ends are exclusive',
    () async {
      final hour = DateTime(2026, 11, 19, 8);
      await Future.wait([
        for (var i = 0; i < 20; i++) ...[
          database.trafficHourlyDao.add(
            hour: hour,
            download: 10,
            upload: 1,
            proxied: true,
          ),
          database.appTrafficHourlyDao.add(
            hour: hour,
            process: 'com.twitter.android',
            download: 10,
            upload: 1,
          ),
        ],
      ]);
      final hours = await database.trafficHourlyDao.between(
        hour,
        hour.add(const Duration(hours: 1)),
      );
      final apps = await database.appTrafficHourlyDao.between(
        hour,
        hour.add(const Duration(hours: 1)),
      );
      expect(hours.fold(0, (n, h) => n + h.bytes), 220);
      expect(apps.fold(0, (n, h) => n + h.bytes), 220);
      expect(
        await database.trafficHourlyDao.between(
          hour.subtract(const Duration(hours: 1)),
          hour,
        ),
        isEmpty,
      );
      expect(
        await database.appTrafficHourlyDao.between(
          hour.subtract(const Duration(hours: 1)),
          hour,
        ),
        isEmpty,
      );
    },
  );
}
