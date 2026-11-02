import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/local_date_provider.dart';
import '../../../services/health_sync_service.dart';
import '../../../services/hive_service.dart';
import '../../../services/pedometer_service.dart';
import '../../dashboard/models/daily_telemetry_model.dart';
import '../models/health_import.dart';
import '../models/health_snapshot.dart';

class HealthPreferencesNotifier extends Notifier<Set<HealthMetric>> {
  static const storageKey = 'health_read_metrics_v1';
  Future<void> _writes = Future.value();
  @override
  Set<HealthMetric> build() {
    final raw = ref.watch(hiveServiceProvider).getSetting<String>(storageKey);
    try {
      final names = raw == null ? <dynamic>[] : jsonDecode(raw) as List;
      return Set.unmodifiable(
        HealthMetric.values.where((m) => names.contains(m.name)),
      );
    } catch (_) {
      return const {};
    }
  }

  Future<void> select(HealthMetric metric, bool enabled) {
    _writes = _writes.catchError((Object _) {}).then((_) async {
      final next = {...state};
      enabled ? next.add(metric) : next.remove(metric);
      await ref
          .read(hiveServiceProvider)
          .putSettingChecked(
            storageKey,
            jsonEncode(next.map((m) => m.name).toList()),
          );
      if (ref.mounted) state = Set.unmodifiable(next);
    });
    return _writes;
  }
}

final healthPreferencesProvider =
    NotifierProvider<HealthPreferencesNotifier, Set<HealthMetric>>(
      HealthPreferencesNotifier.new,
    );
final healthClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class HealthImportNotifier extends AsyncNotifier<HealthImport> {
  bool _authorizing = false;
  Completer<void>? _authorization;
  @override
  Future<HealthImport> build() async {
    final metrics = ref.watch(healthPreferencesProvider);
    final day = ref.watch(localDateProvider);
    final service = ref.watch(healthSyncServiceProvider);
    final now = ref.watch(healthClockProvider)();
    final authorization = _authorization;
    if (authorization != null) await authorization.future;
    // Riverpod discards superseded builds. Permission checks never reuse imports.
    HealthAvailability availability;
    try {
      availability = await service.availability();
    } catch (_) {
      availability = HealthAvailability.error;
    }
    final readings = <HealthMetric, HealthReading>{};
    for (final metric in metrics) {
      if (availability != HealthAvailability.ready) {
        readings[metric] = HealthReading(
          state: availability == HealthAvailability.error
              ? HealthReadState.error
              : HealthReadState.unavailable,
        );
        continue;
      }
      try {
        readings[metric] = await service.read(
          metric,
          HealthWindow.forMetric(metric, now),
        );
      } catch (_) {
        readings[metric] = const HealthReading(state: HealthReadState.error);
      }
    }
    return HealthImport(
      day: day,
      availability: availability,
      readings: Map.unmodifiable(readings),
      refreshedAt: now,
    );
  }

  void refresh() {
    if (_authorizing) return;
    state = const AsyncLoading();
    ref.invalidateSelf();
  }

  Future<void> authorize() async {
    if (_authorizing) return;
    _authorizing = true;
    _authorization = Completer<void>();
    state = const AsyncLoading();
    // Cancel any older read before showing the system authorization sheet.
    ref.invalidateSelf();
    try {
      await ref
          .read(healthSyncServiceProvider)
          .requestPermissions(ref.read(healthPreferencesProvider));
    } finally {
      _authorizing = false;
      _authorization?.complete();
      _authorization = null;
      if (ref.mounted) refresh();
    }
  }
}

final healthImportProvider =
    AsyncNotifierProvider<HealthImportNotifier, HealthImport>(
      HealthImportNotifier.new,
    );

/// Loading and previous-day imports cannot escape into Home or Recovery.
final currentHealthImportProvider = Provider<HealthImport?>((ref) {
  final async = ref.watch(healthImportProvider);
  final selected = ref.watch(healthPreferencesProvider);
  final today = ref.watch(localDateProvider);
  if (async.isLoading || async.hasError) return null;
  final data = async.value;
  if (data == null || data.day != today) return null;
  return HealthImport(
    day: data.day,
    availability: data.availability,
    refreshedAt: data.refreshedAt,
    readings: Map.unmodifiable({
      for (final entry in data.readings.entries)
        if (selected.contains(entry.key)) entry.key: entry.value,
    }),
  );
});

final healthTrackingProvider = Provider<HealthSnapshot>((ref) {
  final metrics = ref.watch(dailyTelemetryProvider);
  final imported = ref.watch(currentHealthImportProvider);
  return HealthSnapshot(
    recordedAt: imported?.refreshedAt ?? ref.watch(healthClockProvider)(),
    steps: ref.watch(effectiveStepsAvailableProvider) ? metrics.steps : null,
    heartRateBpm: imported?.reading(HealthMetric.heartRate).value?.round(),
    sleepHours: metrics.sleepRecorded ? metrics.sleepHours : null,
    activeCalories: metrics.caloriesRecorded ? metrics.calories : null,
  );
});

final effectiveStepsAvailableProvider = Provider<bool>((ref) {
  if (ref.watch(dailyTelemetryProvider).importedSteps) return true;
  final status = ref.watch(stepTrackingStatusProvider);
  final updated = ref.watch(stepSyncInfoProvider).updatedAt?.toLocal();
  final today = ref.watch(localDateProvider);
  return status != StepTrackingStatus.permissionDenied &&
      status != StepTrackingStatus.sensorUnavailable &&
      (status != StepTrackingStatus.syncFailed ||
          (updated != null &&
              DateTime(updated.year, updated.month, updated.day) == today));
});
