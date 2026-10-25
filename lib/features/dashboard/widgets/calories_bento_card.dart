/// Calories Bento Card for the LEON Dashboard.
///
/// Features:
/// - Clear metric identification: "Active Burn" from workouts
/// - Correct unit: kcal
/// - Progress ring only rendered when meaningful (calories > 0)
/// - Clean intentional empty state when 0 calories recorded (no broken 0% rings)
/// - Consistent 22dp radius and subtle #373942 border
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/acrylic_card.dart';
import '../models/daily_telemetry_model.dart';
import 'bento_donut_progress.dart';
import 'telemetry_detail_sheets.dart';

/// Minimal square Bento card displaying daily active calories burned.
class CaloriesBentoCard extends StatelessWidget {
  const CaloriesBentoCard({
    super.key,
    required this.telemetry,
    this.onTap,
  });

  /// Telemetry data source.
  final DailyTelemetry telemetry;

  /// Optional card tap handler override.
  final VoidCallback? onTap;

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final hasCalories = telemetry.calories > 0;
    final progress = telemetry.caloriesProgress;
    final progressPct = (progress * 100).toInt();

    return AcrylicCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(14),
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          showCaloriesDetailSheet(context, telemetry);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
              // ── Header Row: Title + Chevron ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Calories',
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 15,
                      color: AppColors.platinum,
                    ),
                  ),
                ],
              ),

              // ── Bottom Row: Value + Progress Ring / Empty State Indicator ─
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatNumber(telemetry.calories),
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pureWhite,
                            letterSpacing: -0.5,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'kcal active burn',
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.platinum,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasCalories)
                    BentoDonutProgress(
                      progress: progress,
                      percentage: progressPct,
                      size: 78,
                      strokeWidth: 6.5,
                    )
                  else
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceSecondary,
                        border: Border.all(
                          color: AppColors.subtleBorder.withValues(alpha: 0.5),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center_rounded,
                          size: 22,
                          color: AppColors.platinum,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
    );
  }
}
