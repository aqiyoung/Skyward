import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/common/service_probe.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/features/features.dart';
import 'package:skyward/features/ip_quality/labels.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/ip_quality.dart';
import 'package:skyward/providers/outbound_ip.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/providers/routed_probe.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:skyward/views/dashboard/probe_start_hold.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';
import 'traffic.dart';

const _builtinOutbounds = {'DIRECT', 'REJECT', 'REJECT-DROP', 'PASS'};

bool isBuiltinOutbound(String name) => _builtinOutbounds.contains(name);

const ipMask = '*****';

/// The address the proxied traffic leaves by, next to the start button.
class CurrentOutboundCard extends ConsumerStatefulWidget {
  const CurrentOutboundCard({super.key});

  @override
  ConsumerState<CurrentOutboundCard> createState() =>
      _CurrentOutboundCardState();
}

class _CurrentOutboundCardState extends ConsumerState<CurrentOutboundCard>
    with ProbeStartHold<CurrentOutboundCard> {
  late final OutboundIpProbe _probe;

  /// The last address shown, kept across a recheck so a long background's
  /// revalidation dims the row instead of blanking it.
  IpInfo? _lastIp;

  @override
  void initState() {
    super.initState();
    _probe = ref.read(outboundIpProbeProvider.notifier)..watch(routedOutbound);
  }

  @override
  void dispose() {
    _probe.unwatch(routedOutbound);
    super.dispose();
  }

  void _refresh(String? ip) {
    _probe.refresh(const [routedOutbound]);
    if (ip != null && ref.read(ipQualityProvider(ip)).hasError) {
      ref.invalidate(ipQualityProvider(ip));
    }
  }

  @override
  Widget build(BuildContext context) {
    final density = DashboardDensityScope.of(context);
    final hasProfile = ref.watch(
      profilesProvider.select((state) => state.isNotEmpty),
    );
    final isStart = ref.watch(isStartProvider);
    final suspended = isStart && ref.watch(suspendProvider);
    final entry = ref.watch(
      outboundIpProbeProvider.select((state) => state.entryOf(routedOutbound)),
    );
    final ipInfo = entry.value;
    if (ipInfo != null) {
      _lastIp = ipInfo;
    }
    // A recheck (the route moved under a long background, say) drops the
    // answer while it asks again; hold the last address on screen, dimmed,
    // and swap it only once the new answer lands.
    final rechecking = entry.phase == ProbePhase.probing && ipInfo == null;
    final shown = ipInfo ?? (rechecking ? _lastIp : null);
    final stale = rechecking && shown != null;
    final phase = shownPhase(entry);
    final failed = phase == ProbePhase.failed && shown == null;
    final qualityState = shown == null
        ? null
        : ref.watch(ipQualityProvider(shown.ip));
    final quality = qualityState?.value;
    final qualityLoading =
        qualityState != null && quality == null && qualityState.isLoading;
    final loading = shown == null ? !failed : qualityLoading;
    final metrics = _OutboundMetrics.of(density);
    final appLocalizations = context.appLocalizations;
    final (chipLabel, chipTone) = suspended
        ? (appLocalizations.suspended, DashboardChipTone.warn)
        : isStart
        ? (appLocalizations.running, DashboardChipTone.ok)
        : (appLocalizations.notRunning, DashboardChipTone.idle);
    final header = DashboardCardHeader(
      glyph: AppGlyphs.status,
      title: appLocalizations.status,
      leading: [
        DashboardChip(label: chipLabel, tone: chipTone, dot: isStart),
      ],
    );
    // The profiles card answers which profile is active, so the status
    // card does not repeat its name here.
    final exitRow = _ExitRow(
      info: shown,
      stale: stale,
      failed: failed,
      loading: loading,
      checking: phase == ProbePhase.probing || qualityLoading,
      onRefresh: () => _refresh(shown?.ip),
      quality: quality,
      active: isStart,
      metrics: metrics,
      large: !density.isDesktop,
    );
    final cells = _Cells(
      quality: quality,
      loading: loading,
      active: isStart && !suspended,
      gap: metrics.cellGap,
    );
    final startToggle = SizedBox(
      width: metrics.buttonSlot,
      child: _StartToggle(
        size: metrics.buttonSize,
        enabled: hasProfile,
        running: isStart,
        suspended: suspended,
      ),
    );
    // The phone has one status card, so the rates sit in its header, level
    // with the status, and the floor belongs to the charts alone. A desktop
    // card is a fixed tile that keeps the speed cards beside it.
    final content = density.isDesktop
        ? Row(
            spacing: metrics.gap,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    SizedBox(height: metrics.ipTop),
                    exitRow,
                    const Spacer(),
                    cells,
                  ],
                ),
              ),
              startToggle,
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(child: header),
                  const _HeaderRates(),
                ],
              ),
              SizedBox(height: metrics.ipTop),
              Row(
                spacing: metrics.gap,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        exitRow,
                        const SizedBox(height: 16),
                        cells,
                      ],
                    ),
                  ),
                  startToggle,
                ],
              ),
            ],
          );
    // Clash-style status card: no decorative shape behind the button and no
    // faint traffic chart as a backdrop. The card is flat white, the address
    // and the rates lead, and the traffic chart lives on its own card.
    return DashboardCard(
      padding: EdgeInsets.zero,
      semanticLabel: appLocalizations.status,
      child: Padding(padding: metrics.padding, child: content),
    );
  }
}

