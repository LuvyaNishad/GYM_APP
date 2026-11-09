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
  return _decodeLocalProfile(
    stored: stored,
    account: account,
    setupCompleted:
        hive.getSetting<bool>(AppConstants.settingOnboardingComplete) == true,
    primaryGoal: hive.getSetting<String>(AppConstants.settingPrimaryGoal),
    plates: hive.getSetting<Map>('plate_preferences_v1'),
  );
}

/// Avatar writes resolve the same compatible profile from their atomic snapshot.
UserModel? readProfileSnapshot(Map<String, dynamic> snapshot) {
  final users = (snapshot['documents'] as Map)[AppConstants.hiveBoxUser] as Map;
  final settings = snapshot['settings'] as Map;
  return _decodeLocalProfile(
    stored: users[AppConstants.hiveKeyLocalProfile] == null
        ? null
        : Map<String, dynamic>.from(
            users[AppConstants.hiveKeyLocalProfile] as Map,
          ),
    account: users['account_profile_data'] == null
        ? null
        : Map<String, dynamic>.from(users['account_profile_data'] as Map),
    setupCompleted: settings[AppConstants.settingOnboardingComplete] == true,
    primaryGoal: settings[AppConstants.settingPrimaryGoal] as String?,
    plates: settings['plate_preferences_v1'] as Map?,
  );
}

UserModel? _decodeLocalProfile({
  required Map<String, dynamic>? stored,
  required Map<String, dynamic>? account,
  required bool setupCompleted,
  required String? primaryGoal,
  required Map? plates,
}) {
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
  // Completion is durable: replaying setup only changes the questionnaire draft.
  // Older avatar saves could materialize false over this existing completed flag.
  if (setupCompleted) json['onboarding_complete'] = true;
  json['onboarding_complete'] ??= false;
  json['primary_goal'] ??= primaryGoal ?? 'BUILD MUSCLE';
  if (plates != null) {
    json['available_plates'] ??= plates['plates'];
    if (stored?['barbell_tare_kg'] == null && plates['bar'] != null) {
      json['barbell_tare_kg'] = plates['bar'];
    }
  }
  return UserModel.fromJson(json);
}
