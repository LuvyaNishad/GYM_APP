import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exercise_model.dart';

/// Owns the full exercise catalogue and exposes a filtered + searched view.
///
/// The seed list below is a placeholder. Loading the real 100+ exercise
/// catalogue from a bundled JSON asset is a later milestone; the public
/// surface of this notifier (`search`, `refresh`) will not change when it
/// lands, only [_loadExercises].
class ExerciseLibraryNotifier extends AsyncNotifier<List<ExerciseModel>> {
  List<ExerciseModel> _allExercises = const [];
  String _searchQuery = '';

  @override
  Future<List<ExerciseModel>> build() async {
    ref.keepAlive();
    _allExercises = await _loadExercises();
    return _filtered();
  }

  /// Seed data — replace with a bundled JSON catalogue.
  Future<List<ExerciseModel>> _loadExercises() async {
    // Simulate async load.
    await Future.delayed(const Duration(milliseconds: 200));

    return const [
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
  }

  /// Apply the current search query to the cached catalogue.
  List<ExerciseModel> _filtered() {
    if (_searchQuery.isEmpty) return _allExercises;
    final query = _searchQuery.toLowerCase();
    return _allExercises
        .where((ex) =>
            ex.name.toLowerCase().contains(query) ||
            ex.primaryMuscleGroup.toLowerCase().contains(query))
        .toList();
  }

  /// Update the search query and re-filter. Filters in memory — no reload.
  void search(String query) {
    _searchQuery = query;
    state = AsyncValue.data(_filtered());
  }

  /// Refresh from the backing data source, preserving the active query.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _allExercises = await _loadExercises();
      return _filtered();
    });
  }
}

/// Global provider for the Exercise Library.
final exerciseLibraryProvider =
    AsyncNotifierProvider<ExerciseLibraryNotifier, List<ExerciseModel>>(
  ExerciseLibraryNotifier.new,
);
