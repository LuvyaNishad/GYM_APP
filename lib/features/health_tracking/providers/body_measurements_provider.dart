/// Body Measurements and Recomposition providers for LEON.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/hive_service.dart';
import '../../../core/providers/local_date_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../models/body_measurement_model.dart';

const String _boxName = AppConstants.hiveBoxBodyMeasurements;

class BodyMeasurementsNotifier extends Notifier<List<BodyMeasurementEntry>> {
  @override
  List<BodyMeasurementEntry> build() {
    final hive = ref.watch(hiveServiceProvider);
    List<BodyMeasurementEntry> stored = [];
    try {
      stored = hive.readAll(_boxName, BodyMeasurementEntry.fromJson);
    } catch (_) {
      stored = [];
    }

    if (stored.isNotEmpty) {
      stored.sort((a, b) => b.date.compareTo(a.date));
      return stored;
    }

    // Clean initial state: zero fake measurements
    return [];
  }

  Future<void> _changes = Future.value();

  Future<void> _change(Future<void> Function() action) {
    final result = _changes.catchError((Object _) {}).then((_) => action());
    _changes = result;
    return result;
  }

  Future<void> addMeasurement(BodyMeasurementEntry entry) => _change(() async {
    final sizes = [entry.waistCm, entry.chestCm, entry.armsCm, entry.thighsCm];
    final bodyFat = entry.bodyFatPercent;
    if (!entry.weightKg.isFinite ||
        entry.weightKg <= 0 ||
        sizes.any(
          (value) => value != null && (!value.isFinite || value <= 0),
        ) ||
        (bodyFat != null &&
            (!bodyFat.isFinite || bodyFat < 0 || bodyFat > 100))) {
      throw ArgumentError(
        'Measurements must be finite and within valid ranges.',
      );
    }
    final hive = ref.read(hiveServiceProvider);
    await hive.put(_boxName, entry.id, entry.toJson());
    if (!ref.mounted) return;
    state = [entry, ...state.where((e) => e.id != entry.id)]
      ..sort((a, b) => b.date.compareTo(a.date));
  });

  Future<void> deleteMeasurement(String id) => _change(() async {
    await ref.read(hiveServiceProvider).delete(_boxName, id);
    if (ref.mounted) state = state.where((e) => e.id != id).toList();
  });
}

final bodyMeasurementsProvider =
    NotifierProvider<BodyMeasurementsNotifier, List<BodyMeasurementEntry>>(
      BodyMeasurementsNotifier.new,
    );

class RecompositionSummary {
  const RecompositionSummary({
    required this.latestWeight,
    required this.weightDelta30d,
    this.latestBodyFat,
    this.bodyFatDelta30d,
    this.latestWaist,
    this.waistDelta30d,
    this.latestArms,
    this.armDelta30d,
    this.latestChest,
    this.chestDelta30d,
    this.latestThighs,
    this.thighDelta30d,
    this.comparisonDays,
  });

  final double latestWeight;
  final double? weightDelta30d;
  final double? latestThighs, thighDelta30d;
  final int? comparisonDays;
  final double? latestBodyFat;
  final double? bodyFatDelta30d;
  final double? latestWaist;
  final double? waistDelta30d;
  final double? latestArms;
  final double? armDelta30d;
  final double? latestChest;
  final double? chestDelta30d;
}

final recompositionSummaryProvider = Provider<RecompositionSummary>((ref) {
  final today = ref.watch(localDateProvider);
  final entries = ref
      .watch(bodyMeasurementsProvider)
      .where(
        (e) =>
            e.date.isBefore(DateTime(today.year, today.month, today.day + 1)),
      )
      .toList();
  if (entries.isEmpty) {
    return const RecompositionSummary(latestWeight: 0, weightDelta30d: null);
  }
  final latest = entries.first;
  final cutoff = DateTime(
    latest.date.year,
    latest.date.month,
    latest.date.day - 30,
  );
  // At most seven days of tolerance, with the actual interval exposed to the UI.
  final baseline = entries
      .where(
        (e) =>
            e.date.isBefore(cutoff.add(const Duration(days: 1))) &&
            !e.date.isBefore(cutoff.subtract(const Duration(days: 7))),
      )
      .firstOrNull;
  final recent = !latest.date.isBefore(today.subtract(const Duration(days: 7)));
  double? delta(double? current, double? previous) =>
      recent && baseline != null && current != null && previous != null
      ? double.parse((current - previous).toStringAsFixed(1))
      : null;
  return RecompositionSummary(
    latestWeight: latest.weightKg,
    weightDelta30d: delta(latest.weightKg, baseline?.weightKg),
    latestBodyFat: latest.bodyFatPercent,
    bodyFatDelta30d: delta(latest.bodyFatPercent, baseline?.bodyFatPercent),
    latestWaist: latest.waistCm,
    waistDelta30d: delta(latest.waistCm, baseline?.waistCm),
    latestArms: latest.armsCm,
    armDelta30d: delta(latest.armsCm, baseline?.armsCm),
    latestChest: latest.chestCm,
    chestDelta30d: delta(latest.chestCm, baseline?.chestCm),
    latestThighs: latest.thighsCm,
    thighDelta30d: delta(latest.thighsCm, baseline?.thighsCm),
    comparisonDays: recent && baseline != null
        ? latest.date.difference(baseline.date).inDays
        : null,
  );
});
