import 'package:skyward/common/common.dart';
import 'package:skyward/l10n/l10n.dart';
import 'package:skyward/models/clash_config.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

enum RulePreset {
  blockQuic(AppGlyphs.block, [
    'AND,((NETWORK,UDP),(DST-PORT,443)),REJECT-DROP',
  ]),
  blockStun(AppGlyphs.eyeOff, [
    'AND,((NETWORK,UDP),(DST-PORT,3478/19302)),REJECT-DROP',
  ]),
  blockDot(AppGlyphs.dns, ['DST-PORT,853,REJECT']),
  // Connecting to 0.0.0.0 or :: also reaches a local listener.
  blockLoopback(AppGlyphs.sync, [
    'IP-CIDR,127.0.0.0/8,REJECT,no-resolve',
    'IP-CIDR,0.0.0.0/32,REJECT,no-resolve',
    'IP-CIDR6,::1/128,REJECT,no-resolve',
    'IP-CIDR6,::/128,REJECT,no-resolve',
    'AND,((IN-TYPE,TUN),(DST-PORT,853)),REJECT',
  ]),
  lanDirect(AppGlyphs.wifi, [
    'GEOSITE,private,DIRECT',
    'GEOIP,LAN,DIRECT,no-resolve',
  ]),
  systemServicesDirect(AppGlyphs.devices, [
    'GEOSITE,apple,DIRECT',
    'GEOSITE,microsoft,DIRECT',
  ]),
  bittorrentDirect(AppGlyphs.cloudDownload, [
    'GEOSITE,category-public-tracker,DIRECT',
    'GEOSITE,category-pt,DIRECT',
    r'PROCESS-NAME-REGEX,(?i)^(qbittorrent|transmission.*|deluge.*|aria2c|motrix|utorrent|bitcomet)(\.exe)?$,DIRECT',
  ]),
  adBlock(AppGlyphs.block, [
    // Google ads & tracking
    'DOMAIN-SUFFIX,doubleclick.net,REJECT',
    'DOMAIN-SUFFIX,googlesyndication.com,REJECT',
    'DOMAIN-SUFFIX,googleadservices.com,REJECT',
    'DOMAIN-SUFFIX,google-analytics.com,REJECT',
    'DOMAIN-SUFFIX,googletagmanager.com,REJECT',
    'DOMAIN-SUFFIX,googletagservices.com,REJECT',
    // Common ad networks
    'DOMAIN-SUFFIX,adnxs.com,REJECT',
    'DOMAIN-SUFFIX,criteo.com,REJECT',
    'DOMAIN-SUFFIX,outbrain.com,REJECT',
    'DOMAIN-SUFFIX,taboola.com,REJECT',
    // Pangle (ByteDance)
    'DOMAIN-SUFFIX,pangle.io,REJECT',
    'DOMAIN-SUFFIX,pangolin-sdk-toutiao.com,REJECT',
    'DOMAIN-SUFFIX,pglstatp-toutiao.com,REJECT',
    'DOMAIN,api-access.pangolin-sdk-toutiao.com,REJECT',
    'DOMAIN,is.snssdk.com,REJECT',
    // GDT (Tencent)
    'DOMAIN-SUFFIX,gdt.qq.com,REJECT',
    'DOMAIN,pgdt.gtimg.cn,REJECT',
    'DOMAIN,mi.gdt.qq.com,REJECT',
    // Common SDKs
    'DOMAIN-SUFFIX,umeng.com,REJECT',
    'DOMAIN-SUFFIX,umtrack.com,REJECT',
    // Tracking
    'DOMAIN-SUFFIX,scorecardresearch.com,REJECT',
    'DOMAIN-SUFFIX,quantserve.com,REJECT',
    'DOMAIN-SUFFIX,hotjar.com,REJECT',
    'DOMAIN-SUFFIX,mixpanel.com,REJECT',
    'DOMAIN-SUFFIX,amplitude.com,REJECT',
  ]);

  final Glyph glyph;
  final List<String> rawRules;

  const RulePreset(this.glyph, this.rawRules);

  String label(AppLocalizations appLocalizations) => switch (this) {
    RulePreset.blockQuic => appLocalizations.rulePresetBlockQuic,
    RulePreset.blockStun => appLocalizations.rulePresetBlockStun,
    RulePreset.blockDot => appLocalizations.rulePresetBlockDot,
    RulePreset.blockLoopback => appLocalizations.rulePresetBlockLoopback,
    RulePreset.lanDirect => appLocalizations.rulePresetLanDirect,
    RulePreset.systemServicesDirect =>
      appLocalizations.rulePresetSystemServicesDirect,
    RulePreset.bittorrentDirect => appLocalizations.rulePresetBittorrentDirect,
    RulePreset.adBlock => appLocalizations.rulePresetAdBlock,
  };

  List<Rule> get rules => rawRules.map(Rule.parse).toList();
}

class RulePresetSheet extends StatefulWidget {
  final ValueChanged<List<Rule>> onAdd;

  const RulePresetSheet({super.key, required this.onAdd});

  @override
  State<RulePresetSheet> createState() => _RulePresetSheetState();
}

class _RulePresetSheetState extends State<RulePresetSheet> {
  final _selected = <RulePreset>{};

  void _handleToggle(RulePreset preset) {
    setState(() {
      _selected.addOrRemove(preset);
    });
  }

  void _handleConfirm() {
    final rules = [
      for (final preset in RulePreset.values)
        if (_selected.contains(preset)) ...preset.rules,
    ];
    Navigator.of(context).pop();
    widget.onAdd(rules);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    const presets = RulePreset.values;
    return CommonScaffold(
      title: appLocalizations.quickActions,
      confirmationAction: _selected.isEmpty
          ? null
          : IconButtonData(
              glyph: AppGlyphs.check,
              onPressed: _handleConfirm,
              tooltip: appLocalizations.confirm,
            ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.contentTopPadding,
          bottom: 20 + context.bottomInset,
        ),
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final preset = presets[index];
          final isSelected = _selected.contains(preset);
          return ItemPositionProvider(
            position: ItemPosition.get(index, presets.length),
            child: DecorationListItem(
              leading: IconWell(preset.glyph),
              title: Text(preset.label(appLocalizations)),
              subtitle: _PresetSubtitle(preset),
              isSelected: isSelected,
              trailing: isSelected ? const SelectionCheck() : null,
              onPressed: () => _handleToggle(preset),
            ),
          );
        },
      ),
    );
  }
}

class _PresetSubtitle extends StatelessWidget {
  final RulePreset preset;

  const _PresetSubtitle(this.preset);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final raw in preset.rawRules)
          Text(
            raw,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.footnote
                .of(context)
                .toJetBrainsMono
                .copyWith(color: context.colorScheme.tertiary),
          ),
      ],
    );
  }
}
