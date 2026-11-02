import 'dart:convert';
import 'dart:typed_data';
import '../../../core/utils/measurement_units.dart';
import '../../../models/workout_model.dart';
import '../../../services/hive_service.dart';
import '../../../services/workout_history.dart';
import '../../health_tracking/models/body_measurement_model.dart';

class TrainingReportData {
  TrainingReportData({
    required this.month,
    required List<WorkoutModel> history,
    required List<BodyMeasurementEntry> measurements,
    DateTime? now,
  }) {
    final cutoff = now ?? DateTime.now();
    sessions =
        recalculateWorkoutHistory(
            history.where((w) => !w.date.isAfter(cutoff)),
          ).where((w) => contains(w.date)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    this.measurements =
        measurements
            .where((m) => contains(m.date) && !m.date.isAfter(cutoff))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
  }
  final DateTime month;
  late final List<WorkoutModel> sessions;
  late final List<BodyMeasurementEntry> measurements;
  bool contains(DateTime date) =>
      date.year == month.year && date.month == month.month;
  double get volumeKg =>
      sessions.fold(0, (sum, w) => sum + (w.totalVolumeKg ?? 0));
  int get seconds => sessions.fold(0, (sum, w) => sum + w.durationSeconds);
  int get sets => sessions.fold(
    0,
    (sum, w) =>
        sum +
        w.exercises.fold(
          0,
          (n, e) =>
              n + (e.isWarmup ? 0 : e.sets.where((s) => !s.isWarmup).length),
        ),
  );
  List<(DateTime, String, WorkoutSet)> get prs => [
    for (final w in sessions)
      for (final e in w.exercises)
        for (final s in e.sets)
          if (s.isPr) (w.date, e.exerciseName, s),
  ];
  static Future<TrainingReportData> load(
    HiveService hive,
    DateTime month,
  ) async {
    final docs = (await hive.flushedSnapshot())['documents'] as Map;
    return TrainingReportData(
      month: month,
      history: (docs['workouts'] as Map).values
          .map(
            (j) => WorkoutModel.fromJson(Map<String, dynamic>.from(j as Map)),
          )
          .toList(),
      measurements: (docs['body_measurements'] as Map).values
          .map(
            (j) => BodyMeasurementEntry.fromJson(
              Map<String, dynamic>.from(j as Map),
            ),
          )
          .toList(),
    );
  }

  String summary(MeasurementUnits units) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}\n'
      '${sessions.length} sessions · $sets working sets · ${seconds ~/ 60} min\n'
      '${units.weight(volumeKg)} lifted · ${prs.length} PR sets\n'
      '${measurements.length} measurements logged\nVolume excludes warm-ups and counts each recorded side.';

  static Uint8List workoutsCsv(List<WorkoutModel> workouts) {
    String cell(Object? value) {
      var s = value?.toString() ?? '';
      if (RegExp(r'^[=+@\-\t\r]').hasMatch(s)) s = "'$s";
      return '"${s.replaceAll('"', '""')}"';
    }

    final rows = <List<Object?>>[
      [
        'workout_id',
        'date',
        'workout',
        'exercise_id',
        'exercise',
        'set',
        'side',
        'weight_kg',
        'reps',
        'rpe',
        'warmup',
        'pr',
        'duration_seconds',
      ],
      for (final w in recalculateWorkoutHistory(workouts))
        for (final e in w.exercises)
          for (final (i, s) in e.sets.indexed)
            for (final right in [
              false,
              if (s.weightKgRight != null || s.repsRight != null) true,
            ])
              [
                w.id,
                w.date.toIso8601String(),
                w.name,
                e.exerciseId,
                e.exerciseName,
                i + 1,
                right ? 'right' : 'left/both',
                right ? s.weightKgRight ?? s.weightKg : s.weightKg,
                right ? s.repsRight ?? s.reps : s.reps,
                s.rpe,
                e.isWarmup || s.isWarmup,
                s.isPr,
                w.durationSeconds,
              ],
    ];
    return Uint8List.fromList(
      utf8.encode(rows.map((r) => r.map(cell).join(',')).join('\r\n')),
    );
  }
}
