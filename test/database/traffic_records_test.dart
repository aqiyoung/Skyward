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
}
