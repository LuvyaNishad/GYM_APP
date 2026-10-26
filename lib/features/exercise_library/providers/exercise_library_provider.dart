import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise_library_item.dart';
import '../repositories/exercise_repository.dart';

/// Filter parameters for the Exercise Library
@immutable
class ExerciseFilterState {
  const ExerciseFilterState({
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.selectedEquipment = 'All',
    this.selectedType = 'All',
    this.selectedDifficulty = 'All',
    this.onlyCustom = false,
  });

  final String searchQuery;
  final String selectedCategory;
  final String selectedEquipment;
  final String selectedType;
  final String selectedDifficulty;
  final bool onlyCustom;

  int get activeFiltersCount {
    int count = 0;
    if (selectedCategory != 'All') count++;
    if (selectedEquipment != 'All') count++;
    if (selectedType != 'All') count++;
    if (selectedDifficulty != 'All') count++;
    if (onlyCustom) count++;
    return count;
  }

  bool get hasActiveFilters => activeFiltersCount > 0 || searchQuery.isNotEmpty;

  ExerciseFilterState copyWith({
    String? searchQuery,
    String? selectedCategory,
    String? selectedEquipment,
    String? selectedType,
    String? selectedDifficulty,
    bool? onlyCustom,
  }) {
    return ExerciseFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
      selectedType: selectedType ?? this.selectedType,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      onlyCustom: onlyCustom ?? this.onlyCustom,
    );
  }
}

/// Composite state for the Exercise Library
@immutable
class ExerciseLibraryState {
  const ExerciseLibraryState({
    required this.allExercises,
    required this.filteredExercises,
    required this.filter,
    this.isLoading = false,
  });

  final List<ExerciseLibraryItem> allExercises;
  final List<ExerciseLibraryItem> filteredExercises;
  final ExerciseFilterState filter;
  final bool isLoading;

  ExerciseLibraryState copyWith({
    List<ExerciseLibraryItem>? allExercises,
    List<ExerciseLibraryItem>? filteredExercises,
    ExerciseFilterState? filter,
    bool? isLoading,
  }) {
    return ExerciseLibraryState(
      allExercises: allExercises ?? this.allExercises,
      filteredExercises: filteredExercises ?? this.filteredExercises,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Exercise repository singleton provider
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository();
});

/// Riverpod notifier managing the Exercise Library catalog and filtering
class ExerciseLibraryNotifier extends Notifier<ExerciseLibraryState> {
  static const searchDebounceDuration = Duration(milliseconds: 150);
  Timer? _searchDebounce;
  String? _pendingSearchQuery;

  @override
  ExerciseLibraryState build() {
    ref.keepAlive();
    ref.onDispose(_cancelSearch);
    final repo = ref.watch(exerciseRepositoryProvider);

    // Initial load trigger
    if (!repo.isLoaded) {
      Future.microtask(() {
        if (ref.mounted) loadCatalog();
      });
    }

    final all = repo.allExercises;
    return ExerciseLibraryState(
      allExercises: all,
      filteredExercises: all,
      filter: const ExerciseFilterState(),
      isLoading: !repo.isLoaded,
    );
  }

  ExerciseRepository get _repository => ref.read(exerciseRepositoryProvider);

  Future<void> loadCatalog() async {
    state = state.copyWith(isLoading: true);
    await _repository.loadCatalog();
    if (!ref.mounted) return;
    final all = _repository.allExercises;
    state = state.copyWith(
      allExercises: all,
      isLoading: false,
    );
    _applyFilter(state.filter);
  }

  void _applyFilter(ExerciseFilterState newFilter) {
    // A filter tap during typing commits the latest query and cancels stale work.
    final pendingQuery = _pendingSearchQuery;
    if (pendingQuery != null) {
      newFilter = newFilter.copyWith(searchQuery: pendingQuery);
      _cancelSearch();
    }
    final filtered = _repository.filter(
      searchQuery: newFilter.searchQuery,
      category: newFilter.selectedCategory,
      equipment: newFilter.selectedEquipment,
      exerciseType: newFilter.selectedType,
      difficulty: newFilter.selectedDifficulty,
      onlyCustom: newFilter.onlyCustom,
    );

    state = state.copyWith(
      filter: newFilter,
      filteredExercises: filtered,
    );
  }

  void toggleOnlyCustom() {
    _applyFilter(state.filter.copyWith(onlyCustom: !state.filter.onlyCustom));
  }

  void setOnlyCustom(bool onlyCustom) {
    _applyFilter(state.filter.copyWith(onlyCustom: onlyCustom));
  }

  void setSearchQuery(String query) {
    _cancelSearch();
    _applyFilter(state.filter.copyWith(searchQuery: query));
  }

  /// Text entry stays immediate; filtering runs after typing settles.
  void debounceSearchQuery(String query) {
    _cancelSearch();
    if (query.trim().isEmpty) {
      setSearchQuery(query);
      return;
    }
    _pendingSearchQuery = query;
    _searchDebounce = Timer(searchDebounceDuration, () {
      _pendingSearchQuery = null;
      _searchDebounce = null;
      _applyFilter(state.filter.copyWith(searchQuery: query));
    });
  }

  void _cancelSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = null;
    _pendingSearchQuery = null;
  }

  void setCategory(String category) {
    final current = state.filter.selectedCategory;
    final next = (current == category && category != 'All') ? 'All' : category;
    _applyFilter(state.filter.copyWith(selectedCategory: next));
  }

  void setEquipment(String equipment) {
    final current = state.filter.selectedEquipment;
    final next = (current == equipment && equipment != 'All') ? 'All' : equipment;
    _applyFilter(state.filter.copyWith(selectedEquipment: next));
  }

  void setType(String type) {
    final current = state.filter.selectedType;
    final next = (current == type && type != 'All') ? 'All' : type;
    _applyFilter(state.filter.copyWith(selectedType: next));
  }

  void setDifficulty(String difficulty) {
    final current = state.filter.selectedDifficulty;
    final next = (current == difficulty && difficulty != 'All') ? 'All' : difficulty;
    _applyFilter(state.filter.copyWith(selectedDifficulty: next));
  }

  void resetFilters() {
    _applyFilter(ExerciseFilterState(searchQuery: state.filter.searchQuery));
  }

  void clearAll() {
    _cancelSearch();
    _applyFilter(const ExerciseFilterState());
  }

  void addCustomExercise(ExerciseLibraryItem item) {
    _repository.addCustomExercise(item);
    final all = _repository.allExercises;
    state = state.copyWith(allExercises: all);
    _applyFilter(state.filter);
  }

  List<ExerciseLibraryItem> getAlternatives(String exerciseId) {
    return _repository.getAlternatives(exerciseId);
  }
}

final exerciseLibraryProvider =
    NotifierProvider<ExerciseLibraryNotifier, ExerciseLibraryState>(
  ExerciseLibraryNotifier.new,
);
