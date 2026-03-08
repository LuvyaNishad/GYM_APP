/// Filter criteria for the Exercise Library.
///
/// All fields are optional — null means "no filter applied" for that dimension.
class ExerciseFilter {
  const ExerciseFilter({
    this.muscleGroup,
    this.equipment,
    this.type,
    this.showWarmupOnly = false,
  });

  /// e.g. `'push'`, `'pull'`, `'legs'`, `'core'`
  final String? muscleGroup;

  /// e.g. `'barbell'`, `'dumbbell'`, `'cable'`, `'bodyweight'`
  final String? equipment;

  /// e.g. `'compound'`, `'isolation'`
  final String? type;

  /// When true, only warm-up exercises are shown.
  final bool showWarmupOnly;

  ExerciseFilter copyWith({
    String? muscleGroup,
    String? equipment,
    String? type,
    bool? showWarmupOnly,
  }) =>
      ExerciseFilter(
        muscleGroup: muscleGroup ?? this.muscleGroup,
        equipment: equipment ?? this.equipment,
        type: type ?? this.type,
        showWarmupOnly: showWarmupOnly ?? this.showWarmupOnly,
      );

  /// Returns true when no filters are active.
  bool get isEmpty =>
      muscleGroup == null &&
      equipment == null &&
      type == null &&
      !showWarmupOnly;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseFilter &&
          runtimeType == other.runtimeType &&
          muscleGroup == other.muscleGroup &&
          equipment == other.equipment &&
          type == other.type &&
          showWarmupOnly == other.showWarmupOnly;

  @override
  int get hashCode => Object.hash(muscleGroup, equipment, type, showWarmupOnly);
}
