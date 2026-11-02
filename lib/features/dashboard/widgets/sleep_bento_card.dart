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
    final metrics = telemetry != null
        ? (
            telemetry!.sleepHours,
            telemetry!.sleepRecorded,
            telemetry!.sleepSource,
            telemetry!.sleepProgress,
          )
        : ref.watch(
            dailyTelemetryProvider.select(
              (t) => (
                t.sleepHours,
                t.sleepRecorded,
                t.sleepSource,
                t.sleepProgress,
              ),
            ),
          );
    return ActivityMetricCard(
      title: 'Sleep',
      icon: Icons.bedtime_outlined,
      value: metrics.$2 ? '${metrics.$1.toStringAsFixed(1)} h' : '—',
      caption: metrics.$2
          ? '${metrics.$3 ?? 'Manual log'} · last night'
          : 'No sleep logged',
      progress: metrics.$2 ? metrics.$4 : null,
      onTap:
          onTap ??
          () => showSleepDetailSheet(
            context,
            telemetry ?? ref.read(dailyTelemetryProvider),
          ),
    );
  }
}
