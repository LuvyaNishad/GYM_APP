import '../../../core/utils/measurement_units.dart';
import '../../../models/user_model.dart';

const _unchanged = Object();

/// Account is a view of the canonical local profile plus derived metrics.
class AccountProfile {
  const AccountProfile({
    this.id = 'guest_user',
    this.displayName = '',
    this.email = '',
    this.avatarUrl,
    required this.memberSince,
    this.age,
    this.sex,
    this.heightCm,
    this.currentWeightKg,
    this.targetWeightKg,
    this.startingWeightKg,
    this.goalDirection,
    this.weightUpdatedAt,
    this.weightUnit = 'kg',
    this.heightUnit = 'cm',
    this.preferredSplit = 'split_ppl',
    this.experienceLevel = 'Not set',
    this.trainingDaysPerWeek,
    this.equipment = const [],
    this.injuries = const [],
    this.primaryGoal = 'BUILD MUSCLE',
    this.defaultRestSeconds = 90,
    this.barbellTareKg = 20,
    this.cycleTrackingEnabled = false,
    this.audioCuesEnabled = true,
    this.hapticFeedbackEnabled = true,
    this.totalWorkouts = 0,
    this.totalVolumeKg = 0,
  });

  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final DateTime memberSince;
  final int? age;
  final String? sex;
  final double? heightCm;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final double? startingWeightKg;
  final String? goalDirection;
  final DateTime? weightUpdatedAt;
  final String weightUnit;
  final String heightUnit;
  final String preferredSplit;
  final String experienceLevel;
  final int? trainingDaysPerWeek;
  final List<String> equipment;
  final List<String> injuries;
  final String primaryGoal;
  final int defaultRestSeconds;
  final double barbellTareKg;
  final bool cycleTrackingEnabled;
  final bool audioCuesEnabled;
  final bool hapticFeedbackEnabled;
  final int totalWorkouts;
  final double totalVolumeKg;

  MeasurementUnits get units =>
      MeasurementUnits(weightUnit: weightUnit, heightUnit: heightUnit);
  String get formattedHeight => units.height(heightCm);
  String formatWeight(double? kg) => units.weight(kg);
  double? get bmi =>
      heightCm == null || currentWeightKg == null || heightCm! <= 0
      ? null
      : currentWeightKg! / ((heightCm! / 100) * (heightCm! / 100));
  String get formattedBmi => bmi?.toStringAsFixed(1) ?? 'Not set';
  String get bmiCategory => bmi == null
      ? 'Height and weight needed'
      : bmi! < 18.5
      ? 'Underweight'
      : bmi! < 25
      ? 'Normal Weight'
      : bmi! < 30
      ? 'Overweight'
      : 'Obesity range';
  double? get weightDeltaKg => currentWeightKg == null || targetWeightKg == null
      ? null
      : (currentWeightKg! - targetWeightKg!).abs();
  bool get isCutting =>
      goalDirection == 'lose' ||
      (goalDirection == null &&
          currentWeightKg != null &&
          targetWeightKg != null &&
          currentWeightKg! > targetWeightKg!);
  double? get goalProgress {
    if (startingWeightKg == null ||
        currentWeightKg == null ||
        targetWeightKg == null) {
      return null;
    }
    final total = targetWeightKg! - startingWeightKg!;
    if (total == 0) return currentWeightKg == targetWeightKg ? 1 : 0;
    return ((currentWeightKg! - startingWeightKg!) / total).clamp(0.0, 1.0);
  }

  int? get bmrEstimate {
    if (age == null ||
        heightCm == null ||
        currentWeightKg == null ||
        !['male', 'female'].contains(sex)) {
      return null;
    }
    return (10 * currentWeightKg! +
            6.25 * heightCm! -
            5 * age! +
            (sex == 'male' ? 5 : -161))
        .round();
  }

  int? get maintenanceCaloriesEstimate =>
      bmrEstimate == null ? null : (bmrEstimate! * 1.55).round();
  String get calorieAssumptions => bmrEstimate == null
      ? 'Add age, height, weight and sex to estimate calories.'
      : 'Mifflin–St Jeor estimate; assumes moderate activity (1.55). Actual needs vary.';

  AccountProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    Object? avatarUrl = _unchanged,
    DateTime? memberSince,
    Object? age = _unchanged,
    Object? sex = _unchanged,
    Object? heightCm = _unchanged,
    Object? currentWeightKg = _unchanged,
    Object? targetWeightKg = _unchanged,
    Object? startingWeightKg = _unchanged,
    Object? goalDirection = _unchanged,
    Object? weightUpdatedAt = _unchanged,
    String? weightUnit,
    String? heightUnit,
    String? preferredSplit,
    String? experienceLevel,
    Object? trainingDaysPerWeek = _unchanged,
    List<String>? equipment,
    List<String>? injuries,
    String? primaryGoal,
    int? defaultRestSeconds,
    double? barbellTareKg,
    bool? cycleTrackingEnabled,
    bool? audioCuesEnabled,
    bool? hapticFeedbackEnabled,
    int? totalWorkouts,
    double? totalVolumeKg,
  }) => AccountProfile(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    avatarUrl: identical(avatarUrl, _unchanged)
        ? this.avatarUrl
        : avatarUrl as String?,
    memberSince: memberSince ?? this.memberSince,
    age: identical(age, _unchanged) ? this.age : age as int?,
    sex: identical(sex, _unchanged) ? this.sex : sex as String?,
    heightCm: identical(heightCm, _unchanged)
        ? this.heightCm
        : heightCm as double?,
    currentWeightKg: identical(currentWeightKg, _unchanged)
        ? this.currentWeightKg
        : currentWeightKg as double?,
    targetWeightKg: identical(targetWeightKg, _unchanged)
        ? this.targetWeightKg
        : targetWeightKg as double?,
    startingWeightKg: identical(startingWeightKg, _unchanged)
        ? this.startingWeightKg
        : startingWeightKg as double?,
    goalDirection: identical(goalDirection, _unchanged)
        ? this.goalDirection
        : goalDirection as String?,
    weightUpdatedAt: identical(weightUpdatedAt, _unchanged)
        ? this.weightUpdatedAt
        : weightUpdatedAt as DateTime?,
    weightUnit: weightUnit ?? this.weightUnit,
    heightUnit: heightUnit ?? this.heightUnit,
    preferredSplit: preferredSplit ?? this.preferredSplit,
    experienceLevel: experienceLevel ?? this.experienceLevel,
    trainingDaysPerWeek: identical(trainingDaysPerWeek, _unchanged)
        ? this.trainingDaysPerWeek
        : trainingDaysPerWeek as int?,
    equipment: equipment ?? this.equipment,
    injuries: injuries ?? this.injuries,
    primaryGoal: primaryGoal ?? this.primaryGoal,
    defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
    barbellTareKg: barbellTareKg ?? this.barbellTareKg,
    cycleTrackingEnabled: cycleTrackingEnabled ?? this.cycleTrackingEnabled,
    audioCuesEnabled: audioCuesEnabled ?? this.audioCuesEnabled,
    hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    totalWorkouts: totalWorkouts ?? this.totalWorkouts,
    totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
  );

  Map<String, dynamic> toJson() => {
    'schema_version': 2,
    'id': id,
    'display_name': displayName,
    'email': email,
    'avatar_url': avatarUrl,
    'member_since': memberSince.toIso8601String(),
    'age': age,
    'sex': sex,
    'height_cm': heightCm,
    'current_weight_kg': currentWeightKg,
    'target_weight_kg': targetWeightKg,
    'starting_weight_kg': startingWeightKg,
    'goal_direction': goalDirection,
    'weight_updated_at': weightUpdatedAt?.toIso8601String(),
    'weight_unit': weightUnit,
    'height_unit': heightUnit,
    'preferred_split': preferredSplit,
    'experience_level': experienceLevel,
    'training_days_per_week': trainingDaysPerWeek,
    'equipment': equipment,
    'injuries': injuries,
    'primary_goal': primaryGoal,
    'default_rest_seconds': defaultRestSeconds,
    'barbell_tare_kg': barbellTareKg,
    'cycle_tracking_enabled': cycleTrackingEnabled,
    'audio_cues_enabled': audioCuesEnabled,
    'haptic_feedback_enabled': hapticFeedbackEnabled,
    'total_workouts': totalWorkouts,
    'total_volume_kg': totalVolumeKg,
  };

  factory AccountProfile.fromJson(Map<String, dynamic> json) => AccountProfile(
    id: (json['id'] as String?) ?? 'guest_user',
    displayName: (json['display_name'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    avatarUrl: json['avatar_url'] as String?,
    memberSince:
        DateTime.tryParse(json['member_since'] as String? ?? '') ??
        DateTime.now(),
    age: (json['age'] as num?)?.toInt(),
    sex: json['sex'] as String?,
    heightCm: (json['height_cm'] as num?)?.toDouble(),
    currentWeightKg: (json['current_weight_kg'] as num?)?.toDouble(),
    targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
    startingWeightKg: (json['starting_weight_kg'] as num?)?.toDouble(),
    goalDirection: json['goal_direction'] as String?,
    weightUpdatedAt: DateTime.tryParse(
      json['weight_updated_at'] as String? ?? '',
    ),
    weightUnit: (json['weight_unit'] as String?) ?? 'kg',
    heightUnit: (json['height_unit'] as String?) ?? 'cm',
    preferredSplit: (json['preferred_split'] as String?) ?? 'split_ppl',
    experienceLevel: (json['experience_level'] as String?) ?? 'Not set',
    trainingDaysPerWeek: (json['training_days_per_week'] as num?)?.toInt(),
    equipment: (json['equipment'] as List? ?? []).cast<String>(),
    injuries: (json['injuries'] as List? ?? []).cast<String>(),
    primaryGoal: (json['primary_goal'] as String?) ?? 'BUILD MUSCLE',
    defaultRestSeconds: (json['default_rest_seconds'] as num?)?.toInt() ?? 90,
    barbellTareKg: (json['barbell_tare_kg'] as num?)?.toDouble() ?? 20,
    cycleTrackingEnabled: (json['cycle_tracking_enabled'] as bool?) ?? false,
    audioCuesEnabled: (json['audio_cues_enabled'] as bool?) ?? true,
    hapticFeedbackEnabled: (json['haptic_feedback_enabled'] as bool?) ?? true,
    totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
    totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble() ?? 0,
  );

  factory AccountProfile.fromUser(UserModel user) => AccountProfile(
    id: user.id,
    displayName: user.displayName,
    email: user.email,
    avatarUrl: user.avatarUrl,
    memberSince: user.createdAt ?? DateTime.now(),
    age: user.age,
    sex: user.sex,
    heightCm: user.heightCm,
    currentWeightKg: user.currentWeight,
    targetWeightKg: user.targetWeight,
    startingWeightKg: user.startingWeightKg,
    goalDirection: user.goalDirection,
    weightUpdatedAt: user.weightUpdatedAt,
    weightUnit: user.weightUnit,
    heightUnit: user.heightUnit,
    preferredSplit: user.preferredSplit ?? 'split_ppl',
    experienceLevel: user.experienceLevel ?? 'Not set',
    trainingDaysPerWeek: user.trainingDaysPerWeek,
    equipment: user.equipment,
    injuries: user.injuries,
    primaryGoal: user.primaryGoal,
    defaultRestSeconds: user.defaultRestSeconds,
    barbellTareKg: user.barbellTareKg,
    cycleTrackingEnabled: user.cyclesEnabled,
    audioCuesEnabled: user.audioCuesEnabled,
    hapticFeedbackEnabled: user.hapticFeedbackEnabled,
    totalWorkouts: user.totalWorkouts,
    totalVolumeKg: user.totalVolumeKg.toDouble(),
  );
}
