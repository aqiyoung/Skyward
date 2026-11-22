part of 'database.dart';

/// Per-app traffic in one hour, kept as deltas so each period (today / last 7
/// days / this month / total) can be summed accurately. A separate table from
/// traffic_hourly so the existing domain/rule/node statistics and their
/// schema stay untouched.
@DataClassName('AppTrafficHour')
class AppTrafficHourly extends Table {
  @override
  String get tableName => 'app_traffic_hourly';

  /// Hour start, milliseconds since epoch (UTC).
  IntColumn get hour => integer()();

  /// The connection's process (package name), '' when unknown.
  TextColumn get process => text()();

  /// 0 = download, 1 = upload.
  IntColumn get direction => integer()();

  IntColumn get bytes => integer()();

  @override
  Set<Column> get primaryKey => {hour, process, direction};
}

@DriftAccessor(tables: [AppTrafficHourly])
class AppTrafficHourlyDao extends DatabaseAccessor<Database>
    with _$AppTrafficHourlyDaoMixin {
  AppTrafficHourlyDao(super.attachedDatabase);

  Future<void> add({
    required DateTime hour,
    required String process,
    required int download,
    required int upload,
  }) async {
    await _add(hour, process, 0, download);
    await _add(hour, process, 1, upload);
  }

  Future<void> _add(
    DateTime hour,
    String process,
    int direction,
    int bytes,
  ) async {
    if (bytes <= 0) return;
    final key = hour.millisecondsSinceEpoch;
    Expression<bool> match($AppTrafficHourlyTable t) =>
        t.hour.equals(key) &
        t.process.equals(process) &
        t.direction.equals(direction);
    final existing = await (select(
      appTrafficHourly,
    )..where(match)).getSingleOrNull();
    if (existing == null) {
      await into(appTrafficHourly).insert(
        AppTrafficHourlyCompanion.insert(
          hour: key,
          process: process,
          direction: direction,
          bytes: bytes,
        ),
      );
    } else {
      await (update(appTrafficHourly)..where(match)).write(
        AppTrafficHourlyCompanion(bytes: Value(existing.bytes + bytes)),
      );
    }
  }

  Future<List<AppTrafficHour>> between(DateTime start, DateTime end) =>
      (select(appTrafficHourly)..where(
            (t) =>
                t.hour.isBiggerOrEqualValue(start.millisecondsSinceEpoch) &
                t.hour.isSmallerOrEqualValue(end.millisecondsSinceEpoch),
          ))
          .get();

  Future<int> pruneBefore(DateTime cutoff) =>
      (delete(appTrafficHourly)..where(
            (t) => t.hour.isSmallerThanValue(cutoff.millisecondsSinceEpoch),
          ))
          .go();
}
