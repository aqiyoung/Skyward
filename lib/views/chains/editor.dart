import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' show Localizations;
import 'package:material_ui/material_ui.dart';

import 'state.dart';
import 'widgets.dart';

/// Bilingual labels for the chain sheet, independent of the l10n catalog.
extension _ChainL10n on BuildContext {
  bool get _zh => Localizations.localeOf(this).languageCode == 'zh';
  String get cYou => _zh ? '你' : 'You';
  String get cPhone => _zh ? '手机' : 'Phone';
  String get cEntry => _zh ? '入口' : 'Entry';
  String get cMiddle => _zh ? '中转' : 'Middle';
  String get cExit => _zh ? '出口' : 'Exit';
  String get cInternet => _zh ? '互联网' : 'Internet';
  String get cThen => _zh ? '然后' : 'Then';
  String get cSelect => _zh ? '选择' : 'Select';
  String get cNewChain => _zh ? '新建链路' : 'New chain';
  String get cName => _zh ? '名称' : 'Name';
  String get cEntryCaption =>
      _zh ? '入口是设备连接的服务器。' : 'The entry is the server your device connects to.';
  String get cMiddleCaption => _zh
      ? '中转是流量经过的中间服务器。'
      : 'The middle is the server traffic passes through.';
  String get cExitCaption =>
      _zh ? '出口是网站看到的服务器。' : 'The exit is the server the website sees.';
  String get cSearch => _zh ? '城市、国家或名称' : 'City, country or name';
  String get cGroups => _zh ? '组 — 自动选择服务器' : 'Groups — auto-select servers';
  String get cServers => _zh ? '服务器' : 'Servers';
  String get cGroup => _zh ? '组' : 'Group';
  String get cAll => _zh ? '全部' : 'All';
  String get cRemoveMiddle => _zh ? '移除中转服务器' : 'Remove middle server';
  String get cAddMiddle => _zh ? '添加中转服务器' : 'Add middle server';
  String get cShowInServers =>
      _zh ? '在服务器中显示' : 'Show in servers';
  String get cOfferedHint => _zh
      ? '链路会出现在“🚀 节点选择”中普通服务器旁边。当前所选服务器不会改变。'
      : 'The chain appears beside regular servers in the proxy group. The current selection will not change.';
  String cManual(int n) => _zh ? '$n 个中手动' : 'Manual among $n';
  String cFastest(int n) => _zh ? '$n 个中最快' : 'Fastest among $n';
  String cFallback(int n) => _zh ? '$n 个中第一个可用' : 'First available among $n';
  String cBalance(int n) => _zh ? '$n 个轮流' : 'Round-robin among $n';
}

enum _Slot { entry, middle, exit }

/// Opens the sheet that creates or edits a link chain.
Future<void> showChainEditor(BuildContext context, {SavedChain? chain}) {
  return showSheet<void>(
    context: context,
    props: const SheetProps(detents: [0.95]),
    builder: (_) => ChainEditor(chain: chain),
  );
}

class ChainEditor extends ConsumerStatefulWidget {
  const ChainEditor({super.key, this.chain});

  final SavedChain? chain;

  @override
  ConsumerState<ChainEditor> createState() => _ChainEditorState();
}

class _ChainEditorState extends ConsumerState<ChainEditor> {
  late String? _entry;
  late String? _middle;
  late String? _exit;
  late final TextEditingController _name;
  bool _offered = true;
  _Slot _picking = _Slot.entry;

