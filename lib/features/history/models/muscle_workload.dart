import 'dart:math' as math;

import '../../../models/muscle_radar_data.dart';
import '../../../models/workout_model.dart';
import 'training_coverage.dart';

String formatSetEquivalents(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

/// One set can contribute at most once to each broad muscle category.
Map<String, double> categoryWeights(Map<String, double> anatomy) {
  final result = <String, double>{};
  for (final entry in anatomy.entries) {
    final category = radarMuscleCategory(entry.key);
    if (category != null && entry.value.isFinite && entry.value > 0) {
      result[category] = math.max(
        result[category] ?? 0,
        entry.value.clamp(0, 1),
      );
    }
  }
  return result;
}

class MuscleWorkloadEntry {
  const MuscleWorkloadEntry({
    required this.name,
    this.direct = 0,
    this.supporting = 0,
    this.planned = 0,
  });
  final String name;
  final double direct, supporting, planned;
  double get completed => direct + supporting;
}

class MuscleWorkload {
  MuscleWorkload({
    required this.muscles,
    this.workingSets = 0,
    this.unmappedSets = 0,
    this.durationSeconds = 0,
    this.volumeKg = 0,
    this.workoutCount = 0,
    this.hasPlan = false,
  });
  final List<MuscleWorkloadEntry> muscles;
  final int workingSets, unmappedSets, durationSeconds, workoutCount;
  final double volumeKg;
  final bool hasPlan;

  static MuscleWorkload fromWorkout(
    WorkoutModel workout,
    TrainingCoverageIndex index, {
    CoveragePlan? plan,
  }) {
    final direct = <String, double>{};
    final supporting = <String, double>{};
    final planned = <String, double>{};
    var workingSets = 0, unmapped = 0;
    var volume = 0.0;
    for (final exercise in workout.exercises.where((e) => !e.isWarmup)) {
      final sets = exercise.sets
          .where((s) => !s.isWarmup && s.reps > 0)
          .toList();
      workingSets += sets.length;
      for (final set in sets) {
        volume += math.max(0, set.weightKg) * set.reps;
        if (set.weightKgRight != null && set.repsRight != null) {
          volume +=
              math.max(0, set.weightKgRight!) * math.max(0, set.repsRight!);
        }
      }
      final weights = categoryWeights(
        index.weights(
          exercise.exerciseId,
          exercise.exerciseName,
          exercise.muscleGroup,
        ),
      );
      if (weights.isEmpty) unmapped += sets.length;
      for (final entry in weights.entries) {
        final totals = entry.value == 1 ? direct : supporting;
        totals[entry.key] =
            (totals[entry.key] ?? 0) + sets.length * entry.value;
      }
    }
    for (final exercise in plan?.exercises ?? <CoverageExercisePlan>[]) {
      for (final entry in categoryWeights(exercise.weights).entries) {
        planned[entry.key] =
            (planned[entry.key] ?? 0) + exercise.sets * entry.value;
      }
    }
    return MuscleWorkload(
      muscles: [
        for (final category in muscleRadarCategories)
          MuscleWorkloadEntry(
            name: category,
            direct: direct[category] ?? 0,
            supporting: supporting[category] ?? 0,
            planned: planned[category] ?? 0,
          ),
      ],
      workingSets: workingSets,
      unmappedSets: unmapped,
      durationSeconds: workout.durationSeconds,
      volumeKg: volume,
      workoutCount: 1,
      hasPlan: plan != null,
    );
  }

  static MuscleWorkload combine(
    Iterable<MuscleWorkload> workouts, {
    Map<String, double>? targets,
  }) {
    final sessions = workouts.toList();
    return MuscleWorkload(
      muscles: [
        for (var i = 0; i < muscleRadarCategories.length; i++)
          MuscleWorkloadEntry(
            name: muscleRadarCategories[i],
            direct: sessions.fold(0, (sum, w) => sum + w.muscles[i].direct),
            supporting: sessions.fold(
              0,
              (sum, w) => sum + w.muscles[i].supporting,
            ),
            planned: targets?[muscleRadarCategories[i]] ?? 0,
          ),
      ],
      workingSets: sessions.fold(0, (sum, w) => sum + w.workingSets),
      unmappedSets: sessions.fold(0, (sum, w) => sum + w.unmappedSets),
      durationSeconds: sessions.fold(0, (sum, w) => sum + w.durationSeconds),
      volumeKg: sessions.fold(0, (sum, w) => sum + w.volumeKg),
      workoutCount: sessions.length,
      hasPlan: targets != null,
    );
  }
}

Map<String, double> weeklyWorkloadTargets(TrainingCoverageIndex index) {
  final days = index.split.workouts.where((d) => !d.isRestDay).toList();
  final frequency = days.isEmpty ? 0.0 : index.split.daysPerWeek / days.length;
  final result = {for (final category in muscleRadarCategories) category: 0.0};
  for (final day in days) {
    for (final exercise in day.exercises) {
      final weights = categoryWeights(
        index.weights(
          exercise.exerciseId,
          exercise.exerciseName,
          exercise.muscleGroup,
        ),
      );
      for (final entry in weights.entries) {
        result[entry.key] =
            result[entry.key]! + exercise.targetSets * entry.value * frequency;
      }
    }
  }
  return result;
}

/// Shared scale across the comparable sessions; never normalize to one workout.
double muscleWorkloadScale(
  Iterable<MuscleWorkload> sessions, {
  double minimum = 20,
}) {
  var peak = minimum;
  for (final session in sessions) {
    for (final muscle in session.muscles) {
      peak = math.max(peak, math.max(muscle.completed, muscle.planned));
    }
  }
  return (peak / 10).ceil() * 10.0;
}