/// The two rates at the header's end, level with the status: the phone has no
/// room for a row of their own, and each keeps what it has carried. Clash
/// reads traffic as large figures, so these rates are one size up from the
/// old caption figures, with totals still in small gray.
class _HeaderRates extends ConsumerWidget {
  const _HeaderRates();

  static const _maxWidth = 150.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traffics = ref.watch(trafficsProvider);
    final total = ref.watch(totalTrafficProvider);
    final latest = traffics.list.safeLast(const Traffic());
    final outline = context.colorScheme.outlineVariant;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            _HeaderRate(
              direction: TrafficDirection.upload,
              latest: latest,
              total: total,
            ),
            Container(width: 0.5, height: 26, color: outline),
            _HeaderRate(
              direction: TrafficDirection.download,
              latest: latest,
              total: total,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRate extends StatelessWidget {
  const _HeaderRate({
    required this.direction,
    required this.latest,
    required this.total,
  });

  final TrafficDirection direction;
  final Traffic latest;
  final Traffic total;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 1,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            GlyphIcon(
              direction.glyph,
              size: 14,
              color: direction.glyphColorOf(context),
            ),
            Text(
              '${dashboardTraffic(direction.of(latest))}/s',
              maxLines: 1,
              style: DashboardText.figure(
                context,
                AppTextStyle.subheadline,
                color: context.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Text(
          appLocalizations.trafficTotal(dashboardTraffic(direction.of(total))),
          maxLines: 1,
          style: AppTextStyle.caption2
              .of(context)
              .toTabular
              .copyWith(color: context.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _OutboundMetrics {
  const _OutboundMetrics({
    required this.padding,
    required this.gap,
    required this.ipTop,
    required this.cellGap,
    required this.badgeSize,
    required this.ip,
    required this.buttonSize,
    required this.buttonSlot,
  });

  factory _OutboundMetrics.of(DashboardDensity density) => switch (density) {
    DashboardDensity.standard => _OutboundMetrics(
      padding: dashboardCardPadding(density),
      gap: 16,
      ipTop: 10,
      cellGap: 28,
      badgeSize: 48,
      ip: AppTextStyle.largeTitle,
      buttonSize: 88,
      buttonSlot: 104,
    ),
    DashboardDensity.compact => _OutboundMetrics(
      padding: dashboardCardPadding(density),
      gap: 16,
      ipTop: 8,
      cellGap: 22,
      badgeSize: 40,
      ip: AppTextStyle.title1,
      buttonSize: 72,
      buttonSlot: 84,
    ),
    DashboardDensity.mobile => const _OutboundMetrics(
      padding: EdgeInsetsDirectional.fromSTEB(20, 18, 16, 18),
      gap: 10,
      ipTop: 12,
      cellGap: 24,
      badgeSize: 48,
      ip: AppTextStyle.title2,
      buttonSize: 64,
      buttonSlot: 64,
    ),
  };

  final EdgeInsetsGeometry padding;
  final double gap;
  final double ipTop;
  final double cellGap;
  final double badgeSize;
  final AppTextStyle ip;
  final double buttonSize;
  final double buttonSlot;
}

class _ExitRow extends StatelessWidget {
  const _ExitRow({
    required this.info,
    required this.stale,
    required this.failed,
    required this.loading,
    required this.checking,
    required this.onRefresh,
    required this.quality,
    required this.active,
    required this.metrics,
    required this.large,
  });

  final IpInfo? info;

  /// Showing the last address while a recheck runs, dimmed so it reads as
  /// provisional rather than as the current exit.
  final bool stale;
  final bool failed;
  final bool loading;
  final bool checking;
  final VoidCallback onRefresh;
  final IpQuality? quality;
  final bool active;
  final _OutboundMetrics metrics;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final color = active ? colorScheme.onSurface : colorScheme.onSurfaceVariant;
    final style = DashboardText.figure(
      context,
      metrics.ip,
      color: stale ? color.withValues(alpha: 0.45) : color,
    ).copyWith(letterSpacing: 0);
    final info = this.info;
    final appLocalizations = context.appLocalizations;
    final Widget ip = info != null
        ? Tooltip(
            message: appLocalizations.details(appLocalizations.outboundIp),
            child: FocusRing(
              shape: AppShape.xs,
              standsOff: true,
              child: InkWell(
                onTap: () => showIpQualitySheet(context, ip: info.ip),
                customBorder: AppShape.xs,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: _IpText(ip: info.ip, style: style),
              ),
            ),
          )
        : failed
        ? Text(
            appLocalizations.serviceFailed,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(color: colorScheme.error),
          )
        : SkeletonText(width: 140, style: style);
    return Row(
      spacing: 12,
      children: [
        _CountryBadge(
          countryCode: info?.countryCode,
          size: metrics.badgeSize,
          active: active,
          checking: checking,
          onRefresh: onRefresh,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height:
                    metrics.ip.leading * DashboardDensityScope.scaleOf(context),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ip,
                ),
              ),
              const SizedBox(height: 4),
              if (failed)
                SizedBox(
                  height: _chipHeight(large),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      appLocalizations.tapIconToRetry,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DashboardText.label(context),
                    ),
                  ),
                )
              else
                _IpChips(quality: quality, loading: loading, large: large),
            ],
          ),
        ),
      ],
    );
  }
}

