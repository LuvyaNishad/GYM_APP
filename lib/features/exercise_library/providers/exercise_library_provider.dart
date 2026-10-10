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
  });

  final String searchQuery;
  final String selectedCategory;
  final String selectedEquipment;
  final String selectedType;
  final String selectedDifficulty;

  int get activeFiltersCount {
    int count = 0;
    if (selectedCategory != 'All') count++;
    if (selectedEquipment != 'All') count++;
    if (selectedType != 'All') count++;
    if (selectedDifficulty != 'All') count++;
    return count;
  }

  bool get hasActiveFilters => activeFiltersCount > 0 || searchQuery.isNotEmpty;

  ExerciseFilterState copyWith({
    String? searchQuery,
    String? selectedCategory,
    String? selectedEquipment,
    String? selectedType,
    String? selectedDifficulty,
  }) {
    return ExerciseFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
      selectedType: selectedType ?? this.selectedType,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
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
  @override
  ExerciseLibraryState build() {
    ref.keepAlive();
    final repo = ref.watch(exerciseRepositoryProvider);

    // Initial load trigger
    if (!repo.isLoaded) {
      Future.microtask(() => loadCatalog());
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
    final all = _repository.allExercises;
    state = state.copyWith(
      allExercises: all,
      filteredExercises: all,
      isLoading: false,
    );
  }

  void _applyFilter(ExerciseFilterState newFilter) {
    final filtered = _repository.filter(
      searchQuery: newFilter.searchQuery,
      category: newFilter.selectedCategory,
      equipment: newFilter.selectedEquipment,
      exerciseType: newFilter.selectedType,
      difficulty: newFilter.selectedDifficulty,
    );

    state = state.copyWith(
      filter: newFilter,
      filteredExercises: filtered,
    );
  }

  void setSearchQuery(String query) {
    _applyFilter(state.filter.copyWith(searchQuery: query));
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
