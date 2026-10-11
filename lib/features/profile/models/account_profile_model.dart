/// Account & User Profile Data Model for LEON.
///
/// Encapsulates personal information, physical biometrics, training
/// preferences, goal milestones, and app settings.
library;

class AccountProfile {
  const AccountProfile({
    this.id = 'guest_user',
    this.displayName = 'Leon',
    this.email = 'leon@fitness.os',
    this.avatarUrl,
    required this.memberSince,
    this.heightCm = 180.0,
    this.currentWeightKg = 78.5,
    this.targetWeightKg = 74.0,
    this.weightUnit = 'kg',
    this.heightUnit = 'cm',
    this.preferredSplit = 'Push / Pull / Legs',
    this.experienceLevel = 'Intermediate',
    this.defaultRestSeconds = 90,
    this.barbellTareKg = 20.0,
    this.cycleTrackingEnabled = false,
    this.audioCuesEnabled = true,
    this.hapticFeedbackEnabled = true,
    this.totalWorkouts = 24,
    this.totalVolumeKg = 48600,
  });

  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final DateTime memberSince;

  /// Height in centimeters.
  final double heightCm;

  /// Current weight in kilograms.
  final double currentWeightKg;

  /// Target goal weight in kilograms.
  final double targetWeightKg;

  /// Measurement units ('kg' or 'lbs').
  final String weightUnit;

  /// Height display unit ('cm' or 'ft').
  final String heightUnit;

  /// Selected training split (e.g. 'Push / Pull / Legs').
  final String preferredSplit;

  /// Experience tier ('Beginner', 'Intermediate', 'Advanced').
  final String experienceLevel;

  /// Default rest countdown in seconds (60, 90, 120, 180).
  final int defaultRestSeconds;

  /// Standard Olympic barbell base tare weight (20.0 kg or 15.0 kg).
  final double barbellTareKg;

  /// Menstrual cycle tracking enabled for recovery modulation.
  final bool cycleTrackingEnabled;

  /// Audio beeps on rest countdown and set completion.
  final bool audioCuesEnabled;

  /// Haptic feedback enabled.
  final bool hapticFeedbackEnabled;

  /// All-time sessions logged.
  final int totalWorkouts;

  /// All-time volume lifted in kg.
  final int totalVolumeKg;

  // ── Smart Computed Biometric Helpers ─────────────────────────────────────

  /// Body Mass Index (BMI).
  double get bmi {
    if (heightCm <= 0) return 0.0;
    final heightMeters = heightCm / 100.0;
    return currentWeightKg / (heightMeters * heightMeters);
  }

  /// BMI classification label.
  String get bmiCategory {
    final value = bmi;
    if (value < 18.5) return 'Underweight';
    if (value < 25.0) return 'Normal Weight';
    if (value < 30.0) return 'Overweight';
    return 'Athletic / Muscular';
  }

  /// Remaining weight delta to reach target goal (in kg).
  double get weightDeltaKg => (currentWeightKg - targetWeightKg).abs();

  /// Whether current weight is above target (cutting/fat loss).
  bool get isCutting => currentWeightKg > targetWeightKg;

  /// Goal progress percentage (0.0 to 1.0).
  double get goalProgress {
    // If current weight is already at or past target
    if ((isCutting && currentWeightKg <= targetWeightKg) ||
        (!isCutting && currentWeightKg >= targetWeightKg)) {
      return 1.0;
    }
    // Estimated starting reference point (e.g. 5 kg difference baseline)
    final totalDelta = (weightDeltaKg + 3.0);
    final completed = 3.0;
    return (completed / totalDelta).clamp(0.15, 0.95);
  }

  /// Estimated Basal Metabolic Rate (BMR) via Harris-Benedict formula.
  int get bmrEstimate {
    return (10 * currentWeightKg + 6.25 * heightCm - 5 * 26 + 5).round();
  }

  /// Estimated Daily Maintenance Calories (TDEE for moderately active lifter).
  int get maintenanceCaloriesEstimate => (bmrEstimate * 1.55).round();

