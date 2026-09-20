// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_filter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExerciseFilterModel _$ExerciseFilterModelFromJson(Map<String, dynamic> json) =>
    _ExerciseFilterModel(
      muscleGroup: json['muscle_group'] as String?,
      equipment: json['equipment'] as String?,
      type: json['type'] as String?,
      showWarmupOnly: json['show_warmup_only'] as bool? ?? false,
    );

Map<String, dynamic> _$ExerciseFilterModelToJson(
  _ExerciseFilterModel instance,
) => <String, dynamic>{
  'muscle_group': instance.muscleGroup,
  'equipment': instance.equipment,
  'type': instance.type,
  'show_warmup_only': instance.showWarmupOnly,
};
