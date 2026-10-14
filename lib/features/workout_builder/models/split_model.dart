import 'package:flutter/foundation.dart';
import '../../workout_session/models/active_session_state.dart';

/// Status indicating volume sufficiency for hypertrophy/recovery.
enum MuscleVolumeStatus {
  lacking,
  optimal,
  high,
}

/// A planned exercise within a routine or split workout day.
@immutable
class PlannedExercise {
  const PlannedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    this.equipment = 'barbell',
    this.targetSets = 3,
    this.repRange = '8–12',
    this.targetRir = 2.0,
    this.targetWeightKg = 60.0,
    this.restSeconds = 90,
  });

  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final String equipment;
  final int targetSets;
  final String repRange;
  final double targetRir;
  final double targetWeightKg;
  final int restSeconds;

  /// Converts this planned exercise into active session state with pre-populated sets.
  ActiveExerciseState toActiveExerciseState() {
    final sets = List.generate(
      targetSets,
      (index) => ActiveSetState(
        setNumber: index + 1,
        weightKg: targetWeightKg,
        reps: int.tryParse(repRange.split('–').first.trim()) ?? 10,
        rir: targetRir,
        rpe: 10.0 - targetRir,
        previousWeightKg: targetWeightKg,
        previousReps: int.tryParse(repRange.split('–').first.trim()) ?? 10,
      ),
    );

    return ActiveExerciseState(
      exerciseId: exerciseId,
      name: exerciseName,
      muscleGroup: muscleGroup,
      equipment: equipment,
      sets: sets,
      restDurationSeconds: restSeconds,
    );
  }

  PlannedExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    String? muscleGroup,
    String? equipment,
    int? targetSets,
    String? repRange,
    double? targetRir,
    double? targetWeightKg,
    int? restSeconds,
  }) {
    return PlannedExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      targetSets: targetSets ?? this.targetSets,
      repRange: repRange ?? this.repRange,
      targetRir: targetRir ?? this.targetRir,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'targetSets': targetSets,
      'repRange': repRange,
      'targetRir': targetRir,
      'targetWeightKg': targetWeightKg,
      'restSeconds': restSeconds,
    };
  }

  factory PlannedExercise.fromJson(Map<String, dynamic> json) {
    return PlannedExercise(
      exerciseId: json['exerciseId'] as String? ?? '',
      exerciseName: json['exerciseName'] as String? ?? 'Exercise',
      muscleGroup: json['muscleGroup'] as String? ?? 'General',
      equipment: json['equipment'] as String? ?? 'barbell',
      targetSets: (json['targetSets'] as num?)?.toInt() ?? 3,
      repRange: json['repRange'] as String? ?? '8–12',
      targetRir: (json['targetRir'] as num?)?.toDouble() ?? 2.0,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 60.0,
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 90,
    );
  }
}

/// A single training session/day within a training split.
@immutable
class SplitWorkoutDay {
  const SplitWorkoutDay({
    required this.id,
    required this.name,
    this.subtitle = '',
    required this.targetMuscles,
    this.isRestDay = false,
    this.exercises = const [],
    this.estimatedDurationMinutes = 50,
  });

  final String id;
  final String name;
  final String subtitle;
  final List<String> targetMuscles;
  final bool isRestDay;
  final List<PlannedExercise> exercises;
  final int estimatedDurationMinutes;

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.targetSets);

  SplitWorkoutDay copyWith({
    String? id,
    String? name,
    String? subtitle,
    List<String>? targetMuscles,
    bool? isRestDay,
    List<PlannedExercise>? exercises,
    int? estimatedDurationMinutes,
  }) {
    return SplitWorkoutDay(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      isRestDay: isRestDay ?? this.isRestDay,
      exercises: exercises ?? this.exercises,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtitle': subtitle,
      'targetMuscles': targetMuscles,
      'isRestDay': isRestDay,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
    };
  }

  factory SplitWorkoutDay.fromJson(Map<String, dynamic> json) {
    return SplitWorkoutDay(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      targetMuscles: (json['targetMuscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isRestDay: json['isRestDay'] as bool? ?? false,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => PlannedExercise.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      estimatedDurationMinutes:
          (json['estimatedDurationMinutes'] as num?)?.toInt() ?? 50,
    );
  }
}

/// Comprehensive model for a Training Split (e.g. PPL, Upper/Lower, Bro Split).
@immutable
class TrainingSplitModel {
  const TrainingSplitModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.daysPerWeek,
    required this.description,
    this.isCustom = false,
    required this.workouts,
    required this.plannedMuscleSets,
  });

  final String id;
  final String name;
  final String shortName;
  final int daysPerWeek;
  final String description;
  final bool isCustom;
  final List<SplitWorkoutDay> workouts;

  /// Target weekly sets mapped by muscle group (Chest, Back, Shoulders, Quads, Hamstrings, Arms).
  final Map<String, int> plannedMuscleSets;

  int get totalWorkouts => workouts.where((w) => !w.isRestDay).length;

  int get totalWeeklySets =>
      workouts.fold(0, (sum, w) => sum + w.totalSets);

  TrainingSplitModel copyWith({
    String? id,
    String? name,
    String? shortName,
    int? daysPerWeek,
    String? description,
    bool? isCustom,
    List<SplitWorkoutDay>? workouts,
    Map<String, int>? plannedMuscleSets,
  }) {
    return TrainingSplitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      workouts: workouts ?? this.workouts,
      plannedMuscleSets: plannedMuscleSets ?? this.plannedMuscleSets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'daysPerWeek': daysPerWeek,
      'description': description,
      'isCustom': isCustom,
      'workouts': workouts.map((w) => w.toJson()).toList(),
      'plannedMuscleSets': plannedMuscleSets,
    };
  }

  factory TrainingSplitModel.fromJson(Map<String, dynamic> json) {
    return TrainingSplitModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      shortName: json['shortName'] as String? ?? '',
      daysPerWeek: (json['daysPerWeek'] as num?)?.toInt() ?? 4,
      description: json['description'] as String? ?? '',
      isCustom: json['isCustom'] as bool? ?? true,
      workouts: (json['workouts'] as List<dynamic>?)
              ?.map((w) => SplitWorkoutDay.fromJson(Map<String, dynamic>.from(w as Map)))
              .toList() ??
          const [],
      plannedMuscleSets: (json['plannedMuscleSets'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          const {},
    );
  }
}
