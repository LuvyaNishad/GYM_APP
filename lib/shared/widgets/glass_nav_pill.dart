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
              Positioned.fill(
                child: LimelightIndicator(
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

/// The Limelight spotlight indicator inspired by 21st.dev.
/// Features an overhead emitter bar and a smooth trapezoidal downward beam.
class LimelightIndicator extends StatefulWidget {
  const LimelightIndicator({
    super.key,
    required this.activeIndex,
    required this.totalTabs,
    this.lightColor = const Color(0xFFF1F5F9),
    this.barWidth = 40.0,
    this.barHeight = 4.0,
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
      begin: _currentIndex.toDouble(),
      end: _currentIndex.toDouble(),
    ).animate(_controller);

    _intensityAnimation = const AlwaysStoppedAnimation(1.0);
    _stretchAnimation = const AlwaysStoppedAnimation(1.0);
  }

  @override
  void didUpdateWidget(LimelightIndicator oldWidget) {
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
            final stretch = _controller.isAnimating
                ? _stretchAnimation.value
                : 1.0;

            final currentCenterX = (animIndex + 0.5) * tabWidth;
            final currentBarWidth =
                (widget.barWidth * stretch).clamp(24.0, tabWidth * 0.85);
            final bottomBeamWidth =
                (tabWidth * 0.92).clamp(currentBarWidth * 1.3, tabWidth);

            return IgnorePointer(
              child: Stack(
                children: [
                  // 1. Limelight Spotlight Cone (Beam shining down over active icon and label)
                  CustomPaint(
                    size: Size(totalWidth, totalHeight),
                    painter: _LimelightBeamPainter(
                      color: widget.lightColor,
                      intensity: intensity,
                      centerX: currentCenterX,
                      topWidth: currentBarWidth,
                      bottomWidth: bottomBeamWidth,
                      height: totalHeight,
                    ),
                  ),

                  // 2. Horizontal Header Emitter Bar (Glowing top pill)
                  Positioned(
                    left: currentCenterX - (currentBarWidth / 2),
                    top: 1.0,
                    child: Container(
                      width: currentBarWidth,
                      height: widget.barHeight,
                      decoration: BoxDecoration(
                        color: widget.lightColor,
                        borderRadius:
                            BorderRadius.circular(widget.barHeight / 2),
                        boxShadow: [
                          BoxShadow(
                            color: widget.lightColor
                                .withValues(alpha: 0.95 * intensity),
                            blurRadius: 7,
                            spreadRadius: 0.6,
                          ),
                          BoxShadow(
                            color: widget.lightColor
                                .withValues(alpha: 0.45 * intensity),
                            blurRadius: 18,
                            offset: const Offset(0, 3),
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

/// Custom painter that draws the trapezoidal limelight spotlight beam
class _LimelightBeamPainter extends CustomPainter {
  const _LimelightBeamPainter({
    required this.color,
    required this.intensity,
    required this.centerX,
    required this.topWidth,
    required this.bottomWidth,
    required this.height,
  });

  final Color color;
  final double intensity;
  final double centerX;
  final double topWidth;
  final double bottomWidth;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.01) return;

    final halfTop = topWidth / 2;
    final halfBottom = bottomWidth / 2;

    // Trapezoidal spotlight cone
    final path = Path()
      ..moveTo(centerX - halfTop, 2.0)
      ..lineTo(centerX + halfTop, 2.0)
      ..lineTo(centerX + halfBottom, height)
      ..lineTo(centerX - halfBottom, height)
      ..close();

    final beamRect = Rect.fromLTWH(
      centerX - halfBottom,
      0,
      bottomWidth,
      height,
    );

    // 1. Primary downward beam gradient spanning full height
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.42 * intensity),
          color.withValues(alpha: 0.28 * intensity),
          color.withValues(alpha: 0.16 * intensity),
          color.withValues(alpha: 0.05 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.60, 0.88, 1.0],
      ).createShader(beamRect);

    canvas.drawPath(path, beamPaint);

    // 2. Central radiant beam core (emitter glow bloom)
    final corePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.65),
        radius: 0.85,
        colors: [
          color.withValues(alpha: 0.28 * intensity),
          color.withValues(alpha: 0.10 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(beamRect);

    canvas.drawPath(path, corePaint);

    // 3. Ground illumination puddle on the active icon and label section
    final groundRect = Rect.fromCenter(
      center: Offset(centerX, height * 0.60),
      width: bottomWidth * 0.95,
      height: height * 0.65,
    );
    final groundPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          color.withValues(alpha: 0.15 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(groundRect);

    canvas.drawOval(groundRect, groundPaint);

    // 4. Subtle optical boundary rays for volumetric light feel
    final edgePaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.30 * intensity),
          color.withValues(alpha: 0.10 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(beamRect);

    canvas.drawLine(
      Offset(centerX - halfTop, 2.0),
      Offset(centerX - halfBottom, height),
      edgePaint,
    );
    canvas.drawLine(
      Offset(centerX + halfTop, 2.0),
      Offset(centerX + halfBottom, height),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LimelightBeamPainter old) {
    return old.intensity != intensity ||
        old.centerX != centerX ||
        old.topWidth != topWidth ||
        old.bottomWidth != bottomWidth ||
        old.height != height ||
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
    final inactiveColor = Colors.white.withValues(alpha: 0.40);

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
              const SizedBox(height: 5),
              AnimatedScale(
                scale: isActive ? 1.08 : 1.0,
                duration: AppConstants.animFast,
                curve: Curves.easeOutBack,
                child: Icon(
                  isActive ? tab.activeIcon : tab.icon,
                  size: 21,
                  color: isActive ? activeColor : inactiveColor,
                  shadows: isActive
                      ? [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.80),
                            blurRadius: 10,
                          ),
                          Shadow(
                            color: const Color(0xFFF1F5F9).withValues(alpha: 0.40),
                            blurRadius: 18,
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
                  fontSize: 9.0,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 1.1,
                  color: isActive ? activeColor : inactiveColor,
                  shadows: isActive
                      ? [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.65),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
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
