import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/models/record_filter.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/state.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/widgets/record_filter.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class LogListController extends ValueNotifier<LogsState> {
  LogListController() : super(const LogsState());

  void search(String query) {
    value = value.copyWith(query: query);
  }

  void setLogs(List<Log> logs) {
    if (identical(logs, value.logs)) {
      return;
    }
    value = value.copyWith(
      logs: value.autoScrollToEnd
          ? logs
          : retainTrimmedHead(value.logs, logs, pausedMaxLogsLength),
    );
  }

  void setAutoScrollToEnd(bool autoScrollToEnd) {
    value = value.copyWith(autoScrollToEnd: autoScrollToEnd);
  }

  void resumeAutoScrollToEnd(List<Log> logs) {
    value = value.copyWith(autoScrollToEnd: true, logs: logs);
  }
}

class LogsView extends ConsumerStatefulWidget {
  const LogsView({super.key});

  @override
  ConsumerState<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends ConsumerState<LogsView>
    with RouteMotionHoldMixin<LogsView> {
  final _listController = LogListController();
  final _filters = RecordFilterController<Log>(facets: logFacets);
  late final ScrollController _scrollController;
  late final _physics = FollowEndScrollPhysics(
    isFollowing: () => _listController.value.autoScrollToEnd,
  );

  @override
  void initState() {
    super.initState();
    _scrollController = sheetScrollController(
      context,
      initialScrollOffset: double.maxFinite,
    );
    _setLogs(ref.read(logsProvider).list);
    ref.listenManual(logsProvider.select((state) => state.revision), (_, _) {
      updateLogsThrottler();
    });
  }

  List<IconButtonData> _buildActions() {
    return [
      IconButtonData(
        glyph: AppGlyphs.export,
        tooltip: context.appLocalizations.exportLogs,
        onPressed: _handleExport,
      ),
    ];
  }

  @override
  void dispose() {
    _listController.dispose();
    _filters.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    final appLocalizations = context.appLocalizations;
    final res = await globalState.safeRun<bool>(() async {
      return ref.read(logsProvider.notifier).exportLogs();
    }, title: appLocalizations.exportLogs);
    if (res != true) return;
    unawaited(
      dialogs.showAlert(
        title: appLocalizations.tip,
        message: TextSpan(text: appLocalizations.exportSuccess),
      ),
    );
  }

  void _setLogs(List<Log> logs) {
    _listController.setLogs(logs);
    _filters.offer(_listController.value.logs);
  }

  void updateLogsThrottler() {
    throttler.call(FunctionTag.logs, () {
      if (!mounted) {
        return;
      }
      updateWhenRouteSettled(() => _setLogs(ref.read(logsProvider).list));
    }, duration: renderThrottleDuration);
  }

  @override
  Widget build(BuildContext context) {
    final body = RecordFilterScope(
      onFilter: _filters.add,
      child: _buildBody(context),
    );
    return CommonScaffold(
      iconActions: _buildActions(),
      menuItems: _filters.menuItems(context, pinned: false),
      searchState: AppBarSearchState(onSearch: _listController.search),
      title: context.appLocalizations.logs,
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return ListenableBuilder(
      listenable: Listenable.merge([_listController, _filters]),
      builder: (context, _) {
        final state = _listController.value;
        final logs = _filters.apply(state.list);
        final isSearching = state.isSearching || _filters.isFiltering;
        return Column(
          children: [
            if (_filters.isFiltering) _FilterChips(filters: _filters),
            Expanded(
              child: NullStatusSwitcher(
                isEmpty: logs.isEmpty,
                isSearching: isSearching,
                nullStatus: NullStatus(
                  illustration: NullStatusIllustration.logs,
                  label: appLocalizations.nullTip(appLocalizations.logs),
                ),
                child: _buildList(context, state, logs),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(BuildContext context, LogsState state, List<Log> logs) {
    final padding = EdgeInsets.only(
      top: context.contentTopPadding,
      bottom: 16 + context.bottomInset,
    );
    return Align(
      alignment: Alignment.topCenter,
      child: FloatingScrollbar(
        controller: _scrollController,
        hintBuilder: (fraction) {
          final index = (fraction * (logs.length - 1)).round();
          return logs[index].dateTime;
        },
        child: ScrollToEndBox(
          onCancelToEnd: () {
            _listController.setAutoScrollToEnd(false);
          },
          onResumeToEnd: () {
            _listController.resumeAutoScrollToEnd(ref.read(logsProvider).list);
            _filters.offer(_listController.value.logs);
          },
          controller: _scrollController,
          enable: state.autoScrollToEnd,
          child: SuperListView.separated(
            physics: _physics,
            reverse: true,
            shrinkWrap: true,
            controller: _scrollController,
            padding: padding,
            itemCount: logs.length,
            extentEstimation: recordListExtentEstimation,
            separatorBuilder: (_, _) =>
                const SizedBox(height: recordListGap),
            itemBuilder: (_, index) {
              final log = logs[index];
              return LogItem(log: log);
            },
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.filters});

  final RecordFilterController<Log> filters;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in filters.filters)
            TonalChip(
              label: filters.facetOf(filter.kind)?.label(filter.value) ??
                  filter.value,
              color: context.raisedSurfaceLevel.colorOf(colorScheme),
              foregroundColor: colorScheme.onSurfaceVariant,
              onPressed: () => filters.remove(filter),
            ),
        ],
      ),
    );
  }
}

class LogItem extends StatelessWidget {
  final Log log;

  const LogItem({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final tone = switch (log.logLevel) {
      LogLevel.warning => RecordTone.warning,
      LogLevel.error => RecordTone.error,
      LogLevel.info || LogLevel.debug || LogLevel.silent => RecordTone.neutral,
    };
    final payload = LogPayload.parse(log.payload);
    return RecordListItem(
      onTap: () {},
      header: RecordHeader(
        children: [
          RecordTimestamp(log.dateTime),
          RecordLabel(
            label: log.logLevel.name,
            tone: tone,
            onPressed: () => RecordFilterScope.add(
              context,
              RecordFilter(RecordFacetKind.level, log.logLevel.name),
            ),
          ),
        ],
      ),
      body: _LogBody(payload: payload, errorColor: tone.accentColor(context)),
    );
  }
}

class _LogBody extends StatelessWidget {
  final LogPayload payload;
  final Color? errorColor;

  const _LogBody({required this.payload, this.errorColor});

  String get _sourceText => [
    payload.tag,
    if (payload.route case final route?) ...[route.source, route.sourceDetail],
  ].where((text) => text.isNotEmpty).join('  ·  ');

  @override
  Widget build(BuildContext context) {
    final styles = RecordTextStyles.of(context);
    final route = payload.route;
    if (route == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(payload.message, style: styles.primary),
          if (payload.tag.isNotEmpty)
            Text(payload.tag, style: styles.secondary),
        ],
      );
    }
    return SelectableText.rich(
      TextSpan(
        children: [
          TextSpan(text: route.destination, style: styles.title),
          if (route.error.isNotEmpty)
            TextSpan(
              text: '\n${route.error}',
              style: styles.secondary.copyWith(color: errorColor),
            ),
          const TextSpan(text: '\n'),
          if (route.rule.isNotEmpty) ...[
            TextSpan(text: route.rule, style: styles.secondary),
            TextSpan(text: ' \u2192 ', style: styles.secondary.toJetBrainsMono),
          ],
          TextSpan(
            text: route.proxy,
            style: AppTextStyle.footnote
                .of(context, emphasized: true)
                .copyWith(color: context.colorScheme.onSurface),
          ),
          TextSpan(text: '\n$_sourceText', style: styles.secondary),
        ],
      ),
    );
  }
}
