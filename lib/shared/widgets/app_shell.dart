/// LEON main-tab shell with interactive horizontal sliding / swiping navigation.
///
/// Features:
/// - Smooth horizontal gesture swiping (swipe right-to-left / left-to-right) across all 5 main sections:
///   * Tab 0: Home / Dashboard
///   * Tab 1: Workouts / Training Splits
///   * Tab 2: Exercises / Movement Library
///   * Tab 3: History / Analytics
///   * Tab 4: Account / Profile
/// - High-performance PageView with BouncingScrollPhysics for tactile momentum and edge elasticity
/// - AutomaticKeepAlive on all 5 tabs so scroll positions, inputs, and states are preserved across swipes
/// - Bidirectional sync between gesture swiping, the floating [GlassNavPill], and GoRouter routes
/// - Real-time synchronization with [AtmosphericGlowBackdrop] so ambient glow glides with the active section
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/exercise_library/screens/exercise_library_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/workout_builder/screens/workout_builder_screen.dart';
import 'atmospheric_glow_backdrop.dart';
import 'glass_nav_pill.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.location, this.child, super.key});

  /// Current router location, used to decide which tab reads as active.
  final String location;

  /// Optional fallback child screen from GoRouter.
  final Widget? child;

  /// Space the floating pill covers at the bottom of the viewport, excluding
  /// the device's own safe-area inset.
  static const double reservedBottomSpace = GlassNavPill.height + _margin * 2;

  static const double _margin = 16;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isProgrammaticScroll = false;

  /// The 5 persistent tab screens in display order.
  static const List<Widget> _tabScreens = <Widget>[
    _KeepAliveTab(child: DashboardScreen()),
    _KeepAliveTab(child: WorkoutBuilderScreen()),
    _KeepAliveTab(child: ExerciseLibraryScreen()),
    _KeepAliveTab(child: HistoryScreen()),
    _KeepAliveTab(child: ProfileScreen()),
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex = navPillIndexFor(widget.location);
    _currentIndex = (initialIndex >= 0 && initialIndex < kNavPillTabs.length)
        ? initialIndex
        : 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location) {
      final targetIndex = navPillIndexFor(widget.location);
      if (targetIndex >= 0 &&
          targetIndex < kNavPillTabs.length &&
          targetIndex != _currentIndex) {
        _currentIndex = targetIndex;
        if (_pageController.hasClients) {
          final currentPage = _pageController.page?.round();
          if (currentPage != targetIndex) {
            _isProgrammaticScroll = true;
            _pageController
                .animateToPage(
                  targetIndex,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                )
                .then((_) {
                  if (mounted) {
                    _isProgrammaticScroll = false;
                  }
                });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });

    if (!_isProgrammaticScroll) {
      final targetRoute = kNavPillTabs[index].route;
      if (widget.location != targetRoute) {
        GoRouter.maybeOf(context)?.go(targetRoute);
      }
    }
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });

    _isProgrammaticScroll = true;
    if (_pageController.hasClients) {
      _pageController
          .animateToPage(
            index,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          )
          .then((_) {
            if (mounted) {
              _isProgrammaticScroll = false;
            }
          });
    }
    GoRouter.maybeOf(context)?.go(kNavPillTabs[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = navPillIndexFor(widget.location);
    final isKnownTab = activeIndex >= 0 && activeIndex < kNavPillTabs.length;

    return Stack(
      children: [
        // 1. Hardware-accelerated atmospheric glow backdrop
        Positioned.fill(
          child: AtmosphericGlowBackdrop(
            activeIndex: isKnownTab ? _currentIndex : activeIndex,
          ),
        ),

        // 2. Interactive horizontally swipeable main sections
        Positioned.fill(
          child: isKnownTab
              ? PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  dragStartBehavior: DragStartBehavior.down,
                  children: _tabScreens,
                )
              : (widget.child ?? const SizedBox.shrink()),
        ),

        // 3. Floating glass navigation pill with tubelight indicator
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                0,
                24,
                AppShell._margin,
              ),
              child: GlassNavPill(
                activeIndex: isKnownTab ? _currentIndex : activeIndex,
                onTabSelected: _onTabSelected,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper wrapper that guarantees the state, scroll offset, and controllers of
/// each tab remain alive when swiping between sections.
class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});
  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
