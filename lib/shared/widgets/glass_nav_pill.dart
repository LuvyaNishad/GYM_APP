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
    final validActive = activeIndex.clamp(0, kNavPillTabs.length - 1);

    return SizedBox(
      height: height,
      child: GlassCard(
        borderRadius: borderRadius,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        sigmaBlur: 14,
        blur: true,
        borderWidth: 1.0,
        borderColor: Colors.white.withValues(alpha: 0.24),
        glowColor: const Color(0xFF40C4FF).withValues(alpha: 0.16),
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
        child: Stack(
          children: [
            // ── 1. Animated Sliding White-Blue Luminous Spotlight ───────────
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment(
                -1.0 + (validActive * 2.0 / (kNavPillTabs.length - 1)),
                0.0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1.0 / kNavPillTabs.length,
                heightFactor: 1.0,
                child: Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.45),
                          const Color(0xFF80D8FF).withValues(alpha: 0.35),
                          const Color(0xFF2979FF).withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.30, 0.65, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF448AFF).withValues(alpha: 0.30),
                          blurRadius: 26,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── 2. Interactive Navigation Tabs (Clean, No Box Border) ───────
            Row(
              children: [
                for (var i = 0; i < kNavPillTabs.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: i == validActive,
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: i == validActive ? 1.15 : 1.0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  child: Icon(
                                    i == validActive
                                        ? kNavPillTabs[i].activeIcon
                                        : kNavPillTabs[i].icon,
                                    size: 21,
                                    color: i == validActive
                                        ? Colors.white
                                        : AppColors.platinum
                                            .withValues(alpha: 0.65),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  kNavPillTabs[i].label,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontBody,
                                    fontSize: 11,
                                    fontWeight: i == validActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: i == validActive
                                        ? Colors.white
                                        : AppColors.platinum
                                            .withValues(alpha: 0.65),
                                    shadows: i == validActive
                                        ? [
                                            Shadow(
                                              color: const Color(0xFF80D8FF)
                                                  .withValues(alpha: 0.70),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
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
          ],
        ),
      ),
    );
  }
}
