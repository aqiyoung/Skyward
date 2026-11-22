import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/page_large_title.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// ReClash-style chain manager. Each chain is 2-3 hops (entry, optional relay,
/// exit); the core materializes it into cloned virtual nodes plus a selectable
/// group. Saved chains live in [chainsProvider] and are written into the
/// generated config's `chains:` key at setup time.
class ChainsView extends ConsumerStatefulWidget {
  const ChainsView({super.key});

  @override
  ConsumerState<ChainsView> createState() => _ChainsViewState();
}

class _ChainsViewState extends ConsumerState<ChainsView> {
  Future<void> _openEditor({ChainSpec? chain}) async {
    await showSheet<void>(
      context: context,
      props: const SheetProps(detents: [0.9]),
      builder: (_) => ChainEditor(chain: chain),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final chains = ref.watch(chainsProvider).value ?? const [];
    final largeTitle =
        ViewScope.isMobileOf(context) && !context.isInCompactSheet;
    final statusBarTop = MediaQuery.paddingOf(context).top;

    final body = chains.isEmpty
        ? _ChainsEmpty(onCreate: () => _openEditor())
        : ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + context.bottomInset),
            itemCount: chains.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const GlyphIcon(AppGlyphs.add, fill: 1, size: 18),
                    label: Text(l.chainCreate),
                  ),
                );
              }
              final chain = chains[index - 1];
              return _ChainCard(
                chain: chain,
                onEdit: () => _openEditor(chain: chain),
                onDelete: () =>
                    ref.read(chainsProvider.notifier).del(chain.id),
              );
            },
          );

    return CommonScaffold(
      title: l.chainManager,
      largeTitle: largeTitle,
      body: largeTitle
          ? PageLargeTitle(
              title: l.chainManager,
              statusBarTop: statusBarTop,
              body: body,
            )
          : body,
    );
  }
}

/// The empty-state guide with a route strip: you -> entry -> exit -> web,
/// using country flags derived from the example nodes.
class _ChainsEmpty extends StatelessWidget {
  const _ChainsEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: _RouteStrip(
              nodes: [
                _RouteNode.flag('🇷🇺', l.chainEntryRole, l.chainEntry),
                _RouteNode.flag('🇳🇱', l.chainExitRole, l.chainExit),
              ],
              connected: true,
              you: l.chainYou,
              web: l.chainInternet,
            ),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Text(
              l.chainGuideDesc,
              textAlign: TextAlign.center,
              style: AppTextStyle.body.of(context),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onCreate,
            child: Text(l.chainCreate),
          ),
        ],
      ),
    );
  }
}

class _RouteNode {
  const _RouteNode.flag(this.flag, this.label, this.caption)
      : glyph = null;
  const _RouteNode.glyph(this.glyph, this.label, this.caption)
      : flag = null;

  final String? flag;
  final Glyph? glyph;
  final String label;
  final String caption;
}

/// A horizontal chain diagram: you -> [hops] -> web, joined by green segments.
class _RouteStrip extends StatelessWidget {
  const _RouteStrip({
    required this.nodes,
    required this.you,
    required this.web,
    this.connected = false,
    this.activeIndex,
  });

  final List<_RouteNode> nodes;
  final String you;
  final String web;
  final bool connected;
  final int? activeIndex;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final all = <_RouteNode>[
      _RouteNode.glyph(AppGlyphs.account, you, lPhone(context)),
      ...nodes,
      _RouteNode.glyph(AppGlyphs.globe, web, ''),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final cell = constraints.maxWidth / all.length;
      const size = 44.0;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final node in all)
                Expanded(child: _NodeView(node: node, size: size)),
            ],
          ),
          for (var i = 0; i < all.length - 1; i++)
            Positioned(
              left: cell * (i + 0.5) + size / 2 + 4,
              width: math.max(cell - size - 8, 0),
              top: size / 2 - 1.5,
              height: 3,
              child: Container(
                decoration: ShapeDecoration(
                  color: connected || (activeIndex != null && i < activeIndex!)
                      ? cs.primary
                      : cs.surfaceContainerHighest,
                  shape: AppShape.all(2),
                ),
              ),
            ),
        ],
      );
    });
  }

  String lPhone(BuildContext context) =>
      ViewScope.isMobileOf(context)
          ? context.appLocalizations.chainPhone
          : '';
}

class _NodeView extends StatelessWidget {
  const _NodeView({required this.node, required this.size});

