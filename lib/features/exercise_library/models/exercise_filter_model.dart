import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_filter_model.freezed.dart';
part 'exercise_filter_model.g.dart';

/// Filter criteria for the Exercise Library.
///
/// All fields are optional — null means "no filter applied" for that dimension.
/// Uses Freezed for immutability and JsonSerializable for potential persistence.
@freezed
class ExerciseFilterModel with _$ExerciseFilterModel {
  // Private generative constructor for the isEmpty getter.
  const ExerciseFilterModel._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ExerciseFilterModel({
    /// e.g. `'push'`, `'pull'`, `'legs'`, `'core'`
    String? muscleGroup,

    /// e.g. `'barbell'`, `'dumbbell'`, `'cable'`, `'bodyweight'`
    String? equipment,

    /// e.g. `'compound'`, `'isolation'`
    String? type,

    /// When true, only warm-up exercises are shown.
    @Default(false) bool showWarmupOnly,
  }) = _ExerciseFilterModel;

  factory ExerciseFilterModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFilterModelFromJson(json);

  // ── Derived state ──────────────────────────────────────────────────────────

  /// Returns true when no filters are active.
  bool get isEmpty =>
      muscleGroup == null &&
      equipment == null &&
      type == null &&
      !showWarmupOnly;
}
