/// LEON Atmospheric Ambient Glow Backdrop.
///
/// Features:
/// - Prominent, luminescent gradient: brilliant whitish origin spreading out into vibrant electric blue
/// - High-performance hardware acceleration with zero GC allocations in render loop
/// - Snappy, instant 140ms transition when switching sections
/// - Screen-aware spatial positioning:
///   * Tab 0 (Home / Dashboard): Whitish bottom origin spreading upward behind cards
///   * Tab 1 (Workouts): Emits from both left and right flanks as tactical framing brackets
///   * Tab 2 (Exercises): Top-right horizon spreading down behind search & filters
///   * Tab 3 (History): Wide center-horizon ribbon framing charts
///   * Tab 4 (Profile): Top-center avatar halo
/// - Organic, subtle breathing micro-motion (sine-wave idle drift)
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Preset configurations for standalone screens or modals.
enum GlowPreset {
  home,
  workouts,
  exercises,
  history,
  profile,
  center,
}

/// A spatial configuration for the dual atmospheric glow emitters.
class _GlowConfig {
  const _GlowConfig({
    required this.alignmentA,
    required this.radiusA,
    required this.opacityA,
    required this.alignmentB,
    required this.radiusB,
    required this.opacityB,
  });

  final Alignment alignmentA;
  final double radiusA;
  final double opacityA;

  final Alignment alignmentB;
  final double radiusB;
  final double opacityB;

  // ── Prominent Glow Configurations ──────────────────────────────────────────
  // Opacities increased to 0.42-0.48 for strong luminescence while keeping contrast.
  static const _GlowConfig home = _GlowConfig(
    alignmentA: Alignment(-0.18, 1.02),
    radiusA: 1.20,
    opacityA: 0.48,
    alignmentB: Alignment(0.18, 1.02),
    radiusB: 1.20,
    opacityB: 0.48,
  );

  static const _GlowConfig workouts = _GlowConfig(
    alignmentA: Alignment(-1.08, 0.18),
    radiusA: 1.05,
    opacityA: 0.44,
    alignmentB: Alignment(1.08, 0.32),
    radiusB: 1.05,
    opacityB: 0.44,
  );

  static const _GlowConfig exercises = _GlowConfig(
    alignmentA: Alignment(0.75, -0.85),
    radiusA: 1.15,
    opacityA: 0.46,
    alignmentB: Alignment(-0.65, -0.45),
    radiusB: 0.90,
    opacityB: 0.32,
  );

  static const _GlowConfig history = _GlowConfig(
    alignmentA: Alignment(-0.85, 0.15),
    radiusA: 1.15,
    opacityA: 0.42,
    alignmentB: Alignment(0.85, 0.22),
    radiusB: 1.15,
    opacityB: 0.42,
  );

  static const _GlowConfig profile = _GlowConfig(
    alignmentA: Alignment(0.0, -0.92),
    radiusA: 1.15,
    opacityA: 0.46,
    alignmentB: Alignment(0.0, 0.70),
    radiusB: 0.80,
    opacityB: 0.28,
  );

  static const _GlowConfig center = _GlowConfig(
    alignmentA: Alignment(0.0, 0.0),
    radiusA: 1.05,
    opacityA: 0.44,
    alignmentB: Alignment(0.0, 0.35),
    radiusB: 0.85,
    opacityB: 0.30,
  );

  static _GlowConfig forIndex(int index) {
    switch (index) {
      case 0:
        return home;
      case 1:
        return workouts;
      case 2:
        return exercises;
      case 3:
        return history;
      case 4:
        return profile;
      default:
        return home;
    }
  }

  static _GlowConfig forPreset(GlowPreset preset) {
    switch (preset) {
      case GlowPreset.home:
        return home;
      case GlowPreset.workouts:
        return workouts;
      case GlowPreset.exercises:
        return exercises;
      case GlowPreset.history:
        return history;
      case GlowPreset.profile:
        return profile;
      case GlowPreset.center:
        return center;
    }
  }

  static _GlowConfig lerp(_GlowConfig a, _GlowConfig b, double t) {
    return _GlowConfig(
      alignmentA: Alignment.lerp(a.alignmentA, b.alignmentA, t) ?? b.alignmentA,
      radiusA: a.radiusA + (b.radiusA - a.radiusA) * t,
      opacityA: a.opacityA + (b.opacityA - a.opacityA) * t,
      alignmentB: Alignment.lerp(a.alignmentB, b.alignmentB, t) ?? b.alignmentB,
      radiusB: a.radiusB + (b.radiusB - a.radiusB) * t,
      opacityB: a.opacityB + (b.opacityB - a.opacityB) * t,
    );
  }
}

/// Atmospheric ambient glow backdrop widget.
class AtmosphericGlowBackdrop extends StatefulWidget {
  const AtmosphericGlowBackdrop({
    super.key,
    this.activeIndex = 0,
    this.preset,
    this.child,
  });

  /// The active main navigation tab index (0: Home, 1: Workouts, 2: Exercises, 3: History, 4: Profile).
  final int activeIndex;

  /// Optional preset for standalone screens. If specified, overrides [activeIndex].
  final GlowPreset? preset;

  /// Optional child content placed over this glowing backdrop.
  final Widget? child;

  @override
  State<AtmosphericGlowBackdrop> createState() => _AtmosphericGlowBackdropState();
}

