import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'script.dart';
import 'standard.dart';

class ExtendView extends ConsumerStatefulWidget {
  final int profileId;

  const ExtendView({super.key, required this.profileId});

  @override
  ConsumerState<ExtendView> createState() => _ExtendViewState();
}

class _ExtendViewState extends ConsumerState<ExtendView> {
  late SetupAction _setupAction;

  @override
  void initState() {
    super.initState();
    _setupAction = ref.read(setupActionProvider.notifier);
    ref.listenManual(clashConfigProvider(widget.profileId), (_, _) {});
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return ProfileIdProvider(
      profileId: widget.profileId,
      child: CommonScaffold(
        title: appLocalizations.extend,
        body: ScrollConfiguration(
          behavior: const ShowBarScrollBehavior(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: context.appBarInset)),
              const _Title(),
              const _Content(),
              SliverToBoxAdapter(child: SizedBox(height: context.bottomInset)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _setupAction.autoApplyProfile();
    super.dispose();
  }
}

class _Title extends ConsumerWidget {
  const _Title();

  String _getTitle(BuildContext context, ExtendType type) {
    return switch (type) {
      ExtendType.standard => context.appLocalizations.standard,
      ExtendType.script => context.appLocalizations.script,
    };
  }

  String _getDesc(BuildContext context, ExtendType type) {
    return switch (type) {
      ExtendType.standard => context.appLocalizations.standardModeDesc,
      ExtendType.script => context.appLocalizations.scriptModeDesc,
    };
  }

  void _handleChangeType(WidgetRef ref, int profileId, ExtendType type) {
    ref.read(profilesProvider.notifier).updateProfile(profileId, (state) {
      return state.copyWith(extendType: type);
    });
  }

  @override
  Widget build(context, ref) {
    final appLocalizations = context.appLocalizations;
    final profileId = ProfileIdProvider.of(context)!.profileId;
    final extendType = ref.watch(extendTypeProvider(profileId));
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListHeader(title: appLocalizations.extendMode),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: generateGroup([
              for (final type in ExtendType.values)
                _ExtendModeOption(
                  title: _getTitle(context, type),
                  description: _getDesc(context, type),
                  isSelected: extendType == type,
                  onPressed: () => _handleChangeType(ref, profileId, type),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ExtendModeOption extends StatelessWidget {
  const _ExtendModeOption({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onPressed,
  });

  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecorationListItem(
      isSelected: isSelected,
      title: Text(title),
      subtitle: Text(description),
      trailing: isSelected ? const SelectionBadge() : null,
      onPressed: onPressed,
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content();

  @override
  Widget build(BuildContext context, ref) {
    final profileId = ProfileIdProvider.of(context)!.profileId;
    final extendType = ref.watch(extendTypeProvider(profileId));
    return switch (extendType) {
      ExtendType.standard => const StandardContent(),
      ExtendType.script => const ScriptContent(),
    };
  }
}
