import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/tempo_pacer_state.dart';

/// Renders a dynamic, high-tech biomechanical wave track (the "gym game" visualizer).
///
/// Features:
/// - Real-time animated kinetic energy orb with trailing comet aura & sonar ripples.
/// - Dynamic biomechanical S-curve showing Descent (eccentric), Depth Plateau (isometric hold),
///   and Steep Ascent (concentric drive).
/// - Illuminated past trajectory vs. blueprint upcoming trajectory.
/// - Horizontal datum lines (LOCKOUT / DEPTH) and phase transition markers.
/// - Vertical energetic laser filaments beneath the curve.
class TempoSineWaveWidget extends StatefulWidget {
  final TempoPacerState state;
  final double height;

  const TempoSineWaveWidget({
    super.key,
    required this.state,
    this.height = 200,
  });

  @override
  State<TempoSineWaveWidget> createState() => _TempoSineWaveWidgetState();
}

class _TempoSineWaveWidgetState extends State<TempoSineWaveWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tickerController;
  final Stopwatch _phaseStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    // Continuous VSync animation ticker for 60/120 FPS buttery smooth curve motion
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    if (widget.state.isActive && !widget.state.isPaused) {
      _phaseStopwatch.start();
    }
  }

  @override
  void didUpdateWidget(covariant TempoSineWaveWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.phase != widget.state.phase ||
        oldWidget.state.currentRep != widget.state.currentRep) {
      _phaseStopwatch.reset();
      if (widget.state.isActive && !widget.state.isPaused) {
        _phaseStopwatch.start();
      }
    }

    if (oldWidget.state.isPaused != widget.state.isPaused) {
      if (widget.state.isPaused) {
        _phaseStopwatch.stop();
      } else {
        _phaseStopwatch.start();
      }
    }
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _phaseStopwatch.stop();
    super.dispose();
  }

  int _getPhaseDurationMs(TempoPhase phase, TempoPreset preset, bool isConcentricFirst) {
    switch (phase) {
      case TempoPhase.countdown:
        return 5000;
      case TempoPhase.eccentric:
        return preset.eccentricSeconds * 1000;
      case TempoPhase.bottomHold:
        return preset.bottomHoldSeconds * 1000;
      case TempoPhase.concentric:
        return preset.concentricSeconds * 1000;
      case TempoPhase.topHold:
        return preset.topHoldSeconds * 1000;
      case TempoPhase.completed:
        return 0;
    }
  }

  double _computeCycleProgress(double phaseProgress) {
    final state = widget.state;
    final totalSec = state.preset.totalCycleSeconds;
    if (totalSec <= 0) return 0.0;

    double elapsedBefore = 0.0;
    if (state.isConcentricFirst) {
      switch (state.phase) {
        case TempoPhase.concentric:
          elapsedBefore = 0.0;
          break;
        case TempoPhase.topHold:
          elapsedBefore = state.preset.concentricSeconds.toDouble();
          break;
        case TempoPhase.eccentric:
          elapsedBefore = (state.preset.concentricSeconds + state.preset.topHoldSeconds).toDouble();
          break;
        case TempoPhase.bottomHold:
          elapsedBefore = (state.preset.concentricSeconds +
                  state.preset.topHoldSeconds +
                  state.preset.eccentricSeconds)
              .toDouble();
          break;
        default:
          return 0.0;
      }
    } else {
      switch (state.phase) {
        case TempoPhase.eccentric:
          elapsedBefore = 0.0;
          break;
        case TempoPhase.bottomHold:
          elapsedBefore = state.preset.eccentricSeconds.toDouble();
          break;
        case TempoPhase.concentric:
          elapsedBefore = (state.preset.eccentricSeconds + state.preset.bottomHoldSeconds).toDouble();
          break;
        case TempoPhase.topHold:
          elapsedBefore = (state.preset.eccentricSeconds +
                  state.preset.bottomHoldSeconds +
                  state.preset.concentricSeconds)
              .toDouble();
          break;
        default:
          return 0.0;
      }
    }

    final currentPhaseDuration = _getPhaseDurationMs(state.phase, state.preset, state.isConcentricFirst);
    final currentPhaseSec = currentPhaseDuration / 1000.0;
    final currentSec = elapsedBefore + (phaseProgress * currentPhaseSec);
    return (currentSec / totalSec).clamp(0.0, 1.0);
  }

  double _getSmoothCycleProgress() {
    final state = widget.state;
    if (!state.isActive || state.phase == TempoPhase.countdown) return 0.0;
    if (state.phase == TempoPhase.completed) return 1.0;
    if (state.isPaused) return state.cycleProgress;

    final phaseDurationMs = _getPhaseDurationMs(state.phase, state.preset, state.isConcentricFirst);
    if (phaseDurationMs <= 0) return state.cycleProgress;

    final elapsedMs = _phaseStopwatch.elapsedMilliseconds;
    final phaseProg = (elapsedMs / phaseDurationMs).clamp(0.0, 1.0);
    return _computeCycleProgress(phaseProg);
  }

  double _getSmoothPhaseProgress() {
    final state = widget.state;
    if (!state.isActive || state.phase == TempoPhase.countdown) return 0.0;
    if (state.phase == TempoPhase.completed) return 1.0;
    if (state.isPaused) return state.phaseProgress;

    final phaseDurationMs = _getPhaseDurationMs(state.phase, state.preset, state.isConcentricFirst);
    if (phaseDurationMs <= 0) return state.phaseProgress;

    final elapsedMs = _phaseStopwatch.elapsedMilliseconds;
    return (elapsedMs / phaseDurationMs).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tickerController,
      builder: (context, _) {
        final smoothCycleProgress = _getSmoothCycleProgress();
        final smoothPhaseProgress = _getSmoothPhaseProgress();

        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            painter: _BiomechanicalWavePainter(
              cycleProgress: smoothCycleProgress,
              phaseProgress: smoothPhaseProgress,
              phase: widget.state.phase,
              preset: widget.state.preset,
              isConcentricFirst: widget.state.isConcentricFirst,
              pulseProgress: _tickerController.value,
            ),
          ),
        );
      },
    );
  }
}