  final _RouteNode node;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: ShapeDecoration(
            color: cs.surfaceContainerHigh,
            shape: AppShape.all(size / 2),
          ),
          alignment: Alignment.center,
          child: node.flag != null
              ? Text(node.flag!, style: const TextStyle(fontSize: 26))
              : GlyphIcon(node.glyph!, size: size * 0.5, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text(
          node.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyle.footnote.of(context, emphasized: true),
        ),
        if (node.caption.isNotEmpty)
          Text(
            node.caption,
            style: AppTextStyle.caption1.of(context).copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// The saved-chain row with its route strip and edit/delete actions.
class _ChainCard extends StatelessWidget {
  const _ChainCard({
    required this.chain,
    required this.onEdit,
    required this.onDelete,
  });

  final ChainSpec chain;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final flagOf = <String, String>{
      for (final h in chain.hops) h: GroupIconSource.flagOf(h),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: cs.surfaceContainerLow,
        shape: AppShape.all(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlyphIcon(AppGlyphs.link, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(chain.name,
                    style: AppTextStyle.body.of(context, emphasized: true)),
              ),
              IconButton(
                tooltip: context.appLocalizations.chainEdit,
                onPressed: onEdit,
                icon: const GlyphIcon(AppGlyphs.edit, size: 18),
              ),
              IconButton(
                tooltip: context.appLocalizations.chainDelete,
                onPressed: onDelete,
                icon: GlyphIcon(AppGlyphs.delete, size: 18, color: cs.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RouteStrip(
            nodes: [
              for (final h in chain.hops)
                _RouteNode.flag(
                  flagOf[h]!.isEmpty ? '🌐' : flagOf[h]!,
                  h,
                  h == chain.hops.first
                      ? context.appLocalizations.chainEntryRole
                      : h == chain.hops.last
                          ? context.appLocalizations.chainExitRole
                          : context.appLocalizations.chainMiddleRole,
                ),
            ],
            you: context.appLocalizations.chainYou,
            web: context.appLocalizations.chainInternet,
            connected: true,
          ),
        ],
      ),
    );
  }
}

/// Chain creation/editing sheet: when no slot is being picked it shows the
/// assembled route plus the ready/full edit view (name, relay, shown toggle).
class ChainEditor extends ConsumerStatefulWidget {
  const ChainEditor({super.key, this.chain});

  final ChainSpec? chain;

  @override
  ConsumerState<ChainEditor> createState() => _ChainEditorState();
}

class _ChainEditorState extends ConsumerState<ChainEditor> {
  late String? _entry;
  late String? _middle;
  late String? _exit;
  late bool _hasMiddle;
  late bool _offered;
  late final TextEditingController _name;
  int? _picking; // 0 entry, 1 middle, 2 exit; null = ready view

  @override
  void initState() {
    super.initState();
    final c = widget.chain;
    final hops = c?.hops ?? const <String>[];
    _entry = hops.isNotEmpty ? hops[0] : null;
    _exit = hops.length >= 2 ? hops.last : null;
    _middle = hops.length >= 3 ? hops[1] : null;
    _hasMiddle = hops.length >= 3;
    _offered = c?.offered ?? true;
    _name = TextEditingController(text: c?.name ?? '');
    _picking = c == null ? 0 : null;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<String?> get _slots => [
        _entry,
        if (_hasMiddle) _middle,
        _exit,
      ];

  bool get _complete => _slots.every((s) => s != null && s.isNotEmpty);

  Future<void> _save() async {
    if (!_complete) return;
    final hops = _slots.cast<String>();
    final name = _name.text.trim().isEmpty ? hops.join(' → ') : _name.text.trim();
    final id = widget.chain?.id ?? DateTime.now().microsecondsSinceEpoch;
    await ref.read(chainsProvider.notifier).put(ChainSpec(
          id: id,
          name: name,
          hops: hops,
          offered: _offered,
          targetGroup: widget.chain?.targetGroup,
          heal: widget.chain?.heal ?? false,
        ));
    if (mounted) Navigator.of(context).pop();
  }

  void _fill(String name) {
    setState(() {
      if (_picking == 0) _entry = name;
      if (_picking == 1) _middle = name;
      if (_picking == 2) _exit = name;
      final next = _slots.indexWhere((s) => s == null || s.isEmpty);
      _picking = next == -1 ? null : next;
    });
  }

  void _toggleMiddle() {
    setState(() {
      _hasMiddle = !_hasMiddle;
      if (_hasMiddle) {
        _picking = 1;
      } else {
        _middle = null;
        _picking = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final slots = _slots;
    final nodes = <_RouteNode>[
      for (var i = 0; i < slots.length; i++)
        _RouteNode.flag(
          flagsFor(slots[i]),
          slots[i] ?? _role(i, slots.length),
          _caption(i, slots),
        ),
    ];

    return CommonScaffold(
      title: widget.chain == null ? l.chainNew : l.chainManager,
      confirmationAction: IconButtonData(
        glyph: AppGlyphs.check,
        tooltip: l.chainSave,
        onPressed: _complete ? _save : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _RouteStrip(
              nodes: nodes,
              you: l.chainYou,
              web: l.chainInternet,
              activeIndex: _picking,
              connected: _picking == null,
            ),
          ),
          Expanded(
            child: _picking == null
                ? _ReadyBody(
                    entry: _entry,
                    middle: _middle,
                    exit: _exit,
                    hasMiddle: _hasMiddle,
                    name: _name,
                    offered: _offered,
                    onOffered: (v) => setState(() => _offered = v),
                    onPick: (i) => setState(() => _picking = i),
                    onToggleMiddle: _toggleMiddle,
                  )
                : _HopPicker(
                    slot: _picking!,
                    current: slots[_picking!],
                    onPicked: _fill,
                  ),
          ),
        ],
      ),
    );
  }

  String _role(int i, int count) {
    final l = currentAppLocalizations;
    if (i == 0) return l.chainEntryRole;
    if (i == count - 1) return l.chainExitRole;
    return l.chainMiddleRole;
  }

  String _caption(int i, List<String?> slots) {
    final l = currentAppLocalizations;
    if (_picking == i) return l.chainPick;
    final filled = slots[i] != null && slots[i]!.isNotEmpty;
    if (!filled && i > 0 && slots[i - 1] != null) return l.chainThen;
    return _role(i, slots.length);
  }

  String flagsFor(String? name) {
    if (name == null || name.isEmpty) return '＋';
    final flag = GroupIconSource.flagOf(name);
    return flag.isEmpty ? '🌐' : flag;
  }
}

/// The picker body for one hop: hint, search, country chips, grouped nodes.
class _HopPicker extends ConsumerStatefulWidget {
  const _HopPicker({
    required this.slot,
    required this.current,
    required this.onPicked,
  });

  final int slot;
  final String? current;
  final ValueChanged<String> onPicked;

  @override
  ConsumerState<_HopPicker> createState() => _HopPickerState();
}

class _HopPickerState extends ConsumerState<_HopPicker> {
  final _search = TextEditingController();
  String? _country;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final groups = ref.watch(groupsProvider);
    final candidates = <({String name, String flag, String? code, bool isGroup})>[];
    final counts = <String, int>{};
    final seen = <String>{};
    for (final g in groups) {
      if (g.hidden == true) continue;
      candidates.add((
        name: g.name,
        flag: GroupIconSource.flagOf(g.name),
        code: _codeOf(g.name),
        isGroup: true,
      ));
      for (final p in g.all) {
        if (!seen.add(p.name)) continue;
        final code = _codeOf(p.name);
        if (code != null) counts[code] = (counts[code] ?? 0) + 1;
        candidates.add((
          name: p.name,
          flag: GroupIconSource.flagOf(p.name),
          code: code,
          isGroup: false,
        ));
      }
    }
    final countries = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final q = _search.text.toLowerCase();
    final groupItems = candidates
        .where((c) => c.isGroup)
        .where((c) =>
            (_country == null || c.code == _country) &&
            (q.isEmpty || c.name.toLowerCase().contains(q)))
        .toList();
    final leafItems = candidates
        .where((c) => !c.isGroup)
        .where((c) =>
            (_country == null || c.code == _country) &&
            (q.isEmpty || c.name.toLowerCase().contains(q)))
        .toList();
    final hint = widget.slot == 0
        ? l.chainEntryHint2
        : widget.slot == 1
            ? l.chainMiddleHint
            : l.chainExitHint2;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(hint,
            style: AppTextStyle.subheadline
                .of(context)
                .copyWith(color: context.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: l.chainSearchHint,
            prefixIcon: const GlyphIcon(AppGlyphs.search, size: 20),
            filled: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (countries.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: countries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final code = countries[i];
                final selected = _country == code;
                return FilterChip(
                  label: Text(
                      '${_flagOfCode(code)} ${code.toUpperCase()} · ${counts[code]}'),
                  selected: selected,
                  onSelected: (_) => setState(
                      () => _country = selected ? null : code),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        _SectionHeader(l.chainGroupsSection),
        for (final item in groupItems)
          _HopRow(
            name: item.name,
            flag: item.flag,
            subtitle: _groupSubtitle(context, item.name),
            selected: widget.current == item.name,
            onTap: () => widget.onPicked(item.name),
          ),
        if (leafItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SectionHeader(l.chainServers),
          for (final item in leafItems)
            _HopRow(
              name: item.name,
              flag: item.flag,
              subtitle: currentAppLocalizations.tsNode,
              selected: widget.current == item.name,
              onTap: () => widget.onPicked(item.name),
            ),
        ],
      ],
    );
  }

  String? _codeOf(String name) {
    final flag = GroupIconSource.flagOf(name);
    if (flag.isEmpty) return null;
    // flag emoji -> ISO code (regional indicator pair)
    final cps = flag.runes.toList();
    if (cps.length != 2) return null;
    return String.fromCharCodes([
      cps[0] - 0x1F1E6 + 0x61,
      cps[1] - 0x1F1E6 + 0x61,
    ]);
  }

  String _flagOfCode(String code) {
    if (code.length != 2) return '🌐';
    return String.fromCharCodes([
      code.codeUnitAt(0) - 0x61 + 0x1F1E6,
      code.codeUnitAt(1) - 0x61 + 0x1F1E6,
    ]);
  }

  String _groupSubtitle(BuildContext context, String name) {
    final g = ref.read(groupsProvider).getGroup(name);
    final n = g?.all.length ?? 0;
    final l = currentAppLocalizations;
    return switch (g?.type) {
      GroupType.URLTest => l.chainGroupFastest(n),
      GroupType.Fallback => l.chainGroupFallback(n),
      GroupType.LoadBalance => l.chainGroupBalance(n),
      _ => l.chainGroupManual(n),
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            style: AppTextStyle.subheadline.of(context, emphasized: true)),
      );
}

class _HopRow extends StatelessWidget {
  const _HopRow({
    required this.name,
    required this.flag,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String flag;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return ListTile(
      shape: AppShape.all(12),
      tileColor: selected ? cs.primaryContainer : null,
      leading: Container(
        width: 32,
        height: 32,
        decoration: ShapeDecoration(
          color: cs.surfaceContainerHigh,
          shape: AppShape.all(16),
        ),
        alignment: Alignment.center,
        child: Text(flag.isEmpty ? '🌐' : flag,
            style: const TextStyle(fontSize: 18)),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1),
      onTap: onTap,
    );
  }
}

/// The assembled-chain view: editable route rows, add/remove relay, name and
/// the "show in servers" toggle.
class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.entry,
    required this.middle,
    required this.exit,
    required this.hasMiddle,
    required this.name,
    required this.offered,
    required this.onOffered,
    required this.onPick,
    required this.onToggleMiddle,
  });

  final String? entry;
  final String? middle;
  final String? exit;
  final bool hasMiddle;
  final TextEditingController name;
  final bool offered;
  final ValueChanged<bool> onOffered;
  final ValueChanged<int> onPick;
  final VoidCallback onToggleMiddle;

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final rows = <(String, String?, int)>[
      (l.chainEntryRole, entry, 0),
      if (hasMiddle) (l.chainMiddleRole, middle, 1),
      (l.chainExitRole, exit, 2),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Container(
          decoration: ShapeDecoration(
            color: context.colorScheme.surfaceContainerLow,
            shape: AppShape.all(16),
          ),
          child: Column(
            children: [
              for (final (role, value, idx) in rows)
                ListTile(
                  title: Text(role),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(value ?? l.chainPick,
                          style: AppTextStyle.body
                              .of(context)
                              .copyWith(color: context.colorScheme.primary)),
                      const SizedBox(width: 4),
                      const GlyphIcon(AppGlyphs.chevronForward, size: 18),
                    ],
                  ),
                  onTap: () => onPick(idx),
                ),
              ListTile(
                leading: GlyphIcon(
                  hasMiddle ? AppGlyphs.remove : AppGlyphs.add,
                  size: 20,
                  color: hasMiddle ? null : context.colorScheme.primary,
                ),
                title: Text(
                  hasMiddle ? l.chainRemoveMiddle : l.chainAddMiddle,
                  style: hasMiddle
                      ? null
                      : TextStyle(color: context.colorScheme.primary),
                ),
                onTap: onToggleMiddle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: ShapeDecoration(
            color: context.colorScheme.surfaceContainerLow,
            shape: AppShape.all(16),
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(l.chainName),
                trailing: SizedBox(
                  width: 200,
                  child: TextField(
                    controller: name,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(isDense: true),
                  ),
                ),
              ),
              SwitchListTile(
                title: Text(l.chainShowInServers),
                value: offered,
                onChanged: onOffered,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l.chainShowDesc,
          style: AppTextStyle.footnote
              .of(context)
              .copyWith(color: context.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
