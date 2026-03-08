/// A catalogued exercise in the LEON exercise library.
///
/// Plain Dart class — no code generation required.
/// TODO(freezed): Annotate with @freezed when the backend phase is activated.
class ExerciseModel {
  const ExerciseModel({
    required this.id,
    required this.name,
    required this.primaryMuscleGroup,
    this.secondaryMuscleGroups = const [],
    this.equipment = 'barbell',
    this.type = 'compound',
    this.videoUrl,
    this.instructions,
    this.isCustom = false,
    // ── New fields ────────────────────────────────────────────────────────
    this.supersetGroupId,
    this.rpe,
    this.isWarmup = false,
  });

  final String id;
  final String name;
  final String primaryMuscleGroup;
  final List<String> secondaryMuscleGroups;
  final String equipment;
  final String type;
  final String? videoUrl;
  final String? instructions;
  final bool isCustom;

  /// Links this exercise to a superset group (shared ID across exercises).
  final String? supersetGroupId;

  /// Rate of Perceived Exertion for this exercise definition (1–10).
  final int? rpe;

  /// Whether this exercise is designated as a warm-up movement.
  final bool isWarmup;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
        id: json['id'] as String,
        name: json['name'] as String,
        primaryMuscleGroup: json['primary_muscle_group'] as String,
        secondaryMuscleGroups:
            (json['secondary_muscle_groups'] as List<dynamic>?)
                    ?.cast<String>() ??
                [],
        equipment: (json['equipment'] as String?) ?? 'barbell',
        type: (json['type'] as String?) ?? 'compound',
        videoUrl: json['video_url'] as String?,
        instructions: json['instructions'] as String?,
        isCustom: (json['is_custom'] as bool?) ?? false,
        supersetGroupId: json['superset_group_id'] as String?,
        rpe: json['rpe'] as int?,
        isWarmup: (json['is_warmup'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primary_muscle_group': primaryMuscleGroup,
        'secondary_muscle_groups': secondaryMuscleGroups,
        'equipment': equipment,
        'type': type,
        'video_url': videoUrl,
        'instructions': instructions,
        'is_custom': isCustom,
        'superset_group_id': supersetGroupId,
        'rpe': rpe,
        'is_warmup': isWarmup,
      };

  ExerciseModel copyWith({
    String? id,
    String? name,
    String? primaryMuscleGroup,
    List<String>? secondaryMuscleGroups,
    String? equipment,
    String? type,
    String? videoUrl,
    String? instructions,
    bool? isCustom,
    String? supersetGroupId,
    int? rpe,
    bool? isWarmup,
  }) =>
      ExerciseModel(
        id: id ?? this.id,
        name: name ?? this.name,
        primaryMuscleGroup: primaryMuscleGroup ?? this.primaryMuscleGroup,
        secondaryMuscleGroups:
            secondaryMuscleGroups ?? this.secondaryMuscleGroups,
        equipment: equipment ?? this.equipment,
        type: type ?? this.type,
        videoUrl: videoUrl ?? this.videoUrl,
        instructions: instructions ?? this.instructions,
        isCustom: isCustom ?? this.isCustom,
        supersetGroupId: supersetGroupId ?? this.supersetGroupId,
        rpe: rpe ?? this.rpe,
        isWarmup: isWarmup ?? this.isWarmup,
      );
}
