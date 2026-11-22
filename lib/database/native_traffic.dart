part of 'database.dart';

@DataClassName('NativeTrafficRow')
class NativeTraffic extends Table {
  TextColumn get bucketId => text()();
  IntColumn get hour => integer()();
  TextColumn get host => text()();
  TextColumn get rule => text()();
  TextColumn get rulePayload => text()();
  TextColumn get node => text()();
  TextColumn get network => text()();
  TextColumn get process => text()();
  IntColumn get upload => integer()();
  IntColumn get download => integer()();
  IntColumn get runtimeMs => integer()();
  IntColumn get connections => integer()();

  @override
  Set<Column> get primaryKey => {bucketId};
}

@DriftAccessor(tables: [NativeTraffic])
class NativeTrafficDao extends DatabaseAccessor<Database>
    with _$NativeTrafficDaoMixin {
  NativeTrafficDao(super.attachedDatabase);

  Future<void> importRows(List<Map<String, Object?>> rows, DateTime cutoff) =>
      attachedDatabase.transaction(() async {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(nativeTraffic, [
            for (final row in rows)
              NativeTrafficCompanion.insert(
                bucketId: row['id'] as String,
                hour: (row['hour'] as num).toInt(),
                host: row['host'] as String,
                rule: row['rule'] as String,
                rulePayload: row['rulePayload'] as String,
                node: row['node'] as String,
                network: row['network'] as String,
                process: row['process'] as String,
                upload: (row['upload'] as num).toInt(),
                download: (row['download'] as num).toInt(),
                runtimeMs: (row['runtime'] as num).toInt(),
                connections: (row['connections'] as num).toInt(),
              ),
          ]);
        });
        await (delete(nativeTraffic)..where(
              (t) => t.hour.isSmallerThanValue(cutoff.millisecondsSinceEpoch),
            ))
            .go();
      });

  Future<List<NativeTrafficRow>> between(DateTime start, DateTime end) =>
      (select(nativeTraffic)..where(
            (t) =>
                t.hour.isBiggerOrEqualValue(start.millisecondsSinceEpoch) &
                t.hour.isSmallerThanValue(end.millisecondsSinceEpoch),
          ))
          .get();
}
