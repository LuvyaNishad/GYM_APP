import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/app_providers.dart';
import 'glass_card.dart';

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

/// Floating frosted acrylic navigation pill with a specular light streak rim.
/// Replicates premium liquid glass: content passing behind is visibly diffused,
/// softly refracted, and recognizable with specular bevel catch along the top rim.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: height,
      child: GlassCard(
        borderRadius: borderRadius,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        sigmaBlur: 10,
        blur: true,
        borderWidth: 1.2,
        borderColor: Colors.white.withValues(alpha: 0.85),
        glowColor: AppColors.primary.withValues(alpha: 0.12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.22), // Specular surface light sheen
            const Color(0xFF1E2638).withValues(alpha: 0.32), // Translucent frosted acrylic body
            const Color(0xFF121622).withValues(alpha: 0.44), // Grounded glass base
          ],
          stops: const [0.0, 0.30, 1.0],
        ),
        child: Row(
          children: [
            for (var i = 0; i < kNavPillTabs.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == activeIndex,
                  button: true,
                  label: kNavPillTabs[i].label,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(bottomNavIndexProvider.notifier).select(i);
                      onTabSelected(i);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: i == activeIndex ? 10 : 2,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: i == activeIndex
                              ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.22),
                                    AppColors.primary.withValues(alpha: 0.08),
                                  ],
                                )
                              : null,
                          border: i == activeIndex
                              ? Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.55),
                                  width: 1.0,
                                )
                              : null,
                          boxShadow: i == activeIndex
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.28),
                                    blurRadius: 10,
                                    spreadRadius: -1,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              i == activeIndex
                                  ? kNavPillTabs[i].activeIcon
                                  : kNavPillTabs[i].icon,
                              size: 21,
                              color: i == activeIndex
                                  ? AppColors.primary
                                  : AppColors.platinum,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              kNavPillTabs[i].label,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppTypography.fontBody,
                                fontSize: 11,
                                fontWeight: i == activeIndex
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: i == activeIndex
                                    ? AppColors.primary
                                    : AppColors.platinum,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
