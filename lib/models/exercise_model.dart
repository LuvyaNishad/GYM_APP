import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_model.freezed.dart';
part 'exercise_model.g.dart';

/// A catalogued exercise in the LEON exercise library.
///
/// Uses Freezed for immutability and JsonSerializable for serialisation.
@freezed
class ExerciseModel with _$ExerciseModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ExerciseModel({
    required String id,
    required String name,
    required String primaryMuscleGroup,
    @Default([]) List<String> secondaryMuscleGroups,
    @Default('barbell') String equipment,
    @Default('compound') String type,
    String? videoUrl,
    String? instructions,
    @Default(false) bool isCustom,
    // ── New fields ──────────────────────────────────────────────────────────
    /// Links this exercise to a superset group (shared ID across exercises).
    String? supersetGroupId,

    /// Rate of Perceived Exertion for this exercise definition (1–10).
    int? rpe,

    /// Whether this exercise is designated as a warm-up movement.
    @Default(false) bool isWarmup,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);
}
