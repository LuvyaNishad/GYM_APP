/// LEON floating tubelight glass navigation pill.
///
/// Implements the 21st.dev / shadcn Tubelight Navbar:
/// - Rounded pill container with backdrop blur and border
/// - Active tab highlighted with a rounded pill background (bg-muted / bg-primary/5)
/// - Overhead "tubelight" lamp emitter positioned on the top edge of the active tab
/// - 3-tier concentrated downward glow blooms mirroring the React component:
///   1) Wide soft glow (48x24, blur 14)
///   2) Medium glow (32x16, blur 8)
///   3) Core lamp bloom (16x10, blur 4)
///   4) Solid overhead tube emitter bar (32x3.5) with rounded top corners
/// - Smooth spring-sliding transition that glides the lamp and active background
///   across tabs with easeInOutCubic physics
/// - Clean dark Cyber-Slate palette with high-contrast text and icons
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
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

/// Floating Tubelight Glass Navigation Pill.
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

  static const double height = 64.0;

  /// Corner radius for stadium capsule styling (rounded-full).
  static const double borderRadius = 32.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LiquidGlassContainer(
      height: height,
      borderRadius: borderRadius,
      blurSigma: 24,
      borderWidth: 1.0,
      showGlow: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Tubelight Animated Lamp Indicator ────────────────────────────
            if (activeIndex >= 0 && activeIndex < kNavPillTabs.length)
              Positioned.fill(
                child: TubelightIndicator(
                  activeIndex: activeIndex,
                  totalTabs: kNavPillTabs.length,
                ),
              ),

            // ── Navigation Buttons Row ───────────────────────────────────────
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

/// Backward compatibility alias for any references to LimelightIndicator.
typedef LimelightIndicator = TubelightIndicator;

/// Tubelight Lamp Indicator ported directly from 21st.dev / shadcn Tubelight Navbar.
/// Features a rounded active tab highlight pill with an overhead tubelight fixture
/// and concentrated 3-layer downward glow blooms.
class TubelightIndicator extends StatefulWidget {
  const TubelightIndicator({
    super.key,
    required this.activeIndex,
    required this.totalTabs,
    this.lampColor = const Color(0xFFF1F5F9),
    this.tubeWidth = 32.0,
    this.tubeHeight = 3.5,
  });

  final int activeIndex;
  final int totalTabs;
  final Color lampColor;
  final double tubeWidth;
  final double tubeHeight;

  @override
  State<TubelightIndicator> createState() => _TubelightIndicatorState();
}

class _TubelightIndicatorState extends State<TubelightIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _intensityAnimation;

  int _previousIndex = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.activeIndex.clamp(0, widget.totalTabs - 1);
    _previousIndex = _currentIndex;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<double>(
      begin: _currentIndex.toDouble(),
      end: _currentIndex.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _intensityAnimation = const AlwaysStoppedAnimation(1.0);
  }

  @override
  void didUpdateWidget(TubelightIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != _currentIndex && widget.activeIndex >= 0) {
      _previousIndex = _currentIndex;
      _currentIndex = widget.activeIndex.clamp(0, widget.totalTabs - 1);

      final startPos = _controller.isAnimating
          ? _slideAnimation.value
          : _previousIndex.toDouble();
      final endPos = _currentIndex.toDouble();

      _slideAnimation = Tween<double>(
        begin: startPos,
        end: endPos,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOutCubic,
        ),
      );

      // Tubelight dynamic glow dip during movement, then flares bright upon landing
      _intensityAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.40)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.40, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInCubic)),
          weight: 60,
        ),
      ]).animate(_controller);

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeIndex < 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        if (totalWidth <= 0 || widget.totalTabs <= 0) {
          return const SizedBox.shrink();
        }

        final tabWidth = totalWidth / widget.totalTabs;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final animIndex = _controller.isAnimating
                ? _slideAnimation.value
                : _currentIndex.toDouble();
            final intensity = _controller.isAnimating
                ? _intensityAnimation.value
                : 1.0;

            final currentCenterX = (animIndex + 0.5) * tabWidth;
            final activePillWidth = (tabWidth - 6).clamp(36.0, tabWidth);
            final activePillHeight = totalHeight - 10;
            final tubeWidth = widget.tubeWidth.clamp(20.0, tabWidth * 0.7);

            return IgnorePointer(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── 1. Active Tab Pill Background (bg-muted / bg-primary/5) ──
                  Positioned(
                    left: currentCenterX - (activePillWidth / 2),
                    top: 5.0,
                    width: activePillWidth,
                    height: activePillHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08 * intensity),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.07 * intensity),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),

                  // ── 2. Layer 1: Wide Soft Downward Glow (w-12 h-6 blur-md) ──
                  Positioned(
                    left: currentCenterX - 24,
                    top: -2.0,
                    child: Container(
                      width: 48,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: widget.lampColor
                            .withValues(alpha: 0.18 * intensity),
                        boxShadow: [
                          BoxShadow(
                            color: widget.lampColor
                                .withValues(alpha: 0.28 * intensity),
                            blurRadius: 14,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 3. Layer 2: Medium Concentrated Glow (w-8 h-6 blur-md) ──
                  Positioned(
                    left: currentCenterX - 16,
                    top: -1.0,
                    child: Container(
                      width: 32,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: widget.lampColor
                            .withValues(alpha: 0.24 * intensity),
                        boxShadow: [
                          BoxShadow(
                            color: widget.lampColor
                                .withValues(alpha: 0.40 * intensity),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 4. Layer 3: Core Lamp Bloom (w-4 h-4 blur-sm) ──────────
                  Positioned(
                    left: currentCenterX - 8,
                    top: 1.0,
                    child: Container(
                      width: 16,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: widget.lampColor
                            .withValues(alpha: 0.35 * intensity),
                        boxShadow: [
                          BoxShadow(
                            color: widget.lampColor
                                .withValues(alpha: 0.60 * intensity),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 5. Overhead Tubelight Bar (w-8 h-1 bg-primary rounded-t-full) ─
                  Positioned(
                    left: currentCenterX - (tubeWidth / 2),
                    top: 0.0,
                    child: Container(
                      width: tubeWidth,
                      height: widget.tubeHeight,
                      decoration: BoxDecoration(
                        color: widget.lampColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                          bottomLeft: Radius.circular(1),
                          bottomRight: Radius.circular(1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.lampColor
                                .withValues(alpha: 0.95 * intensity),
                            blurRadius: 5,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Navigation Button for each tab item.
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
    const activeColor = Colors.white;
    final inactiveColor = Colors.white.withValues(alpha: 0.45);

    return Semantics(
      button: true,
      selected: isActive,
      label: tab.label,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: GlassNavPill.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.06 : 1.0,
                duration: AppConstants.animFast,
                curve: Curves.easeOutBack,
                child: Icon(
                  isActive ? tab.activeIcon : tab.icon,
                  size: 20,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 3.0),
              AnimatedDefaultTextStyle(
                duration: AppConstants.animFast,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9.0,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 1.0,
                  color: isActive ? activeColor : inactiveColor,
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
