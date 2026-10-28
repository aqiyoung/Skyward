import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/manager/app_manager.dart';
import 'package:skyward/models/common.dart';
import 'package:skyward/providers/providers.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasViewSize = ref.watch(
      viewSizeProvider.select((size) => !size.isEmpty),
    );
    if (!hasViewSize) {
      return const SizedBox.shrink();
    }
    return HomeBackScopeContainer(
      child: AppSidebarContainer(
        child: _HomeShell(
          child: Consumer(
            builder: (_, ref, _) {
              final navigationItems = ref
                  .watch(currentNavigationItemsStateProvider)
                  .value;
              final isMobile = ref.watch(isMobileViewProvider);
              return _HomePageView(
                navigationItems: navigationItems,
                pageBuilder: (_, index) {
                  final navigationItem = navigationItems[index];
                  return _NavigationPage(
                    key: ValueKey(navigationItem.label),
                    item: navigationItem,
                    isMobile: isMobile,
                    view: navigationItem.builder(context),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeShell extends ConsumerStatefulWidget {
  const _HomeShell({required this.child});

  final Widget child;

  @override
  ConsumerState<_HomeShell> createState() => _HomeShellState();
}

/// How far the list has to travel under the finger before the labels leave,
/// and how much further before the bar follows them out of the page. Two
/// steps, so a nudge does not take the whole bar away.
const double _scrollTravelToCollapse = 12;
const double _scrollTravelToLeave = 64;

/// The bar has three places to be: whole, icons only, and gone.
enum _DockPhase { expanded, compact, hidden }

class _HomeShellState extends ConsumerState<_HomeShell> {
  final _dockPhase = ValueNotifier(_DockPhase.expanded);
  ScrollDirection _scrollDirection = ScrollDirection.idle;
  double _scrollTravel = 0;

  /// The bar follows the finger, never a list that restores its position
  /// on its own, nor a page that is not the active one.
  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical ||
        notification.context
                ?.getInheritedWidgetOfExactType<PageActivityScope>()
                ?.isActive ==
            false) {
      return false;
    }
    if (notification is UserScrollNotification) {
      _scrollDirection = notification.direction;
      _scrollTravel = 0;
      return false;
    }
    if (notification is! ScrollUpdateNotification) {
      return false;
    }
    final metrics = notification.metrics;
    // Nothing left to uncover at the top of the list, and nothing left to hide
    // behind at its foot: either end puts the whole bar back, so a reader who
    // scrolled to the end can still reach the destinations.
    if (metrics.extentBefore <= 0 || metrics.extentAfter <= 0) {
      _setPhase(_DockPhase.expanded);
      _scrollTravel = 0;
      return false;
    }
    if (notification.dragDetails == null ||
        _scrollDirection == ScrollDirection.idle) {
      return false;
    }
    // Dragging back down uncovers what the bar was hiding behind, so it comes
    // back whole rather than one step at a time.
    if (_scrollDirection == ScrollDirection.forward) {
      _setPhase(_DockPhase.expanded);
      _scrollTravel = 0;
      return false;
    }
    _scrollTravel += (notification.scrollDelta ?? 0).abs();
    if (_scrollTravel >= _scrollTravelToLeave) {
      _setPhase(_DockPhase.hidden);
    } else if (_scrollTravel >= _scrollTravelToCollapse) {
      _setPhase(_DockPhase.compact);
    }
    return false;
  }

  void _setPhase(_DockPhase phase) {
    if (_dockPhase.value != phase) {
      _dockPhase.value = phase;
    }
  }

  @override
  void dispose() {
    _dockPhase.dispose();
    super.dispose();
  }

  void _handleToPage(PageLabel pageLabel) {
    ref.read(currentPageLabelProvider.notifier).toPage(pageLabel);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentPageLabelProvider, (previous, next) {
      if (previous == next) return;
      _dockPhase.value = _DockPhase.expanded;
      _scrollDirection = ScrollDirection.idle;
      _scrollTravel = 0;
    });
    final state = ref.watch(navigationStateProvider);
    final isMobile = state.viewMode == ViewMode.mobile;
    final navigationItems = state.navigationItems;
    final floating = ref.watch(
      appSettingProvider.select((state) => state.floatingNavigationBar),
    );
    final dockScale = ref.watch(
      themeSettingProvider.select((state) => state.dockScale),
    );
    final hideLabelOnScroll = ref.watch(
      themeSettingProvider.select((state) => state.dockHideLabelOnScroll),
    );
    // A floating dock follows the page; only the labels answer to the setting.
    final dockFollows = isMobile && floating;
    final dockFoldsLabels = dockFollows && hideLabelOnScroll;
    return Material(
      color: SurfaceLevel.page.colorOf(context.colorScheme),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FocusTraversalGroup(
                    policy: PageTraversalPolicy(),
                    child: BottomInsetScope(
                      inset: isMobile && floating
                          ? NavigationDock.insetOf(context, dockScale)
                          : 0,
                      child: _BodyPadding(
                        isMobile: isMobile,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: dockFollows ? _handleScroll : null,
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: ValueListenableBuilder<_DockPhase>(
                    valueListenable: _dockPhase,
                    builder: (context, phase, _) {
                      final hidden = phase == _DockPhase.hidden;
                      final compact = phase != _DockPhase.expanded;
                      return AnimatedVisibility.bottomNavigation(
                        // The room the inset keeps stays put while the bar
                        // leaves, so the page under it never moves.
                        visible: dockFollows && !hidden,
                        child: _NavigationPadding(
                          child: NavigationDock(
                            destinations: [
                              for (final item in navigationItems)
                                NavigationDockDestination(
                                  glyph: item.glyph,
                                  label: item.label.label,
                                ),
                            ],
                            selectedIndex: state.currentIndex,
                            onSelected: (index) {
                              _handleToPage(navigationItems[index].label);
                            },
                            scale: dockScale,
                            showLabel: !(dockFoldsLabels && compact),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          AnimatedVisibility.bottomNavigation(
            visible: isMobile && !floating,
            child: _NavigationPadding(
              child: NavigationBar(
                destinations: [
                  for (final (index, item) in navigationItems.indexed)
                    NavigationDestination(
                      icon: AnimatedGlyph(
                        glyph: item.glyph,
                        filled: index == state.currentIndex,
                      ),
                      label: item.label.label,
                    ),
                ],
                selectedIndex: state.currentIndex,
                onDestinationSelected: (index) {
                  _handleToPage(navigationItems[index].label);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyPadding extends StatelessWidget {
  const _BodyPadding({required this.isMobile, required this.child});

  final bool isMobile;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      removeTop: false,
      removeBottom: isMobile,
      removeLeft: isMobile,
      removeRight: isMobile,
      context: context,
      child: child,
    );
  }
}

class _NavigationPadding extends StatelessWidget {
  const _NavigationPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      removeTop: true,
      removeBottom: false,
      removeLeft: true,
      removeRight: true,
      context: context,
      child: child,
    );
  }
}

class _NavigationPage extends StatelessWidget {
  const _NavigationPage({
    super.key,
    required this.item,
    required this.isMobile,
    required this.view,
  });

  final NavigationItem item;
  final bool isMobile;
  final Widget view;

  @override
  Widget build(BuildContext context) {
    final scopedView = PageFocusScope(child: view);
    final keptView = KeepScope(
      key: ValueKey(item.label),
      child: isMobile
          ? scopedView
          : Navigator(
              key: ValueKey('${item.label.name}_navigator'),
              pages: [MaterialPage(child: scopedView)],
              onDidRemovePage: (_) {},
            ),
    );
    return Consumer(
      builder: (_, ref, child) {
        final isActive = ref.watch(
          shownPageLabelProvider.select((label) => label == item.label),
        );
        // A kept-alive page off screen still ticks its animations, and
        // each tick asks for a frame.
        return PageActivityScope(
          isActive: isActive,
          child: TickerMode(
            enabled: isActive,
            child: ExcludeFocus(
              excluding: !isActive,
              child: KeyboardInsetHold(child: child!),
            ),
          ),
        );
      },
      child: keptView,
    );
  }
}

class _HomePageView extends ConsumerStatefulWidget {
  final IndexedWidgetBuilder pageBuilder;
  final List<NavigationItem> navigationItems;

  const _HomePageView({
    required this.pageBuilder,
    required this.navigationItems,
  });

  @override
  ConsumerState createState() => _HomePageViewState();
}

class _HomePageViewState extends ConsumerState<_HomePageView> {
  late PageController _pageController;

  List<int>? _order;
  int _slide = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _pageIndex);
    ref.listenManual(currentPageLabelProvider, (prev, next) {
      if (prev != next) {
        _toPage(next);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _HomePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
      _labelsOf(oldWidget.navigationItems),
      _labelsOf(widget.navigationItems),
    )) {
      _order = null;
      _updatePageController();
    }
  }

  static List<PageLabel> _labelsOf(List<NavigationItem> items) => [
    for (final item in items) item.label,
  ];

  int get _pageIndex => _indexOf(ref.read(currentPageLabelProvider));

  int _indexOf(PageLabel pageLabel) {
    final shown = shownPageLabelOf(pageLabel, widget.navigationItems);
    return widget.navigationItems.indexWhere((item) => item.label == shown);
  }

  Future<void> _toPage(
    PageLabel pageLabel, [
    bool ignoreAnimateTo = false,
  ]) async {
    if (!mounted) {
      return;
    }
    final index = _indexOf(pageLabel);
    if (index == -1) {
      return;
    }
    final tabAnimation = ref.read(appSettingProvider).tabAnimation;
    final isMobile = ref.read(isMobileViewProvider);
    final slide = ++_slide;
    final page = _pageController.hasClients
        ? _pageController.page?.round() ?? index
        : index;
    final current = _order?[page] ?? page;
    if (_order != null) {
      setState(() => _order = null);
      _pageController.jumpToPage(current);
    }
    if (!isMobile || ignoreAnimateTo) {
      _pageController.jumpToPage(index);
      return;
    }
    // As TabBarView does, so no page between is built and painted on the way.
    if ((index - current).abs() > 1) {
      final adjacent = index > current ? index - 1 : index + 1;
      setState(() {
        _order = List.generate(widget.navigationItems.length, (item) => item)
          ..[adjacent] = current
          ..[current] = adjacent;
      });
      _pageController.jumpToPage(adjacent);
    }
    final fade = tabAnimation == TabAnimation.fade;
    await _pageController.animateToPage(
      index,
      duration: fade ? fadeTabDuration : kTabScrollDuration,
      curve: fade ? fadeTabCurve : Curves.easeOut,
    );
    if (mounted && slide == _slide && _order != null) {
      setState(() => _order = null);
    }
  }

  void _updatePageController() {
    final pageLabel = ref.read(currentPageLabelProvider);
    _toPage(pageLabel, true);
  }

  /// A drag across settles on a page the selection has not heard about yet:
  /// the label is what the rest of the app reads, so it takes the page the
  /// finger chose. Read after the scroll ends, never while it runs — an
  /// `animateToPage` under a live drag fights the finger.
  void _settleOnDraggedPage() {
    if (!mounted || _order != null || !_pageController.hasClients) {
      return;
    }
    final page = _pageController.page?.round();
    if (page == null || page < 0 || page >= widget.navigationItems.length) {
      return;
    }
    final label = widget.navigationItems[page].label;
    if (ref.read(currentPageLabelProvider) == label) {
      return;
    }
    ref.read(currentPageLabelProvider.notifier).toPage(label);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = ref.watch(
      currentNavigationItemsStateProvider.select((state) => state.value.length),
    );
    final fade = ref.watch(
      appSettingProvider.select(
        (state) => state.tabAnimation == TabAnimation.fade,
      ),
    );
    // A phone drags from page to page the way it expects to; on a desktop the
    // pages are the sidebar's, and a mouse drag across one is only a slip.
    final viewMode = ref.watch(navigationStateProvider).viewMode;
    final dragsPages = viewMode == ViewMode.mobile;
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        if (notification.depth == 0) {
          _settleOnDraggedPage();
        }
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        physics: dragsPages ? null : const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        findChildIndexCallback: (key) {
          if (key is! ValueKey<PageLabel>) {
            return null;
          }
          final index = widget.navigationItems.indexWhere(
            (item) => item.label == key.value,
          );
          if (index == -1) {
            return null;
          }
          return _order?.indexOf(index) ?? index;
        },
        itemBuilder: (context, index) {
          final page = widget.pageBuilder(context, _order?[index] ?? index);
          return _FadeTabPage(
            key: page.key,
            controller: _pageController,
            position: index,
            enabled: fade,
            child: page,
          );
        },
      ),
    );
  }
}

/// Cancels the page view's slide so a tab switch cross-fades in place, and
/// wraps every page even when off so switching the setting keeps their state.
class _FadeTabPage extends StatelessWidget {
  const _FadeTabPage({
    super.key,
    required this.controller,
    required this.position,
    required this.enabled,
    required this.child,
  });

  final PageController controller;
  final int position;
  final bool enabled;
  final Widget child;

  double get _delta {
    if (!controller.hasClients || !controller.position.hasContentDimensions) {
      return 0;
    }
    final page = controller.page ?? position.toDouble();
    return (position - page).clamp(-1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final offset = _delta;
        final delta = enabled ? offset : 0.0;
        return FractionalTranslation(
          translation: Offset(-delta, 0),
          child: Opacity(opacity: 1 - delta.abs(), child: child),
        );
      },
      child: child,
    );
  }
}

class HomeBackScopeContainer extends ConsumerWidget {
  final Widget child;

  const HomeBackScopeContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context, ref) {
    return CommonPopScope(
      onPop: (context) async {
        final pageLabel = ref.read(shownPageLabelProvider);
        final realContext =
            GlobalObjectKey(pageLabel).currentContext ?? context;
        final canPop = Navigator.canPop(realContext);
        if (canPop) {
          Navigator.of(realContext).pop();
        } else if (system.isTV && pageLabel != PageLabel.dashboard) {
          ref
              .read(currentPageLabelProvider.notifier)
              .toPage(PageLabel.dashboard);
        } else {
          await ref.read(systemActionProvider.notifier).handleClose();
        }
        return false;
      },
      child: child,
    );
  }
}
