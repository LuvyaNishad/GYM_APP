/// Sleep Bento Card for the LEON Dashboard.
///
/// Clean, minimal bento card designed for vertical stacking:
/// - Sleep logged in hours (e.g. 7.5 hrs)
/// - Clean horizontal progress gauge with daily target readout
/// - Tactical indigo/purple styling without sloppy blur glows
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/daily_telemetry_model.dart';

/// Compact Bento card displaying daily sleep duration in hours.
class SleepBentoCard extends StatelessWidget {
  const SleepBentoCard({
    super.key,
    required this.telemetry,
    this.onTap,
  });

  /// Telemetry data source.
  final DailyTelemetry telemetry;

  /// Optional tap handler.
  final VoidCallback? onTap;

  static const Color _cardBg = Color(0xFF161A23);
  static const Color _sleepAccent = Color(0xFFCBD5E1); // Luminous silver-slate
  static const Color _sleepBg = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    final progress = telemetry.sleepProgress;
    final progressPct = (progress * 100).toInt();
    final hoursStr = telemetry.sleepHours.toStringAsFixed(1);
    final goalHoursStr = telemetry.sleepGoalHours.toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Top Row: Moon Icon + Label + Value Readout ────────────────────
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
                      color: _sleepBg.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: _sleepAccent.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.bedtime_rounded,
                        color: _sleepAccent,
                        size: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SLEEP',
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

              // 7.5 hrs stat
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    hoursStr,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'hrs',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: _sleepAccent,
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
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(_sleepAccent),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // ── Goal Readout Row ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$hoursStr / $goalHoursStr hrs',
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
                  color: _sleepAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
