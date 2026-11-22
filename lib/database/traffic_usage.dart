// Traffic usage forecast for the dashboard traffic card — a port of
// ReClash's features/traffic_forecast/forecast.dart onto Skyward's
// `TrafficStatistics.trend` (per-hour usage), so the card can warn when the
// plan will run out.

import 'dart:math' as math;

import 'package:skyward/models/traffic_statistics.dart';

/// The pace reads the trailing window of whole days.
const usageWindowDays = 7;

/// One day of spending. [mark] is the cumulative use at the last sample;
/// Skyward has no row-per-day store, so adapters set it to the day's total.
class UsageDay {
  const UsageDay(this.day, this.bytes, this.mark);

  final int day;
  final int bytes;
  final int mark;

  @override
  bool operator ==(Object other) =>
      other is UsageDay &&
      other.day == day &&
      other.bytes == bytes &&
      other.mark == mark;

  @override
  int get hashCode => Object.hash(day, bytes, mark);
}

int usageDayOf(DateTime time) =>
    DateTime.utc(time.year, time.month, time.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

DateTime usageDateOf(int day) => DateTime(1970, 1, 1 + day);

/// Convert Skyward's hourly [trend] into [UsageDay]s: one entry per UTC day,
/// bytes = upload + download summed over the day's hours.
List<UsageDay> usageDaysFromTrend(List<TrafficHourPoint> trend) {
  final byDay = <int, int>{};
  for (final point in trend) {
    final day = usageDayOf(point.hour);
    byDay[day] = (byDay[day] ?? 0) + point.upload + point.download;
  }
  return [
    for (final entry in byDay.entries)
      UsageDay(entry.key, entry.value, entry.value),
  ];
}

/// Bytes a day, over the whole days before [today] that follow the first
/// sample: the sampling day is partial and so is today. Null until there is
/// one.
int? usagePace(Iterable<UsageDay> days, int today) {
  if (days.isEmpty) return null;
  final first = days.map((day) => day.day).reduce(math.min);
  final start = math.max(first + 1, today - usageWindowDays);
  final count = today - start;
  if (count < 1) return null;
  final total = days
      .where((day) => day.day >= start && day.day < today)
      .fold<int>(0, (sum, day) => sum + day.bytes);
  return total ~/ count;
}

enum TrafficForecastKind {
  /// Too little history to say anything.
  gathering,

  /// The quota is not going to run out in a year, or nothing is spent.
  plenty,

  /// Runs out on [TrafficForecast.runsOut] with no end of the plan to compare.
  until,

  /// Runs out [TrafficForecast.daysEarly] days before the plan ends.
  early,

  /// Runs out before the plan ends, but not early enough to warn on.
  lasts,

  /// The quota is not going to run out in a year, or nothing is spent.
  depleted,
}

class TrafficForecast {
  const TrafficForecast(
    this.kind, {
    this.perDay,
    this.runsOut,
    this.daysEarly = 0,
  });

  final TrafficForecastKind kind;
  final int? perDay;
  final DateTime? runsOut;
  final int daysEarly;
}

/// Where the traffic left of [total] ends at the pace of the recent
/// [usageWindowDays] whole days.
TrafficForecast forecastTraffic({
  required List<UsageDay> days,
  required int used,
  required int total,
  required DateTime now,
  DateTime? expiry,
}) {
  final perDay = usagePace(days, usageDayOf(now));
  // total == 0 means the subscription did not report a quota, not that the
  // quota is used up. Treating it as exhausted shows "已耗尽" for every user
  // whose provider omits the traffic total.
  if (total <= 0) {
    return perDay == null
        ? const TrafficForecast(TrafficForecastKind.gathering)
        : TrafficForecast(TrafficForecastKind.plenty, perDay: perDay);
  }
  final left = total - used;
  if (left <= 0) {
    return TrafficForecast(TrafficForecastKind.depleted, perDay: perDay);
  }
  if (perDay == null) {
    return const TrafficForecast(TrafficForecastKind.gathering);
  }
  if (perDay == 0) {
    return const TrafficForecast(TrafficForecastKind.plenty, perDay: 0);
  }
  final daysLeft = left / perDay;
  final runsOut = now.add(
    Duration(
      milliseconds: (math.min(daysLeft, 36500) * Duration.millisecondsPerDay)
          .round(),
    ),
  );
  if (expiry == null) {
    return TrafficForecast(
      daysLeft > 365 ? TrafficForecastKind.plenty : TrafficForecastKind.until,
      perDay: perDay,
      runsOut: runsOut,
    );
  }
  final early = expiry.difference(runsOut).inDays;
  return TrafficForecast(
    early >= 1 ? TrafficForecastKind.early : TrafficForecastKind.lasts,
    perDay: perDay,
    runsOut: runsOut,
    daysEarly: math.max(early, 0),
  );
}
