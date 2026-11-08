import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Carries the reader's choice through the tree so a row or a dock can ask
/// whether a tap should vibrate without watching the settings provider itself.
class HapticFeedbackScope extends InheritedWidget {
  const HapticFeedbackScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  /// Read from a tap callback, so it must not register a build dependency.
  /// A tree without a scope keeps the feedback on, matching the setting's
  /// default; the app root always installs a scope so the switch governs it.
  static bool enabledOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<HapticFeedbackScope>()?.enabled ??
      true;

  @override
  bool updateShouldNotify(HapticFeedbackScope oldWidget) =>
      enabled != oldWidget.enabled;
}

void hapticTap(BuildContext context) {
  if (HapticFeedbackScope.enabledOf(context)) {
    HapticFeedback.lightImpact();
  }
}

void hapticSelection(BuildContext context) {
  if (HapticFeedbackScope.enabledOf(context)) {
    HapticFeedback.selectionClick();
  }
}
