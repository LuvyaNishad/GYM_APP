import 'package:flutter/foundation.dart';

/// Helper converting Reps In Reserve (RIR 0–4) to Rate of Perceived Exertion (RPE 6–10).
double rpeFromRir(double rir) {
  final rpe = 10.0 - rir;
  return rpe.clamp(6.0, 10.0);
}

/// Helper converting Rate of Perceived Exertion (RPE 6–10) to Reps In Reserve (RIR 0–4).
double rirFromRpe(double rpe) {
  final rir = 10.0 - rpe;
  return rir.clamp(0.0, 4.0);
}

/// A single set in an active workout session.
@immutable
class ActiveSetState {
  const ActiveSetState({
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    this.rir = 2.0,
    this.rpe = 8.0,
    this.isCompleted = false,
    this.isWarmup = false,
    this.isPr = false,
    this.previousWeightKg,
    this.previousReps,
    this.previousRir,
    this.previousRpe,
  });

  final int setNumber;
  final double weightKg;
  final int reps;
  final double rir;
  final double rpe;
  final bool isCompleted;
  final bool isWarmup;
  final bool isPr;

  /// Ghost reference values from previous logged workout.
  final double? previousWeightKg;
  final int? previousReps;
  final double? previousRir;
  final double? previousRpe;

  /// Set volume in kilograms (weight × reps). Warm-up sets do not count toward working volume.
  double get volumeKg => isWarmup ? 0.0 : (weightKg * reps);

  ActiveSetState copyWith({
    int? setNumber,
    double? weightKg,
    int? reps,
    double? rir,
    double? rpe,
    bool? isCompleted,
    bool? isWarmup,
    bool? isPr,
    double? previousWeightKg,
    int? previousReps,
    double? previousRir,
    double? previousRpe,
  }) {
    return ActiveSetState(
      setNumber: setNumber ?? this.setNumber,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      rpe: rpe ?? this.rpe,
      isCompleted: isCompleted ?? this.isCompleted,
      isWarmup: isWarmup ?? this.isWarmup,
      isPr: isPr ?? this.isPr,
      previousWeightKg: previousWeightKg ?? this.previousWeightKg,
      previousReps: previousReps ?? this.previousReps,
      previousRir: previousRir ?? this.previousRir,
      previousRpe: previousRpe ?? this.previousRpe,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveSetState &&
          runtimeType == other.runtimeType &&
          setNumber == other.setNumber &&
          weightKg == other.weightKg &&
          reps == other.reps &&
          rir == other.rir &&
          rpe == other.rpe &&
          isCompleted == other.isCompleted &&
          isWarmup == other.isWarmup &&
          isPr == other.isPr;

  @override
  int get hashCode => Object.hash(
        setNumber,
        weightKg,
        reps,
        rir,
        rpe,
        isCompleted,
        isWarmup,
        isPr,
      );
}

/// An exercise in the active workout sequence.
@immutable
class ActiveExerciseState {
  const ActiveExerciseState({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    this.equipment = 'barbell',
    required this.sets,
    this.notes,
    this.supersetGroupId,
    this.restDurationSeconds = 90,
  });

  final String exerciseId;
  final String name;
  final String muscleGroup;
  final String equipment;
  final List<ActiveSetState> sets;
  final String? notes;
  final String? supersetGroupId;
  final int restDurationSeconds;

  int get completedSetsCount =>
      sets.where((s) => s.isCompleted).length;

  int get totalSetsCount => sets.length;

  bool get isFullyCompleted =>
      sets.isNotEmpty && sets.every((s) => s.isCompleted);

  ActiveSetState? get topCompletedSet {
    final completed = sets.where((s) => s.isCompleted).toList();
    if (completed.isEmpty) return null;
    completed.sort((a, b) => b.weightKg.compareTo(a.weightKg));
    return completed.first;
  }

  double get totalVolumeKg =>
      sets.where((s) => s.isCompleted).fold(0.0, (acc, s) => acc + s.volumeKg);

  ActiveExerciseState copyWith({
    String? exerciseId,
    String? name,
    String? muscleGroup,
    String? equipment,
    List<ActiveSetState>? sets,
    String? notes,
    String? supersetGroupId,
    int? restDurationSeconds,
  }) {
    return ActiveExerciseState(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      supersetGroupId: supersetGroupId ?? this.supersetGroupId,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveExerciseState &&
          runtimeType == other.runtimeType &&
          exerciseId == other.exerciseId &&
          name == other.name &&
          muscleGroup == other.muscleGroup &&
          listEquals(sets, other.sets);

  @override
  int get hashCode => Object.hash(
        exerciseId,
        name,
        muscleGroup,
        sets,
      );
}

/// Full state of an in-progress workout session.
@immutable
class ActiveSessionState {
  const ActiveSessionState({
    this.workoutId = '',
    this.splitName = "TODAY'S WORKOUT",
    required this.startTime,
    this.elapsedSeconds = 0,
    this.isActive = false,
    this.isPaused = false,
    this.exercises = const [],
    this.expandedExerciseId,
  });

  final String workoutId;
  final String splitName;
  final DateTime startTime;
  final int elapsedSeconds;
  final bool isActive;
  final bool isPaused;
  final List<ActiveExerciseState> exercises;
  final String? expandedExerciseId;

  int get completedSetCount =>
      exercises.fold(0, (acc, ex) => acc + ex.completedSetsCount);

  int get totalSetCount =>
      exercises.fold(0, (acc, ex) => acc + ex.totalSetsCount);

  double get completionRatio =>
      totalSetCount == 0 ? 0.0 : (completedSetCount / totalSetCount);

  double get totalVolumeKg =>
      exercises.fold(0.0, (acc, ex) => acc + ex.totalVolumeKg);

  String get formattedElapsed {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  ActiveSessionState copyWith({
    String? workoutId,
    String? splitName,
    DateTime? startTime,
    int? elapsedSeconds,
    bool? isActive,
    bool? isPaused,
    List<ActiveExerciseState>? exercises,
    String? expandedExerciseId,
    bool clearExpandedExercise = false,
  }) {
    return ActiveSessionState(
      workoutId: workoutId ?? this.workoutId,
      splitName: splitName ?? this.splitName,
      startTime: startTime ?? this.startTime,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      exercises: exercises ?? this.exercises,
      expandedExerciseId: clearExpandedExercise
          ? null
          : (expandedExerciseId ?? this.expandedExerciseId),
    );
  }
}

/// State for the floating countdown rest timer.
@immutable
class RestTimerState {
  const RestTimerState({
    this.totalDurationSeconds = 90,
    this.remainingSeconds = 0,
    this.isRunning = false,
    this.autoStart = true,
    this.exerciseName,
    this.setNumber,
  });

  final int totalDurationSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool autoStart;
  final String? exerciseName;
  final int? setNumber;

  bool get isFinished => remainingSeconds == 0 && isRunning;

  double get progressRatio {
    if (totalDurationSeconds <= 0) return 0.0;
    return (remainingSeconds / totalDurationSeconds).clamp(0.0, 1.0);
  }

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  RestTimerState copyWith({
    int? totalDurationSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? autoStart,
    String? exerciseName,
    int? setNumber,
  }) {
    return RestTimerState(
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      autoStart: autoStart ?? this.autoStart,
      exerciseName: exerciseName ?? this.exerciseName,
      setNumber: setNumber ?? this.setNumber,
    );
  }
}
