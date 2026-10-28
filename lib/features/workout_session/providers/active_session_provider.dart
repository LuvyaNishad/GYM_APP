import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/workout_model.dart';
import '../../../services/hive_service.dart';
import '../../../services/workout_service.dart';
import '../../history/providers/history_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../models/active_session_state.dart';
import '../models/warmup_plan.dart';
import '../services/notification_service.dart';
import 'plate_preferences_provider.dart';
import 'rest_timer_provider.dart';

/// Provider managing the active workout session in progress.
class ActiveSessionNotifier extends Notifier<ActiveSessionState> {
  Timer? _elapsedTicker;
  Timer? _saveDebounce;
  Future<void> _pendingWrite = Future<void>.value();
  Future<void>? _saving;

  @override
  ActiveSessionState build() {
    ref.keepAlive();
    ref.onDispose(() {
      _elapsedTicker?.cancel();
      _saveDebounce?.cancel();
    });

    // Auto-resume previously interrupted / in-progress workout session
    try {
      final savedData = ref
          .read(hiveServiceProvider)
          .getSetting<Map>(AppConstants.settingActiveSessionData);
      if (savedData != null) {
        final restored = ActiveSessionState.fromJson(
          Map<String, dynamic>.from(savedData),
        );
        if (restored.isActive) {
          if (!restored.isPaused) {
            final now = DateTime.now();
            int currentElapsed = restored.elapsedSeconds;
            if (restored.lastResumedAt != null) {
              currentElapsed += now
                  .difference(restored.lastResumedAt!)
                  .inSeconds;
            }
            final updated = restored.copyWith(
              elapsedSeconds: currentElapsed,
              lastResumedAt: now,
            );
            _startElapsedTicker();
            return updated;
          }
          return restored;
        }
      }
    } catch (_) {}

    return ActiveSessionState(startTime: DateTime.now());
  }

