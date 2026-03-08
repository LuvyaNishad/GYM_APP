import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// LEON user profile data model.
///
/// Uses Freezed for immutability and JsonSerializable for serialisation.
@freezed
class UserModel with _$UserModel {
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
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
