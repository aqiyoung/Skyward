import 'package:skyward/enum/enum.dart';

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
