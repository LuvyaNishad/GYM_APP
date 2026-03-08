import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exercise_model.dart';

/// A [StateNotifier] that owns the full exercise catalogue and exposes
/// a filtered + searched view of it.
///
/// Data source will be replaced with Isar/Supabase in the backend phase.
class ExerciseLibraryNotifier
    extends StateNotifier<AsyncValue<List<ExerciseModel>>> {
  ExerciseLibraryNotifier() : super(const AsyncValue.loading()) {
    _loadExercises();
  }

  List<ExerciseModel> _allExercises = [];
  String _searchQuery = '';

  /// Seed data — replace with a real DB/API call in the backend phase.
  Future<void> _loadExercises() async {
    // Simulate async load.
    await Future.delayed(const Duration(milliseconds: 200));

    _allExercises = const [
      ExerciseModel(
        id: 'ex_squat',
        name: 'Barbell Back Squat',
        primaryMuscleGroup: 'legs',
        secondaryMuscleGroups: ['core', 'glutes'],
        equipment: 'barbell',
        type: 'compound',
      ),
      ExerciseModel(
        id: 'ex_bench',
        name: 'Barbell Bench Press',
        primaryMuscleGroup: 'push',
        secondaryMuscleGroups: ['shoulders', 'triceps'],
        equipment: 'barbell',
        type: 'compound',
      ),
      ExerciseModel(
        id: 'ex_deadlift',
        name: 'Conventional Deadlift',
        primaryMuscleGroup: 'pull',
        secondaryMuscleGroups: ['legs', 'core'],
        equipment: 'barbell',
        type: 'compound',
      ),
      ExerciseModel(
        id: 'ex_ohp',
        name: 'Overhead Press',
        primaryMuscleGroup: 'push',
        secondaryMuscleGroups: ['core'],
        equipment: 'barbell',
        type: 'compound',
      ),
      ExerciseModel(
        id: 'ex_pullup',
        name: 'Pull-Up',
        primaryMuscleGroup: 'pull',
        secondaryMuscleGroups: ['biceps'],
        equipment: 'bodyweight',
        type: 'compound',
      ),
      ExerciseModel(
        id: 'ex_curl_warmup',
        name: 'Band Bicep Curl',
        primaryMuscleGroup: 'pull',
        equipment: 'cable',
        type: 'isolation',
        isWarmup: true,
        rpe: 5,
      ),
    ];

    _applyFilters();
  }

  void _applyFilters() {
    final filtered = _allExercises.where((ex) {
      if (_searchQuery.isEmpty) return true;
      return ex.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ex.primaryMuscleGroup
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    state = AsyncValue.data(filtered);
  }

  /// Update the search query and re-filter.
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Refresh from the backing data source.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadExercises();
  }
}

/// Global provider for the Exercise Library.
final exerciseLibraryProvider = StateNotifierProvider<ExerciseLibraryNotifier,
    AsyncValue<List<ExerciseModel>>>(
  (_) => ExerciseLibraryNotifier(),
);
