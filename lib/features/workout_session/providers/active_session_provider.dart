import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/workout_model.dart';
import '../models/active_session_state.dart';
import 'rest_timer_provider.dart';

/// Provider managing the active workout session in progress.
class ActiveSessionNotifier extends Notifier<ActiveSessionState> {
  Timer? _elapsedTicker;

  @override
  ActiveSessionState build() {
    ref.keepAlive();
    ref.onDispose(() {
      _elapsedTicker?.cancel();
    });
    return ActiveSessionState(startTime: DateTime.now());
  }

  /// Starts a new active workout session with planned exercises.
  void startSession({
    String splitName = 'PUSH DAY // WORKOUT A',
    List<ActiveExerciseState>? initialExercises,
  }) {
    _elapsedTicker?.cancel();

    final exercises = initialExercises ?? _buildDefaultPushWorkout();

    state = ActiveSessionState(
      workoutId: 'wkt_${DateTime.now().microsecondsSinceEpoch}',
      splitName: splitName,
      startTime: DateTime.now(),
      elapsedSeconds: 0,
      isActive: true,
      isPaused: false,
      exercises: exercises,
      expandedExerciseId: exercises.isNotEmpty ? exercises.first.exerciseId : null,
    );

    _startElapsedTicker();
  }

  void _startElapsedTicker() {
    _elapsedTicker?.cancel();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isActive && !state.isPaused) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  /// Pauses or resumes the elapsed session stopwatch.
  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  /// Accordion expansion toggle.
  /// Tapping the expanded exercise collapses it; tapping another expands that one.
  void toggleExerciseExpand(String exerciseId) {
    if (state.expandedExerciseId == exerciseId) {
      state = state.copyWith(clearExpandedExercise: true);
    } else {
      state = state.copyWith(expandedExerciseId: exerciseId);
    }
  }

  /// Toggles or updates set completion.
  /// When marked complete, triggers haptics and auto-starts the rest timer if configured.
  void logSet({
    required String exerciseId,
    required int setIndex,
    bool? completed,
  }) {
    final exIndex = state.exercises.indexWhere((e) => e.exerciseId == exerciseId);
    if (exIndex == -1) return;

    final exercise = state.exercises[exIndex];
    if (setIndex < 0 || setIndex >= exercise.sets.length) return;

    final currentSet = exercise.sets[setIndex];
    final targetCompleted = completed ?? !currentSet.isCompleted;

    final updatedSet = currentSet.copyWith(isCompleted: targetCompleted);
    final updatedSets = List<ActiveSetState>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;

    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[exIndex] = updatedExercise;

    state = state.copyWith(exercises: updatedExercises);

    if (targetCompleted) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}

