import 'package:skyward/common/common.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/config/filters.dart';
import 'package:skyward/views/config/icon_sets.dart';
import 'package:skyward/views/config/providers.dart';
import 'package:skyward/views/profiles/custom/custom_proxies.dart';
import 'package:material_ui/material_ui.dart';

class CustomResourcesView extends StatelessWidget {
  const CustomResourcesView({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final items = [
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
      title: appLocalizations.customProfileResources,
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
