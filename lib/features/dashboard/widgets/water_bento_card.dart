/// Hydration / Water Bento Card for the LEON Dashboard.
///
/// Clean, minimal, non-sloppy design without outer blur glows:
/// - Daily water intake stat in milliliters (ml)
/// - Custom-painted clean fluid wave curve chart with subtle gradient underfill
/// - Daily milestone completion readout
/// - Tactical cyan styling
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/daily_telemetry_model.dart';

/// Bento grid card displaying daily water intake with a clean wave curve.
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

  static const Color _cardBg = Color(0xFF161A23);

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

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: Water Drop Icon & Title ───────────────────────────────
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.primary,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'HYDRATION',
                  style: AppTypography.labelSmall.copyWith(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Stat Numbers: 2,750 ml ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(telemetry.waterMl),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 3),
              const Text(
                'ml',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Fluid Wave Curve Chart (Clean, No Glow Blur) ──────────────────
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 68,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CustomPaint(
                  size: const Size(double.infinity, 68),
                  painter: _FluidWaveCurvePainter(
                    progress: progress,
                    waveColor: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Goal Milestone ────────────────────────────────────────────────
          Center(
            child: Text(
              '$liters / $goalLiters L ($progressPct%)',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for rendering a fluid hydrodynamic wave curve without blur glow.
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

    final baseHeight = height - (height * 0.60 * progress.clamp(0.1, 1.0));

    final wavePath = Path();
    wavePath.moveTo(0, baseHeight + 6);

    wavePath.cubicTo(
      width * 0.25,
      baseHeight - 10,
      width * 0.45,
      baseHeight + 12,
      width * 0.70,
      baseHeight - 4,
    );
    wavePath.cubicTo(
      width * 0.85,
      baseHeight - 14,
      width * 0.95,
      baseHeight - 2,
      width,
      baseHeight - 6,
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
          waveColor.withValues(alpha: 0.22),
          waveColor.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Clean wave crest line (no maskFilter blur)
    final crestPaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(wavePath, crestPaint);

    // Clean beacon dot at wave crest
    final dotX = width * 0.70;
    final dotY = baseHeight - 4;

    canvas.drawCircle(Offset(dotX, dotY), 3.5, Paint()..color = waveColor);
    canvas.drawCircle(Offset(dotX, dotY), 1.6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _FluidWaveCurvePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveColor != waveColor;
  }
}
