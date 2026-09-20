/// LEON Workout Service
///
/// All CRUD operations on workouts, exercises, and sets. Backed by the local
/// Hive cache via [HiveService]; a Supabase sync layer will be added on top
/// without changing this surface.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/workout_model.dart';
import 'hive_service.dart';

/// Provider that exposes the WorkoutService singleton.
final workoutServiceProvider = Provider<WorkoutService>(
  (ref) => WorkoutService(ref.watch(hiveServiceProvider)),
);

class WorkoutService {
  const WorkoutService(this._hive);

  final HiveService _hive;

  /// Fetch all workouts for [userId], newest first.
  ///
  /// Pass a null [userId] to fetch every stored workout (guest mode, where
  /// records carry a placeholder user id).
  Future<List<WorkoutModel>> fetchWorkouts({String? userId}) async {
    final all = _hive.readAll(
      AppConstants.hiveBoxWorkouts,
      WorkoutModel.fromJson,
    );
    final scoped =
        userId == null ? all : all.where((w) => w.userId == userId).toList();
    scoped.sort((a, b) => b.date.compareTo(a.date));
    return scoped;
  }

  /// Fetch a single workout by id, or null when absent.
  Future<WorkoutModel?> fetchWorkout(String workoutId) async => _hive.read(
        AppConstants.hiveBoxWorkouts,
        workoutId,
        WorkoutModel.fromJson,
      );

  /// Save a new or updated workout, keyed by [WorkoutModel.id].
  Future<void> saveWorkout(WorkoutModel workout) => _hive.put(
        AppConstants.hiveBoxWorkouts,
        workout.id,
        workout.toJson(),
      );

  /// Delete a workout by id. No-op when it doesn't exist.
  Future<void> deleteWorkout(String workoutId) =>
      _hive.delete(AppConstants.hiveBoxWorkouts, workoutId);

  /// Total volume in kg across every set of a workout, warm-ups excluded.
  ///
  /// Warm-ups are excluded because they inflate volume without contributing
  /// meaningful training stimulus — the same reason they're flagged on
  /// [WorkoutSet.isWarmup].
  static double totalVolumeKg(WorkoutModel workout) {
    var volume = 0.0;
    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        if (set.isWarmup) continue;
        volume += set.weightKg * set.reps;
      }
    }
    return volume;
  }
}
