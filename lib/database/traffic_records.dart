part of 'database.dart';

/// One persisted connection. mihomo keeps no closed-connection history, so we
/// upsert each live connection's totals and aggregate these rows in an isolate.
@DataClassName('TrafficRecord')
class TrafficRecords extends Table {
  @override
  String get tableName => 'traffic_records';

  TextColumn get connectionId => text()();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime()();

  TextColumn get host => text()();

  TextColumn get rule => text()();

  TextColumn get rulePayload => text()();

  /// The leaf of the connection's chain -- the node it finally left through.
  TextColumn get node => text()();

  TextColumn get network => text()();

  IntColumn get upload => integer()();

  IntColumn get download => integer()();

  @override
  Set<Column> get primaryKey => {connectionId};
}

@DriftAccessor(tables: [TrafficRecords])
class TrafficRecordsDao extends DatabaseAccessor<Database>
    with _$TrafficRecordsDaoMixin {
  TrafficRecordsDao(super.attachedDatabase);

  /// Upserts the latest totals of a connection, keeping its first-seen time.
  Future<void> upsert(TrafficRecord record) async {
    final existing =
        await (select(trafficRecords)
              ..where((t) => t.connectionId.equals(record.connectionId)))
            .getSingleOrNull();
    await into(trafficRecords).insertOnConflictUpdate(
      TrafficRecordsCompanion.insert(
        connectionId: record.connectionId,
        startedAt: existing?.startedAt ?? record.startedAt,
        endedAt: record.endedAt,
        host: record.host,
        rule: record.rule,
        rulePayload: record.rulePayload,
        node: record.node,
        network: record.network,
        upload: record.upload,
        download: record.download,
      ),
    );
  }

  /// Rows whose lifetime overlaps [start]..[end].
  Future<List<TrafficRecord>> between(DateTime start, DateTime end) =>
      (select(trafficRecords)..where(
            (t) =>
                t.startedAt.isSmallerOrEqualValue(end) &
                t.endedAt.isBiggerOrEqualValue(start),
          ))
          .get();

  Future<int> pruneBefore(DateTime cutoff) {
    return (delete(
      trafficRecords,
    )..where((t) => t.endedAt.isSmallerThanValue(cutoff))).go();
  }
}
