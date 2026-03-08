/// LEON user profile data model.
///
/// Plain Dart class — JSON serialisation via toJson/fromJson.
/// TODO(freezed): Annotate with @freezed when the backend phase is activated.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.weightUnit = 'kg',
    this.totalWorkouts = 0,
    this.totalVolumeKg = 0,
    this.createdAt,
    this.lastActiveAt,
    // ── New fields ──────────────────────────────────────────────────────
    this.currentWeight,
    this.targetWeight,
    this.preferredSplit,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String weightUnit;
  final int totalWorkouts;
  final int totalVolumeKg;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  /// Current body weight in the user's preferred [weightUnit].
  final double? currentWeight;

  /// Goal body weight in the user's preferred [weightUnit].
  final double? targetWeight;

  /// User's preferred training split — e.g. `'PPL'`, `'Upper/Lower'`, `'Full Body'`.
  final String? preferredSplit;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['display_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        weightUnit: (json['weight_unit'] as String?) ?? 'kg',
        totalWorkouts: (json['total_workouts'] as int?) ?? 0,
        totalVolumeKg: (json['total_volume_kg'] as int?) ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        lastActiveAt: json['last_active_at'] != null
            ? DateTime.parse(json['last_active_at'] as String)
            : null,
        currentWeight: (json['current_weight'] as num?)?.toDouble(),
        targetWeight: (json['target_weight'] as num?)?.toDouble(),
        preferredSplit: json['preferred_split'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'weight_unit': weightUnit,
        'total_workouts': totalWorkouts,
        'total_volume_kg': totalVolumeKg,
        'created_at': createdAt?.toIso8601String(),
        'last_active_at': lastActiveAt?.toIso8601String(),
        'current_weight': currentWeight,
        'target_weight': targetWeight,
        'preferred_split': preferredSplit,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? weightUnit,
    int? totalWorkouts,
    int? totalVolumeKg,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    double? currentWeight,
    double? targetWeight,
    String? preferredSplit,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        weightUnit: weightUnit ?? this.weightUnit,
        totalWorkouts: totalWorkouts ?? this.totalWorkouts,
        totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
        createdAt: createdAt ?? this.createdAt,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
        currentWeight: currentWeight ?? this.currentWeight,
        targetWeight: targetWeight ?? this.targetWeight,
        preferredSplit: preferredSplit ?? this.preferredSplit,
      );
}
