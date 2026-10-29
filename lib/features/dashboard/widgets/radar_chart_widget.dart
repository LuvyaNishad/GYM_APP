import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/progress_model.dart';
import '../../../models/muscle_radar_data.dart';
import '../../../shared/widgets/radar_chart.dart';

/// Weekly volume balance using the same six muscle categories as every radar.
class RadarChartWidget extends StatelessWidget {
  const RadarChartWidget({super.key, this.snapshot, this.weakThreshold = 0.4});

  final RadarSnapshot? snapshot;
  final double weakThreshold;

  static RadarSnapshot get _demo => RadarSnapshot(
    weekStart: DateTime.now(),
    backVolume: 2600,
    legsVolume: 7400,
    chestVolume: 4500,
    armsVolume: 2200,
    coreVolume: 1200,
    shouldersVolume: 3700,
  );

  @override
  Widget build(BuildContext context) {
    final data = snapshot ?? _demo;
    final axes = <RadarAxis>[
      for (final category in muscleRadarCategories)
        RadarAxis(
          label: category,
          value: data.muscleVolumes[category]!,
          color: AppColors.platinum,
        ),
    ];

    final maxVolume = axes.fold<double>(0, (m, a) => math.max(m, a.value));
    final weakest = axes.reduce((a, b) => a.value <= b.value ? a : b);
    final hasInsight =
        maxVolume > 0 && weakest.value < weakThreshold * maxVolume;

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
                Row(
                  children: [
                    Text(
                      'MUSCLE BALANCE',
                      style: AppTypography.labelSmall.copyWith(
                        letterSpacing: 1.5,
                        fontSize: 11.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _showMuscleBalanceDialog(context),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                  ],
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
                  fontFamily: AppTypography.fontMono,
                  fontSize: 11.0,
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
        for (var row = 0; row < 2; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (var column = 0; column < 3; column++) ...[
                  if (column > 0) const SizedBox(width: 8),
                  _VolumeBadge(
                    label: axes[row * 3 + column].label,
                    volumeKg: axes[row * 3 + column].value,
                    color: AppColors.platinum,
                  ),
                ],
              ],
            ),
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
                            fontFamily: AppTypography.fontMono,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${weakest.label} volume is low. Review your plan for ${weakest.label.toLowerCase()} exercises.',
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

  void _showMuscleBalanceDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.onyx,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.steel),
        ),
        title: Row(
          children: [
            const Icon(Icons.hub_outlined, color: Color(0xFF00E5FF), size: 20),
            const SizedBox(width: 8),
            Text(
              'MUSCLE BALANCE SCIENCE',
              style: AppTypography.headlineSmall.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.pureWhite,
              ),
            ),
          ],
        ),
        content: const Text(
          'Weekly training volume across Back, Legs, Chest, Arms, Core, and Shoulders. Each spoke always represents the same muscle category.\n\nReview the distribution alongside your routine and recovery needs.',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'UNDERSTOOD',
              style: TextStyle(
                fontFamily: AppTypography.fontBody,
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeBadge extends StatelessWidget {
  const _VolumeBadge({
    required this.label,
    required this.volumeKg,
    required this.color,
  });

  final String label;
  final double volumeKg;
  final Color color;

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
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
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
                    fontFamily: AppTypography.fontMono,
                    fontSize: 11.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              formattedKg,
              style: AppTypography.labelSmall.copyWith(
                fontFamily: AppTypography.fontMono,
                fontWeight: FontWeight.w700,
                fontSize: 11.0,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