class _BiomechanicalWavePainter extends CustomPainter {
  final double cycleProgress;
  final double phaseProgress;
  final TempoPhase phase;
  final TempoPreset preset;
  final bool isConcentricFirst;
  final double pulseProgress;

  _BiomechanicalWavePainter({
    required this.cycleProgress,
    required this.phaseProgress,
    required this.phase,
    required this.preset,
    this.isConcentricFirst = false,
    required this.pulseProgress,
  });

  // Normalized phase fractions within one rep
  double get _eccFraction =>
      preset.eccentricSeconds / preset.totalCycleSeconds;
  double get _bottomHoldFraction =>
      preset.bottomHoldSeconds / preset.totalCycleSeconds;
  double get _concentricFraction =>
      preset.concentricSeconds / preset.totalCycleSeconds;
  double get _topHoldFraction =>
      preset.topHoldSeconds / preset.totalCycleSeconds;

  /// Returns normalized Y in [0.0, 1.0] where 1.0 is TOP (Lockout) and 0.0 is BOTTOM (Full Depth).
  double _getYForCycleProgress(double t) {
    if (isConcentricFirst) {
      final concEnd = _concentricFraction;
      final topHoldEnd = concEnd + _topHoldFraction;
      final eccEnd = topHoldEnd + _eccFraction;

      if (t <= 0.0) {
        return 0.0; // starts at bottom / floor
      } else if (t <= concEnd) {
        // Concentric drive: smooth ascent from bottom (0.0) to top (1.0)
        final localT = (t / concEnd).clamp(0.0, 1.0);
        return 0.5 - 0.5 * math.cos(localT * math.pi);
      } else if (t <= topHoldEnd) {
        // Peak contraction hold at top (1.0)
        return 1.0;
      } else if (t <= eccEnd) {
        // Eccentric lowering: smooth descent from top (1.0) back to bottom (0.0)
        final localT = ((t - topHoldEnd) / (eccEnd - topHoldEnd)).clamp(0.0, 1.0);
        return 0.5 + 0.5 * math.cos(localT * math.pi);
      } else {
        // Bottom hold / pause at stretch
        return 0.0;
      }
    }

    final eccEnd = _eccFraction;
    final bottomEnd = eccEnd + _bottomHoldFraction;
    final concEnd = bottomEnd + _concentricFraction;

    if (t <= 0.0) {
      return 1.0;
    } else if (t <= eccEnd) {
      // Eccentric descent: smooth S-curve from top (1.0) to bottom (0.0)
      final localT = (t / eccEnd).clamp(0.0, 1.0);
      return 0.5 + 0.5 * math.cos(localT * math.pi);
    } else if (t <= bottomEnd) {
      // Bottom hold: isometric pause at full depth (0.0)
      return 0.0;
    } else if (t <= concEnd) {
      // Concentric ascent: explosive drive from bottom (0.0) to top (1.0)
      final localT = ((t - bottomEnd) / (concEnd - bottomEnd)).clamp(0.0, 1.0);
      return 0.5 - 0.5 * math.cos(localT * math.pi);
    } else {
      // Top hold / reset: lockout (1.0)
      return 1.0;
    }
  }

