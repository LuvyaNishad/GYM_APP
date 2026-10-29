import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_telemetry_model.dart';
import 'activity_metric_card.dart';
import 'telemetry_detail_sheets.dart';
import '../../../services/pedometer_service.dart';

class StepsBentoCard extends ConsumerWidget {
  const StepsBentoCard({super.key, this.telemetry, this.onTap});
  final DailyTelemetry? telemetry;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(stepTrackingStatusProvider);
    final updatedAt = ref.watch(
      stepSyncInfoProvider.select((s) => s.updatedAt),
    );
    final unavailable =
        status == StepTrackingStatus.permissionDenied ||
        status == StepTrackingStatus.sensorUnavailable ||
        (status == StepTrackingStatus.syncFailed &&
            !DateUtils.isSameDay(updatedAt?.toLocal(), DateTime.now()));
    final steps =
        telemetry?.steps ??
        ref.watch(dailyTelemetryProvider.select((t) => t.steps));
    return ActivityMetricCard(
      title: 'Steps',
      icon: Icons.directions_walk_rounded,
      value: unavailable ? '—' : '$steps',
      caption: unavailable
          ? (status == StepTrackingStatus.permissionDenied
                ? 'Permission needed'
                : 'Steps unavailable')
          : status == StepTrackingStatus.syncFailed
          ? 'Saved total · retrying'
          : steps == 0 && updatedAt == null
          ? 'Move to start tracking'
          : 'Recorded today',
      onTap:
          onTap ??
          () => showStepsDetailSheet(
            context,
            telemetry ?? ref.read(dailyTelemetryProvider),
          ),
    );
  }
}
