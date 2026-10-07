/// LEON floating glass navigation pill.
///
/// Per the Liquid Glass Tactical spec (§ Floating Navigation Pill): a fully
/// pill-shaped glass bar floating over the content, outlined icons only, with a
/// 32px radial cyan glow sitting *behind* the active icon. The glow slides
/// between tabs rather than cutting, so the eye tracks the move.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../state/app_providers.dart';

/// One tab in the navigation pill.
class NavPillTab {
  const NavPillTab({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;

  /// Not rendered — used as the accessibility label.
  final String label;

  final String route;
}

/// The five main tabs, in display order. Index positions match
/// [bottomNavIndexProvider].
const List<NavPillTab> kNavPillTabs = <NavPillTab>[
  NavPillTab(
    icon: Icons.dashboard_outlined,
    label: 'Dashboard',
    route: AppConstants.routeDashboard,
  ),
  NavPillTab(
    icon: Icons.work_outline,
    label: 'Builder',
    route: AppConstants.routeWorkoutBuilder,
  ),
  NavPillTab(
    icon: Icons.fitness_center,
    label: 'Exercises',
    route: AppConstants.routeExerciseLibrary,
  ),
  NavPillTab(
    icon: Icons.show_chart,
    label: 'Analytics',
    route: AppConstants.routeAnalytics,
  ),
  NavPillTab(
    icon: Icons.person_outline,
    label: 'Profile',
    route: AppConstants.routeProfile,
  ),
];

/// Index of the tab owning [location], or -1 when none does.
int navPillIndexFor(String location) {
  // Longest match first so `/workout-builder` doesn't lose to `/`.
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

  /// Called with the tapped index. The pill also updates
  /// [bottomNavIndexProvider] so other widgets can read the selection.
  final ValueChanged<int> onTabSelected;

  static const double height = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const radius = BorderRadius.all(Radius.circular(height / 2));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            // Elevated glass: the pill floats above content, so it reads
            // brighter than a card.
            color: AppColors.glassWhiteStrong,
            borderRadius: radius,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (activeIndex >= 0) _ActiveGlow(index: activeIndex),
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
        ),
      ),
    );
  }
}

/// The 32px radial cyan glow that slides behind the active icon.
class _ActiveGlow extends StatelessWidget {
  const _ActiveGlow({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    // Tabs are equal-width, so the centre of tab i sits at this alignment.
    final x = -1 + 2 * index / (kNavPillTabs.length - 1);

    return AnimatedAlign(
      alignment: Alignment(x, 0),
      duration: AppConstants.animNormal,
      curve: Curves.easeOutCubic,
      child: IgnorePointer(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 32,
              ),
            ],
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
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: GlassNavPill.height,
          child: Center(
            child: AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: AppConstants.animFast,
              child: Icon(
                tab.icon,
                size: 22,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
