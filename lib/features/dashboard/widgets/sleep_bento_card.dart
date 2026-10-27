import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_telemetry_model.dart';
import 'activity_metric_card.dart';
import 'telemetry_detail_sheets.dart';

class SleepBentoCard extends ConsumerWidget {
  const SleepBentoCard({super.key, this.telemetry, this.onTap});
  final DailyTelemetry? telemetry;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = telemetry;
    final metrics = data != null
        ? (data.sleepHours, data.sleepGoalHours)
        : ref.watch(
            dailyTelemetryProvider.select(
              (t) => (t.sleepHours, t.sleepGoalHours),
            ),
          );
    return ActivityMetricCard(
      title: 'Sleep',
      icon: Icons.bedtime_outlined,
      value: metrics.$1 == 0 ? '—' : '${metrics.$1.toStringAsFixed(1)} h',
      caption: metrics.$1 == 0
          ? 'No sleep logged'
          : 'Last night · ${metrics.$2.toStringAsFixed(1)} h goal',
      progress: metrics.$1 > 0 ? metrics.$1 / metrics.$2 : null,
      onTap:
          onTap ??
          () => showSleepDetailSheet(
            context,
            data ?? ref.read(dailyTelemetryProvider),
          ),
    );
  }
}
