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
    );
    if (result == null) return;
    unawaited(
      commonAction.checkUpdateResultHandle(data: result.release, isUser: true),
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

  Widget _buildContributorTile(
    BuildContext context,
    Contributor contributor,
    String subtitle,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          foregroundImage: AssetImage(contributor.avatar),
          child: Text(contributor.name[0]),
        ),
        const SizedBox(height: 6),
        Text(contributor.name, style: context.listTitleStyle),
        Text(
          subtitle,
          style: context.listSubtitleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFlClashTile(BuildContext context) {
    return GestureDetector(
      onTap: () {
        dialogs.openUrl('https://github.com/chen08209/FlClash');
      },
      child: Column(
        children: [
          SizedBox.square(
            dimension: 32,
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: AppShape.md),
              child: Image.asset(
                'assets/images/avatar/flclash.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FlClash', style: context.listTitleStyle),
              const SizedBox(width: 2),
              GlyphIcon(
                AppGlyphs.openExternal,
                size: 12,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContributorsRow(BuildContext context, String subtitle) {
    return CommonCard(
      shape: AppShape.of(
        AppRadius.vertical(top: AppCorner.xl, bottom: AppCorner.xl),
      ),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(child: _buildFlClashTile(context)),
            Container(
              width: 1,
              height: 40,
              color: context.colorScheme.outlineVariant,
            ),
            Expanded(
              child: _buildContributorTile(context, _contributors[0], subtitle),
            ),
            Container(
              width: 1,
              height: 40,
              color: context.colorScheme.outlineVariant,
            ),
            Expanded(
              child: _buildContributorTile(context, _contributors[1], subtitle),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final isLoading = ref.watch(loadingProvider(LoadingTag.checkUpdate));
    return CommonScaffold(
      isLoading: isLoading,
      title: appLocalizations.about,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.contentTopPadding,
          bottom: 32 + context.bottomInset,
        ),
        children: [
          _AboutHero(
            isCheckingUpdate: isLoading,
            onCheckUpdate: () {
              _checkUpdate(context, ref);
            },
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
              _buildContributorsRow(context, appLocalizations.appIconDesign),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutHero extends StatelessWidget {
  final bool isCheckingUpdate;
  final VoidCallback onCheckUpdate;
  final VoidCallback onEnterDeveloperMode;

  const _AboutHero({
    required this.isCheckingUpdate,
    required this.onCheckUpdate,
    required this.onEnterDeveloperMode,
  });

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
          const SizedBox(height: 10),
          _Pill(
            label: 'v${globalState.packageInfo.displayVersion}',
            color: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
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
          const SizedBox(height: 20),
          TonalButton(
            size: TonalButtonSize.bar,
            glyph: AppGlyphs.sync,
            label: appLocalizations.checkUpdate,
            onPressed: isCheckingUpdate ? null : onCheckUpdate,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color foregroundColor;

  const _Pill({
    required this.label,
    required this.color,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(color: color, shape: AppShape.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          label,
          style: AppTextStyle.caption1
              .of(context, emphasized: true)
              .copyWith(color: foregroundColor),
        ),
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
