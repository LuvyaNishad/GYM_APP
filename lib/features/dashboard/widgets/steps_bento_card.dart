/// Footsteps / Step Count Bento Card for the LEON Dashboard.
///
/// Features:
/// - Clear distinction between:
///   1. Populated: recorded step count (e.g. 8,420), distance, and 24-hr sparkline
///   2. Zero steps: intentional "Move to start tracking" state
///   3. Unavailable: distinct "Not connected" / "Tap to enable" state with permission trigger
/// - Clean 22dp rounded corners and subtle #373942 border
/// - Apple HIG compliant typography and touch targets
/// - Fine-grained Riverpod rebuild scoping: watches only step metrics via [select] when telemetry is omitted
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/pedometer_service.dart';
import '../models/daily_telemetry_model.dart';
import 'telemetry_detail_sheets.dart';

/// Minimal square Bento card displaying daily step count with intentional data states.
class StepsBentoCard extends ConsumerWidget {
  const StepsBentoCard({
    super.key,
    this.telemetry,
    this.onTap,
  });

  /// Optional daily telemetry source override.
  /// When null, watches only the relevant step fields via Riverpod [select].
  final DailyTelemetry? telemetry;

  /// Optional card tap handler override.
  final VoidCallback? onTap;

  static const Color _cardBg = AppColors.cardBackground;

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingStatus = ref.watch(stepTrackingStatusProvider);
    final isPermissionDenied = trackingStatus == StepTrackingStatus.permissionDenied;
    final isSensorUnavailable = trackingStatus == StepTrackingStatus.sensorUnavailable;
    final isUnavailable = isPermissionDenied || isSensorUnavailable;

    final int steps = telemetry != null
        ? telemetry!.steps
        : ref.watch(dailyTelemetryProvider.select((t) => t.steps));
    final double distanceKm = telemetry != null
        ? telemetry!.distanceKm
        : ref.watch(dailyTelemetryProvider.select((t) => t.distanceKm));
    final List<int> hourlySteps = telemetry != null
        ? telemetry!.hourlySteps
        : ref.watch(dailyTelemetryProvider.select((t) => t.hourlySteps));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (isPermissionDenied) {
            ref.read(pedometerServiceProvider).requestPermission();
            return;
          }
          if (onTap != null) {
            onTap!();
          } else {
            final DailyTelemetry effectiveTelemetry =
                telemetry ?? ref.read(dailyTelemetryProvider);
            showStepsDetailSheet(context, effectiveTelemetry);
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
          padding: const EdgeInsets.all(14),
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
                        '👟',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Steps',
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceSecondary,
                      border: Border.all(
                        color: AppColors.subtleBorder.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.platinum,
                    ),
                  ),
                ],
              ),

              // ── Middle: Metric Value or Unavailable ───────────────────────
              if (isUnavailable)
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '--',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.platinum,
                        letterSpacing: -0.4,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Data unavailable',
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.platinum,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatNumber(steps),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                        letterSpacing: -0.4,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps > 0
                          ? '$distanceKm km'
                          : 'Move to track steps',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.platinum,
                      ),
                    ),
                  ],
                ),

              // ── Bottom Visualization / Unavailable State ──────────────────
              if (isUnavailable)
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.subtleBorder.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(
                        isPermissionDenied
                            ? Icons.lock_outline_rounded
                            : Icons.sensors_off_rounded,
                        size: 16,
                        color: AppColors.platinum,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isPermissionDenied
                            ? 'Sensor permission needed'
                            : 'No hardware sensor',
                          style: const TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.platinum,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else
                _SlimBarGraph(
                  hourlySteps: hourlySteps,
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
          height: 38,
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
                barHeight = (fraction * 32.0 + 6.0).clamp(6.0, 38.0);
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
        const SizedBox(height: 4),
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
