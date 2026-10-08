/// LEON floating liquid glass navigation pill.
///
/// Implements 21st.dev-inspired Liquid Glass Tactical aesthetics:
/// - Refractive frosted lens with 26px backdrop blur
/// - Multi-layer specular perimeter highlight and optical caustic rim
/// - Curved lens surface sheen and convex bevel depth
/// - Fluid sliding liquid indicator pod with cyan aura
/// - Logical tactical icons (Home, Workouts, Exercises, History, Account)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../state/app_providers.dart';
import 'liquid_glass.dart';

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

/// The five main operational tabs in display order.
/// Updated with logical, high-clarity tactical icons:
/// - Home (Dashboard & readiness overview)
/// - Workouts (Builder & active routine)
/// - Exercises (Movement library & form guides)
/// - History (Analytics, logs & progression records)
/// - Account (Profile, biometric settings & operative credentials)
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
        ? location == route
        : location.startsWith(route);
    if (matches && route.length >= bestLength) {
      bestIndex = i;
      bestLength = route.length;
    }
  }
  return bestIndex;
}

class GlassNavPill extends ConsumerWidget {
  const GlassNavPill({
    required this.activeIndex,
    required this.onTabSelected,
    super.key,
  });

  /// The tab to highlight. Pass -1 to highlight nothing.
  final int activeIndex;

  /// Called with the tapped index.
  final ValueChanged<int> onTabSelected;

  static const double height = 66;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const radiusVal = height / 2;

    return LiquidGlassContainer(
      height: height,
      borderRadius: radiusVal,
      blurSigma: 26,
      borderWidth: 1.2,
      showGlow: true,
      glowColor: AppColors.primary.withValues(alpha: 0.16),
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (activeIndex >= 0 && activeIndex < kNavPillTabs.length)
              _ActiveLiquidIndicator(
                index: activeIndex,
                totalTabs: kNavPillTabs.length,
              ),
            Row(
              children: [
                for (var i = 0; i < kNavPillTabs.length; i++)
                  Expanded(
                    child: _NavPillButton(
                      tab: kNavPillTabs[i],
                      isActive: i == activeIndex,
                      onTap: () {
                        ref.read(bottomNavIndexProvider.notifier).select(i);
                        onTabSelected(i);
                      },
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

/// The sliding liquid glass pod and neon aura behind the active tab.
class _ActiveLiquidIndicator extends StatelessWidget {
  const _ActiveLiquidIndicator({
    required this.index,
    required this.totalTabs,
  });

  final int index;
  final int totalTabs;

  @override
  Widget build(BuildContext context) {
    final x = totalTabs > 0 ? -1.0 + (2.0 * index + 1.0) / totalTabs : 0.0;

    return AnimatedAlign(
      alignment: Alignment(x, 0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: IgnorePointer(
        child: Container(
          width: 54,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // Glowing neon liquid aura
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
            // Liquid active pod fill
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.22),
                AppColors.primary.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.55),
              width: 1.0,
            ),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              width: 24,
              height: 1.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavPillButton extends StatelessWidget {
  const _NavPillButton({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final NavPillTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: tab.label,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: AppColors.primary.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: GlassNavPill.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.12 : 1.0,
                duration: AppConstants.animFast,
                curve: Curves.easeOutBack,
                child: Icon(
                  isActive ? tab.activeIcon : tab.icon,
                  size: 21,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.8),
                  shadows: isActive
                      ? [
                          Shadow(
                            color: AppColors.primary.withValues(alpha: 0.75),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: AppConstants.animFast,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 8.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 1.0,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.6),
                ),
                child: Text(tab.label.toUpperCase()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
