/// A completed or planned workout entry.
///
/// Plain Dart class — no code generation required.
/// Freezed annotations will be added in the backend phase.
class WorkoutModel {
  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.date,
    this.exercises = const [],
    this.durationSeconds = 0,
    this.notes,
    this.totalVolumeKg,
    this.averageRpe,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime date;
  final List<WorkoutExercise> exercises;
  final int durationSeconds;
  final String? notes;
  final double? totalVolumeKg;
  final double? averageRpe;

  factory WorkoutModel.fromJson(Map<String, dynamic> json) => WorkoutModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        date: DateTime.parse(json['date'] as String),
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map(
                    (e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        durationSeconds: (json['duration_seconds'] as int?) ?? 0,
        notes: json['notes'] as String?,
        totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble(),
        averageRpe: (json['average_rpe'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'date': date.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'duration_seconds': durationSeconds,
        'notes': notes,
        'total_volume_kg': totalVolumeKg,
        'average_rpe': averageRpe,
      };

  WorkoutModel copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? date,
    List<WorkoutExercise>? exercises,
    int? durationSeconds,
    String? notes,
    double? totalVolumeKg,
    double? averageRpe,
  }) =>
      WorkoutModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        date: date ?? this.date,
        exercises: exercises ?? this.exercises,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        notes: notes ?? this.notes,
        totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
        averageRpe: averageRpe ?? this.averageRpe,
      );
}

/// A single exercise performed within a [WorkoutModel].
class WorkoutExercise {
  const WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    this.sets = const [],
  });

  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final List<WorkoutSet> sets;

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        exerciseId: json['exercise_id'] as String,
        exerciseName: json['exercise_name'] as String,
        muscleGroup: json['muscle_group'] as String,
        sets: (json['sets'] as List<dynamic>?)
                ?.map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'muscle_group': muscleGroup,
        'sets': sets.map((s) => s.toJson()).toList(),
      };
}

/// A single set within a [WorkoutExercise].
class WorkoutSet {
  const WorkoutSet({
    required this.reps,
    required this.weightKg,
    this.rpe = 0.0,
    this.isWarmup = false,
    this.isPr = false,
  });

  final int reps;
  final double weightKg;
  final double rpe;
  final bool isWarmup;
  final bool isPr;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        reps: json['reps'] as int,
        weightKg: (json['weight_kg'] as num).toDouble(),
        rpe: (json['rpe'] as num?)?.toDouble() ?? 0.0,
        isWarmup: (json['is_warmup'] as bool?) ?? false,
        isPr: (json['is_pr'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'weight_kg': weightKg,
        'rpe': rpe,
        'is_warmup': isWarmup,
        'is_pr': isPr,
      };
}
