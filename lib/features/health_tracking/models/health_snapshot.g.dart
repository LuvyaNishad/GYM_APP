// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HealthSnapshot _$HealthSnapshotFromJson(Map<String, dynamic> json) =>
    _HealthSnapshot(
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      steps: (json['steps'] as num?)?.toInt(),
      heartRateBpm: (json['heart_rate_bpm'] as num?)?.toInt(),
      sleepHours: (json['sleep_hours'] as num?)?.toDouble(),
      activeCalories: (json['active_calories'] as num?)?.toInt(),
    );

Map<String, dynamic> _$HealthSnapshotToJson(_HealthSnapshot instance) =>
    <String, dynamic>{
      'recorded_at': instance.recordedAt.toIso8601String(),
      'steps': instance.steps,
      'heart_rate_bpm': instance.heartRateBpm,
      'sleep_hours': instance.sleepHours,
      'active_calories': instance.activeCalories,
    };
