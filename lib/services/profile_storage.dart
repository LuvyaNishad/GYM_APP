import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'hive_service.dart';

/// Merges older Account-only fields without inventing missing personal data.
UserModel? readLocalProfile(HiveService hive) {
  final stored = hive.read(
    AppConstants.hiveBoxUser,
    AppConstants.hiveKeyLocalProfile,
    (json) => json,
  );
  final account = hive.read(
    AppConstants.hiveBoxUser,
    'account_profile_data',
    (json) => json,
  );
  if (stored == null && account == null) return null;
  final json = <String, dynamic>{...?stored};
  const fields = {
    'id': 'id',
    'email': 'email',
    'display_name': 'display_name',
    'avatar_url': 'avatar_url',
    'created_at': 'member_since',
    'current_weight': 'current_weight_kg',
    'target_weight': 'target_weight_kg',
    'cycles_enabled': 'cycle_tracking_enabled',
    'height_cm': 'height_cm',
    'age': 'age',
    'sex': 'sex',
    'starting_weight_kg': 'starting_weight_kg',
    'goal_direction': 'goal_direction',
    'weight_updated_at': 'weight_updated_at',
    'weight_unit': 'weight_unit',
    'height_unit': 'height_unit',
    'preferred_split': 'preferred_split',
    'experience_level': 'experience_level',
    'training_days_per_week': 'training_days_per_week',
    'equipment': 'equipment',
    'injuries': 'injuries',
    'primary_goal': 'primary_goal',
    'default_rest_seconds': 'default_rest_seconds',
    'barbell_tare_kg': 'barbell_tare_kg',
    'audio_cues_enabled': 'audio_cues_enabled',
    'haptic_feedback_enabled': 'haptic_feedback_enabled',
  };
  if (stored?['schema_version'] != 2) {
    for (final entry in fields.entries) {
      if (!json.containsKey(entry.key) &&
          account?.containsKey(entry.value) == true) {
        json[entry.key] = account![entry.value];
      }
    }
  }
  json['id'] ??= 'guest_user';
  json['email'] ??= '';
  json['display_name'] ??= '';
  if (['leon@fitness.os', 'athlete@leon.fit'].contains(json['email'])) {
    json['email'] = '';
  }
  json['onboarding_complete'] ??= hive.getSetting<bool>(
    AppConstants.settingOnboardingComplete,
    fallback: false,
  );
  json['primary_goal'] ??=
      hive.getSetting<String>(AppConstants.settingPrimaryGoal) ??
      'BUILD MUSCLE';
  final plates = hive.getSetting<Map>('plate_preferences_v1');
  if (plates != null) {
    json['available_plates'] ??= plates['plates'];
    if (stored?['barbell_tare_kg'] == null && plates['bar'] != null) {
      json['barbell_tare_kg'] = plates['bar'];
    }
  }
  return UserModel.fromJson(json);
}