  Color _getPhaseColor() {
    switch (phase) {
      case TempoPhase.eccentric:
        return const Color(0xFF00E5FF); // Electric Cyan
      case TempoPhase.bottomHold:
        return const Color(0xFFFFB300); // Radiant Amber tension
      case TempoPhase.concentric:
        return const Color(0xFF00E5FF); // Bright Cyan / White drive
      case TempoPhase.topHold:
        return const Color(0xFF00E5FF);
      case TempoPhase.countdown:
        return const Color(0xFF00E5FF);
      case TempoPhase.completed:
        return const Color(0xFF10B981);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Margins for datum lines, text labels, and floating orb
    const marginLeft = 20.0;
    final marginRight = w - 20.0;
    const marginTop = 30.0;
    final marginBottom = h - 24.0;
    final trackWidth = marginRight - marginLeft;
    final trackHeight = marginBottom - marginTop;

    final activeColor = _getPhaseColor();

    // ── 1. Horizontal Datum Lines (LOCKOUT & DEPTH) ────────────────────────
    final datumPaint = Paint()
      ..color = AppColors.steel.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Top Lockout datum line
    canvas.drawLine(
      Offset(marginLeft, marginTop),
      Offset(marginRight, marginTop),
      datumPaint,
    );

    // Bottom Depth datum line
    canvas.drawLine(
      Offset(marginLeft, marginBottom),
      Offset(marginRight, marginBottom),
      datumPaint,
    );

    // Precision corner reticle calipers
    final caliperPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.40)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Top-left caliper
    canvas.drawLine(Offset(marginLeft, marginTop - 6), Offset(marginLeft, marginTop + 6), caliperPaint);
    // Top-right caliper
    canvas.drawLine(Offset(marginRight, marginTop - 6), Offset(marginRight, marginTop + 6), caliperPaint);
    // Bottom-left caliper
    canvas.drawLine(Offset(marginLeft, marginBottom - 6), Offset(marginLeft, marginBottom + 6), caliperPaint);
    // Bottom-right caliper
    canvas.drawLine(Offset(marginRight, marginBottom - 6), Offset(marginRight, marginBottom + 6), caliperPaint);

    // Datum text badges
    _drawText(
      canvas,
      text: 'LOCKOUT',
      offset: Offset(marginLeft + 4, marginTop - 18),
      color: const Color(0xFF94A3B8),
      fontSize: 11.0,
      isMono: true,
      fontWeight: FontWeight.w700,
    );

    _drawText(
      canvas,
      text: isConcentricFirst ? 'FLOOR / START' : 'FULL DEPTH',
      offset: Offset(marginLeft + 4, marginBottom + 6),
      color: const Color(0xFF94A3B8),
      fontSize: 11.0,
      isMono: true,
      fontWeight: FontWeight.w700,
    );

    // ── 2. Vertical Phase Transition Markers ──────────────────────────────
    final markerPaint = Paint()
      ..color = AppColors.steel.withValues(alpha: 0.30)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    if (isConcentricFirst) {
      final firstX = marginLeft + (_concentricFraction * trackWidth);
      final secondX = firstX + (_topHoldFraction * trackWidth);
      final thirdX = secondX + (_eccFraction * trackWidth);
      _drawDashedVerticalLine(canvas, firstX, marginTop, marginBottom, markerPaint);
      if (_topHoldFraction > 0.0) {
        _drawDashedVerticalLine(canvas, secondX, marginTop, marginBottom, markerPaint);
      }
      if (_bottomHoldFraction > 0.0) {
        _drawDashedVerticalLine(canvas, thirdX, marginTop, marginBottom, markerPaint);
      }
    } else {
      final firstX = marginLeft + (_eccFraction * trackWidth);
      final secondX = firstX + (_bottomHoldFraction * trackWidth);
      final thirdX = secondX + (_concentricFraction * trackWidth);
      _drawDashedVerticalLine(canvas, firstX, marginTop, marginBottom, markerPaint);
      if (_bottomHoldFraction > 0.0) {
        _drawDashedVerticalLine(canvas, secondX, marginTop, marginBottom, markerPaint);
      }
      if (_topHoldFraction > 0.0) {
        _drawDashedVerticalLine(canvas, thirdX, marginTop, marginBottom, markerPaint);
      }
    }

    // ── 4. Full Wave Curve Construction ────────────────────────────────────
    const sampleSteps = 140;
    final fullWavePoints = <Offset>[];

    for (int i = 0; i <= sampleSteps; i++) {
      final t = i / sampleSteps; // 0.0 -> 1.0
      final x = marginLeft + (t * trackWidth);
      final normY = _getYForCycleProgress(t);
      // Invert: 1.0 = marginTop, 0.0 = marginBottom
      final y = marginBottom - (normY * trackHeight);
      fullWavePoints.add(Offset(x, y));
    }

    // ── 5. Upcoming Path (Blueprint Dotted Trajectory) ─────────────────────
    final upcomingPath = Path();
    bool upcomingStarted = false;
    for (int i = 0; i <= sampleSteps; i++) {
      final t = i / sampleSteps;
      if (t >= cycleProgress) {
        final pt = fullWavePoints[i];
        if (!upcomingStarted) {
          upcomingPath.moveTo(pt.dx, pt.dy);
          upcomingStarted = true;
        } else {
          upcomingPath.lineTo(pt.dx, pt.dy);
        }
      }
    }

    if (upcomingStarted) {
      final blueprintPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.30)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(upcomingPath, blueprintPaint);
    }

