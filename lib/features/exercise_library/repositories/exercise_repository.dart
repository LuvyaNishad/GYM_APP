import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/exercise_library_item.dart';

final _searchWhitespace = RegExp(r'\s+');
String _normalize(String value) => value.trim().toLowerCase();

/// Searchable fields are prepared once per exercise, rather than per keystroke.
class _IndexedExercise {
  _IndexedExercise(this.exercise)
      : category = _normalize(exercise.category),
        equipment = [exercise.primaryEquipment, ...exercise.equipment]
            .map(_normalize).toList(growable: false),
        type = _normalize(exercise.exerciseType),
        difficulty = _normalize(exercise.difficulty),
        searchText = _normalize([
          exercise.name, exercise.category, exercise.subCategory,
          exercise.primaryEquipment, ...exercise.primaryMuscles,
          ...exercise.secondaryMuscles, ...exercise.equipment, ...exercise.tags,
        ].join(' '));

  final ExerciseLibraryItem exercise;
  final String category;
  final List<String> equipment;
  final String type;
  final String difficulty;
  final String searchText;
}

List<_IndexedExercise> _decodeCatalog(String source) {
  final jsonList = jsonDecode(source) as List<dynamic>;
  return jsonList.map((item) => _IndexedExercise(
      ExerciseLibraryItem.fromJson(item as Map<String, dynamic>)))
      .toList(growable: false);
}

class ExerciseRepository {
  ExerciseRepository({this.catalogAssetPath = 'assets/data/exercise_catalog.json'});

  final String catalogAssetPath;
  List<_IndexedExercise> _catalog = const [];
  final List<_IndexedExercise> _customExercises = [];
  List<_IndexedExercise> _searchIndex = const [];
  List<ExerciseLibraryItem> _allExercises = const [];
  Map<String, ExerciseLibraryItem> _byId = const {};
  bool _isLoaded = false;
  Future<void>? _catalogLoad;

  bool get isLoaded => _isLoaded;
  List<ExerciseLibraryItem> get allExercises => _allExercises;

  /// Share in-flight loads. Decode and index the 272 KB bundled catalog off
  /// the UI isolate on mobile/desktop, avoiding parsing on first screen build.
  Future<void> loadCatalog() {
    if (_isLoaded) return Future.value();
    return _catalogLoad ??= _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final jsonStr = await rootBundle.loadString(catalogAssetPath);
      final catalog = await compute(
        _decodeCatalog, jsonStr, debugLabel: 'exercise catalog index',
      );
      // An explicitly supplied catalog wins over an earlier asynchronous load.
      if (!_isLoaded) _catalog = catalog;
    } catch (_) {
      // Preserve the existing empty fallback for unavailable assets.
    }
    _isLoaded = true;
    _rebuildViews();
  }

  void _rebuildViews() {
    _searchIndex = List.unmodifiable([..._catalog, ..._customExercises]);
    _allExercises = List.unmodifiable(_searchIndex.map((e) => e.exercise));
    final byId = <String, ExerciseLibraryItem>{};
    for (final exercise in _allExercises) {
      byId.putIfAbsent(exercise.id, () => exercise);
    }
    _byId = Map.unmodifiable(byId);
  }

  /// Initialize with pre-provided items (useful for testing).
  void setCatalog(List<ExerciseLibraryItem> items) {
    _catalog = items.map(_IndexedExercise.new).toList(growable: false);
    _isLoaded = true;
    _rebuildViews();
  }

  void addCustomExercise(ExerciseLibraryItem item) {
    _customExercises.insert(0, _IndexedExercise(item.copyWith(isCustom: true)));
    _rebuildViews();
  }

  ExerciseLibraryItem? getById(String id) => _byId[id];

  List<ExerciseLibraryItem> getAlternatives(String exerciseId) {
    final exercise = getById(exerciseId);
    if (exercise == null) return [];
    final result = <ExerciseLibraryItem>[];
    for (final altId in exercise.alternatives) {
      final alt = getById(altId);
      if (alt != null) result.add(alt);
    }
    if (result.isNotEmpty) return result;
    return _allExercises.where((e) => e.id != exerciseId &&
        e.category == exercise.category && e.exerciseType == exercise.exerciseType)
        .take(3).toList();
  }

  /// A single pass over cached fields avoids intermediate lists and repeated
  /// lowercase/string allocations while preserving all-token search matching.
  List<ExerciseLibraryItem> filter({
    String? searchQuery,
    String? category,
    String? equipment,
    String? exerciseType,
    String? difficulty,
    bool? onlyCustom,
  }) {
    String? selection(String? value) {
      final normalized = _normalize(value ?? '');
      return normalized.isEmpty || normalized == 'all' ? null : normalized;
    }
    final categoryKey = selection(category);
    final equipmentKey = selection(equipment);
    final typeKey = selection(exerciseType);
    final difficultyKey = selection(difficulty);
    final query = _normalize(searchQuery ?? '');
    final tokens = query.isEmpty ? const <String>[] : query.split(_searchWhitespace);
    if (categoryKey == null && equipmentKey == null && typeKey == null &&
        difficultyKey == null && onlyCustom != true && tokens.isEmpty) {
      return _allExercises;
    }
    return List.unmodifiable(_searchIndex.where((entry) {
      return (onlyCustom != true || entry.exercise.isCustom) &&
          (categoryKey == null || entry.category == categoryKey) &&
          (equipmentKey == null ||
              entry.equipment.any((value) => value.contains(equipmentKey))) &&
          (typeKey == null || entry.type == typeKey) &&
          (difficultyKey == null || entry.difficulty.contains(difficultyKey)) &&
          tokens.every(entry.searchText.contains);
    }).map((entry) => entry.exercise));
  }
}
