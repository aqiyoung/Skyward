import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' show Localizations;
import 'package:material_ui/material_ui.dart';

import 'state.dart';


/// Minimal bilingual labels for the chain sheet, independent of the generated
/// l10n catalog so this feature needs no new translation keys.
extension _ChainL10n on BuildContext {
  bool get _zh => Localizations.localeOf(this).languageCode == 'zh';
  String get cYou => _zh ? '你' : 'You';
  String get cPhone => _zh ? '手机' : 'Phone';
  String get cEntry => _zh ? '入口' : 'Entry';
  String get cExit => _zh ? '出口' : 'Exit';
  String get cInternet => _zh ? '互联网' : 'Internet';
  String get cThen => _zh ? '然后' : 'Then';
  String get cSelect => _zh ? '选择' : 'Select';
  String get cNewChain => _zh ? '新建链路' : 'New chain';
  String get cName => _zh ? '名称' : 'Name';
  String get cEntryCaption => _zh ? '入口是设备连接的服务器。' : 'The entry is the server your device connects to.';
  String get cExitCaption => _zh ? '出口是网站看到的服务器。' : 'The exit is the server the website sees.';
  String get cSearch => _zh ? '城市、国家或名称' : 'City, country or name';
  String get cGroups => _zh ? '组 — 自动选择服务器' : 'Groups — auto-select servers';
  String get cGroup => _zh ? '组' : 'Group';
  String get cAll => _zh ? '全部' : 'All';
}

/// Opens the sheet that creates or edits a link chain.
Future<void> showChainEditor(BuildContext context, {SavedChain? chain}) {
  return showSheet<void>(
    context: context,
    props: const SheetProps(detents: [0.92]),
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
  late final List<String?> _hops;
  late final TextEditingController _name;
  String _query = '';
  String? _country;
  bool _offered = true;

  @override
  void initState() {
    super.initState();
    final chain = widget.chain;
    _hops = chain == null
        ? [null, null]
        : [chain.hops.first, chain.hops.last];
    _name = TextEditingController(text: chain?.name ?? '');
    _offered = chain?.offered ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _autoName => _hops.whereType<String>().join(' → ');

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
    final slots = <(String, String)>[
      (context.cYou, context.cPhone),
      (context.cEntry, context.cSelect),
      (context.cExit, context.cThen),
      (context.cInternet, ''),
    ];
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
            onPressed: _hops.every((h) => h != null) ? _save : null,
          ),
        ],
      ),
      body: Column(
        children: [
          _Strip(slots: slots, selected: _selectedSlot, onTap: _pickSlot),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              _captionFor(_selectedSlot),
              style: AppTextStyle.body.of(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _name,
              decoration: InputDecoration(
                hintText: _autoName.isEmpty ? context.cName : _autoName,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          _HopPicker(
            query: _query,
            country: _country,
            onQuery: (q) => setState(() => _query = q),
            onCountry: (c) => setState(() => _country = c),
            onPicked: _pickHop,
          ),
        ],
      ),
    );
  }

  int _selectedSlot = 1;

  void _pickSlot(int index) {
    if (index == 0 || index == 3) return;
    setState(() => _selectedSlot = index);
  }

  String _captionFor(int slot) => slot == 1
      ? context.cEntryCaption
      : context.cExitCaption;

  void _pickHop(String name) {
    setState(() {
      _hops[_selectedSlot - 1] = name;
      if (_selectedSlot == 1 && _hops[1] == null) _selectedSlot = 2;
    });
  }
}

/// The four-step progress strip: you, entry, exit, internet.
class _Strip extends StatelessWidget {
  const _Strip({
    required this.slots,
    required this.selected,
    required this.onTap,
  });

  final List<(String, String)> slots;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < slots.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: i <= selected
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                ),
              ),
            _Step(
              title: slots[i].$1,
              subtitle: slots[i].$2,
              active: i == selected,
              done: i < selected,
              tappable: i == 1 || i == 2,
              onTap: () => onTap(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.done,
    required this.tappable,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool active;
  final bool done;
  final bool tappable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final color = active || done ? scheme.primary : scheme.onSurfaceVariant;
    return GestureDetector(
      onTap: tappable ? onTap : null,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              border: active ? Border.all(color: scheme.primary, width: 2) : null,
            ),
            child: Icon(
              active
                  ? Icons.add
                  : done
                  ? Icons.check
                  : (title == context.cInternet
                      ? Icons.public
                      : Icons.person_outline),
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: AppTextStyle.footnote.of(context)),
          Text(subtitle, style: AppTextStyle.caption2.of(context)),
        ],
      ),
    );
  }
}

class _HopPicker extends ConsumerWidget {
  const _HopPicker({
    required this.query,
    required this.country,
    required this.onQuery,
    required this.onCountry,
    required this.onPicked,
  });

  final String query;
  final String? country;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onCountry;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    final q = query.toLowerCase().trim();

    // Build a catalog of selectable hops: groups plus their leaf proxies.
    final seen = <String>{};
    final candidates = <_Candidate>[];
    for (final group in groups) {
      if (group.hidden == true) continue;
      if (q.isEmpty || group.name.toLowerCase().contains(q)) {
        candidates.add(_Candidate(group.name, group.icon, true));
      }
      for (final proxy in group.all) {
        if (!seen.add(proxy.name)) continue;
        if (q.isEmpty || proxy.name.toLowerCase().contains(q)) {
          candidates.add(_Candidate(proxy.name, '', false));
        }
      }
    }

    final counts = <String, int>{};
    for (final c in candidates) {
      final code = _countryCode(c.name);
      if (code != null) counts[code] = (counts[code] ?? 0) + 1;
    }
    final countries = counts.keys.toList()..sort();
    final shown = country == null
        ? candidates
        : candidates.where((c) => _countryCode(c.name) == country).toList();

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              onChanged: onQuery,
              decoration: InputDecoration(
                hintText: context.cSearch,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (countries.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _CountryChip(
                    label: context.cAll,
                    selected: country == null,
                    onTap: () => onCountry(null),
                  ),
                  for (final code in countries)
                    _CountryChip(
                      label: code.countryFlagEmoji,
                      selected: country == code,
                      onTap: () => onCountry(code),
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
                style: AppTextStyle.subheadline.of(
                  context,
                  emphasized: true,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = shown[index];
                final code = _countryCode(c.name);
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      code == null ? '🌐' : code.countryFlagEmoji,
                    ),
                  ),
                  title: Text(c.name),
                  subtitle: c.isGroup ? Text(context.cGroup) : null,
                  onTap: () => onPicked(c.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String? _countryCode(String name) => geoCountryOfNode(name)?.code;

class _Candidate {
  const _Candidate(this.name, this.icon, this.isGroup);
  final String name;
  final String icon;
  final bool isGroup;
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
