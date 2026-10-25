/// Hydration / Water Bento Card for the LEON Dashboard.
///
/// Features:
/// - Logged quantity and unit: ml
/// - Convenient 1-tap quick log action (+250ml)
/// - Target progress shown only when entries exist
/// - Intentional empty state: "Log your first drink" without broken empty bars
/// - Consistent 22dp radius and subtle #373942 border
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/acrylic_card.dart';
import '../models/daily_telemetry_model.dart';
import 'bento_bar_progress.dart';
import 'telemetry_detail_sheets.dart';

/// Minimal square Bento card displaying daily hydration intake.
class WaterBentoCard extends ConsumerWidget {
  const WaterBentoCard({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final hasWater = telemetry.waterMl > 0;
    final progress = telemetry.waterProgress;
    final progressPct = (progress * 100).toInt();

    return AcrylicCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          showHydrationDetailSheet(context, telemetry);
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
                        '💧',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Water',
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

              // ── Bottom Section: Value & Progress Bar or Quick Log ─────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formatNumber(telemetry.waterMl),
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.pureWhite,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'ml',
                            style: TextStyle(
                              fontFamily: AppTypography.fontBody,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.platinum,
                            ),
                          ),
                        ],
                      ),
                      if (hasWater)
                        Text(
                          '$progressPct%',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pureWhite,
                            letterSpacing: -0.2,
                          ),
                        )
                      else
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(dailyTelemetryProvider.notifier).logWater(250);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.subtleBorder,
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 12, color: AppColors.pureWhite),
                                SizedBox(width: 2),
                                Text(
                                  '250ml',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (hasWater)
                    BentoHorizontalBarProgress(
                      progress: progress,
                      barHeight: 5.0,
                      progressColor: AppColors.pureWhite,
                    )
                  else
                    const Text(
                      'Log your first drink',
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.platinum,
                      ),
                    ),
                ],
              ),
            ],
          ),
    );
  }
}