  @override
  void initState() {
    super.initState();
    final chain = widget.chain;
    if (chain == null) {
      _entry = null;
      _middle = null;
      _exit = null;
    } else {
      final hops = chain.hops;
      _entry = hops.isNotEmpty ? hops.first : null;
      _exit = hops.length > 1 ? hops.last : null;
      _middle = hops.length > 2 ? hops[1] : null;
    }
    _name = TextEditingController(text: chain?.name ?? '');
    _offered = chain?.offered ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<String?> get _hops => [
    _entry,
    if (_middle != null) _middle,
    _exit,
  ];

  String get _autoName =>
      _hops.whereType<String>().join(' → ');

  String? _valueOf(_Slot slot) => switch (slot) {
    _Slot.entry => _entry,
    _Slot.middle => _middle,
    _Slot.exit => _exit,
  };

  void _setValue(_Slot slot, String value) {
    setState(() {
      switch (slot) {
        case _Slot.entry:
          _entry = value;
        case _Slot.middle:
          _middle = value;
        case _Slot.exit:
          _exit = value;
      }
      // Advance to the next empty slot, like the official flow.
      if (slot == _Slot.entry && _exit == null) {
        _picking = _Slot.exit;
      } else if (slot == _Slot.exit && _middle == null && _entry != null) {
        // stay on exit; middle is optional
      }
    });
  }

  Future<void> _save() async {
    final hops = _hops.whereType<String>().toList();
    if (hops.length < 2) return;
    final existing = widget.chain;
    final chain = SavedChain(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch,
      name: _name.text.trim().isEmpty ? _autoName : _name.text.trim(),
      hops: hops,
      offered: _offered,
    );
    await ref.read(chainsProvider.notifier).upsert(chain);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final canSave = _entry != null && _exit != null;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(context.cNewChain),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: canSave ? _save : null,
          ),
        ],
      ),
      body: Column(
        children: [
          _Strip(
            entry: _entry,
            middle: _middle,
            exit: _exit,
            picking: _picking,
            onTap: (slot) => setState(() => _picking = slot),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: Text(
              switch (_picking) {
                _Slot.entry => context.cEntryCaption,
                _Slot.middle => context.cMiddleCaption,
                _Slot.exit => context.cExitCaption,
              },
              style: AppTextStyle.body.of(context),
            ),
          ),
          _HopPicker(
            slot: _picking,
            current: _valueOf(_picking),
            onPicked: (name) => _setValue(_picking, name),
          ),
        ],
      ),
    );
  }

  /// The lower "detailed" form shown once both ends are chosen.
  Widget _detailForm(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: RoundFlag(_entry ?? '', size: 32),
          title: Text(context.cEntry),
          subtitle: Text(_entry ?? ''),
        ),
        if (_middle != null)
          ListTile(
            leading: RoundFlag(_middle!, size: 32),
            title: Text(context.cMiddle),
            subtitle: Text(_middle!),
          ),
        ListTile(
          leading: RoundFlag(_exit ?? '', size: 32),
          title: Text(context.cExit),
          subtitle: Text(_exit ?? ''),
        ),
      ],
    );
  }
}

/// Four/five step strip: you -> entry -> [middle] -> exit -> internet.
class _Strip extends StatelessWidget {
  const _Strip({
    required this.entry,
    required this.middle,
    required this.exit,
    required this.picking,
    required this.onTap,
  });

  final String? entry;
  final String? middle;
  final String? exit;
  final _Slot picking;
  final ValueChanged<_Slot> onTap;

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[
      _Step(label: context.cYou, sub: context.cPhone, value: null, active: false, flag: false, onTap: null),
      _Step(label: context.cEntry, sub: context.cSelect, value: entry, active: picking == _Slot.entry, flag: entry != null, onTap: () => onTap(_Slot.entry)),
      if (middle != null)
        _Step(label: context.cMiddle, sub: '', value: middle, active: picking == _Slot.middle, flag: true, onTap: () => onTap(_Slot.middle)),
      _Step(label: context.cExit, sub: context.cSelect, value: exit, active: picking == _Slot.exit, flag: exit != null, onTap: () => onTap(_Slot.exit)),
      _Step(label: context.cInternet, sub: '', value: null, active: false, flag: false, onTap: null),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: context.colorScheme.primaryContainer,
                ),
              ),
            steps[i],
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.sub,
    required this.value,
    required this.active,
    required this.flag,
    required this.onTap,
  });

  final String label;
  final String sub;
  final String? value;
  final bool active;
  final bool flag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final content = value != null && flag
        ? RoundFlag(value!, size: 44)
        : Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              border: active ? Border.all(color: scheme.primary, width: 2) : null,
            ),
            child: Icon(
              label == context.cInternet
                  ? Icons.public
                  : label == context.cYou
                  ? Icons.devices_other
                  : Icons.add,
              color: active ? scheme.primary : scheme.onSurfaceVariant,
            ),
          );
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          const SizedBox(height: 6),
          Text(label, style: AppTextStyle.footnote.of(context)),
          Text(sub, style: AppTextStyle.caption2.of(context)),
        ],
      ),
    );
  }
}

