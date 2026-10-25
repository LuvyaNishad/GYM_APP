/// Footsteps / Step Count Bento Card for the LEON Dashboard.
///
/// Minimal square card:
/// - "Step Count" header with subtle circular chevron
/// - "Today" caption
/// - Bold hero step count readout (e.g. 8,420)
/// - Slim bar graph showing hourly activity distribution with 00 / 06 / 12 / 18 timeline
/// - Tap interaction opens the deep telemetry detail pop-up modal sheet
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/daily_telemetry_model.dart';
import 'telemetry_detail_sheets.dart';

/// Minimal square Bento card displaying daily step count with a slim-bar sparkline graph.
class StepsBentoCard extends StatelessWidget {
  const StepsBentoCard({
    super.key,
    required this.telemetry,
    this.onTap,
  });

  /// Daily telemetry source data.
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            showStepsDetailSheet(context, telemetry);
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '👟',
                            style: TextStyle(fontSize: 17.5),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Steps',
                            style: TextStyle(
                              fontFamily: AppTypography.fontDisplay,
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
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
                ],
              ),

              // ── Hero Stat: 8,420 ──────────────────────────────────────────
              Text(
                _formatNumber(telemetry.steps),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pureWhite,
                  letterSpacing: -0.4,
                  height: 1.0,
                ),
              ),

              // ── Slim Bar Graph with 00 / 06 / 12 / 18 Timeline ────────────
              _SlimBarGraph(
                hourlySteps: telemetry.hourlySteps,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slim vertical bar graph matching Apple Fitness aesthetic.
class _SlimBarGraph extends StatelessWidget {
  const _SlimBarGraph({required this.hourlySteps});

  final List<int> hourlySteps;

  @override
  Widget build(BuildContext context) {
    const int totalBars = 24;
    final currentHour = DateTime.now().hour;
    final int maxVal = hourlySteps.isNotEmpty
        ? hourlySteps.reduce((a, b) => a > b ? a : b)
        : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 24 slim vertical bars representing hours 00:00 to 23:00
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(totalBars, (hour) {
              final isFuture = hour > currentHour;
              final steps = (hourlySteps.length > hour) ? hourlySteps[hour] : 0;
              final bool hasSteps = steps > 0;

              final double barHeight;
              final Color barColor;

              if (isFuture) {
                barHeight = 4.0;
                barColor = AppColors.steel.withValues(alpha: 0.18);
              } else if (!hasSteps) {
                barHeight = 4.0;
                barColor = AppColors.steel.withValues(alpha: 0.35);
              } else {
                final double fraction = maxVal > 0 ? (steps / maxVal) : 0.0;
                barHeight = (fraction * 34.0 + 6.0).clamp(6.0, 40.0);
                barColor = AppColors.pureWhite;
              }

              return Container(
                width: 2.4,
                height: barHeight,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(1.2),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 5),
        // Timeline hour markers (Apple HIG floor >= 11.0 pt)
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TimeLabel('00'),
            _TimeLabel('06'),
            _TimeLabel('12'),
            _TimeLabel('18'),
          ],
        ),
      ],
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}
