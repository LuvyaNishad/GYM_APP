import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/progress_model.dart';
import '../../../shared/widgets/radar_chart.dart';

/// Muscle-balance radar for the dashboard.
///
/// Builds a 3-axis PPL radar from a [RadarSnapshot] and, when one group is
/// lagging, surfaces a one-line insight beneath it. Falls back to a realistic
/// demo snapshot so the dashboard is never empty (see DESIGN.md § 11).
class RadarChartWidget extends StatelessWidget {
  const RadarChartWidget({super.key, this.snapshot, this.weakThreshold = 0.4});

  final RadarSnapshot? snapshot;
  final double weakThreshold;

  /// Stand-in until the analytics aggregation lands — a mild pull deficit so
  /// the weak-axis highlight is visible on a fresh install.
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
      children: [
        Expanded(child: LeonRadarChart(axes: axes, weakThreshold: weakThreshold)),
        if (hasInsight) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${weakest.label} volume is low — add a ${_dayFor(weakest.label)} focus session.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.danger,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
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
