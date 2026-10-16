/// Sleep Bento Card for the LEON Dashboard.
///
/// Minimal square card:
/// - "Sleep" header with subtle circular chevron
/// - "Last Night" caption
/// - Bold hero sleep duration readout (e.g. 7.5 hrs)
/// - Clean circle graph with percentage in between
/// - Tap interaction opens the deep sleep detail pop-up modal sheet
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/daily_telemetry_model.dart';
import 'bento_bar_progress.dart';
import 'telemetry_detail_sheets.dart';

/// Minimal square Bento card displaying daily sleep duration with a slim progress bar.
class SleepBentoCard extends StatelessWidget {
  const SleepBentoCard({
    super.key,
    required this.telemetry,
    this.onTap,
  });

  /// Telemetry data source.
  final DailyTelemetry telemetry;

  /// Optional card tap handler override.
  final VoidCallback? onTap;

  static const Color _cardBg = AppColors.charcoal;

  @override
  Widget build(BuildContext context) {
    final progress = telemetry.sleepProgress;
    final progressPct = (progress * 100).toInt();
    final hoursStr = telemetry.sleepHours.toStringAsFixed(1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            showSleepDetailSheet(context, telemetry);
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
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '💤',
                            style: TextStyle(fontSize: 14.0),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Sleep',
                            style: TextStyle(
                              fontFamily: AppTypography.fontDisplay,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
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
                ],
              ),

              // ── Bottom Section: Value & % Row + Horizontal Bar ────────────
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
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.pureWhite,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'h',
                            style: TextStyle(
                              fontFamily: AppTypography.fontBody,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$progressPct%',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  BentoHorizontalBarProgress(
                    progress: progress,
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
