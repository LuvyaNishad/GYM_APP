// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutModelImpl _$$WorkoutModelImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutModelImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble(),
      averageRpe: (json['average_rpe'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$WorkoutModelImplToJson(_$WorkoutModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'date': instance.date.toIso8601String(),
      'exercises': instance.exercises,
      'duration_seconds': instance.durationSeconds,
      'notes': instance.notes,
      'total_volume_kg': instance.totalVolumeKg,
      'average_rpe': instance.averageRpe,
    };

_$WorkoutExerciseImpl _$$WorkoutExerciseImplFromJson(
        Map<String, dynamic> json) =>
    _$WorkoutExerciseImpl(
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String,
      muscleGroup: json['muscle_group'] as String,
      sets: (json['sets'] as List<dynamic>?)
              ?.map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      supersetGroupId: json['superset_group_id'] as String?,
      rpe: (json['rpe'] as num?)?.toInt(),
      isWarmup: json['is_warmup'] as bool? ?? false,
    );

Map<String, dynamic> _$$WorkoutExerciseImplToJson(
        _$WorkoutExerciseImpl instance) =>
    <String, dynamic>{
      'exercise_id': instance.exerciseId,
      'exercise_name': instance.exerciseName,
      'muscle_group': instance.muscleGroup,
      'sets': instance.sets,
      'superset_group_id': instance.supersetGroupId,
      'rpe': instance.rpe,
      'is_warmup': instance.isWarmup,
    };

_$WorkoutSetImpl _$$WorkoutSetImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSetImpl(
      reps: (json['reps'] as num).toInt(),
      weightKg: (json['weight_kg'] as num).toDouble(),
      rpe: (json['rpe'] as num?)?.toDouble() ?? 0.0,
      isWarmup: json['is_warmup'] as bool? ?? false,
      isPr: json['is_pr'] as bool? ?? false,
    );

Map<String, dynamic> _$$WorkoutSetImplToJson(_$WorkoutSetImpl instance) =>
    <String, dynamic>{
      'reps': instance.reps,
      'weight_kg': instance.weightKg,
      'rpe': instance.rpe,
      'is_warmup': instance.isWarmup,
      'is_pr': instance.isPr,
    };
