/// Hydration / Water Bento Card for the LEON Dashboard.
///
/// Clean, minimal square card inspired by Apple Fitness:
/// - "Hydration" header with subtle circular chevron
/// - "Today" caption
/// - Bold hero water intake readout (e.g. 2,750 ml)
/// - Minimal thin progress bar and goal milestone percentage
/// - Tap interaction opens the deep hydration detail pop-up modal sheet
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/daily_telemetry_model.dart';
import 'telemetry_detail_sheets.dart';

/// Minimal square Bento card displaying daily hydration intake.
class WaterBentoCard extends StatelessWidget {
  const WaterBentoCard({
    super.key,
    required this.telemetry,
    this.onTap,
  });

  /// Telemetry data source.
  final DailyTelemetry telemetry;

  /// Optional card tap handler override.
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
    final goalLiters = (telemetry.waterGoalMl / 1000).toStringAsFixed(1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            showHydrationDetailSheet(context, telemetry);
          }
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.steel.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Header Row: Title + Chevron ──────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Hydration',
                        style: TextStyle(
                          fontFamily: AppTypography.fontDisplay,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: AppColors.platinum,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Today',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // ── Hero Stat: 2,750 ml ──────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatNumber(telemetry.waterMl),
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pureWhite,
                      letterSpacing: -0.3,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    'ml',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // ── Thin Progress Bar & Goal Milestone ───────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.steel.withValues(alpha: 0.4),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.pureWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$progressPct% of goal',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${goalLiters}L target',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
