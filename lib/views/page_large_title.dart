import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// A phone page whose heading and controls all live inside its own body.
///
/// The floating bar is left completely empty: [CommonScaffold.largeTitle]
/// already hides the bar title and draws only a solid strip over the status
/// bar, and the page passes its actions here instead of to the bar. The
/// heading, the action row and the optional search field sit in one fixed
/// block at the top of the body; the original scrolling body fills the rest.
///
/// The body is re-wrapped with zero [FloatingBarScope] and [TopInsetScope]
/// (and top padding removed), so every inset a page reads for its top --
/// [appBarInset], [contentTopPadding], [cardTopPadding] -- resolves to zero
/// regardless of what an outer scope supplies. The fixed heading above
/// already owns that space; leaving the outer bar inset in place would stack
/// a second empty gap on top. The grids, pinned group headers and reveal
/// offsets below keep their own maths untouched.
class PageLargeTitle extends StatelessWidget {
  const PageLargeTitle({
    super.key,
    required this.title,
    required this.statusBarTop,
    required this.body,
    this.actions = const [],
    this.menuItems = const [],
    this.searchHint,
    this.onSearch,
    this.subtitle,
  });

  final String title;
  final double statusBarTop;
  final Widget body;

  /// Buttons moved down from the bar, shown beside the heading.
  final List<IconButtonData> actions;

  /// Overflow entries moved down from the bar, folded into one menu button.
  final List<CommonPopupMenuItem> menuItems;

  /// When both are set, a page-level search field is drawn under the heading.
  final String? searchHint;
  final ValueChanged<String>? onSearch;

  /// An optional status line under the heading, as the dashboard has.
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final hasSearch = searchHint != null && onSearch != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            22,
            statusBarTop + 12,
            22,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyle.largeTitle.of(
                        context,
                        emphasized: true,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  for (final data in actions) AppBarActionButton(data: data),
                  if (menuItems.isNotEmpty)
                    CommonPopupBox(
                      targetBuilder: (open) => IconButton(
                        tooltip: UiLocalizations.of(context).more,
                        onPressed: open,
                        icon: const GlyphIcon(AppGlyphs.moreCircle),
                      ),
                      popupBuilder: (_) => CommonPopupMenu(items: menuItems),
                    ),
                ],
              ),
              ?subtitle,
              if (hasSearch) ...[
                const SizedBox(height: 12),
                InputDecorationTheme(
                  data: searchPillTheme(context),
                  child: SearchField(
                    hintText: searchHint,
                    fill: SurfaceLevel.floatingOf(
                      colorScheme,
                    ).colorOf(colorScheme),
                    onChanged: onSearch,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: FloatingBarScope(
            inset: 0,
            child: TopInsetScope(
              inset: 0,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: body,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