  void _persistActiveSession() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 350), () {
      persistInBackground();
    });
  }

  Future<void> flushPendingChanges() {
    _saveDebounce?.cancel();
    final snapshot = state;
    final hive = ref.read(hiveServiceProvider);
    _pendingWrite = _pendingWrite
        .catchError((Object _) {})
        .then((_) async {
          if (snapshot.isActive) {
            await hive.putSettingChecked(
              AppConstants.settingActiveSessionData,
              snapshot.toJson(),
            );
          } else {
            await hive.deleteSettingChecked(
              AppConstants.settingActiveSessionData,
            );
          }
          if (ref.mounted) state = state.copyWith(clearPersistenceError: true);
        })
        .catchError((Object error, StackTrace stack) {
          if (ref.mounted) {
            state = state.copyWith(
              persistenceError:
                  'Your latest changes could not be saved on this device. Retry before closing the app.',
            );
          }
          Error.throwWithStackTrace(error, stack);
        });
    return _pendingWrite;
  }

  /// Lifecycle/timer callers surface errors in the session without unhandled futures.
  void persistInBackground() {
    unawaited(flushPendingChanges().catchError((Object _) {}));
  }

  Future<void> _clearActiveSession() {
    _saveDebounce?.cancel();
    final hive = ref.read(hiveServiceProvider);
    _pendingWrite = _pendingWrite
        .catchError((Object _) {})
        .then(
          (_) =>
              hive.deleteSettingChecked(AppConstants.settingActiveSessionData),
        );
    return _pendingWrite;
  }

  /// Starts a new active workout session with planned exercises.
  void startSession({
    String splitName = 'PUSH DAY ● WORKOUT A',
    List<ActiveExerciseState>? initialExercises,
  }) {
    // All launch points resume an existing workout instead of overwriting it.
    if (state.isActive) return;
    _elapsedTicker?.cancel();

    final goalConfig = ref.read(trainingGoalConfigProvider);
    final exercises = _withHistory(
      initialExercises ?? _buildDefaultPushWorkout(goalConfig),
    );
    final now = DateTime.now();

    state = ActiveSessionState(
      workoutId: 'wkt_${now.microsecondsSinceEpoch}',
      splitName: splitName,
      startTime: now,
      lastResumedAt: now,
      elapsedSeconds: 0,
      isActive: true,
      isPaused: false,
      exercises: exercises,
      expandedExerciseId: exercises.isNotEmpty
          ? exercises.first.exerciseId
          : null,
    );

    _startElapsedTicker();
    persistInBackground();
  }

  List<ActiveExerciseState> _withHistory(List<ActiveExerciseState> exercises) {
    final history = ref.read(historyWorkoutsProvider);
    return exercises.map((exercise) {
      WorkoutExercise? previous;
      for (final workout in history) {
        for (final candidate in workout.exercises) {
          if (candidate.exerciseId == exercise.exerciseId ||
              candidate.exerciseName.toLowerCase() ==
                  exercise.name.toLowerCase()) {
            previous = candidate;
            break;
          }
        }
        if (previous != null) break;
      }
      final priorSets =
          previous?.sets.where((s) => !s.isWarmup).toList() ?? <WorkoutSet>[];
      var workingIndex = 0;
      return exercise.copyWith(
        sets: List.generate(exercise.sets.length, (index) {
          final set = exercise.sets[index];
          final prior = !set.isWarmup && workingIndex < priorSets.length
              ? priorSets[workingIndex]
              : null;
          if (!set.isWarmup) workingIndex++;
          final hasEffort = prior != null && prior.rpe >= 6 && prior.rpe <= 10;
          return ActiveSetState.fromJson({
            ...set.toJson(),
            'previousWeightKg': prior?.weightKg,
            'previousReps': prior?.reps,
            'previousRpe': hasEffort ? prior.rpe : null,
            'previousRir': hasEffort ? rirFromRpe(prior.rpe) : null,
            'previousWeightKgRight': exercise.isUnilateral
                ? prior?.weightKgRight
                : null,
            'previousRepsRight': exercise.isUnilateral
                ? prior?.repsRight
                : null,
            if (prior != null) 'weightKg': prior.weightKg,
            if (prior != null) 'reps': prior.reps,
            if (exercise.isUnilateral && prior?.weightKgRight != null)
              'weightKgRight': prior!.weightKgRight,
            if (exercise.isUnilateral && prior?.repsRight != null)
              'repsRight': prior!.repsRight,
          });
        }),
      );
    }).toList();
  }

  /// Starts an empty active workout session with no initial exercises.
  void startEmptySession({String splitName = 'CUSTOM WORKOUT'}) {
    startSession(splitName: splitName, initialExercises: const []);
  }

  void _startElapsedTicker() {
    _elapsedTicker?.cancel();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isActive && !state.isPaused && state.lastResumedAt != null) {
        final now = DateTime.now();
        final delta = now.difference(state.lastResumedAt!).inSeconds;
        if (delta > 0) {
          state = state.copyWith(
            elapsedSeconds: state.elapsedSeconds + delta,
            lastResumedAt: now,
          );
        }
      }
    });
  }

  /// Resyncs the elapsed workout stopwatch against wall-clock time when app resumes from background.
  void resyncWithWallClock() {
    if (state.isActive && !state.isPaused && state.lastResumedAt != null) {
      final now = DateTime.now();
      final delta = now.difference(state.lastResumedAt!).inSeconds;
      if (delta > 0) {
        state = state.copyWith(
          elapsedSeconds: state.elapsedSeconds + delta,
          lastResumedAt: now,
        );
        _persistActiveSession();
      }
    }
  }

  /// Pauses or resumes the elapsed session stopwatch with wall-clock precision.
  void togglePause() {
    final now = DateTime.now();
    if (!state.isPaused) {
      int newElapsed = state.elapsedSeconds;
      if (state.lastResumedAt != null) {
        newElapsed += now.difference(state.lastResumedAt!).inSeconds;
      }
      state = state.copyWith(
        isPaused: true,
        elapsedSeconds: newElapsed,
        clearLastResumedAt: true,
      );
      _elapsedTicker?.cancel();
    } else {
      state = state.copyWith(isPaused: false, lastResumedAt: now);
      _startElapsedTicker();
    }
    _persistActiveSession();
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
    final exIndex = state.exercises.indexWhere(
      (e) => e.exerciseId == exerciseId,
    );
    if (exIndex == -1) return;

    final exercise = state.exercises[exIndex];
    if (setIndex < 0 || setIndex >= exercise.sets.length) return;

    final currentSet = exercise.sets[setIndex];
    final targetCompleted = completed ?? !currentSet.isCompleted;
    if (targetCompleted == currentSet.isCompleted) return;

    final updatedSet = currentSet.copyWith(
      isCompleted: targetCompleted,
      isLeftCompleted: targetCompleted,
      isRightCompleted: targetCompleted,
    );
    final updatedSets = List<ActiveSetState>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;

    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[exIndex] = updatedExercise;

    // Check for superset partner transition
    String? nextExpandedId = state.expandedExerciseId;
    String nextExerciseId = exerciseId;
    int restDurationToUse = exercise.restDurationSeconds;

    if (targetCompleted && exercise.supersetGroupId != null) {
      final partner = updatedExercises.firstWhere(
        (e) =>
            e.supersetGroupId == exercise.supersetGroupId &&
            e.exerciseId != exercise.exerciseId,
        orElse: () => exercise,
      );

      if (partner.exerciseId != exercise.exerciseId) {
        final partnerHasIncomplete = partner.sets.any((s) => !s.isCompleted);
        if (partnerHasIncomplete) {
          // Switch active view directly to superset partner
          nextExpandedId = partner.exerciseId;
          nextExerciseId = partner.exerciseId;
          // Intermediate transition rest between superset pairings (default 60s or half duration)
          restDurationToUse = (exercise.restDurationSeconds / 2)
              .clamp(45.0, 90.0)
              .toInt();
        }
      }
    }

    state = state.copyWith(
      exercises: updatedExercises,
      expandedExerciseId: nextExpandedId,
    );
    _persistActiveSession();

    if (targetCompleted) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}

      _startRestAfterSet(exercise, nextExerciseId, restDurationToUse);
    } else {
      // If user unchecks a set, dismiss the active countdown if it was triggered for this exercise
      final restState = ref.read(restTimerProvider);
      if (restState.sourceExerciseId == exerciseId) {
        ref.read(restTimerProvider.notifier).skip();
      }
    }
  }

  void _startRestAfterSet(
    ActiveExerciseState completedExercise,
    String preferredExerciseId,
    int restDurationSeconds,
  ) {
    final next = state.nextPendingSet(preferredExerciseId: preferredExerciseId);
    final rest = ref.read(restTimerProvider.notifier);
    // Also dismiss an earlier countdown if the user logs ahead of the timer.
    rest.skip();
    if (next == null) {
      ref.read(workoutNotificationServiceProvider).cancelAll();
      return;
    }
    if (ref.read(restTimerProvider).autoStart) {
      rest.startTimer(
        durationSeconds: restDurationSeconds > 0 ? restDurationSeconds : 90,
        nextSet: next,
        sourceExerciseId: completedExercise.exerciseId,
      );
    }
  }

  /// Logs either the Left or Right side of a unilateral set.
  /// When both sides are completed, marks the entire set completed and triggers the rest timer.
  void logSetSide({
    required String exerciseId,
    required int setIndex,
    required bool isLeft,
    bool? completed,
  }) {
    final exIndex = state.exercises.indexWhere(
      (e) => e.exerciseId == exerciseId,
    );
    if (exIndex == -1) return;

    final exercise = state.exercises[exIndex];
    if (setIndex < 0 || setIndex >= exercise.sets.length) return;

    final currentSet = exercise.sets[setIndex];
    final targetCompleted =
        completed ??
        (isLeft ? !currentSet.isLeftCompleted : !currentSet.isRightCompleted);

    final newLeft = isLeft ? targetCompleted : currentSet.isLeftCompleted;
    final newRight = !isLeft ? targetCompleted : currentSet.isRightCompleted;
    final bothCompleted = newLeft && newRight;

    final updatedSet = currentSet.copyWith(
      isLeftCompleted: newLeft,
      isRightCompleted: newRight,
      isCompleted: bothCompleted,
    );
    final updatedSets = List<ActiveSetState>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;

    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[exIndex] = updatedExercise;

    state = state.copyWith(exercises: updatedExercises);
    _persistActiveSession();

    if (bothCompleted && !currentSet.isCompleted) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}

      final partner = exercise.supersetGroupId == null
          ? null
          : updatedExercises
                .where(
                  (candidate) =>
                      candidate.exerciseId != exerciseId &&
                      candidate.supersetGroupId == exercise.supersetGroupId &&
                      candidate.sets.any((set) => !set.isCompleted),
                )
                .firstOrNull;
      if (partner != null) {
        state = state.copyWith(expandedExerciseId: partner.exerciseId);
      }
      _startRestAfterSet(
        exercise,
        partner?.exerciseId ?? exerciseId,
        partner == null
            ? exercise.restDurationSeconds
            : (exercise.restDurationSeconds / 2).clamp(45.0, 90.0).toInt(),
      );
    } else if (targetCompleted && !bothCompleted) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    } else if (!bothCompleted && currentSet.isCompleted) {
      final restState = ref.read(restTimerProvider);
      if (restState.sourceExerciseId == exerciseId) {
        ref.read(restTimerProvider.notifier).skip();
      }
    }
  }

  /// Toggles an exercise between Unilateral and Bilateral mode.
  void toggleUnilateral(String exerciseId) {
    final index = state.exercises.indexWhere((e) => e.exerciseId == exerciseId);
    if (index == -1) return;

    final exercise = state.exercises[index];
    // Changing sides after logging would reinterpret already performed work.
    if (exercise.sets.any(
      (s) => s.isCompleted || s.isLeftCompleted || s.isRightCompleted,
    )) {
      return;
    }
    final newIsUnilateral = !exercise.isUnilateral;

    final updatedSets = exercise.sets.map((s) {
      if (newIsUnilateral) {
        return s.copyWith(
          weightKgRight: s.weightKgRight ?? s.weightKg,
          repsRight: s.repsRight ?? s.reps,
          isLeftCompleted: s.isCompleted,
          isRightCompleted: s.isCompleted,
        );
      } else {
        return s.copyWith(
          clearRightSide: true,
          isCompleted:
              s.isCompleted || (s.isLeftCompleted && s.isRightCompleted),
        );
      }
    }).toList();

    final updatedExercise = exercise.copyWith(
      isUnilateral: newIsUnilateral,
      sets: updatedSets,
    );

    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[index] = updatedExercise;

    state = state.copyWith(exercises: updatedExercises);
    _persistActiveSession();
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Updates weight, reps, RIR, RPE, setType, or warmup flag on a specific set.
  void updateSetValues({
    required String exerciseId,
    required int setIndex,
    double? weightKg,
    int? reps,
    double? rir,
    double? rpe,
    bool clearEffort = false,
    bool? isWarmup,
    ActiveSetType? setType,
    double? weightKgRight,
    int? repsRight,
  }) {
    final exIndex = state.exercises.indexWhere(
      (e) => e.exerciseId == exerciseId,
    );
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
      weightKgRight: weightKgRight ?? currentSet.weightKgRight,
      repsRight: repsRight ?? currentSet.repsRight,
      rir: updatedRir,
      rpe: updatedRpe,
      effortLogged: clearEffort
          ? false
          : (rir != null || rpe != null || currentSet.effortLogged),
      isWarmup: isWarmup,
      setType: setType,
    );

    final updatedSets = List<ActiveSetState>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;

    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[exIndex] = exercise.copyWith(sets: updatedSets);

    state = state.copyWith(exercises: updatedExercises);
    _persistActiveSession();
  }

  /// Adds a new set to an exercise copying the previous set's load.
  void addSet(String exerciseId) {
    final exIndex = state.exercises.indexWhere(
      (e) => e.exerciseId == exerciseId,
    );
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
      weightKgRight:
          lastSet?.weightKgRight ??
          (exercise.isUnilateral ? (lastSet?.weightKg ?? 20.0) : null),
      repsRight:
          lastSet?.repsRight ??
          (exercise.isUnilateral ? (lastSet?.reps ?? 10) : null),
      previousWeightKgRight: lastSet?.previousWeightKgRight,
      previousRepsRight: lastSet?.previousRepsRight,
    );

    final updatedSets = [...exercise.sets, newSet];
    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[exIndex] = exercise.copyWith(sets: updatedSets);

    state = state.copyWith(exercises: updatedExercises);
    _persistActiveSession();
  }

  /// Removes a set from an exercise.
  void removeSet(String exerciseId, int setIndex) {
    final exIndex = state.exercises.indexWhere(
      (e) => e.exerciseId == exerciseId,
    );
    if (exIndex == -1) return;

    final exercise = state.exercises[exIndex];
    if (exercise.sets.length <= 1) return; // Keep at least one set

    final updatedSets = List<ActiveSetState>.from(exercise.sets)
      ..removeAt(setIndex);
    // Renumber remaining sets
    final renumberedSets = [
      for (int i = 0; i < updatedSets.length; i++)
        updatedSets[i].copyWith(setNumber: i + 1),
    ];

    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[exIndex] = exercise.copyWith(sets: renumberedSets);

    state = state.copyWith(exercises: updatedExercises);
    _persistActiveSession();
  }

  /// Generates 3 progressive ramp-up warmup sets before working sets.
  void addWarmupSets(String exerciseId) {
    final exIndex = state.exercises.indexWhere(
      (e) => e.exerciseId == exerciseId,
    );
    if (exIndex == -1) return;

    final exercise = state.exercises[exIndex];
    final firstSet = exercise.sets.where((s) => !s.isWarmup).firstOrNull;
    final baseWeight = firstSet?.weightKg ?? 0;
    final minimum = exercise.equipment == 'barbell'
        ? ref.read(platePreferencesProvider).barKg
        : 0.0;
    final plan = buildWarmupPlan(
      baseWeight,
      minimumWeight: minimum,
      increment: exercise.equipment == 'barbell' ? 2.5 : 1,
    );
    final warmups = [
      for (var i = 0; i < plan.length; i++)
        ActiveSetState(
          setNumber: i + 1,
          weightKg: plan[i].weightKg,
          reps: plan[i].reps,
          isWarmup: true,
          weightKgRight: exercise.isUnilateral ? plan[i].weightKg : null,
          repsRight: exercise.isUnilateral ? plan[i].reps : null,
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
    _persistActiveSession();
  }

  /// Inserts the first tier of the same ramp used by the full warmup plan.
  void addSingleWarmupSet(String exerciseId) {
    final exIndex = state.exercises.indexWhere(
      (e) => e.exerciseId == exerciseId,
    );
    if (exIndex == -1) return;

    final exercise = state.exercises[exIndex];
    final firstSet = exercise.sets.where((s) => !s.isWarmup).firstOrNull;
    final plan = buildWarmupPlan(
      firstSet?.weightKg ?? 0,
      minimumWeight: exercise.equipment == 'barbell'
          ? ref.read(platePreferencesProvider).barKg
          : 0,
      increment: exercise.equipment == 'barbell' ? 2.5 : 1,
    );

    final warmupSet = ActiveSetState(
      setNumber: 1,
      weightKg: plan.first.weightKg,
      reps: plan.first.reps,
      weightKgRight: exercise.isUnilateral ? plan.first.weightKg : null,
      repsRight: exercise.isUnilateral ? plan.first.reps : null,
      setType: ActiveSetType.warmup,
    );

    // Renumber existing sets and insert warmup set at top
    final renumberedWorking = [
      for (int i = 0; i < exercise.sets.length; i++)
        exercise.sets[i].copyWith(setNumber: i + 2),
    ];

    final updatedSets = [warmupSet, ...renumberedWorking];
    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[exIndex] = exercise.copyWith(sets: updatedSets);

    state = state.copyWith(exercises: updatedExercises);
    _persistActiveSession();
  }

  /// Updates the rest countdown interval for a specific exercise in the active workout.
  void updateExerciseRestDuration(String exerciseId, int seconds) {
    final exIndex = state.exercises.indexWhere(
      (e) => e.exerciseId == exerciseId,
    );
    if (exIndex == -1) return;

    final updatedExercises = List<ActiveExerciseState>.from(state.exercises);
    updatedExercises[exIndex] = state.exercises[exIndex].copyWith(
      restDurationSeconds: seconds.clamp(15, 600),
    );

    state = state.copyWith(exercises: updatedExercises);
    _persistActiveSession();
  }

  /// Adds a new exercise to the sequence.
  void addExercise(ActiveExerciseState exercise) {
    exercise = _withHistory([exercise]).first;
    if (state.exercises.any((e) => e.exerciseId == exercise.exerciseId)) {
      exercise = exercise.copyWith(
        exerciseId:
            '${exercise.exerciseId}_${DateTime.now().microsecondsSinceEpoch}',
      );
    }
    final updatedExercises = [...state.exercises, exercise];
    state = state.copyWith(
      exercises: updatedExercises,
      expandedExerciseId: exercise.exerciseId,
    );
    _persistActiveSession();
  }

  /// Removes an exercise from the workout sequence.
  void removeExercise(String exerciseId) {
    final updatedExercises = state.exercises
        .where((e) => e.exerciseId != exerciseId)
        .toList();
    state = state.copyWith(
      exercises: updatedExercises,
      expandedExerciseId: state.expandedExerciseId == exerciseId
          ? (updatedExercises.isNotEmpty
                ? updatedExercises.first.exerciseId
                : null)
          : state.expandedExerciseId,
    );
    _persistActiveSession();
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
    _persistActiveSession();
  }

  /// Replaces an exercise at a given position.
  void replaceExercise(String oldExerciseId, ActiveExerciseState newExercise) {
    final index = state.exercises.indexWhere(
      (e) => e.exerciseId == oldExerciseId,
    );
    if (index == -1) return;
    final original = state.exercises[index];
    // Keep partially logged unilateral sets with their original exercise so the
    // other side can still be completed. Transfer only untouched sets.
    bool hasWork(ActiveSetState set) =>
        set.isCompleted || set.isLeftCompleted || set.isRightCompleted;
    final logged = original.sets.where(hasWork).toList();
    final remaining = original.sets.where((s) => !hasWork(s)).toList();
    if (remaining.isEmpty) return;
    final template =
        newExercise.sets.firstOrNull ??
        const ActiveSetState(setNumber: 1, weightKg: 0, reps: 10);
    newExercise = newExercise.copyWith(
      sets: [
        for (var i = 0; i < remaining.length; i++)
          template.copyWith(
            setNumber: i + 1,
            isCompleted: false,
            isLeftCompleted: false,
            isRightCompleted: false,
            isWarmup: remaining[i].isWarmup,
            effortLogged: false,
          ),
      ],
    );
    newExercise = _withHistory([newExercise]).first;
    if (state.exercises.any(
      (e) =>
          e.exerciseId == newExercise.exerciseId &&
          (e.exerciseId != oldExerciseId || logged.isNotEmpty),
    )) {
      newExercise = newExercise.copyWith(
        exerciseId:
            '${newExercise.exerciseId}_${DateTime.now().microsecondsSinceEpoch}',
      );
    }
    final updated = List<ActiveExerciseState>.from(state.exercises);
    if (logged.isNotEmpty) {
      updated[index] = original.copyWith(sets: logged);
      updated.insert(index + 1, newExercise);
    } else {
      updated[index] = newExercise;
    }

    state = state.copyWith(
      exercises: updated,
      expandedExerciseId: newExercise.exerciseId,
    );
    _persistActiveSession();
  }

  /// Pairs two exercises together into an antagonistic or agonist superset group.
  void createSuperset(String exerciseIdA, String exerciseIdB) {
    if (exerciseIdA == exerciseIdB) return;
    final indexA = state.exercises.indexWhere(
      (e) => e.exerciseId == exerciseIdA,
    );
    final indexB = state.exercises.indexWhere(
      (e) => e.exerciseId == exerciseIdB,
    );
    if (indexA == -1 || indexB == -1) return;

    final groupId = 'ss_${DateTime.now().microsecondsSinceEpoch}';
    final updatedList = List<ActiveExerciseState>.from(state.exercises);

    // Update superset groupId
    updatedList[indexA] = updatedList[indexA].copyWith(
      supersetGroupId: groupId,
    );
    updatedList[indexB] = updatedList[indexB].copyWith(
      supersetGroupId: groupId,
    );

    // Position them adjacent to each other in sequence
    final exB = updatedList.removeAt(
      updatedList.indexWhere((e) => e.exerciseId == exerciseIdB),
    );
    final newIndexA = updatedList.indexWhere(
      (e) => e.exerciseId == exerciseIdA,
    );
    updatedList.insert(newIndexA + 1, exB);

    state = state.copyWith(exercises: updatedList);
    _persistActiveSession();
  }

  /// Removes an exercise from its superset group.
  void unlinkSuperset(String exerciseId) {
    final exIndex = state.exercises.indexWhere(
      (e) => e.exerciseId == exerciseId,
    );
    if (exIndex == -1) return;

    final exercise = state.exercises[exIndex];
    final groupId = exercise.supersetGroupId;
    if (groupId == null) return;

    final updated = List<ActiveExerciseState>.from(state.exercises);
    updated[exIndex] = exercise.copyWith(clearSupersetGroup: true);

    // If only one exercise remains with this groupId, unlink it too
    final remainingWithGroup = updated
        .where((e) => e.supersetGroupId == groupId)
        .toList();
    if (remainingWithGroup.length <= 1) {
      for (int i = 0; i < updated.length; i++) {
        if (updated[i].supersetGroupId == groupId) {
          updated[i] = updated[i].copyWith(clearSupersetGroup: true);
        }
      }
    }

    state = state.copyWith(exercises: updated);
    _persistActiveSession();
  }

  /// Substitutes an exercise with a library alternative while preserving completed sets.
  void substituteExercise({
    required String oldExerciseId,
    required String newExerciseId,
    required String newName,
    required String newMuscleGroup,
    String newEquipment = 'barbell',
    int? newRestSeconds,
  }) {
    final index = state.exercises.indexWhere(
      (e) => e.exerciseId == oldExerciseId,
    );
    if (index == -1) return;

    final existing = state.exercises[index];
    final updated = ActiveExerciseState(
      exerciseId: newExerciseId,
      name: newName,
      muscleGroup: newMuscleGroup,
      equipment: newEquipment,
      restDurationSeconds: newRestSeconds ?? existing.restDurationSeconds,
      sets: List.generate(
        existing.sets.where((s) => !s.isCompleted).length.clamp(1, 20),
        (i) => ActiveSetState(setNumber: i + 1, weightKg: 0, reps: 10),
      ),
    );
    replaceExercise(oldExerciseId, updated);
  }

  /// Builds a completed-only snapshot without destroying the recoverable draft.
  WorkoutModel snapshotWorkout({String userId = 'guest_user'}) {
    return WorkoutModel(
      id: state.workoutId,
      userId: userId,
      name: state.splitName,
      date: state.startTime,
      durationSeconds: state.elapsedSeconds,
      totalVolumeKg: state.totalVolumeKg,
      exercises: [
        for (final ex in state.exercises.where(
          (e) => e.sets.any((s) => s.isCompleted),
        ))
          WorkoutExercise(
            exerciseId: ex.exerciseId,
            exerciseName: ex.name,
            muscleGroup: ex.muscleGroup,
            supersetGroupId: ex.supersetGroupId,
            sets: [
              for (final s in ex.sets.where((s) => s.isCompleted))
                WorkoutSet(
                  reps: s.reps,
                  weightKg: s.weightKg,
                  rpe: s.effortLogged ? s.rpe : 0,
                  isWarmup: s.isWarmup,
                  isPr: s.isPr,
                  weightKgRight: ex.isUnilateral
                      ? s.weightKgRight ?? s.weightKg
                      : null,
                  repsRight: ex.isUnilateral ? s.repsRight ?? s.reps : null,
                ),
            ],
          ),
      ],
    );
  }

  Future<void> saveSession({String userId = 'guest_user', DateTime? date}) {
    return _saving ??= _saveSession(
      userId: userId,
      date: date,
    ).whenComplete(() => _saving = null);
  }

  Future<void> _saveSession({
    String userId = 'guest_user',
    DateTime? date,
  }) async {
    resyncWithWallClock();
    final snapshot = snapshotWorkout(userId: userId);
    if (snapshot.exercises.isEmpty) {
      throw StateError('Log at least one set before saving.');
    }
    await flushPendingChanges();
    await ref
        .read(workoutServiceProvider)
        .saveWorkout(date == null ? snapshot : snapshot.copyWith(date: date));
    await discardSession();
    ref.invalidate(historyWorkoutsProvider);
  }

  /// Legacy synchronous finish used by callers that explicitly manage storage.
  WorkoutModel finishSession({String userId = 'guest_user'}) {
    final workout = snapshotWorkout(userId: userId);
    cancelSession();
    return workout;
  }

  /// Cancels and resets the active workout session, halting all tickers.
  void cancelSession() {
    unawaited(discardSession().catchError((Object _) {}));
  }

  /// Clear durable storage before dropping the in-memory recovery copy.
  Future<void> discardSession() async {
    try {
      await _clearActiveSession();
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          persistenceError:
              'Could not clear the saved draft. Your workout is still available. Please retry.',
        );
      }
      rethrow;
    }
    if (!ref.mounted) return;
    _elapsedTicker?.cancel();
    ref.read(restTimerProvider.notifier).skip();
    ref.read(workoutNotificationServiceProvider).cancelAll();
    state = ActiveSessionState(startTime: DateTime.now());
  }

  static List<ActiveExerciseState> _buildDefaultPushWorkout([
    TrainingGoalConfig? goalConfig,
  ]) {
    final goalType = goalConfig?.type ?? TrainingGoalType.buildMuscle;
    final int compoundRest = goalConfig?.defaultRestSeconds ?? 120;
    final int secondaryRest = goalType == TrainingGoalType.strength
        ? 150
        : (goalType == TrainingGoalType.loseFat ? 60 : 90);
    final int accessoryRest = goalType == TrainingGoalType.strength
        ? 120
        : (goalType == TrainingGoalType.loseFat ? 45 : 60);

    // Goal-specific rep schemes:
    final int compoundReps = goalType == TrainingGoalType.strength
        ? 5
        : (goalType == TrainingGoalType.loseFat
              ? 12
              : (goalType == TrainingGoalType.athletic ? 8 : 8));

    final int secondaryReps = goalType == TrainingGoalType.strength
        ? 6
        : (goalType == TrainingGoalType.loseFat
              ? 12
              : (goalType == TrainingGoalType.athletic ? 8 : 10));

    final int accessoryReps = goalType == TrainingGoalType.strength
        ? 8
        : (goalType == TrainingGoalType.loseFat
              ? 15
              : (goalType == TrainingGoalType.athletic ? 10 : 12));

    return [
      ActiveExerciseState(
        exerciseId: 'ex_bench_press',
        name: 'Barbell Bench Press',
        muscleGroup: 'Chest',
        equipment: 'barbell',
        restDurationSeconds: compoundRest,
        sets: [
          ActiveSetState(
            setNumber: 1,
            weightKg: 80.0,
            reps: compoundReps,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 80.0,
            previousReps: compoundReps,
            previousRir: 2.0,
          ),
          ActiveSetState(
            setNumber: 2,
            weightKg: 80.0,
            reps: compoundReps,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 80.0,
            previousReps: compoundReps,
            previousRir: 2.0,
          ),
          ActiveSetState(
            setNumber: 3,
            weightKg: 82.5,
            reps: (compoundReps - 1).clamp(1, 99),
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 80.0,
            previousReps: compoundReps,
            previousRir: 1.0,
          ),
          ActiveSetState(
            setNumber: 4,
            weightKg: 82.5,
            reps: (compoundReps - 1).clamp(1, 99),
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 80.0,
            previousReps: compoundReps,
            previousRir: 0.0,
          ),
        ],
      ),
      ActiveExerciseState(
        exerciseId: 'ex_incline_db_press',
        name: 'Incline Dumbbell Press',
        muscleGroup: 'Chest',
        equipment: 'dumbbell',
        restDurationSeconds: secondaryRest,
        sets: [
          ActiveSetState(
            setNumber: 1,
            weightKg: 32.0,
            reps: secondaryReps,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 30.0,
            previousReps: secondaryReps,
          ),
          ActiveSetState(
            setNumber: 2,
            weightKg: 32.0,
            reps: (secondaryReps - 1).clamp(1, 99),
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 32.0,
            previousReps: secondaryReps,
          ),
          ActiveSetState(
            setNumber: 3,
            weightKg: 34.0,
            reps: (secondaryReps - 2).clamp(1, 99),
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 32.0,
            previousReps: secondaryReps,
          ),
        ],
      ),
      ActiveExerciseState(
        exerciseId: 'ex_ohp',
        name: 'Standing Overhead Press',
        muscleGroup: 'Shoulders',
        equipment: 'barbell',
        restDurationSeconds: compoundRest,
        sets: [
          ActiveSetState(
            setNumber: 1,
            weightKg: 50.0,
            reps: compoundReps,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 50.0,
            previousReps: compoundReps,
          ),
          ActiveSetState(
            setNumber: 2,
            weightKg: 50.0,
            reps: compoundReps,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 50.0,
            previousReps: compoundReps,
          ),
          ActiveSetState(
            setNumber: 3,
            weightKg: 52.5,
            reps: (compoundReps - 2).clamp(1, 99),
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 50.0,
            previousReps: compoundReps,
          ),
        ],
      ),
      ActiveExerciseState(
        exerciseId: 'ex_cable_lateral_raise',
        name: 'Cable Lateral Raise',
        muscleGroup: 'Shoulders',
        equipment: 'cable',
        restDurationSeconds: accessoryRest,
        sets: [
          ActiveSetState(
            setNumber: 1,
            weightKg: 12.0,
            reps: accessoryReps,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 10.0,
            previousReps: accessoryReps,
          ),
          ActiveSetState(
            setNumber: 2,
            weightKg: 12.0,
            reps: accessoryReps,
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 12.0,
            previousReps: accessoryReps,
          ),
          ActiveSetState(
            setNumber: 3,
            weightKg: 14.0,
            reps: (accessoryReps - 2).clamp(1, 99),
            rir: 0.0,
            rpe: 10.0,
            previousWeightKg: 12.0,
            previousReps: accessoryReps,
          ),
        ],
      ),
      ActiveExerciseState(
        exerciseId: 'ex_tricep_rope_pushdown',
        name: 'Tricep Rope Pushdown',
        muscleGroup: 'Triceps',
        equipment: 'cable',
        restDurationSeconds: accessoryRest,
        sets: [
          ActiveSetState(
            setNumber: 1,
            weightKg: 25.0,
            reps: accessoryReps,
            rir: 2.0,
            rpe: 8.0,
            previousWeightKg: 25.0,
            previousReps: accessoryReps,
          ),
          ActiveSetState(
            setNumber: 2,
            weightKg: 25.0,
            reps: (accessoryReps - 1).clamp(1, 99),
            rir: 1.0,
            rpe: 9.0,
            previousWeightKg: 25.0,
            previousReps: accessoryReps,
          ),
          ActiveSetState(
            setNumber: 3,
            weightKg: 27.5,
            reps: (accessoryReps - 3).clamp(1, 99),
            rir: 0.0,
            rpe: 10.0,
            previousWeightKg: 25.0,
            previousReps: accessoryReps,
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
