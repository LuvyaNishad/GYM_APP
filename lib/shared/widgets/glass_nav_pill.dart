import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/app_providers.dart';
import 'glass_card.dart';
import 'immediate_press_feedback.dart';

/// One tab in the navigation pill.
class NavPillTab {
  const NavPillTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}

/// The five main tabs in display order.
const List<NavPillTab> kNavPillTabs = <NavPillTab>[
  NavPillTab(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
    route: AppConstants.routeDashboard,
  ),
  NavPillTab(
    icon: Icons.fitness_center_outlined,
    activeIcon: Icons.fitness_center_rounded,
    label: 'Workouts',
    route: AppConstants.routeWorkoutBuilder,
  ),
  NavPillTab(
    icon: Icons.local_fire_department_outlined,
    activeIcon: Icons.local_fire_department_rounded,
    label: 'Exercises',
    route: AppConstants.routeExerciseLibrary,
  ),
  NavPillTab(
    icon: Icons.history_rounded,
    activeIcon: Icons.history_rounded,
    label: 'History',
    route: AppConstants.routeAnalytics,
  ),
  NavPillTab(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Account',
    route: AppConstants.routeProfile,
  ),
];

/// Index of the tab owning [location], or -1 when none does.
int navPillIndexFor(String location) {
  var bestIndex = -1;
  var bestLength = 0;
  for (var i = 0; i < kNavPillTabs.length; i++) {
    final route = kNavPillTabs[i].route;
    final matches = route == AppConstants.routeDashboard
        ? (location == route || location == '/dashboard')
        : location.startsWith(route);
    if (matches && route.length >= bestLength) {
      bestIndex = i;
      bestLength = route.length;
    }
  }
  return bestIndex;
}

/// Floating frosted navigation with a fine rim and a temporary pressed tint.
class GlassNavPill extends ConsumerWidget {
  const GlassNavPill({
    required this.activeIndex,
    required this.onTabSelected,
    super.key,
  });

  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  static const double height = 70;
  static const double bodyHeight = 70;
  static const double borderRadius = 26;

  static TextStyle _labelStyle(bool selected, Color color) => TextStyle(
    fontFamily: AppTypography.fontBody,
    fontSize: 11,
    height: 1.2,
    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    color: color,
  );

  /// Measures wrapped labels with the same available space as the actual pill.
  static double heightFor(BuildContext context, {double? availableWidth}) {
    final viewport = MediaQuery.sizeOf(context).width;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final width =
        availableWidth ??
        math.min(viewport > 0 ? viewport : 390.0, 720.0) -
            (largeText ? 24.0 : 48.0);
    final labelWidth = math.max(1.0, (width - 8) / kNavPillTabs.length);
    var labelHeight = 0.0;
    for (final tab in kNavPillTabs) {
      final painter = TextPainter(
        text: TextSpan(text: tab.label, style: _labelStyle(true, Colors.white)),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: labelWidth);
      labelHeight = math.max(labelHeight, painter.height);
      painter.dispose();
    }
    return math.max(height, 21 * 1.15 + 3 + labelHeight + 16);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final validActive = activeIndex.clamp(0, kNavPillTabs.length - 1);
    void activate(int index) {
      HapticFeedback.selectionClick();
      ref.read(bottomNavIndexProvider.notifier).select(index);
      onTabSelected(index);
    }

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: heightFor(context, availableWidth: constraints.maxWidth),
        child: GlassCard(
          borderRadius: borderRadius,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          sigmaBlur: 10,
          blur: true,
          repaintBoundary: true,
          borderWidth: 1.0,
          borderColor: Colors.white.withValues(alpha: 0.24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.16),
              const Color(0xFF161A26).withValues(alpha: 0.42),
              const Color(0xFF0F121B).withValues(alpha: 0.58),
            ],
            stops: const [0.0, 0.35, 1.0],
          ),
          child: Row(
            children: [
              for (var i = 0; i < kNavPillTabs.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == validActive,
                    button: true,
                    label: kNavPillTabs[i].label,
                    onTap: () => activate(i),
                    excludeSemantics: true,
                    child: ImmediatePressFeedback(
                      builder: (context, statesController) =>
                          ValueListenableBuilder(
                            valueListenable: statesController,
                            builder: (context, states, child) => DecoratedBox(
                              key: ValueKey('nav-press-$i'),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: states.contains(WidgetState.pressed)
                                    ? accent.withValues(alpha: .12)
                                    : Colors.transparent,
                              ),
                              child: child,
                            ),
                            child: InkWell(
                              statesController: statesController,
                              onTap: () => activate(i),
                              borderRadius: BorderRadius.circular(20),
                              highlightColor: Colors.transparent,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Transform.scale(
                                        scale: i == validActive ? 1.15 : 1.0,
                                        child: Icon(
                                          i == validActive
                                              ? kNavPillTabs[i].activeIcon
                                              : kNavPillTabs[i].icon,
                                          size: 21,
                                          color: i == validActive
                                              ? accent
                                              : AppColors.platinum,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          kNavPillTabs[i].label,
                                          textAlign: TextAlign.center,
                                          softWrap: true,
                                          style: _labelStyle(
                                            i == validActive,
                                            i == validActive
                                                ? accent
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
