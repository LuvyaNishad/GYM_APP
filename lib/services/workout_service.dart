/// LEON Workout Service (placeholder)
///
/// Responsible for all CRUD operations on workouts, exercises, and sets.
/// Reads/writes to local Hive cache and syncs to Supabase when online.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_model.dart';

/// Provider that exposes the WorkoutService singleton.
final workoutServiceProvider = Provider<WorkoutService>(
  (ref) => WorkoutService(),
);

/// Placeholder workout service.
class WorkoutService {
  WorkoutService();

  /// Fetch all workouts for the current user.
  Future<List<WorkoutModel>> fetchWorkouts() async {
    // TODO(backend): query Supabase 'workouts' table, fallback to Hive cache.
    return [];
  }

  /// Save a new or updated workout.
  Future<void> saveWorkout(WorkoutModel workout) async {
    // TODO(backend): upsert to Supabase and Hive box.
    throw UnimplementedError('saveWorkout not yet implemented.');
  }

  /// Delete a workout by id.
  Future<void> deleteWorkout(String workoutId) async {
    // TODO(backend): delete from Supabase and Hive.
    throw UnimplementedError('deleteWorkout not yet implemented.');
  }
}
