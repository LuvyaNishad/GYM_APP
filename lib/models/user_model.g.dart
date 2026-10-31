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
  heightUnit: json['height_unit'] as String? ?? 'cm',
  age: (json['age'] as num?)?.toInt(),
  heightCm: (json['height_cm'] as num?)?.toDouble(),
  experienceLevel: json['experience_level'] as String?,
  trainingDaysPerWeek: (json['training_days_per_week'] as num?)?.toInt(),
  equipment:
      (json['equipment'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  injuries:
      (json['injuries'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  primaryGoal: json['primary_goal'] as String? ?? 'BUILD MUSCLE',
  startingWeightKg: (json['starting_weight_kg'] as num?)?.toDouble(),
  goalDirection: json['goal_direction'] as String?,
  weightUpdatedAt: json['weight_updated_at'] == null
      ? null
      : DateTime.parse(json['weight_updated_at'] as String),
  defaultRestSeconds: (json['default_rest_seconds'] as num?)?.toInt() ?? 90,
  barbellTareKg: (json['barbell_tare_kg'] as num?)?.toDouble() ?? 20,
  availablePlates:
      (json['available_plates'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      const [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25],
  audioCuesEnabled: json['audio_cues_enabled'] as bool? ?? true,
  hapticFeedbackEnabled: json['haptic_feedback_enabled'] as bool? ?? true,
  schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 2,
  trainingSchedules: json['training_schedules'] as String?,
  onboardingComplete: json['onboarding_complete'] as bool? ?? false,
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
      'height_unit': instance.heightUnit,
      'age': instance.age,
      'height_cm': instance.heightCm,
      'experience_level': instance.experienceLevel,
      'training_days_per_week': instance.trainingDaysPerWeek,
      'equipment': instance.equipment,
      'injuries': instance.injuries,
      'primary_goal': instance.primaryGoal,
      'starting_weight_kg': instance.startingWeightKg,
      'goal_direction': instance.goalDirection,
      'weight_updated_at': instance.weightUpdatedAt?.toIso8601String(),
      'default_rest_seconds': instance.defaultRestSeconds,
      'barbell_tare_kg': instance.barbellTareKg,
      'available_plates': instance.availablePlates,
      'audio_cues_enabled': instance.audioCuesEnabled,
      'haptic_feedback_enabled': instance.hapticFeedbackEnabled,
      'schema_version': instance.schemaVersion,
      'training_schedules': instance.trainingSchedules,
      'onboarding_complete': instance.onboardingComplete,
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
