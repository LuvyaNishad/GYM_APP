/// A point-in-time snapshot of a user's health metrics.
///
/// All fields are nullable — a missing value means the data source
/// did not return that metric for this recording period.
class HealthSnapshot {
  const HealthSnapshot({
    required this.recordedAt,
    this.steps,
    this.heartRateBpm,
    this.sleepHours,
    this.activeCalories,
  });

  /// When this snapshot was recorded / last synced.
  final DateTime recordedAt;

  /// Total step count for the current day.
  final int? steps;

  /// Most recent resting/active heart rate in BPM.
  final int? heartRateBpm;

  /// Hours of sleep for the most recent sleep session.
  final double? sleepHours;

  /// Active (exercise) calories burned today.
  final int? activeCalories;

  /// Returns an empty snapshot timestamped to [now].
  factory HealthSnapshot.empty() => HealthSnapshot(recordedAt: DateTime.now());

  HealthSnapshot copyWith({
    DateTime? recordedAt,
    int? steps,
    int? heartRateBpm,
    double? sleepHours,
    int? activeCalories,
  }) =>
      HealthSnapshot(
        recordedAt: recordedAt ?? this.recordedAt,
        steps: steps ?? this.steps,
        heartRateBpm: heartRateBpm ?? this.heartRateBpm,
        sleepHours: sleepHours ?? this.sleepHours,
        activeCalories: activeCalories ?? this.activeCalories,
      );

  Map<String, dynamic> toJson() => {
        'recorded_at': recordedAt.toIso8601String(),
        'steps': steps,
        'heart_rate_bpm': heartRateBpm,
        'sleep_hours': sleepHours,
        'active_calories': activeCalories,
      };

  factory HealthSnapshot.fromJson(Map<String, dynamic> json) => HealthSnapshot(
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        steps: json['steps'] as int?,
        heartRateBpm: json['heart_rate_bpm'] as int?,
        sleepHours: (json['sleep_hours'] as num?)?.toDouble(),
        activeCalories: json['active_calories'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSnapshot &&
          runtimeType == other.runtimeType &&
          recordedAt == other.recordedAt &&
          steps == other.steps &&
          heartRateBpm == other.heartRateBpm &&
          sleepHours == other.sleepHours &&
          activeCalories == other.activeCalories;

  @override
  int get hashCode =>
      Object.hash(recordedAt, steps, heartRateBpm, sleepHours, activeCalories);
}
