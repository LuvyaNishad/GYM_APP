import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_model.freezed.dart';
part 'workout_model.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutModel
// ─────────────────────────────────────────────────────────────────────────────

/// A completed or planned workout entry.
///
/// Uses Freezed for immutability and JsonSerializable for serialisation.
@freezed
class WorkoutModel with _$WorkoutModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WorkoutModel({
    required String id,
    required String userId,
    required String name,
    required DateTime date,
    @Default([]) List<WorkoutExercise> exercises,
    @Default(0) int durationSeconds,
    String? notes,
    double? totalVolumeKg,
    double? averageRpe,
  }) = _WorkoutModel;

  factory WorkoutModel.fromJson(Map<String, dynamic> json) =>
      _$WorkoutModelFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutExercise
// ─────────────────────────────────────────────────────────────────────────────

/// A single exercise performed within a [WorkoutModel].
@freezed
class WorkoutExercise with _$WorkoutExercise {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WorkoutExercise({
    required String exerciseId,
    required String exerciseName,
    required String muscleGroup,
    @Default([]) List<WorkoutSet> sets,
    // ── New fields ────────────────────────────────────────────────────────
    /// Links this exercise to a superset group within this workout.
    String? supersetGroupId,

    /// Rate of Perceived Exertion logged for this exercise (1–10).
    int? rpe,

    /// Whether this exercise entry was performed as a warm-up.
    @Default(false) bool isWarmup,
  }) = _WorkoutExercise;

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutExerciseFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutSet
// ─────────────────────────────────────────────────────────────────────────────

/// A single set within a [WorkoutExercise].
@freezed
class WorkoutSet with _$WorkoutSet {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WorkoutSet({
    required int reps,
    required double weightKg,
    @Default(0.0) double rpe,
    @Default(false) bool isWarmup,
    @Default(false) bool isPr,
  }) = _WorkoutSet;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSetFromJson(json);
}
