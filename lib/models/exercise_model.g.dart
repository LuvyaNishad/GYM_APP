// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseModelImpl _$$ExerciseModelImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      primaryMuscleGroup: json['primary_muscle_group'] as String,
      secondaryMuscleGroups: (json['secondary_muscle_groups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      equipment: json['equipment'] as String? ?? 'barbell',
      type: json['type'] as String? ?? 'compound',
      videoUrl: json['video_url'] as String?,
      instructions: json['instructions'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
      supersetGroupId: json['superset_group_id'] as String?,
      rpe: (json['rpe'] as num?)?.toInt(),
      isWarmup: json['is_warmup'] as bool? ?? false,
    );

Map<String, dynamic> _$$ExerciseModelImplToJson(_$ExerciseModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'primary_muscle_group': instance.primaryMuscleGroup,
      'secondary_muscle_groups': instance.secondaryMuscleGroups,
      'equipment': instance.equipment,
      'type': instance.type,
      'video_url': instance.videoUrl,
      'instructions': instance.instructions,
      'is_custom': instance.isCustom,
      'superset_group_id': instance.supersetGroupId,
      'rpe': instance.rpe,
      'is_warmup': instance.isWarmup,
    };
