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
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    // Continuous 1-second looping pulse for ambient energy & sonar ripples
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            painter: _BiomechanicalWavePainter(
              cycleProgress: widget.state.cycleProgress,
              phaseProgress: widget.state.phaseProgress,
              phase: widget.state.phase,
              preset: widget.state.preset,
              isConcentricFirst: widget.state.isConcentricFirst,
              phaseSecondsRemaining: widget.state.phaseSecondsRemaining,
              pulseProgress: _rippleController.value,
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
  final int phaseSecondsRemaining;
  final double pulseProgress;

  _BiomechanicalWavePainter({
    required this.cycleProgress,
    required this.phaseProgress,
    required this.phase,
    required this.preset,
    this.isConcentricFirst = false,
    required this.phaseSecondsRemaining,
    required this.pulseProgress,
  });

  // Normalized phase fractions within one rep
  double get _eccFraction =>
      preset.eccentricSeconds / preset.totalCycleSeconds;
  double get _holdFraction =>
      (preset.topHoldSeconds > 0
          ? preset.topHoldSeconds
          : preset.bottomHoldSeconds) /
      preset.totalCycleSeconds;
  double get _concentricFraction =>
      preset.concentricSeconds / preset.totalCycleSeconds;

  /// Returns normalized Y in [0.0, 1.0] where 1.0 is TOP (Lockout) and 0.0 is BOTTOM (Full Depth).
  double _getYForCycleProgress(double t) {
    if (isConcentricFirst) {
      final concEnd = _concentricFraction;
      final holdEnd = concEnd + _holdFraction;

      if (t <= 0.0) {
        return 0.0; // starts at bottom / floor
      } else if (t <= concEnd) {
        // Concentric drive: smooth ascent from bottom (0.0) to top (1.0)
        final localT = (t / concEnd).clamp(0.0, 1.0);
        return 0.5 - 0.5 * math.cos(localT * math.pi);
      } else if (t <= holdEnd) {
        // Peak contraction hold at top (1.0)
        return 1.0;
      } else {
        // Eccentric lowering: smooth descent from top (1.0) back to bottom (0.0)
        final localT = ((t - holdEnd) / (1.0 - holdEnd)).clamp(0.0, 1.0);
        return 0.5 + 0.5 * math.cos(localT * math.pi);
      }
    }

    final eccEnd = _eccFraction;
    final bottomEnd = eccEnd + _holdFraction;
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

    // ── 1. Phase Zone Transition Coordinates ─────────────────────────────
    final double firstX;
    final double secondX;

    if (isConcentricFirst) {
      firstX = marginLeft + (_concentricFraction * trackWidth);
      secondX = firstX + (_holdFraction * trackWidth);
    } else {
      firstX = marginLeft + (_eccFraction * trackWidth);
      secondX = firstX + (_holdFraction * trackWidth);
    }

    // ── 2. Horizontal Datum Lines (LOCKOUT & DEPTH) ────────────────────────
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

    // ── 3. Vertical Phase Transition Markers ──────────────────────────────
    final markerPaint = Paint()
      ..color = AppColors.steel.withValues(alpha: 0.30)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw dashed vertical lines at phase boundaries
    _drawDashedVerticalLine(canvas, firstX, marginTop, marginBottom, markerPaint);
    if (_holdFraction > 0.0) {
      _drawDashedVerticalLine(canvas, secondX, marginTop, marginBottom, markerPaint);
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

    // Floating Target Tooltip Pill right above/below the orb
    final isNearTop = orbY < (marginTop + 35);
    final tooltipY = isNearTop ? orbY + 20 : orbY - 26;

    _drawFloatingPill(
      canvas,
      center: Offset(orbX, tooltipY),
      phase: phase,
      secondsRemaining: phaseSecondsRemaining,
      color: activeColor,
    );
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

  void _drawFloatingPill(
    Canvas canvas, {
    required Offset center,
    required TempoPhase phase,
    required int secondsRemaining,
    required Color color,
  }) {
    String text;
    switch (phase) {
      case TempoPhase.eccentric:
        text = '↓ LOWER ${secondsRemaining}s';
        break;
      case TempoPhase.bottomHold:
        text = '⚡ HOLD ${secondsRemaining}s';
        break;
      case TempoPhase.concentric:
        text = isConcentricFirst ? '↑ LIFT ${secondsRemaining}s' : '↑ DRIVE';
        break;
      case TempoPhase.topHold:
        text = '⚡ SQUEEZE ${secondsRemaining}s';
        break;
      case TempoPhase.countdown:
        text = 'READY';
        break;
      case TempoPhase.completed:
        text = 'DONE';
        break;
    }

    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        fontFamily: AppTypography.fontMono,
        fontSize: 11.0,
        fontWeight: FontWeight.w800,
        color: AppColors.onyx,
        letterSpacing: 0.5,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final pillWidth = textPainter.width + 16.0;
    const pillHeight = 22.0;
    final pillRect = Rect.fromCenter(
      center: center,
      width: pillWidth,
      height: pillHeight,
    );

    // Pill background
    final pillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(11.0)),
      pillPaint,
    );

    // Text centered
    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2),
          center.dy - (textPainter.height / 2)),
    );
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
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.phaseSecondsRemaining != phaseSecondsRemaining;
  }
}
