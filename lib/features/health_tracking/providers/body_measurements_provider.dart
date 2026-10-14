/// Body Measurements and Recomposition providers for LEON.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/hive_service.dart';
import '../models/body_measurement_model.dart';

const String _boxName = 'body_measurements';

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

    return _buildSampleMeasurements();
  }

  Future<void> addMeasurement(BodyMeasurementEntry entry) async {
    final hive = ref.read(hiveServiceProvider);
    try {
      await hive.put(_boxName, entry.id, entry.toJson());
    } catch (_) {}

    final updated = [entry, ...state.where((e) => e.id != entry.id)]
      ..sort((a, b) => b.date.compareTo(a.date));
    state = updated;
  }

  Future<void> deleteMeasurement(String id) async {
    final hive = ref.read(hiveServiceProvider);
    try {
      await hive.delete(_boxName, id);
    } catch (_) {}

    state = state.where((e) => e.id != id).toList();
  }

  static List<BodyMeasurementEntry> _buildSampleMeasurements() {
    final now = DateTime.now();
    return [
      BodyMeasurementEntry(
        id: 'm_today',
        date: now.subtract(const Duration(days: 2)),
        weightKg: 79.2,
        bodyFatPercent: 16.2,
        waistCm: 82.2,
        chestCm: 103.0,
        armsCm: 37.8,
        thighsCm: 58.5,
        notes: 'Morning measurement fasted. Arms peaked.',
      ),
      BodyMeasurementEntry(
        id: 'm_2weeks',
        date: now.subtract(const Duration(days: 16)),
        weightKg: 79.8,
        bodyFatPercent: 16.8,
        waistCm: 83.0,
        chestCm: 102.5,
        armsCm: 37.4,
        thighsCm: 58.2,
        notes: 'Mid-block check-in.',
      ),
      BodyMeasurementEntry(
        id: 'm_month',
        date: now.subtract(const Duration(days: 30)),
        weightKg: 80.5,
        bodyFatPercent: 17.5,
        waistCm: 84.0,
        chestCm: 102.0,
        armsCm: 37.0,
        thighsCm: 58.0,
        notes: 'Baseline measurement.',
      ),
    ];
  }
}

final bodyMeasurementsProvider =
    NotifierProvider<BodyMeasurementsNotifier, List<BodyMeasurementEntry>>(
        BodyMeasurementsNotifier.new);

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
  });

  final double latestWeight;
  final double weightDelta30d;
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
  final entries = ref.watch(bodyMeasurementsProvider);
  if (entries.isEmpty) {
    return const RecompositionSummary(
      latestWeight: 75.0,
      weightDelta30d: 0.0,
    );
  }

  final latest = entries.first;
  final oldest = entries.last;

  double wDelta = latest.weightKg - oldest.weightKg;
  double? bfDelta = (latest.bodyFatPercent != null && oldest.bodyFatPercent != null)
      ? latest.bodyFatPercent! - oldest.bodyFatPercent!
      : null;
  double? waistDelta = (latest.waistCm != null && oldest.waistCm != null)
      ? latest.waistCm! - oldest.waistCm!
      : null;
  double? armDelta = (latest.armsCm != null && oldest.armsCm != null)
      ? latest.armsCm! - oldest.armsCm!
      : null;
  double? chestDelta = (latest.chestCm != null && oldest.chestCm != null)
      ? latest.chestCm! - oldest.chestCm!
      : null;

  return RecompositionSummary(
    latestWeight: latest.weightKg,
    weightDelta30d: double.parse(wDelta.toStringAsFixed(1)),
    latestBodyFat: latest.bodyFatPercent,
    bodyFatDelta30d: bfDelta != null ? double.parse(bfDelta.toStringAsFixed(1)) : null,
    latestWaist: latest.waistCm,
    waistDelta30d: waistDelta != null ? double.parse(waistDelta.toStringAsFixed(1)) : null,
    latestArms: latest.armsCm,
    armDelta30d: armDelta != null ? double.parse(armDelta.toStringAsFixed(1)) : null,
    latestChest: latest.chestCm,
    chestDelta30d: chestDelta != null ? double.parse(chestDelta.toStringAsFixed(1)) : null,
  );
});
