import '../core/utils/strength_math.dart';
import '../models/workout_model.dart';

/// Counts each recorded side, including legacy records with one right field.
double workoutSetVolumeKg(WorkoutSet set) {
  double volume(double weight, int reps) =>
      weight.isFinite && weight >= 0 && reps > 0 ? weight * reps : 0;
  return volume(set.weightKg, set.reps) +
      (set.weightKgRight != null || set.repsRight != null
          ? volume(set.weightKgRight ?? set.weightKg, set.repsRight ?? set.reps)
          : 0);
}

/// Metrics are derived from authored sets on every read. Recomputing the whole
/// timeline keeps later PRs correct after an edit/deletion without a fragile
/// sequence of writes to unrelated historical records.
List<WorkoutModel> recalculateWorkoutHistory(Iterable<WorkoutModel> workouts) {
  final chronological = workouts.toList()
    ..sort((a, b) {
      final date = a.date.compareTo(b.date);
      return date == 0 ? a.id.compareTo(b.id) : date;
    });
  final best = <(String, String, bool), _BestSets>{};
  final result = <WorkoutModel>[];
  for (final workout in chronological) {
    final pending = <((String, String, bool), double, int)>[];
    var volume = 0.0;
    final effort = <double>[];
    final exercises = <WorkoutExercise>[];
    for (final exercise in workout.exercises) {
      final sets = <WorkoutSet>[];
      for (final set in exercise.sets) {
        var isPr = false;
        if (!exercise.isWarmup && !set.isWarmup) {
          volume += workoutSetVolumeKg(set);
          void record(double weight, int reps, bool right) {
            if (!weight.isFinite || weight < 0 || reps <= 0) return;
            final key = (workout.userId, exercise.exerciseId, right);
            isPr |= best[key]?.isRecord(weight, reps) ?? false;
            pending.add((key, weight, reps));
          }

          record(set.weightKg, set.reps, false);
          if (set.weightKgRight != null || set.repsRight != null) {
            record(
              set.weightKgRight ?? set.weightKg,
              set.repsRight ?? set.reps,
              true,
            );
          }
          final rpe = set.rpe > 0 ? set.rpe : exercise.rpe?.toDouble();
          if (rpe != null && rpe.isFinite && rpe > 0 && rpe <= 10) {
            effort.add(rpe);
          }
        }
        sets.add(set.copyWith(isPr: isPr));
      }
      exercises.add(exercise.copyWith(sets: sets));
    }
    // Compare all sets with previous sessions, never with the candidate's own
    // workout. The first workout for an exercise establishes its baseline.
    for (final (key, weight, reps) in pending) {
      (best[key] ??= _BestSets()).add(weight, reps);
    }
    result.add(
      workout.copyWith(
        exercises: exercises,
        totalVolumeKg: volume,
        averageRpe: effort.isEmpty
            ? null
            : effort.reduce((a, b) => a + b) / effort.length,
      ),
    );
  }
  return result.reversed.toList();
}

class _BestSets {
  double weight = 0, oneRm = 0;
  final repsByWeight = <double, int>{};

  bool isRecord(double candidateWeight, int candidateReps) {
    var previousReps = 0;
    for (final entry in repsByWeight.entries) {
      if (entry.key >= candidateWeight && entry.value > previousReps) {
        previousReps = entry.value;
      }
    }
    return candidateWeight > weight ||
        candidateReps > previousReps ||
        StrengthMath.calculateEpley1RM(candidateWeight, candidateReps) > oneRm;
  }

  void add(double candidateWeight, int candidateReps) {
    if (candidateWeight > weight) weight = candidateWeight;
    final candidateRm = StrengthMath.calculateEpley1RM(
      candidateWeight,
      candidateReps,
    );
    if (candidateRm > oneRm) oneRm = candidateRm;
    if (candidateReps > (repsByWeight[candidateWeight] ?? 0)) {
      repsByWeight[candidateWeight] = candidateReps;
    }
  }
}
