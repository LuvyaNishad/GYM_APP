import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/muscle_spider_chart.dart';
import '../../features/history/models/training_coverage.dart';
import '../../models/muscle_radar_data.dart';

/// Detailed session anatomy is combined into the six fixed radar categories.
/// The detailed model supplies exercise recommendations independently.
class TrainingCoverageRadar extends StatelessWidget {
  const TrainingCoverageRadar({
    super.key,
    required this.muscles,
    this.hasPlan = true,
    this.maxSets = 20,
  });

  final List<MuscleCoverage> muscles;
  final bool hasPlan;
  final double maxSets;

  @override
  Widget build(BuildContext context) {
    final plannedAreas = <String, double>{};
    final completedAreas = <String, double>{};
    for (final muscle in muscles) {
      plannedAreas[muscle.name] =
          (plannedAreas[muscle.name] ?? 0) + muscle.planned;
      completedAreas[muscle.name] =
          (completedAreas[muscle.name] ?? 0) + muscle.completed;
    }
    final planned = muscleRadarTotals(plannedAreas);
    final completed = muscleRadarTotals(completedAreas);
    final scale = maxSets > 0 && maxSets.isFinite ? maxSets : 20.0;
    final values = [
      for (final category in muscleRadarCategories)
        completed[category]! / scale,
    ];
    return MuscleSpiderChart(
      paintKey: const ValueKey('training-coverage-web'),
      series: [
        if (hasPlan)
          SpiderChartSeries(
            values: [
              for (final category in muscleRadarCategories)
                planned[category]! / scale,
            ],
            color: AppColors.platinum,
            filled: false,
          ),
        SpiderChartSeries(values: values),
      ],
      semanticLabel:
          'Muscle coverage. ${muscleRadarCategories.map((category) => '$category: ${completed[category]!.toStringAsFixed(1)}${hasPlan ? ' of ${planned[category]!.toStringAsFixed(1)} planned' : ''} set equivalents').join('. ')}',
    );
  }
}
