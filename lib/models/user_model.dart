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
    @Default(0) int totalWorkouts,
    @Default(0) int totalVolumeKg,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    // ── New fields ──────────────────────────────────────────────────────────
    /// Current body weight in the user's preferred [weightUnit].
    double? currentWeight,

    /// Goal body weight in the user's preferred [weightUnit].
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
