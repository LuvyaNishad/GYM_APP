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

/// The classification type for an individual exercise set.
enum ActiveSetType {
  /// Standard progressive working set (counts toward working volume).
  normal,

  /// Warm-up ramp set (reduced load, excluded from working volume).
  warmup,

  /// Drop set performed immediately following another set at a reduced load.
  dropSet,

  /// Maximal effort set taken to muscular failure (0 RIR / 10 RPE).
  failure,
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
    this.effortLogged = false,
    this.isCompleted = false,
    bool isWarmup = false,
    ActiveSetType? setType,
    this.isPr = false,
    this.previousWeightKg,
    this.previousReps,
    this.previousRir,
    this.previousRpe,
    this.weightKgRight,
    this.repsRight,
    this.isLeftCompleted = false,
    this.isRightCompleted = false,
    this.previousWeightKgRight,
    this.previousRepsRight,
  }) : setType =
           setType ?? (isWarmup ? ActiveSetType.warmup : ActiveSetType.normal);

  final int setNumber;
  final double weightKg;
  final int reps;
  final double rir;
  final double rpe;

  /// Picker defaults are suggestions until the lifter explicitly saves effort.
  final bool effortLogged;
  final bool isCompleted;
  final ActiveSetType setType;
  final bool isPr;

  /// Unilateral properties for independent Left/Right logging
  final double? weightKgRight;
  final int? repsRight;
  final bool isLeftCompleted;
  final bool isRightCompleted;

  /// Whether this set is categorized as a warm-up ramp set.
  bool get isWarmup => setType == ActiveSetType.warmup;

  /// Whether this set is categorized as a drop set.
  bool get isDropSet => setType == ActiveSetType.dropSet;

  /// Whether this set is taken to muscular failure.
  bool get isFailure => setType == ActiveSetType.failure;

  /// Ghost reference values from previous logged workout.
  final double? previousWeightKg;
  final int? previousReps;
  final double? previousRir;
  final double? previousRpe;
  final double? previousWeightKgRight;
  final int? previousRepsRight;

  /// Set volume in kilograms. Warm-up sets do not count toward working volume.
  /// If unilateral (right values specified), calculates both sides: (W_L * R_L) + (W_R * R_R).
  double get volumeKg {
    if (isWarmup) return 0.0;
    final leftVol = weightKg * reps;
    if (weightKgRight != null || repsRight != null) {
      final rightWeight = weightKgRight ?? weightKg;
      final rightReps = repsRight ?? reps;
      return leftVol + (rightWeight * rightReps);
    }
    return leftVol;
  }

  ActiveSetState copyWith({
    int? setNumber,
    double? weightKg,
    int? reps,
    double? rir,
    double? rpe,
    bool? effortLogged,
    bool? isCompleted,
    bool? isWarmup,
    ActiveSetType? setType,
    bool? isPr,
    double? previousWeightKg,
    int? previousReps,
    double? previousRir,
    double? previousRpe,
    double? weightKgRight,
    int? repsRight,
    bool? isLeftCompleted,
    bool? isRightCompleted,
    double? previousWeightKgRight,
    int? previousRepsRight,
    bool clearRightSide = false,
  }) {
    ActiveSetType resolvedType = setType ?? this.setType;
    if (isWarmup != null) {
      resolvedType = isWarmup
          ? ActiveSetType.warmup
          : (resolvedType == ActiveSetType.warmup
                ? ActiveSetType.normal
                : resolvedType);
    }
    return ActiveSetState(
      setNumber: setNumber ?? this.setNumber,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      rpe: rpe ?? this.rpe,
      effortLogged: effortLogged ?? this.effortLogged,
      isCompleted: isCompleted ?? this.isCompleted,
      setType: resolvedType,
      isPr: isPr ?? this.isPr,
      previousWeightKg: previousWeightKg ?? this.previousWeightKg,
      previousReps: previousReps ?? this.previousReps,
      previousRir: previousRir ?? this.previousRir,
      previousRpe: previousRpe ?? this.previousRpe,
      weightKgRight: clearRightSide
          ? null
          : weightKgRight ?? this.weightKgRight,
      repsRight: clearRightSide ? null : repsRight ?? this.repsRight,
      isLeftCompleted: isLeftCompleted ?? this.isLeftCompleted,
      isRightCompleted: isRightCompleted ?? this.isRightCompleted,
      previousWeightKgRight:
          previousWeightKgRight ?? this.previousWeightKgRight,
      previousRepsRight: previousRepsRight ?? this.previousRepsRight,
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
          effortLogged == other.effortLogged &&
          isCompleted == other.isCompleted &&
          setType == other.setType &&
          isPr == other.isPr &&
          weightKgRight == other.weightKgRight &&
          repsRight == other.repsRight &&
          isLeftCompleted == other.isLeftCompleted &&
          isRightCompleted == other.isRightCompleted &&
          previousWeightKg == other.previousWeightKg &&
          previousReps == other.previousReps &&
          previousRir == other.previousRir &&
          previousRpe == other.previousRpe &&
          previousWeightKgRight == other.previousWeightKgRight &&
          previousRepsRight == other.previousRepsRight;

  @override
  int get hashCode => Object.hash(
    setNumber,
    weightKg,
    reps,
    rir,
    rpe,
    effortLogged,
    isCompleted,
    setType,
    isPr,
    weightKgRight,
    repsRight,
    isLeftCompleted,
    isRightCompleted,
    previousWeightKg,
    previousReps,
    previousRir,
    previousRpe,
    previousWeightKgRight,
    previousRepsRight,
  );

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'weightKg': weightKg,
    'reps': reps,
    'rir': rir,
    'rpe': rpe,
    'effortLogged': effortLogged,
    'isCompleted': isCompleted,
    'isWarmup': isWarmup,
    'setType': setType.name,
    'isPr': isPr,
    'previousWeightKg': previousWeightKg,
    'previousReps': previousReps,
    'previousRir': previousRir,
    'previousRpe': previousRpe,
    'weightKgRight': weightKgRight,
    'repsRight': repsRight,
    'isLeftCompleted': isLeftCompleted,
    'isRightCompleted': isRightCompleted,
    'previousWeightKgRight': previousWeightKgRight,
    'previousRepsRight': previousRepsRight,
  };

  factory ActiveSetState.fromJson(Map<String, dynamic> json) {
    ActiveSetType parsedType = ActiveSetType.normal;
    if (json['setType'] != null) {
      parsedType = ActiveSetType.values.firstWhere(
        (e) => e.name == json['setType'],
        orElse: () => ActiveSetType.normal,
      );
    } else if (json['isWarmup'] as bool? ?? false) {
      parsedType = ActiveSetType.warmup;
    }

    final bool legacyCompleted = json['isCompleted'] as bool? ?? false;

    return ActiveSetState(
      setNumber: json['setNumber'] as int? ?? 1,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      reps: json['reps'] as int? ?? 0,
      rir: (json['rir'] as num?)?.toDouble() ?? 2.0,
      rpe: (json['rpe'] as num?)?.toDouble() ?? 8.0,
      // Old drafts did not distinguish suggested effort from measured effort.
      effortLogged: json['effortLogged'] as bool? ?? false,
      isCompleted: legacyCompleted,
      setType: parsedType,
      isPr: json['isPr'] as bool? ?? false,
      previousWeightKg: (json['previousWeightKg'] as num?)?.toDouble(),
      previousReps: json['previousReps'] as int?,
      previousRir: (json['previousRir'] as num?)?.toDouble(),
      previousRpe: (json['previousRpe'] as num?)?.toDouble(),
      weightKgRight: (json['weightKgRight'] as num?)?.toDouble(),
      repsRight: json['repsRight'] as int?,
      isLeftCompleted: json['isLeftCompleted'] as bool? ?? legacyCompleted,
      isRightCompleted: json['isRightCompleted'] as bool? ?? legacyCompleted,
      previousWeightKgRight: (json['previousWeightKgRight'] as num?)
          ?.toDouble(),
      previousRepsRight: json['previousRepsRight'] as int?,
    );
  }
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
    this.isUnilateral = false,
  });

  final String exerciseId;
  final String name;
  final String muscleGroup;
  final String equipment;
  final List<ActiveSetState> sets;
  final String? notes;
  final String? supersetGroupId;
  final int restDurationSeconds;
  final bool isUnilateral;

  int get completedSetsCount => sets.where((s) => s.isCompleted).length;

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
    bool clearSupersetGroup = false,
    int? restDurationSeconds,
    bool? isUnilateral,
  }) {
    return ActiveExerciseState(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      supersetGroupId: clearSupersetGroup
          ? null
          : (supersetGroupId ?? this.supersetGroupId),
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
      isUnilateral: isUnilateral ?? this.isUnilateral,
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
          equipment == other.equipment &&
          notes == other.notes &&
          supersetGroupId == other.supersetGroupId &&
          restDurationSeconds == other.restDurationSeconds &&
          isUnilateral == other.isUnilateral &&
          listEquals(sets, other.sets);

  @override
  int get hashCode => Object.hash(
    exerciseId,
    name,
    muscleGroup,
    equipment,
    notes,
    supersetGroupId,
    restDurationSeconds,
    isUnilateral,
    Object.hashAll(sets),
  );

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'muscleGroup': muscleGroup,
    'equipment': equipment,
    'sets': sets.map((s) => s.toJson()).toList(),
    'notes': notes,
    'supersetGroupId': supersetGroupId,
    'restDurationSeconds': restDurationSeconds,
    'isUnilateral': isUnilateral,
  };

  factory ActiveExerciseState.fromJson(Map<String, dynamic> json) =>
      ActiveExerciseState(
        exerciseId: json['exerciseId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        muscleGroup: json['muscleGroup'] as String? ?? 'push',
        equipment: json['equipment'] as String? ?? 'barbell',
        sets:
            (json['sets'] as List<dynamic>?)
                ?.map(
                  (s) => ActiveSetState.fromJson(
                    Map<String, dynamic>.from(s as Map),
                  ),
                )
                .toList() ??
            const [],
        notes: json['notes'] as String?,
        supersetGroupId: json['supersetGroupId'] as String?,
        restDurationSeconds: json['restDurationSeconds'] as int? ?? 90,
        isUnilateral: json['isUnilateral'] as bool? ?? false,
      );
}

/// A real unfinished set, shared by rest and background workout notifications.
@immutable
class WorkoutSetTarget {
  const WorkoutSetTarget({required this.exercise, required this.set});

  final ActiveExerciseState exercise;
  final ActiveSetState set;

  String get setLabel =>
      set.isWarmup ? 'Warm-up ${set.setNumber}' : 'Set ${set.setNumber}';
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
    this.lastResumedAt,
    this.persistenceError,
  });

  final String workoutId;
  final String splitName;
  final DateTime startTime;
  final int elapsedSeconds;
  final bool isActive;
  final bool isPaused;
  final List<ActiveExerciseState> exercises;
  final String? expandedExerciseId;
  final DateTime? lastResumedAt;
  final String? persistenceError;

  /// Continue the selected exercise, then scan forward and wrap for skipped sets.
  WorkoutSetTarget? nextPendingSet({String? preferredExerciseId}) {
    if (!isActive || exercises.isEmpty) return null;
    final preferredIndex = exercises.indexWhere(
      (exercise) => exercise.exerciseId == preferredExerciseId,
    );
    final start = preferredIndex < 0 ? 0 : preferredIndex;
    for (var offset = 0; offset < exercises.length; offset++) {
      final exercise = exercises[(start + offset) % exercises.length];
      final set = exercise.sets.where((set) => !set.isCompleted).firstOrNull;
      if (set != null) return WorkoutSetTarget(exercise: exercise, set: set);
    }
    return null;
  }

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
    DateTime? lastResumedAt,
    bool clearLastResumedAt = false,
    String? persistenceError,
    bool clearPersistenceError = false,
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
      lastResumedAt: clearLastResumedAt
          ? null
          : (lastResumedAt ?? this.lastResumedAt),
      persistenceError: clearPersistenceError
          ? null
          : persistenceError ?? this.persistenceError,
    );
  }

  Map<String, dynamic> toJson() => {
    'workoutId': workoutId,
    'splitName': splitName,
    'startTime': startTime.toIso8601String(),
    'elapsedSeconds': elapsedSeconds,
    'isActive': isActive,
    'isPaused': isPaused,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'expandedExerciseId': expandedExerciseId,
    'lastResumedAt': lastResumedAt?.toIso8601String(),
  };

  factory ActiveSessionState.fromJson(Map<String, dynamic> json) =>
      ActiveSessionState(
        workoutId: json['workoutId'] as String? ?? '',
        splitName: json['splitName'] as String? ?? "TODAY'S WORKOUT",
        startTime:
            DateTime.tryParse(json['startTime'] as String? ?? '') ??
            DateTime.now(),
        elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? false,
        isPaused: json['isPaused'] as bool? ?? false,
        exercises:
            (json['exercises'] as List<dynamic>?)
                ?.map(
                  (e) => ActiveExerciseState.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList() ??
            const [],
        expandedExerciseId: json['expandedExerciseId'] as String?,
        lastResumedAt: json['lastResumedAt'] != null
            ? DateTime.tryParse(json['lastResumedAt'] as String)
            : null,
      );
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
    this.totalSets = 0,
    this.isWarmup = false,
    this.exerciseId,
    this.sourceExerciseId,
    this.targetEndTime,
  });

  final int totalDurationSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool autoStart;
  final String? exerciseName;
  final int? setNumber;
  final int totalSets;
  final bool isWarmup;
  final String? exerciseId;
  final String? sourceExerciseId;
  final DateTime? targetEndTime;

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
    int? totalSets,
    bool? isWarmup,
    String? exerciseId,
    String? sourceExerciseId,
    DateTime? targetEndTime,
    bool clearTargetEndTime = false,
  }) {
    return RestTimerState(
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      autoStart: autoStart ?? this.autoStart,
      exerciseName: exerciseName ?? this.exerciseName,
      setNumber: setNumber ?? this.setNumber,
      totalSets: totalSets ?? this.totalSets,
      isWarmup: isWarmup ?? this.isWarmup,
      exerciseId: exerciseId ?? this.exerciseId,
      sourceExerciseId: sourceExerciseId ?? this.sourceExerciseId,
      targetEndTime: clearTargetEndTime
          ? null
          : (targetEndTime ?? this.targetEndTime),
    );
  }
}
