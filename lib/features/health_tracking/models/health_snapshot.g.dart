// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HealthSnapshotImpl _$$HealthSnapshotImplFromJson(Map<String, dynamic> json) =>
    _$HealthSnapshotImpl(
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      steps: (json['steps'] as num?)?.toInt(),
      heartRateBpm: (json['heart_rate_bpm'] as num?)?.toInt(),
      sleepHours: (json['sleep_hours'] as num?)?.toDouble(),
      activeCalories: (json['active_calories'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$HealthSnapshotImplToJson(
        _$HealthSnapshotImpl instance) =>
    <String, dynamic>{
      'recorded_at': instance.recordedAt.toIso8601String(),
      'steps': instance.steps,
      'heart_rate_bpm': instance.heartRateBpm,
      'sleep_hours': instance.sleepHours,
      'active_calories': instance.activeCalories,
    };
