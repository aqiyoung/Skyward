import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/record_filter.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/popup.dart';

@immutable
class RecordFilterState {
  final List<RecordFilter> filters;
  final RecordGrouping? grouping;

  const RecordFilterState({this.filters = const [], this.grouping});
}

typedef RecordFacetOptions = Map<RecordFacetKind, List<String>>;

const _optionsEquality = MapEquality<RecordFacetKind, List<String>>(
  values: ListEquality(),
);

class RecordFilterController<T> extends ValueNotifier<RecordFilterState> {
  final List<RecordFacet<T>> facets;
  final List<RecordGrouper<T>> groupers;
  final ValueChanged<RecordGrouping?>? onGroupingChanged;

  final options = ValueNotifier<RecordFacetOptions>(const {});

  RecordFilterController({
    required this.facets,
    this.groupers = const [],
    RecordGrouping? grouping,
    this.onGroupingChanged,
  }) : super(
         RecordFilterState(
           grouping: groupers.any((grouper) => grouper.grouping == grouping)
               ? grouping
               : null,
         ),
       );

  List<RecordFilter> get filters => value.filters;

  bool get isFiltering => filters.isNotEmpty;

  RecordGrouper<T>? get grouper => groupers.firstWhereOrNull(
    (grouper) => grouper.grouping == value.grouping,
  );

  RecordFacet<T>? facetOf(RecordFacetKind kind) =>
      facets.firstWhereOrNull((facet) => facet.kind == kind);

  void add(RecordFilter filter) {
    if (!filters.contains(filter)) {
      _setFilters([...filters, filter]);
    }
  }

  void remove(RecordFilter filter) {
    if (filters.contains(filter)) {
      _setFilters([...filters]..remove(filter));
    }
  }

  void toggle(RecordFilter filter) {
    filters.contains(filter) ? remove(filter) : add(filter);
  }

  void _setFilters(List<RecordFilter> filters) {
    value = RecordFilterState(filters: filters, grouping: value.grouping);
  }

  void setGrouping(RecordGrouping? grouping) {
    if (grouping == value.grouping) {
      return;
    }
    value = RecordFilterState(filters: filters, grouping: grouping);
    onGroupingChanged?.call(grouping);
  }

  /// Offers the values [items] take, read before any filter narrows them.
  void offer(Iterable<T> items) {
    final next = <RecordFacetKind, List<String>>{};
    for (final facet in facets) {
      if (!facet.offered) {
        continue;
      }
      final values = facet.optionsOf(
        items,
        selected: [
          for (final filter in filters)
            if (filter.kind == facet.kind) filter.value,
        ],
      );
      if (values.isNotEmpty) {
        next[facet.kind] = values;
      }
    }
    if (!_optionsEquality.equals(next, options.value)) {
      options.value = next;
    }
  }

  List<T> apply(List<T> items) =>
      isFiltering ? items.whereFilters(facets, filters).toList() : items;

  List<RecordGroup<T>>? groupsOf(List<T> items, {bool reverse = false}) {
    final keyOf = grouper?.keyOf;
    return keyOf == null ? null : groupRecords(items, keyOf, reverse: reverse);
  }

  List<CommonPopupMenuItem> menuItems(
    BuildContext context, {
    required bool pinned,
  }) {
    final appLocalizations = context.appLocalizations;
    final options = this.options.value;
    return [
      if (!pinned && options.isNotEmpty)
        CommonPopupMenuItem(
          glyph: AppGlyphs.filter,
          label: appLocalizations.filter,
          subItems: [
            for (final facet in facets)
              for (final (index, option) in (options[facet.kind] ?? []).indexed)
                CommonPopupMenuItem(
                  label: facet.label(option),
                  checked: filters.contains(RecordFilter(facet.kind, option)),
                  keepsOpen: true,
                  section: index == 0
                      ? CommonPopupMenuSection(title: facet.kind.title)
                      : null,
                  onPressed: () => toggle(RecordFilter(facet.kind, option)),
                ),
          ],
        ),
    ];
  }

  @override
  void dispose() {
    options.dispose();
    super.dispose();
  }
}

/// Lets a value tapped in a row narrow the list it sits in.
class RecordFilterScope extends InheritedWidget {
  final ValueChanged<RecordFilter> onFilter;

  const RecordFilterScope({
    super.key,
    required this.onFilter,
    required super.child,
  });

  static void add(BuildContext context, RecordFilter filter) {
    context.getInheritedWidgetOfExactType<RecordFilterScope>()?.onFilter(
      filter,
    );
  }

  @override
  bool updateShouldNotify(RecordFilterScope oldWidget) => false;
}
