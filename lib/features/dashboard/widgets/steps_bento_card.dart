import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_telemetry_model.dart';
import 'activity_metric_card.dart';
import 'bento_edge_glow.dart';
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
    final metrics = telemetry != null
        ? (telemetry!.steps, telemetry!.importedSteps, telemetry!.stepsSource)
        : ref.watch(
            dailyTelemetryProvider.select(
              (t) => (t.steps, t.importedSteps, t.stepsSource),
            ),
          );
    final unavailable =
        !metrics.$2 &&
        (status == StepTrackingStatus.permissionDenied ||
            status == StepTrackingStatus.sensorUnavailable ||
            (status == StepTrackingStatus.syncFailed &&
                !DateUtils.isSameDay(updatedAt?.toLocal(), DateTime.now())));
    final steps = metrics.$1;
    return ActivityMetricCard(
      title: 'Steps',
      glowPlacement: BentoGlowPlacement.nearLeft,
      icon: Icons.directions_walk_rounded,
      value: unavailable ? '—' : '$steps',
      caption: metrics.$2
          ? '${metrics.$3} · today'
          : unavailable
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
