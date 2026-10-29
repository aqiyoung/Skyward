import 'package:skyward/ui/color.dart';
import 'package:skyward/ui/inherited.dart';
import 'package:skyward/ui/metrics.dart';
import 'package:skyward/ui/scaffold.dart';
import 'package:skyward/ui/typography.dart';
import 'package:skyward/ui/view_scope.dart';
import 'package:material_ui/material_ui.dart';

extension BuildContextExtension on BuildContext {
  CommonScaffoldState? get commonScaffoldState {
    return findAncestorStateOfType<CommonScaffoldState>();
  }

  bool get isMobileView => ViewScope.isMobileOf(this, listen: false);

  void safeNestedPop<T extends Object?>([T? result]) {
    final nestedPop = SheetProvider.of(this)?.nestedNavigatorPop;
    if (nestedPop != null) {
      return nestedPop(result);
    } else {
      return Navigator.of(this).pop(result);
    }
  }

  bool get isInCompactSheet => SheetProvider.of(this)?.type.isCompact ?? false;

  /// Where a page's app bar ends, for a body built outside the scaffold's.
  double get appBarInset =>
      FloatingBarScope.of(this) ??
      (isInCompactSheet
          ? sheetAppBarHeight
          : MediaQuery.paddingOf(this).top + pageToolbarHeight);

  /// A compact sheet's header already trails its own gap.
  double get contentTopPadding =>
      TopInsetScope.of(this) ??
      (isInCompactSheet ? sheetAppBarHeight : appBarInset + 12);

  /// The same, for a page whose first block brings its own air: a section
  /// label, or a card the list already sets apart with a section gap. The
  /// label sits in a box with room for its actions, which trails the bar on
  /// its own, so the gap the body leaves before a card would be spent twice
  /// and the label would read as belonging to nothing.
  double get sectionTopPadding =>
      TopInsetScope.of(this) ??
      (isInCompactSheet ? sheetAppBarHeight : appBarInset);

  /// The label that opens such a page, for the pages that start on one. What
  /// the body gave up above it goes here instead, so the label still stands
  /// clear of the bar rather than of nothing.
  EdgeInsets get sectionHeaderPadding => isInCompactSheet
      ? listHeaderPaddingOf(this)
      : listHeaderPaddingOf(this).copyWith(top: 12.mAp(this));

  /// What the end of a body scrolls clear of: the system bar the body runs
  /// under and what floats over its foot. A docked search only counts below
  /// the scaffold that docks it.
  double get bottomInset =>
      BottomInsetScope.of(this) + MediaQuery.paddingOf(this).bottom;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  bool get disableAnimations => MediaQuery.disableAnimationsOf(this);

  Duration motionDuration(Duration duration) =>
      disableAnimations ? Duration.zero : duration;

  TextStyle get listTitleStyle =>
      AppTextStyle.body.of(this).copyWith(color: colorScheme.onSurface);

  /// Chinese and Japanese set every glyph on a full square, so the same point
  /// size reads heavier than Latin and crowds the title above it; the subtitle
  /// takes a step down there so a row keeps the same weight.
  bool get usesHanDensity {
    final languageCode = Localizations.maybeLocaleOf(this)?.languageCode;
    return languageCode == 'zh' || languageCode == 'ja';
  }

  TextStyle get listSubtitleStyle =>
      (usesHanDensity ? AppTextStyle.footnote : AppTextStyle.subheadline)
          .of(this)
          .copyWith(color: colorScheme.onSurfaceVariant);

  TextStyle get listCaptionStyle => AppTextStyle.footnote
      .of(this)
      .copyWith(color: colorScheme.onSurfaceVariant);

  TextStyle get cardHeaderStyle => AppTextStyle.headline
      .of(this)
      .copyWith(color: colorScheme.onSurfaceVariant.opacity80);
}
