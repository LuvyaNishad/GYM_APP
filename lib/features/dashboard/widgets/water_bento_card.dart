/// Hydration / Water Bento Card for the LEON Dashboard.
///
/// Features:
/// - Daily water intake stat in milliliters (ml)
/// - Custom-painted glowing fluid wave curve chart with subtle gradient underfill
/// - Daily milestone completion readout
/// - Tactical cyan liquid glassmorphism aesthetics
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/liquid_glass.dart';
import '../models/daily_telemetry_model.dart';

/// Bento grid card displaying daily water intake with a fluid wave curve.
class WaterBentoCard extends StatelessWidget {
  const WaterBentoCard({
    super.key,
    required this.telemetry,
    this.onTap,
  });

  /// Telemetry data source.
  final DailyTelemetry telemetry;

  /// Optional tap handler.
  final VoidCallback? onTap;

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final progress = telemetry.waterProgress;
    final progressPct = (progress * 100).toInt();
    final liters = (telemetry.waterMl / 1000).toStringAsFixed(2);
    final goalLiters = (telemetry.waterGoalMl / 1000).toStringAsFixed(1);

    return LiquidGlassContainer(
      borderRadius: 22,
      blurSigma: 24,
      glowColor: AppColors.primary.withValues(alpha: 0.14),
      padding: const EdgeInsets.all(16),
      borderWidth: 1.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Water Drop Icon & Title ───────────────────────────────
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'HYDRATION',
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

          // ── Stat Numbers: 2,750 ml ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(telemetry.waterMl),
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
                'ml',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Fluid Wave Curve Chart ────────────────────────────────────────
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 88,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomPaint(
                  size: const Size(double.infinity, 88),
                  painter: _FluidWaveCurvePainter(
                    progress: progress,
                    waveColor: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Goal Milestone ────────────────────────────────────────────────
          Center(
            child: Text(
              '$liters / $goalLiters L ($progressPct%)',
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

/// Custom painter for rendering a fluid hydrodynamic wave curve with glowing crest.
class _FluidWaveCurvePainter extends CustomPainter {
  const _FluidWaveCurvePainter({
    required this.progress,
    required this.waveColor,
  });

  final double progress;
  final Color waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Baseline wave height mapped to progress
    final baseHeight = height - (height * 0.65 * progress.clamp(0.1, 1.0));

    final wavePath = Path();
    wavePath.moveTo(0, baseHeight + 8);

    // Dynamic wave control points creating a natural liquid ripple
    wavePath.cubicTo(
      width * 0.25,
      baseHeight - 14,
      width * 0.45,
      baseHeight + 16,
      width * 0.70,
      baseHeight - 6,
    );
    wavePath.cubicTo(
      width * 0.85,
      baseHeight - 18,
      width * 0.95,
      baseHeight - 2,
      width,
      baseHeight - 8,
    );

    // Gradient fill beneath the wave
    final fillPath = Path.from(wavePath)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          waveColor.withValues(alpha: 0.32),
          waveColor.withValues(alpha: 0.12),
          waveColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Glowing wave crest line
    final crestPaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final glowCrestPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(wavePath, glowCrestPaint);
    canvas.drawPath(wavePath, crestPaint);

    // Luminous beacon dot at the wave crest
    final dotX = width * 0.70;
    final dotY = baseHeight - 6;

    final dotHaloPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), 6, dotHaloPaint);
    canvas.drawCircle(Offset(dotX, dotY), 3.5, Paint()..color = waveColor);
    canvas.drawCircle(Offset(dotX, dotY), 1.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _FluidWaveCurvePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveColor != waveColor;
  }
}
