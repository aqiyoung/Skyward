import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/common.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

/// Pinned to English so every locale reads K and M, never 万 or тыс.
final _compactFormat = NumberFormat.compact(locale: 'en');

/// Also pinned to English: a count reads the same wherever the app is opened,
/// and the grouping stays in thousands a Chinese reader expects as well.
final _groupedFormat = NumberFormat.decimalPattern('en');

extension NumExt on num {
  String get compact => _compactFormat.format(this);

  /// `1,204` — for a count the reader compares at a glance, such as the
  /// number of rules in a list.
  String get grouped => _groupedFormat.format(this);

  String fixed({int decimals = 2}) {
    String formatted = toStringAsFixed(decimals);
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0*$'), '');
      if (formatted.endsWith('.')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
    }
    return formatted;
  }

  TrafficShow get traffic {
    const units = TrafficUnit.values;
    var size = toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return TrafficShow(
      value: size.fixed(decimals: 1),
      unit: units[unitIndex].name,
    );
  }

  TrafficShow get shortTraffic {
    const units = TrafficUnit.values;
    var size = toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return TrafficShow(
      value: size.toStringAsFixed(0),
      unit: ' ${units[unitIndex].name}',
    );
  }
}

extension DoubleExt on double {
  bool moreOrEqual(double value) {
    return this > value || (value - this).abs() < precisionErrorTolerance;
  }
}

extension OffsetExt on Offset {
  double getCrossAxisOffset(Axis direction) {
    return direction == Axis.vertical ? dx : dy;
  }

  double getMainAxisOffset(Axis direction) {
    return direction == Axis.vertical ? dy : dx;
  }
}
