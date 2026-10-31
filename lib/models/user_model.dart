import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// LEON user profile data model.
///
/// Uses Freezed for immutability and JsonSerializable for serialisation.
@freezed
abstract class UserModel with _$UserModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory UserModel({
    required String id,
    required String email,
    required String displayName,
    String? avatarUrl,
    @Default('kg') String weightUnit,
    @Default('cm') String heightUnit,
    int? age,
    double? heightCm,
    String? experienceLevel,
    int? trainingDaysPerWeek,
    @Default([]) List<String> equipment,
    @Default([]) List<String> injuries,
    @Default('BUILD MUSCLE') String primaryGoal,
    double? startingWeightKg,
    String? goalDirection,
    DateTime? weightUpdatedAt,
    @Default(90) int defaultRestSeconds,
    @Default(20) double barbellTareKg,
    @Default([25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25])
    List<double> availablePlates,
    @Default(true) bool audioCuesEnabled,
    @Default(true) bool hapticFeedbackEnabled,
    @Default(2) int schemaVersion,
    String? trainingSchedules,
    @Default(false) bool onboardingComplete,
    @Default(0) int totalWorkouts,
    @Default(0) int totalVolumeKg,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    // ── New fields ──────────────────────────────────────────────────────────
    /// Current body weight in kilograms, independent of display units.
    double? currentWeight,

    /// Goal body weight in kilograms, independent of display units.
    double? targetWeight,

    /// User's preferred training split — e.g. `'PPL'`, `'Upper/Lower'`.
    String? preferredSplit,

    /// Biological sex, used to unlock cycle-aware recovery. One of
    /// `'male'`, `'female'`, or null (unset / prefer not to say).
    String? sex,

    /// Whether the user has opted into menstrual-cycle tracking. Gates the
    /// cycle module and the `CyclePhaseFactor` in recovery scoring.
    @Default(false) bool cyclesEnabled,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
