/// Progress tracking model.
///
/// Plain Dart class — no code generation required.
class ProgressModel {
  const ProgressModel({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.date,
    required this.weightKg,
    required this.reps,
    this.estimatedOnerm = 0.0,
    this.totalVolumeKg = 0.0,
  });

  final String id;
  final String userId;
  final String exerciseId;
  final DateTime date;
  final double weightKg;
  final int reps;

  /// Estimated 1RM via Epley formula: weight × (1 + reps/30).
  final double estimatedOnerm;
  final double totalVolumeKg;

  factory ProgressModel.fromJson(Map<String, dynamic> json) => ProgressModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        exerciseId: json['exercise_id'] as String,
        date: DateTime.parse(json['date'] as String),
        weightKg: (json['weight_kg'] as num).toDouble(),
        reps: json['reps'] as int,
        estimatedOnerm: (json['estimated_onerm'] as num?)?.toDouble() ?? 0.0,
        totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'exercise_id': exerciseId,
        'date': date.toIso8601String(),
        'weight_kg': weightKg,
        'reps': reps,
        'estimated_onerm': estimatedOnerm,
        'total_volume_kg': totalVolumeKg,
      };
}

/// Aggregate weekly muscle-group volume for the radar chart.
class RadarSnapshot {
  const RadarSnapshot({
    required this.weekStart,
    this.pushVolume = 0.0,
    this.pullVolume = 0.0,
    this.legsVolume = 0.0,
    this.coreVolume = 0.0,
  });

  final DateTime weekStart;
  final double pushVolume;
  final double pullVolume;
  final double legsVolume;
  final double coreVolume;

  factory RadarSnapshot.fromJson(Map<String, dynamic> json) => RadarSnapshot(
        weekStart: DateTime.parse(json['week_start'] as String),
        pushVolume: (json['push_volume'] as num?)?.toDouble() ?? 0.0,
        pullVolume: (json['pull_volume'] as num?)?.toDouble() ?? 0.0,
        legsVolume: (json['legs_volume'] as num?)?.toDouble() ?? 0.0,
        coreVolume: (json['core_volume'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'week_start': weekStart.toIso8601String(),
        'push_volume': pushVolume,
        'pull_volume': pullVolume,
        'legs_volume': legsVolume,
        'core_volume': coreVolume,
      };
}
