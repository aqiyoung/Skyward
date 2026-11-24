import 'package:skyward/common/common.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chainsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final chains = ref.watch(chainsProvider);
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return Scaffold(
      appBar: AppBar(
        title: Text(zh ? '链路' : 'Chains'),
        actions: [
          IconButton(
            icon: const GlyphIcon(AppGlyphs.add),
            onPressed: () => showChainEditor(context),
          ),
        ],
      ),
      body: chains.isEmpty
          ? _Empty(onCreate: () => showChainEditor(context), zh: zh)
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
                for (final chain in chains) _ChainCard(chain: chain, zh: zh),
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
  const _ChainCard({required this.chain, required this.zh});

  final SavedChain chain;
  final bool zh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final entry = chain.hops.first;
    final exit = chain.hops.last;
    Future<void> confirmDelete() async {
      final confirmed = await dialogs.showMessage(
        message: TextSpan(
          text: zh ? '删除链路“${chain.name}”？' : 'Delete chain "${chain.name}"?',
        ),
        title: zh ? '删除链路' : 'Delete chain',
        confirmText: zh ? '删除' : 'Delete',
        destructive: true,
      );
      if (confirmed == true) {
        await ref.read(chainsProvider.notifier).remove(chain.id);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: PairedFlags(entry, exit, size: 28),
          title: Text(chain.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            zh
                ? '入口 — · 路径 —'
                : 'Entry — · Path —',
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
          onLongPress: confirmDelete,
        ),
      ),
    );
  }
}
