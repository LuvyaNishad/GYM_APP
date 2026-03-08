// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_filter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseFilterModelImpl _$$ExerciseFilterModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ExerciseFilterModelImpl(
      muscleGroup: json['muscle_group'] as String?,
      equipment: json['equipment'] as String?,
      type: json['type'] as String?,
      showWarmupOnly: json['show_warmup_only'] as bool? ?? false,
    );

Map<String, dynamic> _$$ExerciseFilterModelImplToJson(
        _$ExerciseFilterModelImpl instance) =>
    <String, dynamic>{
      'muscle_group': instance.muscleGroup,
      'equipment': instance.equipment,
      'type': instance.type,
      'show_warmup_only': instance.showWarmupOnly,
    };
