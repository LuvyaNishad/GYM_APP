import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_telemetry_model.dart';
import 'activity_metric_card.dart';
import 'telemetry_detail_sheets.dart';

class WaterBentoCard extends ConsumerWidget {
  const WaterBentoCard({super.key, this.telemetry, this.onTap});
  final DailyTelemetry? telemetry;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = telemetry;
    final metrics = data != null
        ? (data.waterMl, data.waterGoalMl)
        : ref.watch(
            dailyTelemetryProvider.select((t) => (t.waterMl, t.waterGoalMl)),
          );
    return ActivityMetricCard(
      title: 'Water',
      icon: Icons.water_drop_outlined,
      value: '${metrics.$1} ml',
      caption: metrics.$1 == 0
          ? 'Log your first drink'
          : 'of ${metrics.$2} ml today',
      progress: metrics.$1 > 0 ? metrics.$1 / metrics.$2 : null,
      onTap:
          onTap ??
          () => showHydrationDetailSheet(
            context,
            data ?? ref.read(dailyTelemetryProvider),
          ),
    );
  }
}
