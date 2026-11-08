import 'package:skyward/common/common.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/config/dns.dart';
import 'package:skyward/views/config/scripts.dart';
import 'package:material_ui/material_ui.dart';

import 'ad_block.dart';
import 'rules.dart';
import 'filters.dart';
import 'icon_sets.dart';
import 'providers.dart';
import 'package:skyward/views/profiles/custom/custom_proxies.dart';

class AdvancedConfigView extends StatelessWidget {
  const AdvancedConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final items = [
      ListItem.open(
        title: const Text('DNS'),
        leading: const IconWell(AppGlyphs.dns),
        widget: const DnsView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.rulePresetAdBlock),
        leading: const IconWell(AppGlyphs.block),
        widget: const AdBlockView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.addedRules),
        leading: const IconWell(AppGlyphs.rules),
        widget: const AddedRulesView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.script),
        leading: const IconWell(AppGlyphs.code),
        widget: const ScriptsView(),
      ),
      // 自定义配置资源：原「更多」页独立入口，整合进进阶配置
      ListItem.open(
        title: Text(appLocalizations.proxies),
        leading: const IconWell(AppGlyphs.proxies),
        widget: const CustomProxiesView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.ruleProviders),
        leading: const IconWell(AppGlyphs.resources),
        widget: const ClashProvidersView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.filters),
        leading: const IconWell(AppGlyphs.filter),
        widget: const FiltersView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.iconSets),
        leading: const IconWell(AppGlyphs.photos),
        widget: const IconSetsView(),
      ),
    ];
    return BaseScaffold(
      rowSeparators: false,
      title: appLocalizations.advancedConfig,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.cardTopPadding,
          bottom: 16 + context.bottomInset,
        ),
        children: [generateSection(leadingGap: false, items: items)],
      ),
    );
  }
}
