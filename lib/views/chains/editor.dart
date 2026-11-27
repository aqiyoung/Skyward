import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/views/dashboard/widgets/card.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  String get cSelect => _zh ? '选择' : 'Choose';
  String get cNewChain => _zh ? '新建链路' : 'New chain';
  String get cSave => _zh ? '保存' : 'Save';
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
  String get cShowInServers => _zh ? '在服务器中显示' : 'Show among servers';
  String get cOfferedHint => _zh
      ? '链路会出现在“🚀 节点选择”中普通服务器旁边。当前所选服务器不会改变。'
      : 'The chain appears beside regular servers in the proxy group. The current selection will not change.';
  String get cDeleteChain => _zh ? '删除链路' : 'Delete chain';
  String get cUdpTitle =>
      _zh ? '通话和游戏无法通过此链路' : 'Calls and games won’t pass through this chain';
  String cUdpBody(String entry) => _zh
      ? '入口“$entry”不转发 UDP，而通话、游戏和部分视频需要它。网站、即时通讯和 YouTube 可以正常使用。'
      : 'The entry “$entry” doesn’t carry UDP, which calls, games and some video need. Sites, messengers and YouTube will work.';
  String get cUdpMissingTitle =>
      _zh ? '出口无法在此入口下工作' : 'The exit won’t work behind this entry';
  String cUdpMissingBody(String entry, String exit) => _zh
      ? '“$exit”需要 UDP，而入口“$entry”仅转发 TCP。'
      : '“$exit” needs UDP, and the entry “$entry” carries only TCP.';
  String get cPickUdpEntry => _zh ? '选择支持 UDP 的入口' : 'Pick an entry with UDP';
  String get cChooseAnother => _zh ? '更换服务器' : 'Choose another';
  String get cNotInSubscription => _zh ? '不在当前订阅中' : 'Not in subscription';
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
    props: const SheetProps(detents: [0.9]),
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
  late bool _hasMiddle;
  late final TextEditingController _name;
  late bool _offered;
  _Slot? _picking;
  bool _changed = false;
  bool _saving = false;
  ChainInspection? _inspection;
  ChainReport? _report;

  @override
  void initState() {
    super.initState();
    final chain = widget.chain;
    if (chain == null) {
      _entry = null;
      _middle = null;
      _exit = null;
      _hasMiddle = false;
      _picking = _Slot.entry;
    } else {
      final hops = chain.hops;
      _entry = hops.isNotEmpty ? hops.first : null;
      _exit = hops.length > 1 ? hops.last : null;
      _middle = hops.length > 2 ? hops[1] : null;
      _hasMiddle = hops.length > 2;
      _picking = null;
    }
    _name = TextEditingController(text: chain?.name ?? '');
    _offered = chain?.offered ?? true;
    Future.microtask(_refreshCore);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _refreshCore() async {
    await Future.wait([_inspect(), _loadReport()]);
  }

  /// The complete hop list, or null while a slot is empty.
  List<String>? get _completeHops {
    if (_entry == null || _exit == null) return null;
    if (_hasMiddle && _middle == null) return null;
    return [_entry!, if (_hasMiddle) _middle!, _exit!];
  }

  List<String?> get _hops => [_entry, if (_hasMiddle) _middle, _exit];

  String get _autoName => _hops.whereType<String>().join(' → ');

  String? _valueOf(_Slot slot) => switch (slot) {
    _Slot.entry => _entry,
    _Slot.middle => _middle,
    _Slot.exit => _exit,
  };

  /// Problems from the live inspection while editing, from the saved report
  /// otherwise -- the same split ReClash uses so saved broken chains show the
  /// state the core actually applied.
  List<ChainIssue> get _issues {
    if (_changed || _report == null) {
      return _inspection?.issues ?? const [];
    }
    return _report!.issues;
  }

  Future<void> _inspect() async {
    final hops = _completeHops;
    if (hops == null) {
      if (mounted) setState(() => _inspection = null);
      return;
    }
    final result = await ref
        .read(coreHandlerProvider)
        .inspectChain(InspectChainParams(hops: hops));
    if (mounted) setState(() => _inspection = result);
  }

  Future<void> _loadReport() async {
    final chain = widget.chain;
    if (chain == null) return;
    final reports = await ref.read(coreHandlerProvider).getChainReport();
    ChainReport? found;
    for (final report in reports) {
      if (report.id == chain.id) {
        found = report;
        break;
      }
    }
    if (mounted) setState(() => _report = found);
  }

  void _pick(_Slot slot) => setState(() => _picking = slot);

  void _fill(_Slot slot, String value) {
    setState(() {
      switch (slot) {
        case _Slot.entry:
          _entry = value;
        case _Slot.middle:
          _middle = value;
        case _Slot.exit:
          _exit = value;
      }
      _changed = true;
      _inspection = null;
      // Advance to the first empty slot, or drop into the detail view.
      if (_entry == null) {
        _picking = _Slot.entry;
      } else if (_hasMiddle && _middle == null) {
        _picking = _Slot.middle;
      } else if (_exit == null) {
        _picking = _Slot.exit;
      } else {
        _picking = null;
      }
    });
    unawaited(_inspect());
  }

  void _addMiddle() => setState(() {
    _hasMiddle = true;
    _middle = null;
    _changed = true;
    _picking = _Slot.middle;
  });

  void _removeMiddle() => setState(() {
    _hasMiddle = false;
    _middle = null;
    _changed = true;
  });

  Future<void> _delete() async {
    final chain = widget.chain;
    if (chain == null) return;
    final confirmed = await dialogs.showMessage(
      message: TextSpan(
        text: context._zh
            ? '删除链路“${chain.name}”？'
            : 'Delete chain “${chain.name}”?',
      ),
      title: context.cDeleteChain,
      confirmText: context.cDeleteChain,
      destructive: true,
    );
    if (confirmed == true && mounted) {
      await ref.read(chainsProvider.notifier).remove(chain.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    final hops = _completeHops;
    if (hops == null || _saving) return;
    setState(() => _saving = true);
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

  bool _isError(ChainIssue issue) => const {
    'missingHop',
    'unchainableHop',
    'loop',
    'emptyExit',
    'udpTransportMissing',
    'nameClash',
  }.contains(issue.code);

  void _act(ChainIssue issue) {
    if (issue.code == 'udpLost' || issue.code == 'udpTransportMissing') {
      _pick(_Slot.entry);
      return;
    }
    final slot = switch (issue.hop) {
      <= 0 => _Slot.entry,
      >= 3 => _Slot.exit,
      1 => _Slot.middle,
      _ => _Slot.exit,
    };
    _pick(slot);
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        _completeHops != null &&
        !_issues.any(_isError) &&
        (widget.chain == null || _changed);
    final title = widget.chain == null
        ? context.cNewChain
        : (_name.text.trim().isEmpty ? _autoName : _name.text.trim());
    return CommonScaffold(
      title: title,
      isLoading: _saving,
      confirmationAction: IconButtonData(
        glyph: AppGlyphs.check,
        tooltip: context.cSave,
        onPressed: canSave ? _save : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              context.contentTopPadding + 8,
              16,
              8,
            ),
            child: _Strip(
              entry: _entry,
              middle: _hasMiddle ? _middle : null,
              exit: _exit,
              hasMiddle: _hasMiddle,
              picking: _picking,
              onTap: _pick,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: switch (_picking) {
              final slot? => _HopPicker(
                key: ValueKey(slot),
                slot: slot,
                hops: [
                  _entry ?? '',
                  if (_hasMiddle) _middle ?? '',
                  _exit ?? '',
                ],
                current: _valueOf(slot),
                onPicked: (name) => _fill(slot, name),
              ),
              null => _ReadyBody(
                entry: _entry,
                middle: _middle,
                exit: _exit,
                hasMiddle: _hasMiddle,
                issues: _issues,
                name: _name.text.trim().isEmpty ? _autoName : _name.text.trim(),
                offered: _offered,
                onPick: _pick,
                onAddMiddle: _addMiddle,
                onRemoveMiddle: _removeMiddle,
                onName: (value) => setState(() => _name.text = value ?? ''),
                onOffered: (value) => setState(() {
                  _offered = value;
                  _changed = true;
                }),
                onIssue: _act,
                onDelete: widget.chain == null ? null : _delete,
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// The normal detail view: hops, problems, name and the offered switch.
class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.entry,
    required this.middle,
    required this.exit,
    required this.hasMiddle,
    required this.issues,
    required this.name,
    required this.offered,
    required this.onPick,
    required this.onAddMiddle,
    required this.onRemoveMiddle,
    required this.onName,
    required this.onOffered,
    required this.onIssue,
    required this.onDelete,
  });

  final String? entry;
  final String? middle;
  final String? exit;
  final bool hasMiddle;
  final List<ChainIssue> issues;
  final String name;
  final bool offered;
  final ValueChanged<_Slot> onPick;
  final VoidCallback onAddMiddle;
  final VoidCallback onRemoveMiddle;
  final ValueChanged<String?> onName;
  final ValueChanged<bool> onOffered;
  final ValueChanged<ChainIssue> onIssue;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + context.bottomInset),
      children: [
        generateSection(
          leadingGap: false,
          items: [
            _RouteRow(
              role: context.cEntry,
              value: entry,
              onTap: () => onPick(_Slot.entry),
            ),
            if (hasMiddle)
              _RouteRow(
                role: context.cMiddle,
                value: middle,
                onTap: () => onPick(_Slot.middle),
              ),
            _RouteRow(
              role: context.cExit,
              value: exit,
              onTap: () => onPick(_Slot.exit),
            ),
            if (hasMiddle)
              ListItem(
                leading: SizedBox(
                  width: 28,
                  child: GlyphIcon(AppGlyphs.remove, size: 20),
                ),
                title: Text(context.cRemoveMiddle),
                onTap: onRemoveMiddle,
              )
            else
              ListItem(
                leading: SizedBox(
                  width: 28,
                  child: GlyphIcon(
                    AppGlyphs.add,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
                title: Text(
                  context.cAddMiddle,
                  style: TextStyle(color: scheme.primary),
                ),
                onTap: onAddMiddle,
              ),
          ],
        ),
        if (issues.isNotEmpty) const SizedBox(height: 12),
        for (final issue in issues.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _IssueCard(
              issue: issue,
              entry: entry ?? '',
              exit: exit ?? '',
              onAction: () => onIssue(issue),
            ),
          ),
        generateSection(
          items: [
            ListItem.input(
              title: Text(context.cName),
              dialogTitle: context.cName,
              value: name,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: EmojiText(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subheadline
                          .of(context)
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GlyphIcon(
                    AppGlyphs.chevronForward,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              onChanged: onName,
            ),
            ListItem.toggle(
              title: Text(context.cShowInServers),
              value: offered,
              onChanged: onOffered,
            ),
          ],
          footer: zh
              ? '链路会出现在“🚀 节点选择”中普通服务器旁边。当前所选服务器不会改变。'
              : 'The chain appears beside regular servers in the proxy group. The current selection will not change.',
        ),
        if (onDelete != null)
          generateSection(
            items: [
              ListItem(
                title: Text(
                  context.cDeleteChain,
                  style: TextStyle(color: scheme.error),
                ),
                onTap: onDelete,
              ),
            ],
          ),
      ],
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.role,
    required this.value,
    required this.onTap,
  });

  final String role;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return ListItem(
      leading: RoundFlag(value ?? '', size: 28),
      title: Text(role),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: EmojiText(
              value ??
                  (Localizations.localeOf(context).languageCode == 'zh'
                      ? '选择'
                      : 'Choose'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subheadline
                  .of(context)
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 4),
          GlyphIcon(
            AppGlyphs.chevronForward,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.issue,
    required this.entry,
    required this.exit,
    required this.onAction,
  });

  final ChainIssue issue;
  final String entry;
  final String exit;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final scheme = context.colorScheme;
    final error = const {
      'missingHop',
      'unchainableHop',
      'loop',
      'emptyExit',
      'udpTransportMissing',
      'nameClash',
    }.contains(issue.code);
    final fill = error ? scheme.errorContainer : scheme.warningContainer;
    final ink = error ? scheme.onErrorContainer : scheme.onWarningContainer;
    final glyph = error ? AppGlyphs.error : AppGlyphs.warning;
    final String title;
    final String body;
    if (issue.code == 'udpLost') {
      title = zh
          ? '通话和游戏无法通过此链路'
          : 'Calls and games won’t pass through this chain';
      body = zh
          ? '入口“$entry”不转发 UDP，而通话、游戏和部分视频需要它。网站、即时通讯和 YouTube 可以正常使用。'
          : 'The entry “$entry” doesn’t carry UDP, which calls, games and some video need. Sites, messengers and YouTube will work.';
    } else if (issue.code == 'udpTransportMissing') {
      title = zh ? '出口无法在此入口下工作' : 'The exit won’t work behind this entry';
      body = zh
          ? '“$exit”需要 UDP，而入口“$entry”仅转发 TCP。'
          : '“$exit” needs UDP, and the entry “$entry” carries only TCP.';
    } else {
      title = zh ? '此链路可能无法正常工作' : 'This chain may not work';
      body = issue.code;
    }
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: fill,
        shape: AppShape.all(AppCorner.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlyphIcon(glyph, size: 22, color: ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.subheadline
                        .of(context, emphasized: true)
                        .copyWith(color: ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTextStyle.footnote
                        .of(context)
                        .copyWith(color: ink.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 8),
                  DashboardBlock(
                    radius: AppCorner.full,
                    color: ink.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    onTap: onAction,
                    child: Text(
                      issue.code == 'udpLost' ||
                              issue.code == 'udpTransportMissing'
                          ? (zh ? '选择支持 UDP 的入口' : 'Pick an entry with UDP')
                          : (zh ? '更换服务器' : 'Choose another'),
                      style: AppTextStyle.footnote
                          .of(context, emphasized: true)
                          .copyWith(color: ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Four/five step strip: you -> entry -> [middle] -> exit -> internet.
class _Strip extends ConsumerWidget {
  const _Strip({
    required this.entry,
    required this.middle,
    required this.exit,
    required this.hasMiddle,
    required this.picking,
    required this.onTap,
  });

  final String? entry;
  final String? middle;
  final String? exit;
  final bool hasMiddle;
  final _Slot? picking;
  final ValueChanged<_Slot> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryDelay = entry == null
        ? null
        : ref.watch(delayProvider(proxyName: entry!, testUrl: null));
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final nodes = <_Node>[
      _Node(
        label: zh ? '你' : 'You',
        caption: zh ? '手机' : 'Phone',
        glyph: AppGlyphs.devices,
        active: false,
        filled: false,
      ),
      _Node(
        label: entry ?? (zh ? '入口' : 'Entry'),
        caption: entry == null
            ? (zh ? '选择' : 'Choose')
            : entryDelay == null
            ? (zh ? '入口' : 'Entry')
            : '${zh ? '入口' : 'Entry'} · $entryDelay ms',
        value: entry,
        active: picking == _Slot.entry,
        filled: entry != null,
        onTap: () => onTap(_Slot.entry),
      ),
      if (hasMiddle)
        _Node(
          label: middle ?? (zh ? '中转' : 'Middle'),
          caption: middle == null
              ? (zh ? '选择' : 'Choose')
              : (zh ? '中转' : 'Middle'),
          value: middle,
          active: picking == _Slot.middle,
          filled: middle != null,
          onTap: () => onTap(_Slot.middle),
        ),
      _Node(
        label: exit ?? (zh ? '出口' : 'Exit'),
        caption: exit == null ? (zh ? '选择' : 'Choose') : (zh ? '出口' : 'Exit'),
        value: exit,
        active: picking == _Slot.exit,
        filled: exit != null,
        onTap: () => onTap(_Slot.exit),
      ),
      _Node(
        label: zh ? '互联网' : 'Internet',
        caption: '',
        glyph: AppGlyphs.proxies,
        active: false,
        filled: false,
      ),
    ];
    final colors = DashboardColors.of(context);
    final scheme = context.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = constraints.maxWidth / nodes.length;
        const gap = 6.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final node in nodes)
                  Expanded(child: _NodeView(node: node)),
              ],
            ),
            for (var i = 0; i < nodes.length - 1; i++)
              Positioned(
                left: cell * (i + 0.5) + 22 + gap,
                width: cell > 44 + gap * 2 ? cell - 44 - gap * 2 : 0,
                top: 21,
                height: 3,
                child: Container(
                  decoration: ShapeDecoration(
                    color: i == 0 && entryDelay != null
                        ? scheme.delayColor(entryDelay) ?? colors.track
                        : colors.track,
                    shape: AppShape.full,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Node {
  const _Node({
    required this.label,
    required this.caption,
    this.value,
    this.glyph,
    required this.active,
    required this.filled,
    this.onTap,
  });

  final String label;
  final String caption;
  final String? value;
  final Glyph? glyph;
  final bool active;
  final bool filled;
  final VoidCallback? onTap;
}

class _NodeView extends StatelessWidget {
  const _NodeView({required this.node});

  final _Node node;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final colors = DashboardColors.of(context);
    final Widget content;
    if (node.filled && node.value != null) {
      content = RoundFlag(node.value!, size: 44);
    } else if (node.glyph != null) {
      content = Container(
        width: 44,
        height: 44,
        decoration: ShapeDecoration(
          color: colors.tone2,
          shape: AppShape.circle,
        ),
        child: GlyphIcon(node.glyph!, size: 22, color: scheme.onSurfaceVariant),
      );
    } else {
      content = Container(
        width: 44,
        height: 44,
        decoration: ShapeDecoration(
          color: node.active ? scheme.primaryContainer : colors.tone2,
          shape: AppShape.circle,
        ),
        child: GlyphIcon(
          AppGlyphs.add,
          size: 22,
          color: node.active ? scheme.primary : scheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      children: [
        Semantics(
          button: node.onTap != null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: node.onTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: node.active
                  ? ShapeDecoration(
                      shape: CircleBorder(
                        side: BorderSide(color: scheme.primary, width: 2.5),
                      ),
                    )
                  : null,
              child: Center(child: content),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          node.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.footnote
              .of(context, emphasized: true)
              .copyWith(color: node.active ? scheme.primary : null),
        ),
        Text(
          node.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DashboardText.label(context),
        ),
      ],
    );
  }
}

class _HopPicker extends ConsumerStatefulWidget {
  const _HopPicker({
    super.key,
    required this.slot,
    required this.hops,
    required this.current,
    required this.onPicked,
  });

  final _Slot slot;

  /// The chain's hops with the current slot left empty, used to ask the core
  /// which candidates can legally fill it.
  final List<String> hops;
  final String? current;
  final ValueChanged<String> onPicked;

  @override
  ConsumerState<_HopPicker> createState() => _HopPickerState();
}

class _HopPickerState extends ConsumerState<_HopPicker> {
  String _query = '';
  String? _country;
  Map<String, String> _blocked = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_inspectSlot());
  }

  @override
  void didUpdateWidget(covariant _HopPicker old) {
    super.didUpdateWidget(old);
    if (old.slot != widget.slot || old.hops.join() != widget.hops.join()) {
      unawaited(_inspectSlot());
    }
  }

  /// Ask the core to check each candidate in this slot. Blocked ones are
  /// marked with a reason instead of looking like plain, tappable servers.
  Future<void> _inspectSlot() async {
    final result = await ref
        .read(coreHandlerProvider)
        .inspectChain(
          InspectChainParams(hops: widget.hops, slot: widget.slot.index),
        );
    if (mounted) setState(() => _blocked = result.blocked);
  }

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
        groups2.add(_Candidate(group.name, group.type, true, group.all.length));
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
        : leaves
              .where((c) => geoCountryOfNode(c.name)?.code == _country)
              .toList();

    final caption = switch (widget.slot) {
      _Slot.entry => context.cEntryCaption,
      _Slot.middle => context.cMiddleCaption,
      _Slot.exit => context.cExitCaption,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Text(
            caption,
            style: AppTextStyle.subheadline
                .of(context)
                .copyWith(color: context.colorScheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: context.cSearch,
              prefixIcon: const GlyphIcon(AppGlyphs.search),
              border: AppShape.input,
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
                _CandidateRow(
                  candidate: c,
                  current: widget.current,
                  reason: _blocked[c.name],
                  onTap: () => widget.onPicked(c.name),
                ),
              if (shownLeaves.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                  child: Text(
                    context.cServers,
                    style: AppTextStyle.subheadline.of(
                      context,
                      emphasized: true,
                    ),
                  ),
                ),
              for (final c in shownLeaves)
                _CandidateRow(
                  candidate: c,
                  current: widget.current,
                  reason: _blocked[c.name],
                  onTap: () => widget.onPicked(c.name),
                ),
            ],
          ),
        ),
      ],
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
    this.reason,
  });

  final _Candidate candidate;
  final String? current;
  final VoidCallback onTap;

  /// The core's issue code for why this candidate cannot fill the slot, e.g.
  /// `loop` for a server list itself. Null means it is a legal choice.
  final String? reason;

  String _reasonText(BuildContext context, String code) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return switch (code) {
      'loop' =>
        zh ? '不可用：这就是服务器列表本身' : 'Unavailable: it is the server list itself',
      'udpTransportMissing' =>
        zh
            ? '不可用：需要 UDP，而入口不转发'
            : 'Unavailable: needs UDP, which the entry does not carry',
      'emptyExit' =>
        zh ? '不可用：组中没有服务器' : 'Unavailable: no servers in the group',
      'providerPending' =>
        zh
            ? '不可用：其列表尚不支持链路'
            : 'Unavailable: its list does not support chains yet',
      _ => zh ? '不可用：链路无法经过它' : 'Unavailable: a chain cannot pass through it',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delay = candidate.isGroup
        ? null
        : ref.watch(delayProvider(proxyName: candidate.name, testUrl: null));
    final subtitle = reason != null
        ? _reasonText(context, reason!)
        : candidate.isGroup
        ? switch (candidate.type) {
            GroupType.URLTest => context.cFastest(candidate.count),
            GroupType.Fallback => context.cFallback(candidate.count),
            GroupType.LoadBalance => context.cBalance(candidate.count),
            _ => context.cManual(candidate.count),
          }
        : (delay == null ? context.cGroup : '$delay ms');
    return Opacity(
      opacity: reason == null ? 1 : 0.5,
      child: ListTile(
        leading: candidate.isGroup
            ? CircleAvatar(child: GlyphIcon(AppGlyphs.globe, size: 18))
            : RoundFlag(candidate.name, size: 32),
        title: Text(
          candidate.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(subtitle),
        selected: candidate.name == current,
        onTap: reason == null ? onTap : null,
      ),
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
