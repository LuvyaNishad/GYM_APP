/// Hydration / Water Bento Card for the LEON Dashboard.
///
/// Clean, minimal bento card designed for vertical stacking:
/// - Daily water intake stat in milliliters (ml) and liters (L)
/// - Clean horizontal progress gauge with milestone readout
/// - Tactical cyan styling without sloppy blur glows
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/daily_telemetry_model.dart';

/// Compact Bento card displaying daily hydration intake.
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

  static const Color _cardBg = AppColors.charcoal;

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
          color: AppColors.steel.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Top Row: Water Icon + Label + Value Readout ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.steel.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: AppColors.steel,
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: AppColors.pureWhite,
                        size: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'HYDRATION',
                    style: AppTypography.labelSmall.copyWith(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // 2,750 ml stat
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatNumber(telemetry.waterMl),
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pureWhite,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'ml',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 7),

          // ── Progress Bar ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.steel,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pureWhite),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // ── Goal Readout Row ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$liters / $goalLiters L',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '$progressPct%',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pureWhite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
