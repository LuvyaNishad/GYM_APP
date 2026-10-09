/// LEON floating limelight glass navigation pill.
///
/// Implements 21st.dev Limelight spotlight navigation:
/// - Horizontal glowing greyish-white emitter bar at the top of the pill
/// - Trapezoidal limelight spotlight beam shining downward over the active icon
/// - Smooth transition choreography: light dims on previous tab, emitter slides
///   smoothly across with dynamic stretch, and spotlight flares on over the new tab
/// - Greyish-white / luminous platinum palette for high-contrast visibility
///   over the Cyber-Slate liquid glass backdrop
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
      glowColor: Colors.white.withValues(alpha: 0.06),
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── 21st.dev Limelight Spotlight Indicator ──────────────────────
            if (activeIndex >= 0 && activeIndex < kNavPillTabs.length)
              LimelightIndicator(
                activeIndex: activeIndex,
                totalTabs: kNavPillTabs.length,
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

/// The Limelight spotlight indicator inspired by 21st.dev.
/// Features an overhead emitter bar and a smooth trapezoidal downward beam.
class LimelightIndicator extends StatefulWidget {
  const LimelightIndicator({
    super.key,
    required this.activeIndex,
    required this.totalTabs,
    this.lightColor = const Color(0xFFF1F5F9),
    this.barWidth = 36.0,
    this.barHeight = 3.5,
  });

  final int activeIndex;
  final int totalTabs;
  final Color lightColor;
  final double barWidth;
  final double barHeight;

  @override
  State<LimelightIndicator> createState() => _LimelightIndicatorState();
}

class _LimelightIndicatorState extends State<LimelightIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _intensityAnimation;
  late Animation<double> _stretchAnimation;

  int _previousIndex = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.activeIndex.clamp(0, widget.totalTabs - 1);
    _previousIndex = _currentIndex;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _slideAnimation = Tween<double>(
      begin: _alignmentFor(_currentIndex),
      end: _alignmentFor(_currentIndex),
    ).animate(_controller);

    _intensityAnimation = const AlwaysStoppedAnimation(1.0);
    _stretchAnimation = const AlwaysStoppedAnimation(1.0);
  }

  double _alignmentFor(int index) {
    if (widget.totalTabs <= 0) return 0.0;
    return -1.0 + (2.0 * index + 1.0) / widget.totalTabs;
  }

  @override
  void didUpdateWidget(LimelightIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != _currentIndex && widget.activeIndex >= 0) {
      _previousIndex = _currentIndex;
      _currentIndex = widget.activeIndex.clamp(0, widget.totalTabs - 1);

      final startX = _alignmentFor(_previousIndex);
      final endX = _alignmentFor(_currentIndex);

      _slideAnimation = Tween<double>(
        begin: startX,
        end: endX,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOutCubic,
        ),
      );

      // Light turns off (1.0 -> 0.15) during early motion, then turns on (0.15 -> 1.0) as it lands
      _intensityAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.15)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 35,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.15, end: 0.15),
          weight: 15,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.15, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInCubic)),
          weight: 50,
        ),
      ]).animate(_controller);

      // Subtle dynamic stretch during transit
      _stretchAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.25)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 45,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.25, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 55,
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alignX = _controller.isAnimating
            ? _slideAnimation.value
            : _alignmentFor(_currentIndex);
        final intensity = _controller.isAnimating
            ? _intensityAnimation.value
            : 1.0;
        final stretch = _controller.isAnimating
            ? _stretchAnimation.value
            : 1.0;

        final currentBarWidth = widget.barWidth * stretch;

        return Align(
          alignment: Alignment(alignX, -1.0),
          child: IgnorePointer(
            child: SizedBox(
              width: 80,
              height: GlassNavPill.height,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // 1. Limelight Spotlight Cone (Beam shining down)
                  CustomPaint(
                    size: const Size(80, GlassNavPill.height),
                    painter: _LimelightBeamPainter(
                      color: widget.lightColor,
                      intensity: intensity,
                      topWidth: currentBarWidth,
                      bottomWidth: currentBarWidth * 1.75,
                      height: GlassNavPill.height - 4,
                    ),
                  ),

                  // 2. Horizontal Header Emitter Bar (Glowing top pill)
                  Container(
                    margin: const EdgeInsets.only(top: 1.0),
                    width: currentBarWidth,
                    height: widget.barHeight,
                    decoration: BoxDecoration(
                      color: widget.lightColor,
                      borderRadius: BorderRadius.circular(widget.barHeight / 2),
                      boxShadow: [
                        BoxShadow(
                          color: widget.lightColor.withValues(alpha: 0.85 * intensity),
                          blurRadius: 6,
                          spreadRadius: 0.5,
                        ),
                        BoxShadow(
                          color: widget.lightColor.withValues(alpha: 0.35 * intensity),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter that draws the trapezoidal limelight beam
class _LimelightBeamPainter extends CustomPainter {
  const _LimelightBeamPainter({
    required this.color,
    required this.intensity,
    required this.topWidth,
    required this.bottomWidth,
    required this.height,
  });

  final Color color;
  final double intensity;
  final double topWidth;
  final double bottomWidth;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.01) return;

    final centerX = size.width / 2;
    final halfTop = topWidth / 2;
    final halfBottom = bottomWidth / 2;

    // Trapezoidal spotlight cone
    final path = Path()
      ..moveTo(centerX - halfTop, 2)
      ..lineTo(centerX + halfTop, 2)
      ..lineTo(centerX + halfBottom, height)
      ..lineTo(centerX - halfBottom, height)
      ..close();

    // Downward soft gradient
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.30 * intensity),
          color.withValues(alpha: 0.14 * intensity),
          color.withValues(alpha: 0.04 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, height));

    canvas.drawPath(path, beamPaint);

    // Central diffuse beam core for soft physical radiance
    final corePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 0.9,
        colors: [
          color.withValues(alpha: 0.22 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, height));

    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant _LimelightBeamPainter old) {
    return old.intensity != intensity ||
        old.topWidth != topWidth ||
        old.bottomWidth != bottomWidth ||
        old.color != color;
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
    final activeColor = Colors.white;
    final inactiveColor = Colors.white.withValues(alpha: 0.42);

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
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: GlassNavPill.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              AnimatedScale(
                scale: isActive ? 1.10 : 1.0,
                duration: AppConstants.animFast,
                curve: Curves.easeOutBack,
                child: Icon(
                  isActive ? tab.activeIcon : tab.icon,
                  size: 21,
                  color: isActive ? activeColor : inactiveColor,
                  shadows: isActive
                      ? [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.70),
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
                  color: isActive ? activeColor : inactiveColor.withValues(alpha: 0.35),
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
