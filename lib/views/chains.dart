import 'package:skyward/common/common.dart';
import 'package:skyward/features/form/form.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/page_large_title.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A chain manager over the existing dialer-proxy data. Each entry in
/// `CustomProfileData.dialers` is an exit node reached through an entry node;
/// that is exactly one ReClash-style chain. Saving "creates a chain" by
/// writing the exit node's dialer target, which the core now honours.
class ChainsView extends ConsumerStatefulWidget {
  const ChainsView({super.key});

  @override
  ConsumerState<ChainsView> createState() => _ChainsViewState();
}

class _ChainsViewState extends ConsumerState<ChainsView> {
  int? _profileId() {
    final id = ref.read(currentProfileIdProvider);
    if (id != null) return id;
    final profiles = ref.read(profilesProvider);
    return profiles.isEmpty ? null : profiles.first.id;
  }

  Future<void> _create() async {
    final profileId = _profileId();
    if (profileId == null) return;
    final data = ref.read(customProfileDataProvider(profileId));
    final nodes = <String>[...?data?.proxies, ...?data?.proxyProviders]..sort();
    if (nodes.length < 2) {
      if (mounted) {
        context.showNotifier(context.appLocalizations.chainNoProxies);
      }
      return;
    }
    final exit = await showSheet<String>(
      context: context,
      builder: (context) => SelectionSheet<String>(
        title: context.appLocalizations.chainSelectExit,
        sections: [
          SelectionSection(
            label: context.appLocalizations.chainExit,
            items: nodes,
          ),
        ],
        labelBuilder: (item) => item,
        selectedOf: (_) => '',
        onSelected: (item) => Navigator.of(context).pop(item),
      ),
    );
    if (exit == null || !mounted) return;
    final entry = await showSheet<String>(
      context: context,
      builder: (context) => SelectionSheet<String>(
        title: context.appLocalizations.chainSelectEntry,
        sections: [
          SelectionSection(
            label: context.appLocalizations.chainEntry,
            items: nodes.where((n) => n != exit).toList(),
          ),
        ],
        labelBuilder: (item) => item,
        selectedOf: (_) => '',
        onSelected: (item) => Navigator.of(context).pop(item),
      ),
    );
    if (entry == null || !mounted) return;

    final proxies = ref.read(customProxiesProvider).value ?? const [];
    final exitId = proxies
        .where((p) => p.name == exit)
        .map((p) => p.id)
        .firstOrNull;
    if (exitId == null) {
      // The exit is a provider/group node, not a local custom proxy: those
      // cannot hold a dialer in the per-proxy store.
      if (mounted) {
        context.showNotifier(context.appLocalizations.chainNoProxies);
      }
      return;
    }
    ref.read(proxyDialersProvider(profileId).notifier).set(exitId, entry);
    if (mounted) {
      context.showNotifier(context.appLocalizations.chainSaved);
    }
  }

  void _delete(String exitName, int exitId) {
    final profileId = _profileId();
    if (profileId == null) return;
    ref.read(proxyDialersProvider(profileId).notifier).set(exitId, null);
    context.showNotifier(context.appLocalizations.chainRemoved);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final profileId = _profileId();
    final data = profileId == null
        ? null
        : ref.watch(customProfileDataProvider(profileId));
    final proxies = ref.watch(customProxiesProvider).value ?? const [];
    final idOf = <String, int>{for (final p in proxies) p.name: p.id};

    // exit -> entry, exactly one hop each (the core supports chained hops via
    // nested dialer-proxy, surfaced here as separate rows).
    final chains =
        data?.dialers.entries.where((e) => e.value.isNotEmpty).toList() ??
        const [];

    final largeTitle =
        ViewScope.isMobileOf(context) && !context.isInCompactSheet;
    final statusBarTop = MediaQuery.paddingOf(context).top;

    final body = chains.isEmpty
        ? _Empty(onCreate: _create)
        : ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + context.bottomInset),
            itemCount: chains.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: FilledButton.icon(
                    onPressed: _create,
                    icon: const GlyphIcon(AppGlyphs.add, fill: 1, size: 18),
                    label: Text(appLocalizations.chainCreate),
                  ),
                );
              }
              final entry = chains[index - 1];
              final exitName = entry.key;
              final entryName = entry.value;
              final exitId = idOf[exitName];
              return _ChainTile(
                entry: entryName,
                exit: exitName,
                onDelete: exitId == null
                    ? null
                    : () => _delete(exitName, exitId),
              );
            },
          );

    return CommonScaffold(
      title: appLocalizations.chainManager,
      largeTitle: largeTitle,
      body: largeTitle
          ? PageLargeTitle(
              title: appLocalizations.chainManager,
              statusBarTop: statusBarTop,
              body: body,
            )
          : body,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final cs = context.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + context.bottomInset),
      child: Column(
        children: [
          const Spacer(),
          Text(
            l.chainGuideTitle,
            style: AppTextStyle.title1.of(context, emphasized: true),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _RouteStrip(cs: cs),
          const SizedBox(height: 24),
          Text(
            l.chainGuideDesc,
            style: AppTextStyle.body
                .of(context)
                .copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const GlyphIcon(AppGlyphs.add, fill: 1, size: 18),
              label: Text(l.chainCreate),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStrip extends StatelessWidget {
  const _RouteStrip({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final nodes = [
      (AppGlyphs.account, l.chainEntry),
      (AppGlyphs.globe, l.chainExit),
      (AppGlyphs.globe, 'Web'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < nodes.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GlyphIcon(
                AppGlyphs.chevronForward,
                size: 16,
                color: cs.primary,
              ),
            ),
          _RouteNode(glyph: nodes[i].$1, label: nodes[i].$2, cs: cs),
        ],
      ],
    );
  }
}

class _RouteNode extends StatelessWidget {
  const _RouteNode({
    required this.glyph,
    required this.label,
    required this.cs,
  });

  final Glyph glyph;
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: ShapeDecoration(
            color: cs.primaryContainer,
            shape: AppShape.all(40),
          ),
          child: GlyphIcon(glyph, size: 24, color: cs.onPrimaryContainer),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyle.caption1.of(context)),
      ],
    );
  }
}

class _ChainTile extends StatelessWidget {
  const _ChainTile({
    required this.entry,
    required this.exit,
    required this.onDelete,
  });

  final String entry;
  final String exit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: cs.surfaceContainerLow,
        shape: AppShape.all(16),
      ),
      child: Row(
        children: [
          GlyphIcon(AppGlyphs.link, size: 20, color: cs.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$entry → $exit',
                  style: AppTextStyle.body.of(context, emphasized: true),
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.appLocalizations.chainEntry}: $entry   '
                  '${context.appLocalizations.chainExit}: $exit',
                  style: AppTextStyle.caption1
                      .of(context)
                      .copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: context.appLocalizations.chainDelete,
              onPressed: onDelete,
              icon: GlyphIcon(AppGlyphs.delete, size: 20, color: cs.error),
            ),
        ],
      ),
    );
  }
}