class _IpText extends ConsumerWidget {
  const _IpText({required this.ip, required this.style});

  final String ip;
  final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideIp = ref.watch(
      appSettingProvider.select((state) => state.hideIp),
    );
    return DashboardFitText(hideIp ? ipMask : ip, style: style);
  }
}

double _chipHeight(bool large) => large ? 28 : 24;

const _chipSkeletonWidths = [48.0, 72.0];

class _IpChips extends StatelessWidget {
  const _IpChips({
    required this.quality,
    required this.loading,
    required this.large,
  });

  final IpQuality? quality;
  final bool loading;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final quality = this.quality;
    final height = _chipHeight(large);
    // Chips that do not fit wrap onto a clipped second line; the details
    // sheet still lists them all.
    return SizedBox(
      height: height,
      child: ClipRect(
        child: Wrap(
          spacing: 6,
          runSpacing: height,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: switch (quality) {
            final quality? => [
              Text(
                quality.type.label(context),
                maxLines: 1,
                style: DashboardText.label(context),
              ),
              DashboardChip(
                label:
                    '${context.appLocalizations.ipQualityShort} ${quality.level.label(context)}',
                tone: switch (quality.level) {
                  IpQualityLevel.good => DashboardChipTone.ok,
                  IpQualityLevel.normal => DashboardChipTone.idle,
                  IpQualityLevel.risky => DashboardChipTone.warn,
                },
                large: large,
              ),
            ],
            null when loading => [
              for (final width in _chipSkeletonWidths)
                SkeletonPill(width: width, height: height),
            ],
            null => [
              Text(
                context.appLocalizations.ipTypeUnknown,
                maxLines: 1,
                style: DashboardText.label(context),
              ),
            ],
          },
        ),
      ),
    );
  }
}

const _fadePeriod = Duration(milliseconds: 1500);

/// The exit's country, which checks the exit again when tapped and fades while
/// it is being checked.
class _CountryBadge extends StatefulWidget {
  const _CountryBadge({
    required this.countryCode,
    required this.size,
    required this.active,
    required this.checking,
    required this.onRefresh,
  });

  final String? countryCode;
  final double size;
  final bool active;
  final bool checking;
  final VoidCallback onRefresh;

  @override
  State<_CountryBadge> createState() => _CountryBadgeState();
}

