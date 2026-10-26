/// Sleep Bento Card for the LEON Dashboard.
///
/// Features:
/// - Recorded sleep duration in hours (e.g. 7.5h)
/// - Distinguishes missing sleep data (--) from 0 hours of sleep
/// - No fabricated sleep-quality score
/// - Intentional empty state: "No sleep logged" with tap-to-log prompt
/// - Consistent 22dp radius and subtle #373942 border
/// - Fine-grained Riverpod rebuild scoping: watches only sleep metrics via [select] when telemetry is omitted
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/daily_telemetry_model.dart';
import 'bento_bar_progress.dart';
import 'telemetry_detail_sheets.dart';

/// Minimal square Bento card displaying daily sleep duration.
class SleepBentoCard extends ConsumerWidget {
  const SleepBentoCard({
    super.key,
    this.telemetry,
    this.onTap,
  });

  /// Optional telemetry data source override.
  /// When null, watches only the relevant sleep fields via Riverpod [select].
  final DailyTelemetry? telemetry;

  /// Optional card tap handler override.
  final VoidCallback? onTap;

  static const Color _cardBg = AppColors.cardBackground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double sleepHours = telemetry != null
        ? telemetry!.sleepHours
        : ref.watch(dailyTelemetryProvider.select((t) => t.sleepHours));
    final double sleepProgress = telemetry != null
        ? telemetry!.sleepProgress
        : ref.watch(dailyTelemetryProvider.select((t) => t.sleepProgress));

    final hasSleep = sleepHours > 0;
    final progress = sleepProgress;
    final progressPct = (progress * 100).toInt();
    final hoursStr = hasSleep ? sleepHours.toStringAsFixed(1) : '--';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            final DailyTelemetry effectiveTelemetry =
                telemetry ?? ref.read(dailyTelemetryProvider);
            showSleepDetailSheet(context, effectiveTelemetry);
          }
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.subtleBorder,
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                        '💤',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sleep',
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

              // ── Bottom Section: Value & Progress Bar or Tap to Log ────────
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
                            hoursStr,
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: hasSleep
                                  ? AppColors.pureWhite
                                  : AppColors.textMutedSlate,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'h',
                            style: TextStyle(
                              fontFamily: AppTypography.fontBody,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.platinum,
                            ),
                          ),
                        ],
                      ),
                      if (hasSleep)
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.subtleBorder,
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'Tap to log',
                            style: TextStyle(
                              fontFamily: AppTypography.fontBody,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (hasSleep)
                    BentoHorizontalBarProgress(
                      progress: progress,
                      barHeight: 5.0,
                      progressColor: AppColors.pureWhite,
                    )
                  else
                    const Text(
                      'No sleep logged',
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
        ),
      ),
    );
  }
}
