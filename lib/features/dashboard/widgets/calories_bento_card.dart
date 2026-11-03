import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_telemetry_model.dart';
import 'activity_metric_card.dart';
import 'bento_edge_glow.dart';
import 'telemetry_detail_sheets.dart';

class CaloriesBentoCard extends ConsumerWidget {
  const CaloriesBentoCard({super.key, this.telemetry, this.onTap});
  final DailyTelemetry? telemetry;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = telemetry != null
        ? (
            telemetry!.calories,
            telemetry!.caloriesRecorded,
            telemetry!.caloriesSource,
          )
        : ref.watch(
            dailyTelemetryProvider.select(
              (t) => (t.calories, t.caloriesRecorded, t.caloriesSource),
            ),
          );
    return ActivityMetricCard(
      title: 'Calories',
      glowPlacement: BentoGlowPlacement.nearRight,
      icon: Icons.local_fire_department_outlined,
      value: metrics.$2 ? '${metrics.$1} kcal' : '—',
      caption: metrics.$2
          ? 'Active burn · ${metrics.$3 ?? 'Manual log'}'
          : 'No active burn logged',
      onTap:
          onTap ??
          () => showCaloriesDetailSheet(
            context,
            telemetry ?? ref.read(dailyTelemetryProvider),
          ),
    );
  }
}
