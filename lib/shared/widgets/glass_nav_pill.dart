/// LEON floating tubelight glass navigation pill.
///
/// Implements the 21st.dev / shadcn Tubelight Navbar matching the reference:
/// - Clean, non-glitchy uniform dark glass capsule container
/// - Bulging emitter element that visibly protrudes above the top edge of the navbar
/// - Uniform atmospheric glow and smooth downward light wash
/// - Solid muted active tab background pill (Color(0xFF222634))
/// - Smooth spring-like slide transition connecting tabs with easeInOutCubic physics
/// - Vertically centered icons and labels with high contrast
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../state/app_providers.dart';

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

  /// Total height of the widget including the top bulging emitter protrusion.
  static const double height = 70.0;

  /// Height of the glass pill body itself (below the bulging emitter).
  static const double bodyHeight = 62.0;

  /// Corner radius for stadium capsule styling (rounded-full).
  static const double borderRadius = 31.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── 1. Clean Glass Pill Body Container (No Glitchy Reflections) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bodyHeight,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141722).withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 2. Sliding Tubelight Emitter & Active Tab Background ──────────
          if (activeIndex >= 0 && activeIndex < kNavPillTabs.length)
            Positioned.fill(
              child: TubelightIndicator(
                activeIndex: activeIndex,
                totalTabs: kNavPillTabs.length,
              ),
            ),

          // ── 3. Navigation Buttons Row ────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bodyHeight,
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  for (var i = 0; i < kNavPillTabs.length; i++)
                    Expanded(
                      child: _NavPillButton(
                        tab: kNavPillTabs[i],
                        isActive: i == activeIndex,
                        height: bodyHeight,
                        onTap: () {
                          ref.read(bottomNavIndexProvider.notifier).select(i);
                          onTabSelected(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias for any references to LimelightIndicator.
typedef LimelightIndicator = TubelightIndicator;

/// Tubelight Indicator that renders:
/// 1. The active tab rounded background pill
/// 2. The overhead bulging emitter element protruding above the navbar pill
/// 3. The smooth uniform downward light wash
class TubelightIndicator extends StatefulWidget {
  const TubelightIndicator({
    super.key,
    required this.activeIndex,
    required this.totalTabs,
    this.lampColor = const Color(0xFFF8FAFC),
    this.tubeWidth = 34.0,
    this.tubeHeight = 5.5,
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
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(
      begin: _currentIndex.toDouble(),
      end: _currentIndex.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
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
          curve: Curves.easeOutCubic,
        ),
      );

      // Smooth intensity transition during transit
      _intensityAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.50)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.50, end: 1.0)
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
        final bodyTopOffset = totalHeight - GlassNavPill.bodyHeight; // 8.0

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
            final activePillWidth = (tabWidth - 6).clamp(38.0, tabWidth);
            final activePillHeight = GlassNavPill.bodyHeight - 12; // 50.0

            return IgnorePointer(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── A. Active Tab Background Pill (Muted Solid Pill) ───────
                  Positioned(
                    left: currentCenterX - (activePillWidth / 2),
                    top: bodyTopOffset + 6.0,
                    width: activePillWidth,
                    height: activePillHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF222634),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),

                  // ── B. Uniform Downward Light Wash ────────────────────────
                  Positioned(
                    left: currentCenterX - (activePillWidth / 2),
                    top: bodyTopOffset,
                    width: activePillWidth,
                    height: 38.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(21),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.36 * intensity),
                            Colors.white.withValues(alpha: 0.14 * intensity),
                            Colors.white.withValues(alpha: 0.03 * intensity),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.35, 0.70, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // ── C. Soft Atmospheric Glow Halo around Bulging Emitter ──
                  Positioned(
                    left: currentCenterX - 22.0,
                    top: bodyTopOffset - 6.0,
                    child: Container(
                      width: 44.0,
                      height: 16.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white
                                .withValues(alpha: 0.45 * intensity),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.white
                                .withValues(alpha: 0.25 * intensity),
                            blurRadius: 22,
                            spreadRadius: 3,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── D. THE BULGING EMITTER ELEMENT ────────────────────────
                  // Protrudes visibly above the top edge of the navbar pill
                  Positioned(
                    left: currentCenterX - (widget.tubeWidth / 2),
                    top: bodyTopOffset - 3.8, // Bulges ~4px out above the pill
                    child: Container(
                      width: widget.tubeWidth,
                      height: widget.tubeHeight,
                      decoration: BoxDecoration(
                        color: widget.lampColor,
                        borderRadius: BorderRadius.circular(3.0),
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

/// Navigation Button for each tab item with instant touch response and Title Case label.
class _NavPillButton extends StatefulWidget {
  const _NavPillButton({
    required this.tab,
    required this.isActive,
    required this.height,
    required this.onTap,
  });

  final NavPillTab tab;
  final bool isActive;
  final double height;
  final VoidCallback onTap;

  @override
  State<_NavPillButton> createState() => _NavPillButtonState();
}

class _NavPillButtonState extends State<_NavPillButton> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.white;
    // Apple HIG Contrast: min 4.5:1 on dark glass surface (60% white yields ~5.4:1)
    final inactiveColor = Colors.white.withValues(alpha: 0.60);

    return Semantics(
      button: true,
      selected: widget.isActive,
      label: widget.tab.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _isDown = true);
        },
        onTapUp: (_) {
          setState(() => _isDown = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isDown = false),
        child: AnimatedScale(
          scale: _isDown ? 0.94 : (widget.isActive ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            height: widget.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  widget.isActive ? widget.tab.activeIcon : widget.tab.icon,
                  size: 20,
                  color: widget.isActive ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 2.5),
                AnimatedDefaultTextStyle(
                  duration: AppConstants.animFast,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    // Apple HIG Minimum Typography Floor: 11.0 pt
                    fontSize: 11.0,
                    fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2, // Natural tracking for title case
                    color: widget.isActive ? activeColor : inactiveColor,
                  ),
                  // Apple HIG tab-bars.md: Title Case, not ALL CAPS
                  child: Text(widget.tab.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