class _HopPicker extends ConsumerStatefulWidget {
  const _HopPicker({
    required this.slot,
    required this.current,
    required this.onPicked,
  });

  final _Slot slot;
  final String? current;
  final ValueChanged<String> onPicked;

  @override
  ConsumerState<_HopPicker> createState() => _HopPickerState();
}

class _HopPickerState extends ConsumerState<_HopPicker> {
  String _query = '';
  String? _country;

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider);
    final q = _query.toLowerCase().trim();

    final seen = <String>{};
    final groups2 = <_Candidate>[];
    final leaves = <_Candidate>[];
    for (final group in groups) {
      if (group.hidden == true) continue;
      if (q.isEmpty || group.name.toLowerCase().contains(q)) {
        groups2.add(
          _Candidate(group.name, group.type, true, group.all.length),
        );
      }
      for (final proxy in group.all) {
        if (!seen.add(proxy.name)) continue;
        if (q.isEmpty || proxy.name.toLowerCase().contains(q)) {
          leaves.add(_Candidate(proxy.name, null, false, 0));
        }
      }
    }

    final counts = <String, int>{};
    for (final c in leaves) {
      final code = geoCountryOfNode(c.name)?.code;
      if (code != null) counts[code] = (counts[code] ?? 0) + 1;
    }
    final countryCodes = counts.keys.toList()..sort();
    final shownLeaves = _country == null
        ? leaves
        : leaves.where((c) => geoCountryOfNode(c.name)?.code == _country).toList();

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: context.cSearch,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (countryCodes.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _CountryChip(
                    label: '${context.cAll} · ${leaves.length}',
                    selected: _country == null,
                    onTap: () => setState(() => _country = null),
                  ),
                  for (final code in countryCodes)
                    _CountryChip(
                      label: '${code.countryFlagEmoji} · ${counts[code]}',
                      selected: _country == code,
                      onTap: () => setState(() => _country = code),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                context.cGroups,
                style: AppTextStyle.subheadline.of(context, emphasized: true),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
              children: [
                for (final c in groups2)
                  _CandidateRow(candidate: c, current: widget.current, onTap: () => widget.onPicked(c.name)),
                if (shownLeaves.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                    child: Text(
                      context.cServers,
                      style: AppTextStyle.subheadline.of(context, emphasized: true),
                    ),
                  ),
                for (final c in shownLeaves)
                  _CandidateRow(candidate: c, current: widget.current, onTap: () => widget.onPicked(c.name)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Candidate {
  const _Candidate(this.name, this.type, this.isGroup, this.count);
  final String name;
  final GroupType? type;
  final bool isGroup;
  final int count;
}

class _CandidateRow extends ConsumerWidget {
  const _CandidateRow({
    required this.candidate,
    required this.current,
    required this.onTap,
  });

  final _Candidate candidate;
  final String? current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delay = candidate.isGroup
        ? null
        : ref.watch(
            delayProvider(proxyName: candidate.name, testUrl: null),
          );
    final subtitle = candidate.isGroup
        ? switch (candidate.type) {
            GroupType.URLTest => context.cFastest(candidate.count),
            GroupType.Fallback => context.cFallback(candidate.count),
            GroupType.LoadBalance => context.cBalance(candidate.count),
            _ => context.cManual(candidate.count),
          }
        : (delay == null ? context.cGroup : '$delay ms');
    return ListTile(
      leading: candidate.isGroup
          ? CircleAvatar(child: Icon(Icons.group_work_outlined, size: 18))
          : RoundFlag(candidate.name, size: 32),
      title: Text(candidate.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle),
      selected: candidate.name == current,
      onTap: onTap,
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: scheme.primaryContainer,
      ),
    );
  }
}
