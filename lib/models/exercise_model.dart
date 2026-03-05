/// A catalogued exercise in the LEON exercise library.
///
/// Plain Dart class — no code generation required.
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
      };
}
