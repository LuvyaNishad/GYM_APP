/// Main tabs with retained branches, direct swipes and stationary navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/exercise_library/screens/exercise_library_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/workout_builder/screens/workout_builder_screen.dart';
import '../../state/app_providers.dart';
import 'deferred_tab.dart';
import 'glass_nav_pill.dart';
import 'retained_swipe_tabs.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.location, this.child, super.key})
    : navigationShell = null;

  const AppShell.navigation({required this.navigationShell, super.key})
    : location = null,
      child = null;

  /// Current router location, used to decide which tab reads as active.
  final String? location;

  /// Production navigation uses GoRouter's stateful shell so
  /// branch state, route history, ticker muting, and preloading are managed in
  /// one place instead of duplicated inside this widget.
  final StatefulNavigationShell? navigationShell;

  /// Optional fallback child screen from GoRouter.
  final Widget? child;

  /// Space the floating pill covers at the bottom of the viewport, excluding
  /// the device's own safe-area inset.
  static const double reservedBottomSpace = GlassNavPill.height + _margin * 2;

  static const double _margin = 16;
  static const double mainContentMaxWidth = 720;

  /// Returns the total clearance padding required for scrollables to clear
  /// the floating [GlassNavPill] plus device system safe-area insets (e.g. gesture bar, 3-button bar).
  static double bottomPadding(BuildContext context, {double extra = 24.0}) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return GlassNavPill.heightFor(context) + _margin * 2 + bottomInset + extra;
  }

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _currentIndex;
  final _tabSelectionSignal = ValueNotifier<int>(0);

  /// The 5 persistent tab screens in display order.
  static const List<Widget> _tabScreens = <Widget>[
    DashboardScreen(),
    WorkoutBuilderScreen(),
    ExerciseLibraryScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex =
        widget.navigationShell?.currentIndex ??
        navPillIndexFor(widget.location!);
    _currentIndex = (initialIndex >= 0 && initialIndex < kNavPillTabs.length)
        ? initialIndex
        : 0;
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell == null &&
        widget.location != oldWidget.location) {
      final targetIndex = navPillIndexFor(widget.location!);
      if (targetIndex >= 0 &&
          targetIndex < kNavPillTabs.length &&
          targetIndex != _currentIndex) {
        setState(() {
          _currentIndex = targetIndex;
        });
      }
    }
  }

  void _onTabSelected(int index) {
    _tabSelectionSignal.value++;
    _selectBranch(index);
  }

  void _selectBranch(int index) {
    final activeIndex = widget.navigationShell?.currentIndex ?? _currentIndex;
    if (index == activeIndex) return;
    ref.read(bottomNavIndexProvider.notifier).select(index);

    final navigationShell = widget.navigationShell;
    if (navigationShell != null) {
      navigationShell.goBranch(index);
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    final targetRoute = kNavPillTabs[index].route;
    if (widget.location != targetRoute) {
      GoRouter.maybeOf(context)?.go(targetRoute);
    }
  }

  @override
  void dispose() {
    _tabSelectionSignal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final activeIndex =
        navigationShell?.currentIndex ?? navPillIndexFor(widget.location!);
    final isKnownTab = activeIndex >= 0 && activeIndex < kNavPillTabs.length;
    final currentIndex =
        navigationShell?.currentIndex ??
        (isKnownTab ? _currentIndex : activeIndex);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final navHorizontalPadding = largeText ? 12.0 : 24.0;

    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        children: [
          // 1. Retained branches follow the horizontal gesture.
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppShell.mainContentMaxWidth,
                ),
                child: SizedBox.expand(
                  key: const ValueKey('app-shell-main-content'),
                  child: isKnownTab
                      ? TabSelectionIntent(
                          signal: _tabSelectionSignal,
                          child:
                              navigationShell ??
                              RetainedSwipeTabs(
                                currentIndex: currentIndex,
                                selectionSignal: _tabSelectionSignal,
                                onSelected: _selectBranch,
                                children: [
                                  for (var i = 0; i < _tabScreens.length; i++)
                                    KeyedSubtree(
                                      key: PageStorageKey<String>('tab_$i'),
                                      child: i == 0
                                          ? _tabScreens[i]
                                          : DeferredTab(
                                              index: i,
                                              child: _tabScreens[i],
                                            ),
                                    ),
                                ],
                              ),
                        )
                      : (widget.child ?? const SizedBox.shrink()),
                ),
              ),
            ),
          ),

          // 2. Floating navigation remains stationary while branches swipe.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppShell.mainContentMaxWidth,
                  ),
                  child: SizedBox(
                    key: const ValueKey('app-shell-nav-content'),
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        navHorizontalPadding,
                        0,
                        navHorizontalPadding,
                        AppShell._margin,
                      ),
                      child: GlassNavPill(
                        activeIndex: currentIndex,
                        onTabSelected: _onTabSelected,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
