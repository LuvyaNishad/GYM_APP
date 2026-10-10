import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/progress_model.dart';
import '../../../shared/widgets/radar_chart.dart';

/// Tactical Muscle Balance Radar Card for LEON Command Center.
///
/// Features:
/// - PPL load distribution telemetry badges
/// - Staggered draw-on 3-axis radar chart
/// - Tactical intelligence warning callout banner with 1-tap route action
class RadarChartWidget extends StatelessWidget {
  const RadarChartWidget({
    super.key,
    this.snapshot,
    this.weakThreshold = 0.4,
  });

  final RadarSnapshot? snapshot;
  final double weakThreshold;

  static RadarSnapshot get _demo => RadarSnapshot(
        weekStart: DateTime.now(),
        pushVolume: 8200,
        pullVolume: 2600,
        legsVolume: 7400,
      );

  @override
  Widget build(BuildContext context) {
    final data = snapshot ?? _demo;
    final axes = <RadarAxis>[
      RadarAxis(label: 'PUSH', value: data.pushVolume, color: AppColors.chartPush),
      RadarAxis(label: 'PULL', value: data.pullVolume, color: AppColors.chartPull),
      RadarAxis(label: 'LEGS', value: data.legsVolume, color: AppColors.chartLegs),
    ];

    final maxVolume = axes.fold<double>(0, (m, a) => math.max(m, a.value));
    final weakest = axes.reduce((a, b) => a.value <= b.value ? a : b);
    final hasInsight = maxVolume > 0 && weakest.value < weakThreshold * maxVolume;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card Header Telemetry ───────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MUSCLE BALANCE',
                  style: AppTypography.labelSmall.copyWith(
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Weekly Volume Balance',
                  style: AppTypography.titleLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (hasInsight ? AppColors.warning : AppColors.success)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (hasInsight ? AppColors.warning : AppColors.success)
                      .withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Text(
                hasInsight ? 'NEEDS FOCUS' : 'BALANCED',
                style: AppTypography.labelSmall.copyWith(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: hasInsight ? AppColors.warning : AppColors.success,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Volume Metric Badges ────────────────────────────────────────────
        Row(
          children: [
            _VolumeBadge(
              label: 'PUSH',
              volumeKg: data.pushVolume,
              color: AppColors.chartPush,
            ),
            const SizedBox(width: 8),
            _VolumeBadge(
              label: 'PULL',
              volumeKg: data.pullVolume,
              color: weakest.label == 'PULL' ? AppColors.danger : AppColors.chartPull,
              isAlert: weakest.label == 'PULL',
            ),
            const SizedBox(width: 8),
            _VolumeBadge(
              label: 'LEGS',
              volumeKg: data.legsVolume,
              color: AppColors.chartLegs,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Radar Chart Canvas ──────────────────────────────────────────────
        SizedBox(
          height: 220,
          child: LeonRadarChart(axes: axes, weakThreshold: weakThreshold),
        ),

        // ── Tactical Advisory Banner ────────────────────────────────────────
        if (hasInsight) ...[
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppConstants.routeWorkoutBuilder);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.danger.withValues(alpha: 0.18),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.danger,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRAINING RECOMMENDATION',
                          style: AppTypography.labelSmall.copyWith(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${weakest.label} volume is low. Consider adding a ${_dayFor(weakest.label)} workout session.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.danger,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _dayFor(String axis) => switch (axis) {
        'PUSH' => 'chest & shoulders',
        'PULL' => 'back & biceps',
        'LEGS' => 'lower-body',
        _ => 'balanced',
      };
}

class _VolumeBadge extends StatelessWidget {
  const _VolumeBadge({
    required this.label,
    required this.volumeKg,
    required this.color,
    this.isAlert = false,
  });

  final String label;
  final double volumeKg;
  final Color color;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final formattedKg = volumeKg >= 1000
        ? '${(volumeKg / 1000).toStringAsFixed(1)}k'
        : volumeKg.toInt().toString();

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              formattedKg,
              style: AppTypography.labelSmall.copyWith(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
