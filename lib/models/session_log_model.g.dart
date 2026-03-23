// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionLogModelImpl _$$SessionLogModelImplFromJson(
        Map<String, dynamic> json) =>
    _$SessionLogModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      workoutId: json['workoutId'] as String,
      workoutName: json['workoutName'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      totalVolumeKg: (json['totalVolumeKg'] as num?)?.toInt() ?? 0,
      totalSets: (json['totalSets'] as num?)?.toInt() ?? 0,
      exerciseIds: (json['exerciseIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$SessionLogModelImplToJson(
        _$SessionLogModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'workoutId': instance.workoutId,
      'workoutName': instance.workoutName,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt.toIso8601String(),
      'totalVolumeKg': instance.totalVolumeKg,
      'totalSets': instance.totalSets,
      'exerciseIds': instance.exerciseIds,
      'notes': instance.notes,
    };
