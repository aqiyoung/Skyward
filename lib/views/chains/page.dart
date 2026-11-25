import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' show Localizations;
import 'package:material_ui/material_ui.dart';

import 'editor.dart';
import 'state.dart';
import 'widgets.dart';

/// Opens the link-chain page.
Future<void> openChainsPage(BuildContext context) =>
    BaseNavigator.push<void>(context, const ChainsView());

class ChainsView extends ConsumerStatefulWidget {
  const ChainsView({super.key});

  @override
  ConsumerState<ChainsView> createState() => _ChainsViewState();
}

class _ChainsViewState extends ConsumerState<ChainsView> {
  List<ChainReport> _reports = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(chainsProvider.notifier).load();
      final reports = await ref.read(coreHandlerProvider).getChainReport();
      if (mounted) setState(() => _reports = reports);
    });
  }

  ChainReport? _reportOf(int id) {
    for (final report in _reports) {
      if (report.id == id) return report;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final chains = ref.watch(chainsProvider);
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    void create() => showChainEditor(context);
    // Keep the plain Scaffold/AppBar here: nesting a ListView inside
    // CommonScaffold let its first card scroll up behind the transparent bar.
    return Scaffold(
      appBar: AppBar(
        title: Text(zh ? '链路' : 'Chains'),
        actions: [
          IconButton(
            icon: const GlyphIcon(AppGlyphs.add),
            onPressed: create,
          ),
        ],
      ),
      body: chains.isEmpty
          ? _Empty(onCreate: create, zh: zh)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    zh ? '配置 当前订阅' : 'Profile current',
                    style: AppTextStyle.subheadline.of(context, emphasized: true),
                  ),
                ),
                for (final chain in chains)
                  _ChainCard(
                    chain: chain,
                    report: _reportOf(chain.id),
                    groups: ref.watch(groupsProvider),
                    zh: zh,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                  child: Text(
                    zh
                        ? '已启用的链路位于“🚀 节点选择”中普通服务器旁边。长按链路可删除。'
                        : 'Enabled chains appear beside regular servers in the proxy group. Long-press a chain to delete it.',
                    style: AppTextStyle.footnote.of(context),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate, required this.zh});

  final VoidCallback onCreate;
  final bool zh;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Node(
                  label: zh ? '你' : 'You',
                  sub: zh ? '手机' : 'Phone',
                  icon: GlyphIcon(AppGlyphs.devices),
                  active: false,
                ),
                _Connector(active: false),
                _Node(
                  label: zh ? '入口' : 'Entry',
                  sub: zh ? '选择' : 'Select',
                  icon: GlyphIcon(AppGlyphs.add),
                  active: true,
                ),
                _Connector(active: false),
                _Node(
                  label: zh ? '出口' : 'Exit',
                  sub: zh ? '然后' : 'Then',
                  icon: GlyphIcon(AppGlyphs.add),
                  active: false,
                ),
                _Connector(active: false),
                _Node(
                  label: zh ? '互联网' : 'Internet',
                  sub: '',
                  icon: GlyphIcon(AppGlyphs.globe),
                  active: false,
                ),
              ],
            ),
            const SizedBox(height: 36),
            Text(
              zh
                  ? '连接一台服务器，再通过另一台访问互联网 —— 网站只能看到第二台。'
                  : 'Connect to one server, then reach the internet through '
                      'another — the website only sees the second one.',
              textAlign: TextAlign.center,
              style: AppTextStyle.body.of(context),
            ),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
              ),
              onPressed: onCreate,
              child: Text(zh ? '创建链路' : 'Create chain'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.label,
    required this.sub,
    required this.icon,
    required this.active,
  });

  final String label;
  final String sub;
  final Widget icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceContainerHighest,
            border: active ? Border.all(color: scheme.primary, width: 2) : null,
          ),
          child: IconTheme(
            data: IconThemeData(
              color: active ? scheme.primary : scheme.onSurfaceVariant,
            ),
            child: icon,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyle.footnote.of(context)),
        if (sub.isNotEmpty)
          Text(sub, style: AppTextStyle.caption2.of(context)),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 2,
    color: active
        ? context.colorScheme.primary
        : context.colorScheme.surfaceContainerHighest,
  );
}

