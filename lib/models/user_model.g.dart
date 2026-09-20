// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  displayName: json['display_name'] as String,
  avatarUrl: json['avatar_url'] as String?,
  weightUnit: json['weight_unit'] as String? ?? 'kg',
  totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
  totalVolumeKg: (json['total_volume_kg'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  lastActiveAt: json['last_active_at'] == null
      ? null
      : DateTime.parse(json['last_active_at'] as String),
  currentWeight: (json['current_weight'] as num?)?.toDouble(),
  targetWeight: (json['target_weight'] as num?)?.toDouble(),
  preferredSplit: json['preferred_split'] as String?,
  sex: json['sex'] as String?,
  cyclesEnabled: json['cycles_enabled'] as bool? ?? false,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'weight_unit': instance.weightUnit,
      'total_workouts': instance.totalWorkouts,
      'total_volume_kg': instance.totalVolumeKg,
      'created_at': instance.createdAt?.toIso8601String(),
      'last_active_at': instance.lastActiveAt?.toIso8601String(),
      'current_weight': instance.currentWeight,
      'target_weight': instance.targetWeight,
      'preferred_split': instance.preferredSplit,
      'sex': instance.sex,
      'cycles_enabled': instance.cyclesEnabled,
    };
