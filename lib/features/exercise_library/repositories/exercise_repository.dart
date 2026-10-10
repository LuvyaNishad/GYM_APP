import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exercise_library_item.dart';

class ExerciseRepository {
  ExerciseRepository({this.catalogAssetPath = 'assets/data/exercise_catalog.json'});

  final String catalogAssetPath;
  List<ExerciseLibraryItem> _catalog = [];
  final List<ExerciseLibraryItem> _customExercises = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<ExerciseLibraryItem> get allExercises => [..._catalog, ..._customExercises];

  /// Initialize and load catalog from asset bundle
  Future<void> loadCatalog() async {
    if (_isLoaded) return;
    try {
      final jsonStr = await rootBundle.loadString(catalogAssetPath);
      final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
      _catalog = jsonList
          .map((item) => ExerciseLibraryItem.fromJson(item as Map<String, dynamic>))
          .toList();
      _isLoaded = true;
    } catch (e) {
      // Fallback empty if loading fails in test without assets
      _catalog = [];
      _isLoaded = true;
    }
  }

  /// Initialize with pre-provided items (useful for testing)
  void setCatalog(List<ExerciseLibraryItem> items) {
    _catalog = items;
    _isLoaded = true;
  }

  /// Add a custom exercise to the repository
  void addCustomExercise(ExerciseLibraryItem item) {
    _customExercises.insert(0, item.copyWith(isCustom: true));
  }

  /// Find an exercise by unique ID
  ExerciseLibraryItem? getById(String id) {
    try {
      return allExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get alternatives for a specific exercise
  List<ExerciseLibraryItem> getAlternatives(String exerciseId) {
    final exercise = getById(exerciseId);
    if (exercise == null) return [];

    final result = <ExerciseLibraryItem>[];
    for (final altId in exercise.alternatives) {
      final alt = getById(altId);
      if (alt != null) {
        result.add(alt);
      }
    }

    // Fallback if no pre-set alternatives: search matching category and exercise type
    if (result.isEmpty) {
      return allExercises
          .where((e) => e.id != exerciseId && e.category == exercise.category && e.exerciseType == exercise.exerciseType)
          .take(3)
          .toList();
    }

    return result;
  }

  /// Filter exercises by search text, category, equipment, type, and difficulty
  List<ExerciseLibraryItem> filter({
    String? searchQuery,
    String? category,
    String? equipment,
    String? exerciseType,
    String? difficulty,
  }) {
    var result = allExercises;

    // Filter by Category
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      result = result.where((e) => e.category.toLowerCase() == category.toLowerCase()).toList();
    }

    // Filter by Equipment
    if (equipment != null && equipment.isNotEmpty && equipment.toLowerCase() != 'all') {
      final eqLower = equipment.toLowerCase();
      result = result.where((e) {
        return e.primaryEquipment.toLowerCase().contains(eqLower) ||
            e.equipment.any((eq) => eq.toLowerCase().contains(eqLower));
      }).toList();
    }

    // Filter by Exercise Type (Compound / Isolation / Mobility)
    if (exerciseType != null && exerciseType.isNotEmpty && exerciseType.toLowerCase() != 'all') {
      result = result.where((e) => e.exerciseType.toLowerCase() == exerciseType.toLowerCase()).toList();
    }

    // Filter by Difficulty
    if (difficulty != null && difficulty.isNotEmpty && difficulty.toLowerCase() != 'all') {
      result = result.where((e) => e.difficulty.toLowerCase().contains(difficulty.toLowerCase())).toList();
    }

    // Filter by Search Query
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final tokens = searchQuery.trim().toLowerCase().split(RegExp(r'\s+'));
      result = result.where((e) {
        final searchCorpus = [
          e.name.toLowerCase(),
          e.category.toLowerCase(),
          e.subCategory.toLowerCase(),
          e.primaryEquipment.toLowerCase(),
          ...e.primaryMuscles.map((m) => m.toLowerCase()),
          ...e.secondaryMuscles.map((m) => m.toLowerCase()),
          ...e.equipment.map((eq) => eq.toLowerCase()),
          ...e.tags.map((t) => t.toLowerCase()),
        ].join(' ');

        return tokens.every((token) => searchCorpus.contains(token));
      }).toList();
    }

    return result;
  }
}