class _ChainCard extends ConsumerWidget {
  const _ChainCard({
    required this.chain,
    required this.report,
    required this.groups,
    required this.zh,
  });

  final SavedChain chain;
  final ChainReport? report;
  final List<Group> groups;
  final bool zh;

  /// ReClash's row menu: edit, test, duplicate and delete. A long press on
  /// touch, the menu key on desktop, all handled by ContextMenuRegion.
  List<CommonPopupMenuItem> _menuItems(BuildContext context, WidgetRef ref) {
    final proxy = <Proxy>[];
    for (final group in groups) {
      for (final candidate in group.all) {
        if (candidate.name == chain.name) {
          proxy.add(candidate);
          break;
        }
      }
      if (proxy.isNotEmpty) break;
    }
    return [
      CommonPopupMenuItem(
        glyph: AppGlyphs.edit,
        label: zh ? '编辑' : 'Edit',
        onPressed: () => showChainEditor(context, chain: chain),
      ),
      CommonPopupMenuItem(
        glyph: AppGlyphs.speed,
        label: zh ? '测试' : 'Test',
        onPressed: proxy.isEmpty
            ? null
            : () {
                for (final p in proxy) {
                  ref
                      .read(proxiesActionProvider.notifier)
                      .proxyDelayTest(p, null);
                }
              },
      ),
      CommonPopupMenuItem(
        glyph: AppGlyphs.copy,
        label: zh ? '复制' : 'Duplicate',
        onPressed: () async {
          final copy = SavedChain(
            id: DateTime.now().millisecondsSinceEpoch,
            name: '${chain.name} ${zh ? '副本' : 'copy'}',
            hops: List<String>.from(chain.hops),
            targetGroup: chain.targetGroup,
            enabled: false,
            offered: chain.offered,
          );
          await ref.read(chainsProvider.notifier).upsert(copy);
        },
      ),
      CommonPopupMenuItem(
        danger: true,
        glyph: AppGlyphs.delete,
        label: zh ? '删除' : 'Delete',
        onPressed: () => _confirmDelete(context, ref),
      ),
    ];
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await dialogs.showMessage(
      message: TextSpan(
        text: zh ? '删除链路“${chain.name}”？' : 'Delete chain “${chain.name}”?',
      ),
      title: zh ? '删除链路' : 'Delete chain',
      confirmText: zh ? '删除' : 'Delete',
      destructive: true,
    );
    if (confirmed == true) {
      await ref.read(chainsProvider.notifier).remove(chain.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final route = chain.hops.join(' → ');
    final broken = report?.status == 'broken';
    final warned = broken || (report?.issues.isNotEmpty ?? false);
    final subtitle = !chain.enabled
        ? (zh ? '已关闭' : 'Off')
        : broken
            ? (zh ? '无法工作 · $route' : 'Not working · $route')
            : warned
                ? (zh ? '需注意 · $route' : 'Warning · $route')
                : route;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: generateSection(
        leadingGap: false,
        items: [
          ContextMenuRegion(
            menuItems: _menuItems(context, ref),
            child: ListItem(
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  PairedFlags(chain.hops.first, chain.hops.last, size: 28),
                  if (warned && chain.enabled)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: GlyphIcon(
                        broken ? AppGlyphs.error : AppGlyphs.warning,
                        size: 14,
                        color: broken ? scheme.error : scheme.warning,
                      ),
                    ),
                ],
              ),
              title: Text(
                chain.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: !chain.enabled
                    ? TextStyle(color: scheme.onSurfaceVariant)
                    : null,
              ),
              subtitle: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Switch(
                value: chain.enabled,
                onChanged: (value) async {
                  final updated = SavedChain(
                    id: chain.id,
                    name: chain.name,
                    hops: chain.hops,
                    targetGroup: chain.targetGroup,
                    enabled: value,
                    offered: chain.offered,
                  );
                  await ref.read(chainsProvider.notifier).upsert(updated);
                },
              ),
              onTap: () => showChainEditor(context, chain: chain),
            ),
          ),
        ],
      ),
    );
  }
}
