import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/muscle_spider_chart.dart';
import '../../../models/muscle_radar_data.dart';

/// Planned and logged weekly sets on the app's six standard muscle axes.
class MuscleRadarChart extends StatelessWidget {
  const MuscleRadarChart({
    super.key,
    required this.plannedVolume,
    required this.loggedVolume,
    this.size = 280,
    this.maxSetsScale = 20.0,
  });

  final Map<String, int> plannedVolume;
  final Map<String, int> loggedVolume;
  final double size;
  final double maxSetsScale;
  static const kAxes = muscleRadarCategories;

  @override
  Widget build(BuildContext context) {
    final planned = muscleRadarTotals(plannedVolume);
    final logged = muscleRadarTotals(loggedVolume);
    final peak = [
      ...planned.values,
      ...logged.values,
    ].fold<double>(20, math.max);
    final scale =
        (math.max(peak, maxSetsScale.isFinite ? maxSetsScale : 20) / 10)
            .ceil() *
        10.0;
    return SizedBox(
      width: size,
      child: MuscleSpiderChart(
        height: size,
        series: [
          SpiderChartSeries(
            values: [for (final axis in kAxes) planned[axis]! / scale],
            color: AppColors.platinum,
            filled: false,
          ),
          SpiderChartSeries(
            values: [for (final axis in kAxes) logged[axis]! / scale],
          ),
        ],
        captions: {
          for (final axis in kAxes)
            axis: '${logged[axis]!.toInt()}/${planned[axis]!.toInt()} sets',
        },
        semanticLabel: 'Planned and logged weekly working sets',
        detailBuilder: (context, category) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Text(
                '${category.toUpperCase()} · ${logged[category]!.toInt()} LOGGED / ${planned[category]!.toInt()} PLANNED',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Area = direct working sets · full sector = ${scale.toInt()} sets',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
