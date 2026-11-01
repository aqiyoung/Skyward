import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'disclaimer.dart';
import 'privacy_policy.dart';

@immutable
class Contributor {
  final String avatar;
  final String name;

  const Contributor({required this.avatar, required this.name});
}

class AboutView extends ConsumerStatefulWidget {
  const AboutView({super.key});

  @override
  ConsumerState<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends ConsumerState<AboutView> {
  // Moved here from AboutView in the PR #31 fix: the contributors row
  // is built by this state, and a bare _contributors in state code
  // does not resolve to the widget class's static list — that was
  // the preview build failure (about.dart:143/147).
  static const _contributors = [
    Contributor(avatar: 'assets/images/avatar/june2.jpg', name: 'June2'),
    Contributor(avatar: 'assets/images/avatar/arue.jpg', name: 'Arue'),
  ];

  Widget _buildLinkItem({
    required Glyph glyph,
    required String title,
    required String url,
    required String label,
  }) {
    return ListItem(
      leading: IconWell(glyph, side: 40, glyphSize: 20, shape: AppShape.md),
      title: Text(title),
      subtitle: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const GlyphIcon(AppGlyphs.openExternal),
      onTap: () {
        dialogs.openUrl(url);
      },
    );
  }

  Widget _buildLogoLinkItem({
    required String asset,
    required String title,
    required String url,
    required String label,
  }) {
    return ListItem(
      // Do not clip the logo to a rounded square: the FlClash mark's
      // top bar reaches into the image's top-right corner, and a 16 dp
      // corner on a 36 dp box cuts that tip off. The mark already has
      // its own rounded ends and a transparent background, so it is
      // shown unclipped.
      leading: SizedBox.square(
        dimension: 36,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
      title: Text(title),
      subtitle: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const GlyphIcon(AppGlyphs.openExternal),
      onTap: () {
        dialogs.openUrl(url);
      },
    );
  }

  /// The two icon designers side by side, split down the middle by a hairline.
  /// Each half is laid out like the rows above it — portrait, name, the role
  /// under the name — so the pair needs no header of its own to be read, and
  /// the role is said again for the second person rather than shared.
  Widget _buildContributors(String role) {
    return ListItem(
      title: Row(
        children: [
          for (var index = 0; index < _contributors.length; index++) ...[
            if (index > 0) const _ContributorDivider(),
            Expanded(
              child: _ContributorChip(
                contributor: _contributors[index],
                role: role,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      title: '${appLocalizations.about} $appName',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.contentTopPadding,
          bottom: 32 + context.bottomInset,
        ),
        children: [
          _AboutHero(
            onEnterDeveloperMode: () {
              ref
                  .read(appSettingProvider.notifier)
                  .update((state) => state.copyWith(developerMode: true));
              context.showNotifier(
                appLocalizations.developerModeEnableTip,
                level: MessageLevel.success,
              );
            },
          ),
          const SizedBox(height: 8),
          // No headings over any of the cards: the rows say what they are, and
          // a label above two of them only said it twice. The update check is
          // not here either -- it belongs to the row that names the build, on
          // the tools tab, so this page is only what the build is and what it
          // stands on.
          generateSection(
            items: [
              _buildLinkItem(
                glyph: AppGlyphs.code,
                title: appLocalizations.project,
                url: 'https://github.com/$repository',
                label: 'github.com/$repository',
              ),
              _buildLinkItem(
                glyph: AppGlyphs.cpu,
                title: appLocalizations.core,
                url: 'https://github.com/aqiyoung/skyward-core/tree/FlClash',
                label: 'github.com/aqiyoung/skyward-core',
              ),
              _buildLinkItem(
                glyph: AppGlyphs.gavel,
                title: appLocalizations.disclaimerLicenseTitle,
                url: 'https://github.com/$repository/blob/main/LICENSE',
                label: 'GPL-3.0',
              ),
              // The terms are a page of their own, reached from this row: read
              // here in full, they were a scroll few ever finished.
              ListItem.open(
                leading: IconWell(
                  AppGlyphs.rules,
                  side: 40,
                  glyphSize: 20,
                  shape: AppShape.md,
                ),
                title: Text(appLocalizations.disclaimer),
                widget: const DisclaimerView(),
              ),
              ListItem.open(
                leading: IconWell(
                  AppGlyphs.info,
                  side: 40,
                  glyphSize: 20,
                  shape: AppShape.md,
                ),
                title: Text(appLocalizations.privacyPolicy),
                widget: const PrivacyPolicyView(),
              ),
            ],
          ),
          generateSection(
            items: [
              // Upstream FlClash lives here, not on the card above: that
              // one carries this project's own entry, so a second project
              // there reads as a competing project link.
              _buildLogoLinkItem(
                asset: 'assets/images/avatar/flclash.png',
                title: 'FlClash',
                url: 'https://github.com/chen08209/FlClash',
                label: 'github.com/chen08209/FlClash',
              ),
              _buildContributors(appLocalizations.appIconDesign),
            ],
          ),
        ],
      ),
    );
  }
}

/// One contributor: the portrait, then the name and the role under it — the
/// same arrangement a row of the list above has, so the pair does not read as
/// a different kind of thing.
class _ContributorChip extends StatelessWidget {
  final Contributor contributor;
  final String role;

  const _ContributorChip({required this.contributor, required this.role});

  @override
  Widget build(BuildContext context) {
    return Row(
      // The list puts this much between a row's leading and its title.
      spacing: 16,
      children: [
        CircleAvatar(
          radius: 18,
          foregroundImage: AssetImage(contributor.avatar),
          // Under the portrait while it loads, and left in its place if the
          // asset cannot be read.
          child: Text(contributor.name[0]),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contributor.name,
                style: context.listTitleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                role,
                // A step under the list's own subtitle: half the row's width
                // is the whole budget here, and the role is the same two words
                // on both sides.
                style: AppTextStyle.caption1
                    .of(context)
                    .copyWith(color: context.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A hairline between the two contributors, at the weight the list draws its
/// own row separators with.
class _ContributorDivider extends StatelessWidget {
  const _ContributorDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: context.colorScheme.outlineVariant,
    );
  }
}

class _AboutHero extends StatelessWidget {
  final VoidCallback onEnterDeveloperMode;

  const _AboutHero({required this.onEnterDeveloperMode});

  static const _logoSize = 96.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final appLocalizations = context.appLocalizations;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          _DeveloperModeDetector(
            onEnterDeveloperMode: onEnterDeveloperMode,
            // The icon carries its own tile, so it is the hero itself: no
            // card behind it to show as a rim around its corners.
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: AppShape.all(AppCorner.fit(_logoSize)),
              ),
              child: Image.asset(
                'assets/images/icon.png',
                width: _logoSize,
                height: _logoSize,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            appName,
            style: AppTextStyle.title2.of(context, emphasized: true),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              appLocalizations.desc,
              textAlign: TextAlign.center,
              style: AppTextStyle.subheadline
                  .of(context)
                  .copyWith(color: colorScheme.onSurfaceVariant, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeveloperModeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onEnterDeveloperMode;

  const _DeveloperModeDetector({
    required this.child,
    required this.onEnterDeveloperMode,
  });

  @override
  State<_DeveloperModeDetector> createState() => _DeveloperModeDetectorState();
}

class _DeveloperModeDetectorState extends State<_DeveloperModeDetector> {
  int _counter = 0;
  Timer? _timer;

  void _handleTap() {
    _counter++;
    if (_counter >= 5) {
      widget.onEnterDeveloperMode();
      _resetCounter();
    } else {
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 1), _resetCounter);
    }
  }

  void _resetCounter() {
    _counter = 0;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _handleTap, child: widget.child);
  }
}