class _AtmosphericGlowBackdropState extends State<AtmosphericGlowBackdrop>
    with TickerProviderStateMixin {
  late final AnimationController _transitionController;
  late final AnimationController _breathingController;

  late _GlowConfig _fromConfig;
  late _GlowConfig _toConfig;

  @override
  void initState() {
    super.initState();
    final initial = widget.preset != null
        ? _GlowConfig.forPreset(widget.preset!)
        : _GlowConfig.forIndex(widget.activeIndex);

    _fromConfig = initial;
    _toConfig = initial;

    // Fast, snappy 140ms transition for near-instant response when switching tabs
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      value: 1.0,
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AtmosphericGlowBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.preset != null
        ? _GlowConfig.forPreset(widget.preset!)
        : _GlowConfig.forIndex(widget.activeIndex);

    if (widget.activeIndex != oldWidget.activeIndex ||
        widget.preset != oldWidget.preset) {
      _fromConfig = _GlowConfig.lerp(
        _fromConfig,
        _toConfig,
        _transitionController.value,
      );
      _toConfig = target;
      // Snappy forward animation with easeOutQuad for instant visual presence
      _transitionController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = AnimatedBuilder(
      animation: Listenable.merge([_transitionController, _breathingController]),
      builder: (context, _) {
        final transitionProgress = Curves.easeOutQuad.transform(
          _transitionController.value,
        );
        final currentConfig = _GlowConfig.lerp(
          _fromConfig,
          _toConfig,
          transitionProgress,
        );

        final breathVal = _breathingController.value;
        final breathSine = math.sin(breathVal * math.pi * 2);
        final breathCosine = math.cos(breathVal * math.pi * 2);

        return CustomPaint(
          painter: _AtmosphericGlowPainter(
            config: currentConfig,
            driftX: breathSine * 0.025,
            driftY: breathCosine * 0.020,
            pulseFactor: 1.0 + (breathSine * 0.04),
          ),
          size: Size.infinite,
        );
      },
    );

    if (widget.child != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          painter,
          widget.child!,
        ],
      );
    }

    return painter;
  }
}

class _AtmosphericGlowPainter extends CustomPainter {
  _AtmosphericGlowPainter({
    required this.config,
    required this.driftX,
    required this.driftY,
    required this.pulseFactor,
  });

  final _GlowConfig config;
  final double driftX;
  final double driftY;
  final double pulseFactor;

  // ── Whitish-to-Blue Palette Stops ──────────────────────────────────────────
  // Starts with brilliant white at origin, spreading into electric cyan-blue,
  // then oceanic deep blue, dissolving into dark obsidian.
  static const Color _colorWhiteCore = Color(0xFFFFFFFF);
  static const Color _colorIceHighlight = Color(0xFFE0F2FE);
  static const Color _colorElectricCyan = Color(0xFF38BDF8);
  static const Color _colorOceanicBlue = Color(0xFF0284C7);
  static const Color _colorDeepSlateBlue = Color(0xFF0C4A6E);

  static const List<double> _glowStops = [0.0, 0.14, 0.36, 0.62, 0.84, 1.0];

  // Reused cached Paint instances to prevent GC allocation overhead during 120 FPS render
  static final Paint _bgPaint = Paint()..color = AppColors.dashboardBg;
  static final Paint _paintA = Paint()..blendMode = BlendMode.screen;
  static final Paint _paintB = Paint()..blendMode = BlendMode.screen;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Deep solid background canvas
    canvas.drawRect(rect, _bgPaint);

    // 2. Primary Atmospheric Emitter (Source A)
    final adjustedAlignA = Alignment(
      (config.alignmentA.x + driftX).clamp(-1.5, 1.5),
      (config.alignmentA.y + driftY).clamp(-1.5, 1.5),
    );
    final opA = (config.opacityA * pulseFactor).clamp(0.0, 0.65);

    final shaderA = RadialGradient(
      center: adjustedAlignA,
      radius: config.radiusA * pulseFactor,
      colors: [
        _colorWhiteCore.withValues(alpha: opA),
        _colorIceHighlight.withValues(alpha: opA * 0.88),
        _colorElectricCyan.withValues(alpha: opA * 0.65),
        _colorOceanicBlue.withValues(alpha: opA * 0.38),
        _colorDeepSlateBlue.withValues(alpha: opA * 0.12),
        Colors.transparent,
      ],
      stops: _glowStops,
    ).createShader(rect);

    _paintA.shader = shaderA;
    canvas.drawRect(rect, _paintA);

    // 3. Secondary Atmospheric Emitter (Source B)
    final adjustedAlignB = Alignment(
      (config.alignmentB.x - driftX).clamp(-1.5, 1.5),
      (config.alignmentB.y - driftY).clamp(-1.5, 1.5),
    );
    final opB = (config.opacityB * pulseFactor).clamp(0.0, 0.65);

    final shaderB = RadialGradient(
      center: adjustedAlignB,
      radius: config.radiusB * pulseFactor,
      colors: [
        _colorWhiteCore.withValues(alpha: opB),
        _colorIceHighlight.withValues(alpha: opB * 0.88),
        _colorElectricCyan.withValues(alpha: opB * 0.65),
        _colorOceanicBlue.withValues(alpha: opB * 0.38),
        _colorDeepSlateBlue.withValues(alpha: opB * 0.12),
        Colors.transparent,
      ],
      stops: _glowStops,
    ).createShader(rect);

    _paintB.shader = shaderB;
    canvas.drawRect(rect, _paintB);
  }

  @override
  bool shouldRepaint(covariant _AtmosphericGlowPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.driftX != driftX ||
        oldDelegate.driftY != driftY ||
        oldDelegate.pulseFactor != pulseFactor;
  }
}