      // Auto-trigger rest timer if configured
      final restState = ref.read(restTimerProvider);
      if (restState.autoStart) {
        ref.read(restTimerProvider.notifier).startTimer(
              durationSeconds: exercise.restDurationSeconds,
              exerciseName: exercise.name,
              setNumber: currentSet.setNumber,
            );
      }
    }
  }

  /// Updates weight, reps, RIR, RPE, or warmup flag on a specific set.
  void updateSetValues({
    required String exerciseId,
    required int setIndex,
    double? weightKg,
    int? reps,
    double? rir,
    double? rpe,
    bool? isWarmup,
  }) {
    final exIndex = state.exercises.indexWhere((e) => e.exerciseId == exerciseId);
    if (exIndex == -1) return;

    final exercise = state.exercises[exIndex];
    if (setIndex < 0 || setIndex >= exercise.sets.length) return;

    final currentSet = exercise.sets[setIndex];

    // Synchronize RIR and RPE
    double updatedRir = rir ?? currentSet.rir;
    double updatedRpe = rpe ?? currentSet.rpe;

    if (rir != null && rpe == null) {
      updatedRpe = rpeFromRir(rir);
    } else if (rpe != null && rir == null) {
      updatedRir = rirFromRpe(rpe);
    }

    final updatedSet = currentSet.copyWith(
      weightKg: weightKg ?? currentSet.weightKg,
      reps: reps ?? currentSet.reps,
      rir: updatedRir,
      rpe: updatedRpe,
      isWarmup: isWarmup ?? currentSet.isWarmup,
    );

    final updatedSets = List<ActiveSetState>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;

    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[exIndex] = exercise.copyWith(sets: updatedSets);

    state = state.copyWith(exercises: updatedExercises);
  }

  /// Adds a new set to an exercise copying the previous set's load.
  void addSet(String exerciseId) {
    final exIndex = state.exercises.indexWhere((e) => e.exerciseId == exerciseId);
    if (exIndex == -1) return;

    final exercise = state.exercises[exIndex];
    final lastSet = exercise.sets.isNotEmpty ? exercise.sets.last : null;
    final newSetNumber = exercise.sets.length + 1;

    final newSet = ActiveSetState(
      setNumber: newSetNumber,
      weightKg: lastSet?.weightKg ?? 20.0,
      reps: lastSet?.reps ?? 10,
      rir: lastSet?.rir ?? 2.0,
      rpe: lastSet?.rpe ?? 8.0,
      previousWeightKg: lastSet?.previousWeightKg,
      previousReps: lastSet?.previousReps,
    );

    final updatedSets = [...exercise.sets, newSet];
    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[exIndex] = exercise.copyWith(sets: updatedSets);

    state = state.copyWith(exercises: updatedExercises);
  }

  /// Removes a set from an exercise.
  void removeSet(String exerciseId, int setIndex) {
    final exIndex = state.exercises.indexWhere((e) => e.exerciseId == exerciseId);
    if (exIndex == -1) return;

    final exercise = state.exercises[exIndex];
    if (exercise.sets.length <= 1) return; // Keep at least one set

    final updatedSets = List<ActiveSetState>.from(exercise.sets)..removeAt(setIndex);
    // Renumber remaining sets
    final renumberedSets = [
      for (int i = 0; i < updatedSets.length; i++)
        updatedSets[i].copyWith(setNumber: i + 1),
    ];

    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[exIndex] = exercise.copyWith(sets: renumberedSets);

    state = state.copyWith(exercises: updatedExercises);
  }

  /// Generates 3 progressive ramp-up warmup sets before working sets.
  void addWarmupSets(String exerciseId) {
    final exIndex = state.exercises.indexWhere((e) => e.exerciseId == exerciseId);
    if (exIndex == -1) return;

    final exercise = state.exercises[exIndex];
    final firstSet = exercise.sets.isNotEmpty ? exercise.sets.first : null;
    final baseWeight = firstSet?.weightKg ?? 60.0;

    final warmups = [
      ActiveSetState(
        setNumber: 1,
        weightKg: (baseWeight * 0.40).clamp(20.0, 999.0),
        reps: 10,
        isWarmup: true,
      ),
      ActiveSetState(
        setNumber: 2,
        weightKg: (baseWeight * 0.60).clamp(20.0, 999.0),
        reps: 6,
        isWarmup: true,
      ),
      ActiveSetState(
        setNumber: 3,
        weightKg: (baseWeight * 0.80).clamp(20.0, 999.0),
        reps: 3,
        isWarmup: true,
      ),
    ];

    // Renumber existing working sets
    final renumberedWorking = [
      for (int i = 0; i < exercise.sets.length; i++)
        exercise.sets[i].copyWith(setNumber: warmups.length + i + 1),
    ];

    final updatedSets = [...warmups, ...renumberedWorking];
    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[exIndex] = exercise.copyWith(sets: updatedSets);

    state = state.copyWith(exercises: updatedExercises);
  }

  /// Adds a new exercise to the sequence.
  void addExercise(ActiveExerciseState exercise) {
    final updatedExercises = [...state.exercises, exercise];
    state = state.copyWith(
      exercises: updatedExercises,
      expandedExerciseId: exercise.exerciseId,
    );
  }

  /// Removes an exercise from the workout sequence.
  void removeExercise(String exerciseId) {
    final updatedExercises =
        state.exercises.where((e) => e.exerciseId != exerciseId).toList();
    state = state.copyWith(
      exercises: updatedExercises,
      expandedExerciseId: state.expandedExerciseId == exerciseId
          ? (updatedExercises.isNotEmpty ? updatedExercises.first.exerciseId : null)
          : state.expandedExerciseId,
    );
  }

  /// Reorders exercise positions in the sequence.
  void reorderExercises(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.exercises.length) return;
    if (newIndex < 0 || newIndex > state.exercises.length) return;

    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }

    final updated = List<ActiveExerciseState>.from(state.exercises);
    final moved = updated.removeAt(oldIndex);
    updated.insert(targetIndex, moved);

    state = state.copyWith(exercises: updated);
  }

  /// Replaces an exercise at a given position.
  void replaceExercise(String oldExerciseId, ActiveExerciseState newExercise) {
    final index = state.exercises.indexWhere((e) => e.exerciseId == oldExerciseId);
    if (index == -1) return;

    final updated = List<ActiveExerciseState>.from(state.exercises);
    updated[index] = newExercise;

    state = state.copyWith(
      exercises: updated,
      expandedExerciseId: newExercise.exerciseId,
    );
  }

  /// Finishes the active workout session, returns the compiled WorkoutModel, and halts timer.
  WorkoutModel finishSession({String userId = 'guest_user'}) {
    _elapsedTicker?.cancel();
    ref.read(restTimerProvider.notifier).skip();

    final workoutModel = WorkoutModel(
      id: state.workoutId,
      userId: userId,
      name: state.splitName,
      date: state.startTime,
      durationSeconds: state.elapsedSeconds,
      totalVolumeKg: state.totalVolumeKg,
      exercises: [
        for (final ex in state.exercises)
          WorkoutExercise(
            exerciseId: ex.exerciseId,
            exerciseName: ex.name,
            muscleGroup: ex.muscleGroup,
            supersetGroupId: ex.supersetGroupId,
            sets: [
              for (final s in ex.sets)
                WorkoutSet(
                  reps: s.reps,
                  weightKg: s.weightKg,
                  rpe: s.rpe,
                  isWarmup: s.isWarmup,
                  isPr: s.isPr,
                ),
            ],
          ),
      ],
    );

    state = state.copyWith(isActive: false);
    return workoutModel;
  }

  static List<ActiveExerciseState> _buildDefaultPushWorkout() {
    return [
      ActiveExerciseState(
        exerciseId: 'ex_bench_press',
        name: 'Barbell Bench Press',
        muscleGroup: 'Chest',
        equipment: 'barbell',
        restDurationSeconds: 120,
        sets: [
          const ActiveSetState(
            setNumber: 1,
            weightKg: 80.0,
            reps: 8,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 80.0,
            previousReps: 8,
            previousRir: 2.0,
          ),
          const ActiveSetState(
            setNumber: 2,
            weightKg: 80.0,
            reps: 8,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 80.0,
            previousReps: 8,
            previousRir: 2.0,
          ),
          const ActiveSetState(
            setNumber: 3,
            weightKg: 82.5,
            reps: 6,
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 80.0,
            previousReps: 7,
            previousRir: 1.0,
          ),
          const ActiveSetState(
            setNumber: 4,
            weightKg: 82.5,
            reps: 6,
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 80.0,
            previousReps: 6,
            previousRir: 0.0,
          ),
        ],
      ),
      ActiveExerciseState(
        exerciseId: 'ex_incline_db_press',
        name: 'Incline Dumbbell Press',
        muscleGroup: 'Chest',
        equipment: 'dumbbell',
        restDurationSeconds: 90,
        sets: [
          const ActiveSetState(
            setNumber: 1,
            weightKg: 32.0,
            reps: 10,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 30.0,
            previousReps: 10,
          ),
          const ActiveSetState(
            setNumber: 2,
            weightKg: 32.0,
            reps: 9,
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 32.0,
            previousReps: 8,
          ),
          const ActiveSetState(
            setNumber: 3,
            weightKg: 34.0,
            reps: 8,
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 32.0,
            previousReps: 8,
          ),
        ],
      ),
      ActiveExerciseState(
        exerciseId: 'ex_ohp',
        name: 'Standing Overhead Press',
        muscleGroup: 'Shoulders',
        equipment: 'barbell',
        restDurationSeconds: 120,
        sets: [
          const ActiveSetState(
            setNumber: 1,
            weightKg: 50.0,
            reps: 8,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 50.0,
            previousReps: 8,
          ),
          const ActiveSetState(
            setNumber: 2,
            weightKg: 50.0,
            reps: 8,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 50.0,
            previousReps: 7,
          ),
          const ActiveSetState(
            setNumber: 3,
            weightKg: 52.5,
            reps: 6,
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 50.0,
            previousReps: 6,
          ),
        ],
      ),
      ActiveExerciseState(
        exerciseId: 'ex_cable_lateral_raise',
        name: 'Cable Lateral Raise',
        muscleGroup: 'Shoulders',
        equipment: 'cable',
        restDurationSeconds: 60,
        sets: [
          const ActiveSetState(
            setNumber: 1,
            weightKg: 12.0,
            reps: 12,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 10.0,
            previousReps: 14,
          ),
          const ActiveSetState(
            setNumber: 2,
            weightKg: 12.0,
            reps: 12,
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 12.0,
            previousReps: 11,
          ),
          const ActiveSetState(
            setNumber: 3,
            weightKg: 14.0,
            reps: 10,
            rir: 0.0,
            rpe: 10.0,
            previousWeightKg: 12.0,
            previousReps: 10,
          ),
        ],
      ),
      ActiveExerciseState(
        exerciseId: 'ex_tricep_rope_pushdown',
        name: 'Tricep Rope Pushdown',
        muscleGroup: 'Triceps',
        equipment: 'cable',
        restDurationSeconds: 60,
        sets: [
          const ActiveSetState(
            setNumber: 1,
            weightKg: 25.0,
            reps: 12,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 25.0,
            previousReps: 12,
          ),
          const ActiveSetState(
            setNumber: 2,
            weightKg: 25.0,
            reps: 11,
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 25.0,
            previousReps: 10,
          ),
          const ActiveSetState(
            setNumber: 3,
            weightKg: 27.5,
            reps: 9,
            rir: 0.0,
            rpe: 10.0,
            previousWeightKg: 25.0,
            previousReps: 9,
          ),
        ],
      ),
    ];
  }
}

final activeSessionProvider =
    NotifierProvider<ActiveSessionNotifier, ActiveSessionState>(
  ActiveSessionNotifier.new,
);