class _CountryBadgeState extends State<_CountryBadge>
    with SingleTickerProviderStateMixin {
  static const _fadeFloor = 0.4;

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: _fadePeriod,
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pulse();
  }

  @override
  void didUpdateWidget(_CountryBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checking != widget.checking) {
      _pulse();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _pulse() {
    if (context.disableAnimations) {
      _fade.value = 1;
    } else if (widget.checking) {
      _fade.repeat(reverse: true, min: _fadeFloor, max: 1);
    } else {
      _fade.animateTo(1, duration: _fadePeriod * (1 - _fade.value));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final foreground = widget.active
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;
    final enabled = !widget.checking;
    final size = widget.size;
    final code = widget.countryCode;
    final tooltip = context.appLocalizations.retry;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        child: FocusRing(
          shape: AppShape.full,
          standsOff: true,
          child: InkResponse(
            onTap: enabled ? widget.onRefresh : null,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            child: ElasticPress(
              enabled: enabled,
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: code == null || code.isEmpty
                        ? GlyphIcon(
                            AppGlyphs.proxies,
                            size: size * 0.5,
                            color: foreground,
                          )
                        : Text(
                            code.countryFlagEmoji,
                            maxLines: 1,
                            // The flag is the whole mark, so it is sized like an
                            // icon beside the address, not against the type.
                            style:
                                AppTextStyle.custom(
                                  context,
                                  size: size * 0.58,
                                  leading: size * 0.58,
                                  weight: FontWeight.w600,
                                ).copyWith(
                                  color: foreground,
                                  fontFamily: FontFamily.twEmoji.value,
                                ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cells extends StatelessWidget {
  const _Cells({
    required this.quality,
    required this.loading,
    required this.active,
    required this.gap,
  });

  final IpQuality? quality;
  final bool loading;
  final bool active;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final organization = switch (quality) {
      IpQuality(organization: final name?) when name.isNotEmpty => name,
      IpQuality(asn: final asn?) => 'AS$asn',
      _ => null,
    };
    return Row(
      spacing: gap,
      children: [
        _Cell(
          label: appLocalizations.runTime,
          value: active ? const _RunTimeValue() : const _Placeholder(),
        ),
        Flexible(
          child: _Cell(
            label: appLocalizations.ipOrganization,
            value: organization != null
                ? _CellText(organization)
                : loading
                ? SkeletonText(width: 96, style: _cellStyle(context))
                : const _Placeholder(),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DashboardText.label(context),
        ),
        const SizedBox(height: 2),
        value,
      ],
    );
  }
}

/// A cell's value sits under its label rather than beside it, at the value
/// weight: the address above it is the card's figure, and two figures of one
/// weight leave neither reading first.
TextStyle _cellStyle(BuildContext context) =>
    DashboardText.value(context, AppTextStyle.subheadline);

class _CellText extends StatelessWidget {
  const _CellText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _cellStyle(context),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Text('—', maxLines: 1, style: _cellStyle(context));
  }
}

class _RunTimeValue extends ConsumerWidget {
  const _RunTimeValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CellText(getTimeText(ref.watch(runTimeProvider)));
  }
}

const _morphDuration = Duration(milliseconds: 450);
const _stateDuration = Duration(milliseconds: 150);

final _startMorph = Morph(MaterialShapes.circle, MaterialShapes.cookie9Sided);

Path _morphPath(double progress) => _startMorph.toPath(
  progress: progress,
  rotationPivotX: 0.5,
  rotationPivotY: 0.5,
);

double _morphTurn(double progress) => progress * 2 * math.pi / 9;

/// A circle with a play glyph while stopped that grows the cookie-9 of a
/// running tunnel, the way the M3 Expressive loader morphs between shapes.
class _StartToggle extends ConsumerStatefulWidget {
  const _StartToggle({
    required this.size,
    required this.enabled,
    required this.running,
    required this.suspended,
  });

  final double size;
  final bool enabled;
  final bool running;
  final bool suspended;

  @override
  ConsumerState<_StartToggle> createState() => _StartToggleState();
}

class _StartToggleState extends ConsumerState<_StartToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _morphDuration,
    value: widget.running ? 1 : 0,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeInCubic,
  );
  var _hovered = false;
  var _pressed = false;
  var _focused = false;

  /// The M3 state layer, painted inside the shape: the card's decoration
  /// covers the button, so ink on the card's Material would never show.
  double get _overlay => !widget.enabled
      ? 0
      : _focused
      ? 0.1
      : _hovered
      ? 0.08
      : 0;

  @override
  void didUpdateWidget(_StartToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running != widget.running) {
      widget.running ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    ref.read(commonActionProvider.notifier).toggleRunning();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final appLocalizations = context.appLocalizations;
    final glass = LiquidGlassScope.of(context);
    final size = widget.size;
    final enabled = widget.enabled;
    final up = widget.running || widget.suspended;
    // Clash reserves green for running, so in light mode a running button
    // is green with white ink, not the app's blue primary. A stopped button
    // wears a soft primary, so a filled one only ever means the tunnel is
    // up. Dark mode keeps the primary fill, where green on dark would not
    // carry the same contrast.
    final isLight = colorScheme.brightness == Brightness.light;
    final fill = !enabled
        ? DashboardColors.of(context).tone2
        : up
        ? (isLight ? colorScheme.success : colorScheme.primary)
        : colorScheme.primaryContainer;
    final ink = !enabled
        ? colorScheme.onSurfaceVariant
        : up
        ? (isLight ? Colors.white : colorScheme.onPrimary)
        : colorScheme.onPrimaryContainer;
    final tooltip = widget.suspended
        ? appLocalizations.suspended
        : widget.running
        ? appLocalizations.stop
        : appLocalizations.start;
    final stateDuration = context.motionDuration(_stateDuration);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        child: InkResponse(
          onTap: enabled ? _toggle : null,
          onHover: (value) => setState(() => _hovered = value),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onFocusChange: (value) => setState(() => _focused = value),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          child: ElasticPress(
            enabled: enabled,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _overlay),
              duration: stateDuration,
              builder: (_, overlay, child) => AnimatedBuilder(
                animation: _progress,
                builder: (_, child) {
                  final progress = _progress.value;
                  final color = Color.alphaBlend(
                    ink.withValues(alpha: overlay),
                    fill,
                  );
                  return CustomPaint(
                    painter: _MorphPainter(
                      progress: progress,
                      color: glass ? null : color,
                      shadow: enabled
                          ? (isLight && up
                                  ? colorScheme.success
                                  : colorScheme.primary)
                              .withValues(alpha: up ? 0.3 : 0.16)
                          : Colors.transparent,
                      ring: _focused
                          ? focusRingSide(colorScheme, standsOff: true)
                          : null,
                    ),
                    child: glass
                        ? LiquidGlass(
                            style: LiquidGlassStyle.tinted(colorScheme, color),
                            clipper: _MorphClipper(progress),
                            pressed: _pressed,
                            child: child,
                          )
                        : child,
                  );
                },
                child: child,
              ),
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: widget.suspended
                      ? GlyphIcon(
                          AppGlyphs.wifiOff,
                          size: size * 0.34,
                          color: ink,
                          fill: 1,
                        )
                      : TweenAnimationBuilder<double>(
                          tween: Tween(end: widget.running ? 1 : 0),
                          duration: _morphDuration,
                          curve: Curves.easeOutBack,
                          builder: (_, progress, _) => GlyphIcon(
                            AppGlyphs.playPause(progress),
                            size: size * 0.34,
                            color: ink,
                            fill: 1,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fills the morph, or with no [color] leaves its inside to glass and casts
/// [shadow] only outside it, as one under glass would show through.
class _MorphPainter extends CustomPainter {
  const _MorphPainter({
    required this.progress,
    required this.color,
    required this.shadow,
    required this.ring,
  });

  static const _shadowOffset = Offset(0, 6);
  static const _shadowBlur = 14.0;

  final double progress;
  final Color? color;
  final Color shadow;
  final BorderSide? ring;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _morphPath(progress);
    final color = this.color;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(_morphTurn(progress))
      ..scale(size.width, size.height)
      ..translate(-0.5, -0.5);
    if (shadow.a > 0) {
      canvas.save();
      if (color == null) {
        canvas.clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(const Rect.fromLTRB(-1, -1, 2, 2))
            ..addPath(path, Offset.zero),
        );
      }
      canvas
        ..translate(
          _shadowOffset.dx / size.width,
          _shadowOffset.dy / size.height,
        )
        ..drawPath(
          path,
          Paint()
            ..color = shadow
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              _shadowBlur / 2 / size.width,
            ),
        )
        ..restore();
    }
    if (color != null) {
      canvas.drawPath(path, Paint()..color = color);
    }
    if (ring case final ring?) {
      strokeUnitShape(canvas, path, size.width, ring);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MorphPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.shadow != shadow ||
      oldDelegate.ring != ring;
}

class _MorphClipper extends CustomClipper<Path> {
  const _MorphClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    final transform =
        Matrix4.translationValues(size.width / 2, size.height / 2, 0)
          ..rotateZ(_morphTurn(progress))
          ..scaleByDouble(size.width, size.height, 1, 1)
          ..translateByDouble(-0.5, -0.5, 0, 1);
    return _morphPath(progress).transform(transform.storage);
  }

  @override
  bool shouldReclip(_MorphClipper oldClipper) =>
      oldClipper.progress != progress;
}
