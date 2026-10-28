import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class Contributor {
  final String avatar;
  final String name;

  const Contributor({required this.avatar, required this.name});
}

class AboutView extends ConsumerWidget {
  const AboutView({super.key});

  // Avatars restored from the upstream FlClash repository, whose About
  // page carried these two icon designers before the Skyward rename.
  static const _contributors = [
    Contributor(avatar: 'assets/images/avatar/june2.jpg', name: 'June2'),
    Contributor(avatar: 'assets/images/avatar/arue.jpg', name: 'Arue'),
  ];

  Future<void> _checkUpdate(BuildContext context, WidgetRef ref) async {
    if (ref.read(loadingProvider(LoadingTag.checkUpdate))) return;
    final commonAction = ref.read(commonActionProvider.notifier);
    final result = await globalState.loadingRun(
      () async => (release: await request.checkForUpdate()),
      title: context.appLocalizations.checkUpdate,
      tag: LoadingTag.checkUpdate,
      // No modal on failure either: the check itself is silent, and a
      // failed round trip only leaves a non-modal error banner.
      silence: true,
    );
    if (result == null) return;
    unawaited(
      commonAction.checkUpdateResultHandle(data: result.release, silent: true),
    );
  }

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
      // A full-bleed square carries more weight than a circle of the same box:
      // at 40 dp beside the portraits below it read a size larger than they
      // are, so it takes the side a square of their area would.
      leading: SizedBox.square(
        dimension: 36,
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: AppShape.md),
          child: Image.asset(asset, fit: BoxFit.cover),
        ),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    // The check is deliberately silent: no loading bar under the title
    // while it runs, and no dialog when it finishes. A new release just
    // starts its background download; already-latest shows nothing.
    return CommonScaffold(
      title: appLocalizations.about,
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
          // Reference-style top card, no leading icons, no section
          // header: the version is a plain row with the number on the
          // right, and version update is a row with the default chevron
          // that runs the same manual check.
          generateSection(
            items: [
              ListItem(
                title: Text(appLocalizations.version),
                trailing: Text(
                  globalState.packageInfo.displayVersion,
                  style: context.listSubtitleStyle,
                ),
              ),
              ListItem(
                title: Text(appLocalizations.versionUpdate),
                // A plain onTap row shows no trailing at all: the
                // chevron has to be asked for explicitly.
                trailing: const GlyphIcon(AppGlyphs.chevronForward),
                onTap: () {
                  _checkUpdate(context, ref);
                },
              ),
            ],
          ),
          generateSection(
            title: appLocalizations.more,
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
            ],
          ),
          generateSection(
            title: appLocalizations.otherContributors,
            items: [
              // Upstream FlClash lives here, not in More: More already has
              // this project's own Project entry, so a second project
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