  /// Height formatted according to user preference.
  String get formattedHeight {
    if (heightUnit == 'ft') {
      final totalInches = heightCm / 2.54;
      final feet = totalInches ~/ 12;
      final inches = (totalInches % 12).round();
      return "$feet'$inches\"";
    }
    return '${heightCm.toStringAsFixed(0)} cm';
  }

  /// Formatted weight in selected unit.
  String formatWeight(double kg) {
    if (weightUnit == 'lbs') {
      final lbs = kg * 2.20462;
      return '${lbs.toStringAsFixed(1)} lbs';
    }
    return '${kg.toStringAsFixed(1)} kg';
  }

  AccountProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    DateTime? memberSince,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    String? weightUnit,
    String? heightUnit,
    String? preferredSplit,
    String? experienceLevel,
    int? defaultRestSeconds,
    double? barbellTareKg,
    bool? cycleTrackingEnabled,
    bool? audioCuesEnabled,
    bool? hapticFeedbackEnabled,
    int? totalWorkouts,
    int? totalVolumeKg,
  }) {
    return AccountProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberSince: memberSince ?? this.memberSince,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      weightUnit: weightUnit ?? this.weightUnit,
      heightUnit: heightUnit ?? this.heightUnit,
      preferredSplit: preferredSplit ?? this.preferredSplit,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      barbellTareKg: barbellTareKg ?? this.barbellTareKg,
      cycleTrackingEnabled: cycleTrackingEnabled ?? this.cycleTrackingEnabled,
      audioCuesEnabled: audioCuesEnabled ?? this.audioCuesEnabled,
      hapticFeedbackEnabled:
          hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'display_name': displayName,
      'email': email,
      'avatar_url': avatarUrl,
      'member_since': memberSince.toIso8601String(),
      'height_cm': heightCm,
      'current_weight_kg': currentWeightKg,
      'target_weight_kg': targetWeightKg,
      'weight_unit': weightUnit,
      'height_unit': heightUnit,
      'preferred_split': preferredSplit,
      'experience_level': experienceLevel,
      'default_rest_seconds': defaultRestSeconds,
      'barbell_tare_kg': barbellTareKg,
      'cycle_tracking_enabled': cycleTrackingEnabled,
      'audio_cues_enabled': audioCuesEnabled,
      'haptic_feedback_enabled': hapticFeedbackEnabled,
      'total_workouts': totalWorkouts,
      'total_volume_kg': totalVolumeKg,
    };
  }

  factory AccountProfile.fromJson(Map<String, dynamic> json) {
    return AccountProfile(
      id: (json['id'] as String?) ?? 'guest_user',
      displayName: (json['display_name'] as String?) ?? 'Leon',
      email: (json['email'] as String?) ?? 'leon@fitness.os',
      avatarUrl: json['avatar_url'] as String?,
      memberSince: json['member_since'] != null
          ? DateTime.tryParse(json['member_since'] as String) ??
              DateTime(2026, 10, 1)
          : DateTime(2026, 10, 1),
      heightCm: (json['height_cm'] as num?)?.toDouble() ?? 180.0,
      currentWeightKg: (json['current_weight_kg'] as num?)?.toDouble() ?? 78.5,
      targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble() ?? 74.0,
      weightUnit: (json['weight_unit'] as String?) ?? 'kg',
      heightUnit: (json['height_unit'] as String?) ?? 'cm',
      preferredSplit:
          (json['preferred_split'] as String?) ?? 'Push / Pull / Legs',
      experienceLevel: (json['experience_level'] as String?) ?? 'Intermediate',
      defaultRestSeconds: (json['default_rest_seconds'] as int?) ?? 90,
      barbellTareKg: (json['barbell_tare_kg'] as num?)?.toDouble() ?? 20.0,
      cycleTrackingEnabled: (json['cycle_tracking_enabled'] as bool?) ?? false,
      audioCuesEnabled: (json['audio_cues_enabled'] as bool?) ?? true,
      hapticFeedbackEnabled:
          (json['haptic_feedback_enabled'] as bool?) ?? true,
      totalWorkouts: (json['total_workouts'] as int?) ?? 24,
      totalVolumeKg: (json['total_volume_kg'] as int?) ?? 48600,
    );
  }
}
