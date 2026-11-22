part of 'database.dart';

/// Traffic bytes accumulated in one hour, split by direction and by whether
/// the connection was proxied. Sampled from the per-connection byte deltas so
/// the trend chart reflects when traffic actually happened, not when a
/// connection happened to be closed.
@DataClassName('TrafficHour')
class TrafficHourly extends Table {
  @override
  String get tableName => 'traffic_hourly';

  /// The hour start, as milliseconds since epoch (UTC).
  IntColumn get hour => integer()();

  /// 0 = download, 1 = upload.
  IntColumn get direction => integer()();

  /// 0 = proxied, 1 = direct.
  IntColumn get proxied => integer()();

  IntColumn get bytes => integer()();

  @override
  Set<Column> get primaryKey => {hour, direction, proxied};
}

@DriftAccessor(tables: [TrafficHourly])
class TrafficHourlyDao extends DatabaseAccessor<Database>
    with _$TrafficHourlyDaoMixin {
  TrafficHourlyDao(super.attachedDatabase);

  /// Adds [download]/[upload] bytes to the bucket for [hour].
  Future<void> add({
    required DateTime hour,
    required int download,
    required int upload,
    required bool proxied,
  }) async {
    await _add(hour, 0, download, proxied);
    await _add(hour, 1, upload, proxied);
  }

  Future<void> _add(DateTime hour, int direction, int bytes, bool proxied) async {
    if (bytes <= 0) return;
    final key = hour.millisecondsSinceEpoch;
    final flag = proxied ? 0 : 1;
    final existing = await (select(trafficHourly)
      ..where(
        (t) => t.hour.equals(key) & t.direction.equals(direction) & t.proxied.equals(flag),
      ))
        .getSingleOrNull();
    if (existing == null) {
      await into(trafficHourly).insert(
        TrafficHourlyCompanion.insert(
          hour: key,
          direction: direction,
          proxied: flag,
          bytes: bytes,
        ),
      );
    } else {
      await (update(trafficHourly)
        ..where(
          (t) => t.hour.equals(key) & t.direction.equals(direction) & t.proxied.equals(flag),
        ))
          .write(TrafficHourlyCompanion(bytes: Value(existing.bytes + bytes)));
    }
  }

  Future<List<TrafficHour>> between(DateTime start, DateTime end) =>
      (select(trafficHourly)
        ..where(
          (t) => t.hour.isBiggerOrEqualValue(start.millisecondsSinceEpoch) &
              t.hour.isSmallerOrEqualValue(end.millisecondsSinceEpoch),
        ))
          .get();

  Future<int> pruneBefore(DateTime cutoff) => (delete(trafficHourly)
    ..where((t) => t.hour.isSmallerThanValue(cutoff.millisecondsSinceEpoch)))
      .go();
}
