/// Calories Bento Card for the LEON Dashboard.
///
/// Features:
/// - Daily caloric burn metric with custom formatted readout
/// - Glowing circular radial donut progress ring chart
/// - Milestone percentage completion readout
/// - Tactical amber-orange glassmorphism styling
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/liquid_glass.dart';
import '../models/daily_telemetry_model.dart';

/// Bento grid card displaying daily caloric burn with a radial progress ring.
class CaloriesBentoCard extends StatelessWidget {
  const CaloriesBentoCard({
    super.key,
    required this.telemetry,
    this.onTap,
  });

  /// Telemetry data source.
  final DailyTelemetry telemetry;

  /// Optional tap handler.
  final VoidCallback? onTap;

  static const Color _amberOrange = Color(0xFFFF7A00);
  static const Color _amberLight = Color(0xFFFFB300);

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final progress = telemetry.caloriesProgress;
    final progressPct = (progress * 100).toInt();

    return LiquidGlassContainer(
      borderRadius: 22,
      blurSigma: 24,
      glowColor: _amberOrange.withValues(alpha: 0.14),
      padding: const EdgeInsets.all(16),
      borderWidth: 1.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Flame Icon & Label ────────────────────────────────────
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _amberOrange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _amberOrange.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _amberOrange.withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: _amberOrange,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CALORIES',
                  style: AppTypography.labelSmall.copyWith(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Stat Numbers: 2,390 Kcal ──────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(telemetry.calories),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Kcal',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _amberLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Donut Progress Ring ───────────────────────────────────────────
          Center(
            child: SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(88, 88),
                    painter: _DonutProgressPainter(
                      progress: progress,
                      trackColor: _amberOrange.withValues(alpha: 0.15),
                      progressColor: _amberOrange,
                      secondaryColor: _amberLight,
                      strokeWidth: 8.0,
                    ),
                  ),
                  // Percentage readout in the center
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$progressPct%',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'BURNED',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Goal Milestone ────────────────────────────────────────────────
          Center(
            child: Text(
              'GOAL: ${_formatNumber(telemetry.caloriesGoal)} KCAL',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for rendering the circular radial donut progress ring.
class _DonutProgressPainter extends CustomPainter {
  const _DonutProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.secondaryColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color secondaryColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Glowing active progress arc
    final sweepAngle = (2 * math.pi) * progress.clamp(0.0, 1.0);
    const startAngle = -math.pi / 2;

    final progressRect = Rect.fromCircle(center: center, radius: radius);

    // Gradient sweep shader
    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: sweepAngle,
      colors: [secondaryColor, progressColor],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(progressRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Shadow glow behind the arc
    final glowPaint = Paint()
      ..color = progressColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(progressRect, startAngle, sweepAngle, false, glowPaint);
    canvas.drawArc(progressRect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
