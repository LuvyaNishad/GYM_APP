/// Workout draft — local view model for the Workout Builder screen.
/// Represents an in-progress workout being assembled by the user.
class WorkoutDraftModel {
  const WorkoutDraftModel({
    this.name = 'New Workout',
    this.exerciseIds = const [],
    this.notes = '',
  });

  final String name;
  final List<String> exerciseIds;
  final String notes;

  WorkoutDraftModel copyWith({
    String? name,
    List<String>? exerciseIds,
    String? notes,
  }) =>
      WorkoutDraftModel(
        name: name ?? this.name,
        exerciseIds: exerciseIds ?? this.exerciseIds,
        notes: notes ?? this.notes,
      );
}
