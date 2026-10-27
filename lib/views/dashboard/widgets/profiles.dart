import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/views/profiles/add.dart';
import 'package:skyward/views/profiles/custom/custom.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';
import 'profile_detail.dart';

DateTime? _expiryOf(Profile? profile) {
  final expire = profile?.subscriptionInfo?.expire ?? 0;
  return expire > 0 ? DateTime.fromMillisecondsSinceEpoch(expire * 1000) : null;
}

int _daysLeft(DateTime expiry) =>
    math.max(0, expiry.difference(DateTime.now()).inDays);

String _expiryText(BuildContext context, DateTime expiry) =>
    context.appLocalizations.profileExpiresIn(expiry.show, _daysLeft(expiry));

void _openProfile(BuildContext context, Profile? profile) {
  switch (profile) {
    case null:
      showAddProfilePage(context);
    case Profile(type: ProfileType.custom, :final id):
      showCustomProfileSheet(context, id);
    case _:
      showProfileDetailSheet(context);
  }
}

String _sourceOf(BuildContext context, ProfileType type) => switch (type) {
  ProfileType.url => context.appLocalizations.remote,
  ProfileType.file => context.appLocalizations.local,
  ProfileType.custom => context.appLocalizations.custom,
};

class ProfilesCard extends ConsumerWidget {
  const ProfilesCard({super.key});

  static const _soonDays = 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = DashboardDensityScope.of(context);
    final mobile = !density.isDesktop;
    final compact = density.isCompact;
    final appLocalizations = context.appLocalizations;
    final profile = ref.watch(currentProfileProvider);
    final switchable = ref.watch(
      profilesProvider.select((profiles) => profiles.length > 1),
    );
    final expiry = _expiryOf(profile);
    final updatedAt = profile?.lastUpdateDate;
    final label = DashboardText.label(context);
    final figure = mobile
        ? AppTextStyle.title3
        : (compact ? AppTextStyle.callout : AppTextStyle.headline);
    final name = mobile || !compact
        ? AppTextStyle.headline
        : AppTextStyle.callout;
    final endText = switch ((profile, expiry)) {
      (_, final expiry?) => appLocalizations.profileDaysLeft(_daysLeft(expiry)),
      (final profile?, null) => _sourceOf(context, profile.type),
      _ => null,
    };
    final Widget? end = switch ((endText, expiry)) {
      (final text?, final expiry?) => Tooltip(
        message: _expiryText(context, expiry),
        child: Text(
          text,
          maxLines: 1,
          style: _daysLeft(expiry) <= _soonDays
              ? label.copyWith(color: DashboardColors.of(context).warn)
              : label,
        ),
      ),
      (final text?, null) => Text(text, maxLines: 1, style: label),
      _ => null,
    };
    final sync = profile != null && profile.type == ProfileType.url
        ? _SyncButton(profile: profile)
        : null;
    final nameRow = Row(
      children: [
        Flexible(
          child: EmojiText(
            profile?.realLabel ?? appLocalizations.addProfile,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: name
                .of(context)
                .copyWith(fontWeight: DashboardWeight.title),
          ),
        ),
        if (profile != null && switchable)
          SizedBox(
            height: name.leading,
            child: DashboardIconButton(
              glyph: AppGlyphs.swap,
              tooltip: appLocalizations.switchProfile,
              onPressed: () => showProfilesSheet(context),
            ),
          ),
      ],
    );
    return DashboardCard(
      semanticLabel: appLocalizations.profile,
      onTap: mobile || profile == null
          ? () => _openProfile(context, profile)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: mobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.profiles,
            title: appLocalizations.profile,
            chevron: mobile,
            trailing: [
              if (mobile)
                ?sync
              else
                Transform.translate(
                  offset: const Offset(8, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ?sync,
                      DashboardIconButton(
                        glyph: AppGlyphs.chevronForward,
                        tooltip: appLocalizations.details(
                          appLocalizations.profile,
                        ),
                        onPressed: () => _openProfile(context, profile),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: mobile ? 12 : 10),
          if (compact && end != null)
            DashboardCappedRow(spacing: _rowGap, start: nameRow, end: end)
          else
            nameRow,
          if (profile != null && !compact)
            LayoutBuilder(
              builder: (context, constraints) {
                final time = updatedAt?.getLastUpdateTimeDesc(context);
                final updated = time == null
                    ? null
                    : appLocalizations.profileUpdatedAt(time);
                final fits =
                    updated == null ||
                    _widthOf(updated, label) +
                            _rowGap +
                            _widthOf(endText ?? '', label) <=
                        constraints.maxWidth;
                return Row(
                  spacing: _rowGap,
                  children: [
                    Expanded(
                      child: Text(
                        (fits ? updated : time) ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: label,
                      ),
                    ),
                    ?end,
                  ],
                );
              },
            ),
          if (profile != null) ...[
            if (mobile) const SizedBox(height: 14) else const Spacer(),
            // Reference layout: the card is just the counts. Usage,
            // subscription and providers live in the detail sheet the
            // card opens, and the connection, request and DNS counts
            // live in the tools pages, not on the dashboard.
            _ConfigStats(figure: figure),
          ],
        ],
      ),
    );
  }
}

const _rowGap = 12.0;

double _widthOf(String text, TextStyle style) =>
    globalState.measure.computeTextSize(Text(text, style: style)).width;

class _SyncButton extends ConsumerWidget {
  const _SyncButton({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdating = ref.watch(isUpdatingProvider(profile.updatingKey));
    if (isUpdating) {
      return const SizedBox.square(
        dimension: 32,
        child: Center(child: CommonCircleLoading(size: 18)),
      );
    }
    return DashboardIconButton(
      glyph: AppGlyphs.sync,
      tooltip: context.appLocalizations.update,
      onPressed: () => syncProfile(ref, profile),
    );
  }
}

class _ConfigStats extends ConsumerStatefulWidget {
  const _ConfigStats({required this.figure});

  final AppTextStyle figure;

  @override
  ConsumerState<_ConfigStats> createState() => _ConfigStatsState();
}

class _ConfigStatsState extends ConsumerState<_ConfigStats>
    with ConfigCountsWatch<_ConfigStats> {
  @override
  Widget build(BuildContext context) {
    watchConfigCounts();
    final providers = ref.watch(providersProvider);
    final appLocalizations = context.appLocalizations;
    final stats = switch (configCounts) {
      final counts? => profileStatsOf(counts, providers),
      null => null,
    };
    // Clash-style summary figures: the counts lead the card in bold, with
    // their labels in small gray under them.
    final figure = DashboardText.figure(
      context,
      widget.figure,
    ).copyWith(letterSpacing: 0, fontWeight: DashboardWeight.title);
    final label = DashboardText.label(context);
    Widget item(int? value, String name) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (value != null)
          Text(dashboardCount(value), maxLines: 1, style: figure)
        else if (configCountsFailed)
          Text('—', maxLines: 1, style: figure)
        else
          SkeletonText(width: widget.figure.size * 1.5, style: figure),
        Text(name, maxLines: 1, style: label),
      ],
    );
    // Reference layout: the three counts sit together on the left,
    // not spread across the card's full width. The row itself must
    // be the FittedBox child, with no width constraint in between:
    // constraining it to the card width first lets its columns
    // overflow the row before the box can scale it down.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        // Min size, so the box sees the row's real width and can
        // scale it down; a max-size row would overflow before that.
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 40,
        children: [
          item(stats?.groups, appLocalizations.proxyGroup),
          item(stats?.proxies, appLocalizations.proxies),
          item(stats?.rules, appLocalizations.rules),
        ],
      ),
    );
  }
}
