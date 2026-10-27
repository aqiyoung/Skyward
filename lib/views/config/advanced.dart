import 'package:skyward/common/common.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/config/dns.dart';
import 'package:skyward/views/config/network.dart';
import 'package:skyward/views/config/scripts.dart';
import 'package:material_ui/material_ui.dart';

import 'rules.dart';

class AdvancedConfigView extends StatelessWidget {
  const AdvancedConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final items = [
      ListItem.open(
        title: Text(appLocalizations.network),
        leading: const IconWell(AppGlyphs.key),
        widget: BaseScaffold(
          title: appLocalizations.network,
          body: const NetworkListView(),
        ),
      ),
      ListItem.open(
        title: const Text('DNS'),
        leading: const IconWell(AppGlyphs.dns),
        widget: const DnsView(),
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
    ];
    return BaseScaffold(
      title: appLocalizations.advancedConfig,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.contentTopPadding,
          bottom: 16 + context.bottomInset,
        ),
        children: [generateSection(items: items)],
      ),
    );
  }
}
