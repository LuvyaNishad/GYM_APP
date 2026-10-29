import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/widgets/muscle_spider_chart.dart';
import '../../models/muscle_radar_data.dart';

class RadarAxis {
  const RadarAxis({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// Compatibility adapter for dashboard volume data, using the shared web.
class LeonRadarChart extends StatelessWidget {
  const LeonRadarChart({
    super.key,
    required this.axes,
    this.maxValue,
    this.weakThreshold = 0.4,
    this.duration = const Duration(milliseconds: 850),
  });

  final List<RadarAxis> axes;
  final double? maxValue;
  final double weakThreshold;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final raw = <String, double>{};
    for (final axis in axes) {
      raw[axis.label] = (raw[axis.label] ?? 0) + axis.value;
    }
    final values = muscleRadarTotals(raw);
    final peak = values.values.fold<double>(0, math.max);
    final requestedScale = maxValue ?? peak;
    final scale = requestedScale.isFinite && requestedScale > 0
        ? requestedScale
        : 1.0;
    return LayoutBuilder(
      builder: (context, constraints) => MuscleSpiderChart(
        height: constraints.hasBoundedHeight ? constraints.maxHeight : 282,
        duration: duration,
        highlightedCategories: {
          if (peak > 0)
            for (final category in muscleRadarCategories)
              if (values[category]! < peak * weakThreshold) category,
        },
        series: [
          SpiderChartSeries(
            values: [
              for (final category in muscleRadarCategories)
                values[category]! / scale,
            ],
          ),
        ],
      ),
    );
  }
}
