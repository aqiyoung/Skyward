import 'package:skyward/common/common.dart';
import 'package:skyward/ui/ui.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

class DashboardColors {
  const DashboardColors._({
    required this.page,
    required this.card,
    required this.tone,
    required this.tone2,
    required this.track,
    required this.thumb,
    required this.series2,
    required this.ok,
    required this.okContainer,
    required this.onOkContainer,
    required this.warn,
    required this.warnContainer,
    required this.onWarnContainer,
  });

  factory DashboardColors.of(BuildContext context) {
    final colorScheme = context.colorScheme;
    final card = SurfaceLevel.card.colorOf(colorScheme);
    return DashboardColors._(
      page: SurfaceLevel.page.colorOf(colorScheme),
      card: card,
      tone: SurfaceLevel.block.colorOf(colorScheme),
      tone2: SurfaceLevel.inset.colorOf(colorScheme),
      track: colorScheme.surfaceContainerHighest,
      thumb: colorScheme.outline,
      series2: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.45),
        card,
      ),
      ok: colorScheme.success,
      okContainer: colorScheme.successContainer,
      onOkContainer: colorScheme.onSuccessContainer,
      warn: colorScheme.warning,
      warnContainer: colorScheme.warningContainer,
      onWarnContainer: colorScheme.onWarningContainer,
    );
  }

  final Color page;
  final Color card;

  final Color tone;

  final Color tone2;
  final Color track;
  final Color thumb;
  final Color series2;
  final Color ok;
  final Color okContainer;
  final Color onOkContainer;
  final Color warn;
  final Color warnContainer;
  final Color onWarnContainer;
}

/// Values are the design's CSS shadows. A CSS blur is twice its sigma while
/// Flutter turns a blur radius r into a sigma of 0.577 r + 0.5, so each one
/// goes through [_blur] or it renders a third heavier.
abstract final class DashboardShadows {
  static List<BoxShadow> e1(BuildContext context) =>
      context.colorScheme.brightness == Brightness.dark ? _e1Dark : _e1Light;

  static List<BoxShadow> e2(BuildContext context) =>
      context.colorScheme.brightness == Brightness.dark ? _e2Dark : _e2Light;

  static BoxShadow _shadow(
    int alpha,
    double y,
    double cssBlur, [
    double spread = 0,
  ]) => BoxShadow(
    color: Color.fromARGB(alpha, 0, 0, 0),
    offset: Offset(0, y),
    blurRadius: _blur(cssBlur),
    spreadRadius: spread,
  );

  static double _blur(double cssBlur) =>
      cssBlur <= 1 ? 0 : (cssBlur / 2 - 0.5) / 0.57735;

  static final _e1Light = [_shadow(0x14, 2, 8)];

  static final _e1Dark = [_shadow(0x80, 1, 2), _shadow(0x8C, 10, 28, -6)];

  static final _e2Light = [
    _shadow(0x0F, 1, 3),
    _shadow(0x14, 10, 24),
    _shadow(0x38, 32, 64, -12),
  ];

  static final _e2Dark = [_shadow(0x80, 2, 6), _shadow(0xB3, 32, 64, -12)];
}

/// Off the [AppCorner] scale: a dashboard card is taller than any other
/// surface in the app and keeps a larger corner than a sheet.
abstract final class DashboardCorner {
  static const desktopCard = 32.0;
  static const mobileCard = 34.0;
  static const block = 20.0;
  static const mobileBlock = 22.0;
  static const tab = 16.0;
  static const tableHeader = 12.0;
  static const badge = 14.0;
}

final _groupedFormat = NumberFormat.decimalPattern('en');

/// Grouped digits, as the design shows them, until they outgrow a third of a
/// phone's width.
String dashboardCount(int count) =>
    count < 100000 ? _groupedFormat.format(count) : count.compact;

String dashboardTraffic(num bytes) {
  final show = bytes.traffic;
  return '${show.value} ${show.unit}';
}

/// The two weights the dashboard reads in.
///
/// The system faces Android ships stop at 400, 500 and 700, and a request for
/// 600 resolves to the bold one, so [AppTextStyle.of]'s `emphasized` is bold on
/// a phone. Asking every figure for it set the whole page in bold and left
/// nothing for a card to lead with; values take medium instead.
abstract final class DashboardWeight {
  /// A card's title, and nothing else: the mark a reader finds without reading.
  static const title = FontWeight.w600;

  /// A figure, a rate, a duration, a row's name.
  static const value = FontWeight.w500;

  /// A card's one large figure, the number the card is about. Medium is what a
  /// row's figure takes, and at this size it reads as bold beside the rows
  /// above it; the regular weight keeps the same colour at 34 pt and up.
  static const hero = FontWeight.w400;
}

/// The dashboard's text roles; every figure reads in tabular digits.
abstract final class DashboardText {
  static TextStyle cardTitle(BuildContext context) =>
      AppTextStyle.subheadline
          .of(context)
          .copyWith(fontWeight: DashboardWeight.title);

  static TextStyle label(BuildContext context, {Color? color}) => AppTextStyle
      .caption1
      .of(context)
      .toTabular
      .copyWith(color: color ?? context.colorScheme.onSurfaceVariant);

  static TextStyle figure(
    BuildContext context,
    AppTextStyle style, {
    Color? color,
    FontWeight weight = DashboardWeight.value,
  }) => style
      .of(context)
      .toTabular
      .copyWith(
        color: color,
        fontWeight: weight,
        letterSpacing: -0.02 * style.size,
      );

  /// A value that lives inside a row rather than standing as the card's
  /// figure: a latency, a duration, a count beside its label. Unlike [figure]
  /// it leaves the tracking alone, which belongs to large type only.
  static TextStyle value(
    BuildContext context,
    AppTextStyle style, {
    Color? color,
  }) => style
      .of(context)
      .toTabular
      .copyWith(color: color, fontWeight: DashboardWeight.value);

  static TextStyle unit(
    BuildContext context, [
    AppTextStyle style = AppTextStyle.subheadline,
  ]) => style
      .of(context)
      .copyWith(
        color: context.colorScheme.onSurfaceVariant,
        fontWeight: DashboardWeight.value,
      );

  static TextStyle rowTitle(BuildContext context) =>
      AppTextStyle.subheadline
          .of(context)
          .copyWith(fontWeight: DashboardWeight.value);
}
