import 'package:skyward/enum/enum.dart';

/// Sorts the cards into the places they show in, one place per size: the cards
/// of each size are gathered into a pile where that size first appears, and a
/// hero card always stands in a place of its own.
///
/// A place only holds cards of one size because it shows one after another in
/// the same spot, and the order the reader gave is kept twice over: the piles
/// come in the order their first card was put in, and the cards inside a pile
/// keep the order they had among themselves.
///
/// This is where the cards start, not where they have to stay: once the reader
/// drags two piles together or pulls one apart, the arrangement is saved as it
/// stands and this no longer applies.
List<List<DashboardWidget>> dashboardStacksOf(List<DashboardWidget> cards) {
  final stacks = <List<DashboardWidget>>[];
  final bySize = <DashboardCardSize, List<DashboardWidget>>{};
  for (final card in cards) {
    final stack = card.size == DashboardCardSize.hero
        ? null
        : bySize.putIfAbsent(card.size, () {
            final pile = <DashboardWidget>[];
            stacks.add(pile);
            return pile;
          });
    if (stack == null) {
      stacks.add([card]);
    } else {
      stack.add(card);
    }
  }
  return stacks;
}
