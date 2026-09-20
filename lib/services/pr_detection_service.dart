/// LEON PR (personal record) detection.
///
/// Pure logic over stored workouts — no UI, no network. A set can beat a
/// previous best in three independent ways, so [PrResult] reports each
/// separately rather than collapsing them into one boolean.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_model.dart';
import 'workout_service.dart';

/// Provider that exposes the PrDetectionService singleton.
final prDetectionServiceProvider = Provider<PrDetectionService>(
  (ref) => PrDetectionService(ref.watch(workoutServiceProvider)),
);

/// The ways a single set can be a personal record.
enum PrKind {
  /// Heaviest weight ever lifted on this exercise, at any rep count.
  weight,

  /// Most reps ever performed at this weight or heavier.
  reps,

  /// Best Epley-estimated one-rep max.
  oneRm,
}

/// Outcome of evaluating one set against an exercise's history.
class PrResult {
  const PrResult({
    this.kinds = const <PrKind>{},
    this.previousBestWeightKg = 0.0,
    this.previousBestReps = 0,
    this.previousBestOneRm = 0.0,
    this.estimatedOneRm = 0.0,
  });

  /// Which records this set broke. Empty means no PR.
  final Set<PrKind> kinds;

  final double previousBestWeightKg;
  final int previousBestReps;
  final double previousBestOneRm;

  /// Epley estimate for the evaluated set.
  final double estimatedOneRm;

  bool get isPr => kinds.isNotEmpty;

  /// True when this is the first recorded set for the exercise. A first set
  /// is not treated as a PR — there's nothing to beat.
  bool get isFirstEver => previousBestOneRm == 0.0 && previousBestReps == 0;
}

class PrDetectionService {
  const PrDetectionService(this._workouts);

  final WorkoutService _workouts;

  /// Epley estimated 1RM: `weight × (1 + reps / 30)`.
  ///
  /// Returns 0 for non-positive reps so an empty set never reads as a record.
  static double estimateOneRm(double weightKg, int reps) =>
      reps <= 0 ? 0.0 : weightKg * (1 + reps / 30);

  /// Evaluate [candidate] against every previously logged set of [exerciseId].
  ///
  /// Pass [excludeWorkoutId] when the candidate's own workout has already been
  /// saved, so the set isn't compared against itself.
  Future<PrResult> evaluate({
    required String exerciseId,
    required WorkoutSet candidate,
    String? userId,
    String? excludeWorkoutId,
  }) async {
    if (candidate.isWarmup) return const PrResult();

    final history = await _historyFor(
      exerciseId,
      userId: userId,
      excludeWorkoutId: excludeWorkoutId,
    );

    var bestWeight = 0.0;
    var bestRepsAtWeight = 0;
    var bestOneRm = 0.0;

    for (final set in history) {
      if (set.weightKg > bestWeight) bestWeight = set.weightKg;
      if (set.weightKg >= candidate.weightKg && set.reps > bestRepsAtWeight) {
        bestRepsAtWeight = set.reps;
      }
      final oneRm = estimateOneRm(set.weightKg, set.reps);
      if (oneRm > bestOneRm) bestOneRm = oneRm;
    }

    final candidateOneRm = estimateOneRm(candidate.weightKg, candidate.reps);

    final kinds = <PrKind>{};
    // No history means nothing to beat, so the first set is never a PR.
    if (history.isNotEmpty) {
      if (candidate.weightKg > bestWeight) kinds.add(PrKind.weight);
      if (candidate.reps > bestRepsAtWeight) kinds.add(PrKind.reps);
      if (candidateOneRm > bestOneRm) kinds.add(PrKind.oneRm);
    }

    return PrResult(
      kinds: kinds,
      previousBestWeightKg: bestWeight,
      previousBestReps: bestRepsAtWeight,
      previousBestOneRm: bestOneRm,
      estimatedOneRm: candidateOneRm,
    );
  }

  /// The best estimated 1RM ever recorded for an exercise, or 0 if untrained.
  Future<double> bestOneRm(String exerciseId, {String? userId}) async {
    final history = await _historyFor(exerciseId, userId: userId);
    var best = 0.0;
    for (final set in history) {
      final oneRm = estimateOneRm(set.weightKg, set.reps);
      if (oneRm > best) best = oneRm;
    }
    return best;
  }

  /// Every non-warm-up set logged for [exerciseId].
  Future<List<WorkoutSet>> _historyFor(
    String exerciseId, {
    String? userId,
    String? excludeWorkoutId,
  }) async {
    final workouts = await _workouts.fetchWorkouts(userId: userId);
    final sets = <WorkoutSet>[];
    for (final workout in workouts) {
      if (workout.id == excludeWorkoutId) continue;
      for (final exercise in workout.exercises) {
        if (exercise.exerciseId != exerciseId) continue;
        sets.addAll(exercise.sets.where((s) => !s.isWarmup));
      }
    }
    return sets;
  }
}