    // ── 6. Past Trajectory (Luminous Neon Illuminated Path) ────────────────
    final pastPath = Path();
    final pastFillPath = Path();
    final curStep = (cycleProgress * sampleSteps).clamp(0, sampleSteps).toInt();

    if (curStep > 0) {
      final startPt = fullWavePoints[0];
      pastPath.moveTo(startPt.dx, startPt.dy);
      pastFillPath.moveTo(startPt.dx, marginBottom);
      pastFillPath.lineTo(startPt.dx, startPt.dy);

      for (int i = 1; i <= curStep; i++) {
        final pt = fullWavePoints[i];
        pastPath.lineTo(pt.dx, pt.dy);
        pastFillPath.lineTo(pt.dx, pt.dy);
      }

      final lastPt = fullWavePoints[curStep];
      pastFillPath.lineTo(lastPt.dx, marginBottom);
      pastFillPath.close();

      // Translucent vertical neon area fill
      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          activeColor.withValues(alpha: 0.22),
          activeColor.withValues(alpha: 0.02),
        ],
      );
      final fillPaint = Paint()
        ..shader = fillGradient.createShader(
          Rect.fromLTRB(marginLeft, marginTop, marginRight, marginBottom),
        );
      canvas.drawPath(pastFillPath, fillPaint);

      // Multi-layer neon wave glow
      final neonGlowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.40)
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawPath(pastPath, neonGlowPaint);

      final neonCorePaint = Paint()
        ..color = activeColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(pastPath, neonCorePaint);

      // Pure white centerline highlight
      final highlightPaint = Paint()
        ..color = AppColors.pureWhite.withValues(alpha: 0.80)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(pastPath, highlightPaint);
    }

    // ── 7. Active Kinetic Energy Orb & Sonar Pulse ────────────────────────
    final orbNormX = cycleProgress.clamp(0.0, 1.0);
    final orbX = marginLeft + (orbNormX * trackWidth);
    final orbNormY = _getYForCycleProgress(orbNormX);
    final orbY = marginBottom - (orbNormY * trackHeight);

    // Vertical Laser Guide Line connecting orb to bottom axis
    final guideLinePaint = Paint()
      ..color = activeColor.withValues(alpha: 0.45)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(orbX, marginTop), Offset(orbX, marginBottom), guideLinePaint);

    // Sonar Ripple Rings radiating outward from the orb
    for (int r = 1; r <= 2; r++) {
      final rippleProgress = (pulseProgress + (r * 0.4)) % 1.0;
      final rippleRadius = 8.0 + (rippleProgress * 22.0);
      final rippleAlpha = (1.0 - rippleProgress) * 0.50;

      final ripplePaint = Paint()
        ..color = activeColor.withValues(alpha: rippleAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(orbX, orbY), rippleRadius, ripplePaint);
    }

    // Outer Neon Glow Aura
    final orbAuraPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(Offset(orbX, orbY), 16.0, orbAuraPaint);

    // Outer Ring
    final orbOuterRing = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(orbX, orbY), 8.5, orbOuterRing);

    // Inner Pure White Core
    final orbCorePaint = Paint()
      ..color = AppColors.pureWhite
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(orbX, orbY), 4.5, orbCorePaint);
  }

  void _drawDashedVerticalLine(
    Canvas canvas,
    double x,
    double startY,
    double endY,
    Paint paint,
  ) {
    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double currentY = startY;

    while (currentY < endY) {
      canvas.drawLine(
        Offset(x, currentY),
        Offset(x, math.min(currentY + dashHeight, endY)),
        paint,
      );
      currentY += dashHeight + dashSpace;
    }
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required Color color,
    required double fontSize,
    bool isMono = false,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: isMono ? AppTypography.fontMono : AppTypography.fontBody,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: 0.8,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _BiomechanicalWavePainter oldDelegate) {
    return oldDelegate.cycleProgress != cycleProgress ||
        oldDelegate.phaseProgress != phaseProgress ||
        oldDelegate.phase != phase ||
        oldDelegate.preset != preset ||
        oldDelegate.isConcentricFirst != isConcentricFirst ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}
