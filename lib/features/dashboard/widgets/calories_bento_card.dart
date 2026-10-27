import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_telemetry_model.dart';
import 'activity_metric_card.dart';
import 'telemetry_detail_sheets.dart';

class CaloriesBentoCard extends ConsumerWidget {
  const CaloriesBentoCard({super.key, this.telemetry, this.onTap});
  final DailyTelemetry? telemetry;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calories =
        telemetry?.calories ??
        ref.watch(dailyTelemetryProvider.select((t) => t.calories));
    return ActivityMetricCard(
      title: 'Calories',
      icon: Icons.local_fire_department_outlined,
      value: calories == 0 ? '—' : '$calories kcal',
      caption: calories == 0
          ? 'No active burn logged'
          : 'Active burn · manual log',
      onTap:
          onTap ??
          () => showCaloriesDetailSheet(
            context,
            telemetry ?? ref.read(dailyTelemetryProvider),
          ),
    );
  }
}
