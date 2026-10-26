/// LEON / AEON main-tab shell with instant, zero-peeking persistent tab branches.
///
/// Features:
/// - Instant tab switching between the 5 main sections using [IndexedStack]:
///   * Tab 0: Home / Dashboard
///   * Tab 1: Workouts / Training Splits
///   * Tab 2: Exercises / Movement Library
///   * Tab 3: History / Analytics
///   * Tab 4: Account / Profile
/// - [PageStorageKey] preserves scroll positions and state for every tab independently.
/// - [TickerMode] pauses tickers and animations on offscreen tabs, eliminating background CPU/GPU drain.
/// - [GlassNavPill] integration with clear bottom padding calculation for all scrollable views.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/exercise_library/screens/exercise_library_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/workout_builder/screens/workout_builder_screen.dart';
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

  /// Returns the total clearance padding required for scrollables to clear
  /// the floating [GlassNavPill] plus device system safe-area insets (e.g. gesture bar, 3-button bar).
  static double bottomPadding(BuildContext context, {double extra = 24.0}) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return reservedBottomSpace + bottomInset + extra;
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  double _horizontalDragDelta = 0.0;

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
    final initialIndex = navPillIndexFor(widget.location);
    _currentIndex = (initialIndex >= 0 && initialIndex < kNavPillTabs.length)
        ? initialIndex
        : 0;
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location) {
      final targetIndex = navPillIndexFor(widget.location);
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
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    final targetRoute = kNavPillTabs[index].route;
    if (widget.location != targetRoute) {
      GoRouter.maybeOf(context)?.go(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = navPillIndexFor(widget.location);
    final isKnownTab = activeIndex >= 0 && activeIndex < kNavPillTabs.length;
    final currentIndex = isKnownTab ? _currentIndex : activeIndex;

    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        children: [
          // 1. Instant, zero-peeking persistent tab branches with fast swipe gesture
          Positioned.fill(
            child: isKnownTab
                ? GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (_) {
                      _horizontalDragDelta = 0.0;
                    },
                    onHorizontalDragUpdate: (details) {
                      _horizontalDragDelta += details.delta.dx;
                    },
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0.0;
                      const double kDistanceThreshold = 50.0;
                      const double kVelocityThreshold = 250.0;

                      final isSwipeNext = velocity < -kVelocityThreshold ||
                          _horizontalDragDelta < -kDistanceThreshold;
                      final isSwipePrev = velocity > kVelocityThreshold ||
                          _horizontalDragDelta > kDistanceThreshold;

                      if (isSwipeNext && _currentIndex < _tabScreens.length - 1) {
                        HapticFeedback.lightImpact();
                        _onTabSelected(_currentIndex + 1);
                      } else if (isSwipePrev && _currentIndex > 0) {
                        HapticFeedback.lightImpact();
                        _onTabSelected(_currentIndex - 1);
                      }
                      _horizontalDragDelta = 0.0;
                    },
                    onHorizontalDragCancel: () {
                      _horizontalDragDelta = 0.0;
                    },
                    child: IndexedStack(
                      index: currentIndex,
                      children: [
                        for (int i = 0; i < _tabScreens.length; i++)
                          TickerMode(
                            enabled: i == currentIndex,
                            child: KeyedSubtree(
                              key: PageStorageKey<String>('tab_$i'),
                              child: _tabScreens[i],
                            ),
                          ),
                      ],
                    ),
                  )
                : (widget.child ?? const SizedBox.shrink()),
          ),

          // 2. Floating glass navigation pill with tubelight indicator
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
                  activeIndex: currentIndex,
                  onTabSelected: _onTabSelected,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
