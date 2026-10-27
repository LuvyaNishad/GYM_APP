import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/features/dashboard/providers/habit_log_provider.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/models/warmup_plan.dart';
import 'package:leon/features/workout_session/models/tempo_pacer_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/providers/tempo_pacer_provider.dart';
import 'package:leon/features/workout_session/widgets/plate_calculator_modal.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/services/workout_service.dart';
import '../../helpers/memory_hive_service.dart';

ActiveExerciseState exercise({
  String id = 'row',
  bool unilateral = false,
  int sets = 3,
}) => ActiveExerciseState(
  exerciseId: id,
  name: id,
  muscleGroup: 'Back',
  equipment: 'dumbbell',
  isUnilateral: unilateral,
  sets: List.generate(
    sets,
    (i) => ActiveSetState(
      setNumber: i + 1,
      weightKg: 20,
      reps: 10,
      weightKgRight: unilateral ? 18 : null,
      repsRight: unilateral ? 8 : null,
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryHiveService hive;
  late ProviderContainer container;
  late ActiveSessionNotifier session;
  setUp(() {
    hive = MemoryHiveService();
    container = ProviderContainer(
      overrides: [hiveServiceProvider.overrideWithValue(hive)],
    );
    session = container.read(activeSessionProvider.notifier);
  });
  tearDown(() => container.dispose());

  test(
    'completed-only snapshot retains both sides, missing effort and real volume',
    () async {
      session.startSession(
        initialExercises: [
          exercise(unilateral: true),
          exercise(id: 'unstarted'),
        ],
      );
      session.logSet(exerciseId: 'row', setIndex: 0, completed: true);
      session.logSetSide(exerciseId: 'row', setIndex: 1, isLeft: true);
      final snapshot = session.snapshotWorkout();
      expect(snapshot.exercises.length, 1);
      expect(snapshot.exercises.single.sets.length, 1);
      final set = snapshot.exercises.single.sets.single;
      expect(set.rpe, 0);
      expect(set.weightKgRight, 18);
      expect(set.repsRight, 8);
      expect(WorkoutService.totalVolumeKg(snapshot), 344);
      expect(snapshot.totalVolumeKg, 344);
      await session.saveSession();
      expect(container.read(activeSessionProvider).isActive, false);
      final saved =
          (await container.read(workoutServiceProvider).fetchWorkouts()).single;
      expect(saved.exercises.single.sets.single, set);
    },
  );

  test(
    'explicit effort persists, can be cleared and is not inherited by a new set',
    () async {
      session.startSession(initialExercises: [exercise()]);
      session.updateSetValues(exerciseId: 'row', setIndex: 0, rir: 1);
      session.logSet(exerciseId: 'row', setIndex: 0, completed: true);
      expect(session.snapshotWorkout().exercises.single.sets.single.rpe, 9);
      final current = container
          .read(activeSessionProvider)
          .exercises
          .single
          .sets
          .first;
      expect(ActiveSetState.fromJson(current.toJson()).effortLogged, true);
      session.addSet('row');
      expect(
        container
            .read(activeSessionProvider)
            .exercises
            .single
            .sets
            .last
            .effortLogged,
        false,
      );
      session.updateSetValues(
        exerciseId: 'row',
        setIndex: 0,
        clearEffort: true,
      );
      expect(session.snapshotWorkout().exercises.single.sets.single.rpe, 0);
      expect(ActiveSetState.fromJson({'rpe': 8, 'rir': 2}).effortLogged, false);
    },
  );

  test(
    'same-day sessions survive, and retry upserts the original session ID',
    () async {
      final service = container.read(workoutServiceProvider);
      final prior = WorkoutModel(
        id: 'earlier',
        userId: 'guest_user',
        name: 'Earlier',
        date: DateTime.now(),
      );
      await service.saveWorkout(prior);
      session.startSession(initialExercises: [exercise()]);
      session.logSet(exerciseId: 'row', setIndex: 0, completed: true);
      hive.failDelete = true;
      await expectLater(session.saveSession(), throwsStateError);
      expect(container.read(activeSessionProvider).isActive, true);
      expect((await service.fetchWorkouts()).length, 2);
      hive.failDelete = false;
      await session.saveSession();
      expect((await service.fetchWorkouts()).length, 2);
      expect(container.read(historyWorkoutsProvider).length, 2);
    },
  );

  test(
    'failed saves retain draft, duplicate submits share one write and retry succeeds',
    () async {
      session.startSession(initialExercises: [exercise()]);
      session.logSet(exerciseId: 'row', setIndex: 0, completed: true);
      hive.failDocuments = true;
      await expectLater(session.saveSession(), throwsStateError);
      expect(container.read(activeSessionProvider).isActive, true);
      expect(hive.settings[AppConstants.settingActiveSessionData], isNotNull);
      hive.failDocuments = false;
      hive.documentGate = Completer<void>();
      final first = session.saveSession();
      final second = session.saveSession();
      expect(identical(first, second), true);
      hive.documentGate!.complete();
      await first;
      expect(hive.documentWrites, 1);
    },
  );

  test(
    'ordered draft flush recovers latest changes and checked failures are retryable',
    () async {
      session.startSession(initialExercises: [exercise()]);
      session.updateSetValues(exerciseId: 'row', setIndex: 0, weightKg: 31);
      await session.flushPendingChanges();
      hive.failSettings = true;
      session.updateSetValues(exerciseId: 'row', setIndex: 0, reps: 12);
      await expectLater(session.flushPendingChanges(), throwsStateError);
      expect(container.read(activeSessionProvider).persistenceError, isNotNull);
      hive.failSettings = false;
      await session.flushPendingChanges();
      final restored = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(hive)],
      );
      addTearDown(restored.dispose);
      final state = restored.read(activeSessionProvider);
      expect(state.exercises.single.sets.first.weightKg, 31);
      expect(state.exercises.single.sets.first.reps, 12);
      expect(state.persistenceError, isNull);
      await session.discardSession();
      expect(hive.settings[AppConstants.settingActiveSessionData], isNull);
    },
  );

  test(
    'previous performance hydrates both sides and never invents missing effort',
    () async {
      await container
          .read(workoutServiceProvider)
          .saveWorkout(
            WorkoutModel(
              id: 'previous',
              userId: 'guest_user',
              name: 'Previous',
              date: DateTime.now(),
              exercises: [
                WorkoutExercise(
                  exerciseId: 'row',
                  exerciseName: 'row',
                  muscleGroup: 'Back',
                  sets: [
                    WorkoutSet(weightKg: 5, reps: 10, isWarmup: true),
                    WorkoutSet(
                      weightKg: 24,
                      reps: 9,
                      weightKgRight: 22,
                      repsRight: 7,
                    ),
                  ],
                ),
              ],
            ),
          );
      container.invalidate(historyWorkoutsProvider);
      session.startSession(initialExercises: [exercise(unilateral: true)]);
      final set = container
          .read(activeSessionProvider)
          .exercises
          .single
          .sets
          .first;
      expect(set.previousWeightKg, 24);
      expect(set.previousWeightKgRight, 22);
      expect(set.previousRepsRight, 7);
      expect(set.weightKgRight, 22);
      expect(set.previousRir, isNull);
      expect(set.previousRpe, isNull);
    },
  );

  test(
    'replacement keeps completed and partial work, exact remaining count and unique IDs',
    () {
      session.startSession(
        initialExercises: [
          exercise(unilateral: true, sets: 4),
          exercise(id: 'new'),
        ],
      );
      session.logSet(exerciseId: 'row', setIndex: 0, completed: true);
      session.logSetSide(exerciseId: 'row', setIndex: 1, isLeft: true);
      session.replaceExercise('row', exercise(id: 'new'));
      final result = container.read(activeSessionProvider).exercises;
      expect(result.first.exerciseId, 'row');
      expect(result.first.sets.length, 2);
      expect(result.first.sets.last.isLeftCompleted, true);
      expect(result[1].sets.length, 2);
      expect(
        result[1].sets.every((s) => !s.isCompleted && !s.isLeftCompleted),
        true,
      );
      expect(result.map((e) => e.exerciseId).toSet().length, 3);
      expect(session.snapshotWorkout().exercises.single.exerciseId, 'row');
    },
  );

  test('replacement does not add work when the exercise is fully logged', () {
    session.startSession(initialExercises: [exercise(sets: 1)]);
    session.logSet(exerciseId: 'row', setIndex: 0, completed: true);
    session.replaceExercise('row', exercise(id: 'new'));
    expect(
      container.read(activeSessionProvider).exercises.single.exerciseId,
      'row',
    );
  });

  test(
    'warmup paths agree and do not impose barbell minimums on dumbbells',
    () {
      session.startSession(initialExercises: [exercise(unilateral: true)]);
      session.addSingleWarmupSet('row');
      final single = container
          .read(activeSessionProvider)
          .exercises
          .single
          .sets
          .first;
      session.addWarmupSets('row');
      final full = container
          .read(activeSessionProvider)
          .exercises
          .single
          .sets
          .first;
      expect(full.weightKg, single.weightKg);
      expect(full.weightKgRight, single.weightKg);
      expect(full.weightKg, 8);
      expect(buildWarmupPlan(0, increment: 0).first.weightKg, 0);
    },
  );

  test(
    'plate calculation sanitizes sizes, finds exact combinations and stays below target',
    () {
      expect(
        calculatePlatesPerSide(
          totalWeightKg: 80,
          availablePlates: [15, 20, 0, -2, double.nan, 15],
        ),
        {15.0: 2},
      );
      expect(
        calculatePlatesPerSide(totalWeightKg: 83, availablePlates: [20, 15]),
        {15.0: 2},
      );
      expect(calculatePlatesPerSide(totalWeightKg: 10), isEmpty);
      expect(
        calculatePlatesPerSide(totalWeightKg: 100, availablePlates: []),
        isEmpty,
      );
      expect(calculatePlatesPerSide(totalWeightKg: double.infinity), isEmpty);
    },
  );

  test(
    'equality includes metadata, previous references and collection contents',
    () {
      final original = exercise();
      expect(original, original.copyWith(sets: [...original.sets]));
      expect(
        original.hashCode,
        original.copyWith(sets: [...original.sets]).hashCode,
      );
      expect(original, isNot(original.copyWith(restDurationSeconds: 120)));
      expect(original, isNot(original.copyWith(notes: 'cue')));
      expect(original, isNot(original.copyWith(supersetGroupId: 'pair')));
      expect(
        original.sets.first,
        isNot(original.sets.first.copyWith(previousReps: 8)),
      );
    },
  );

  test(
    'habits isolate dates, undo actual entries, survive restart and recover from failed writes',
    () async {
      final habits = container.read(habitLogProvider.notifier);
      final day = DateTime(2026, 10, 20), other = DateTime(2026, 10, 19);
      await Future.wait([
        habits.addWater(250, date: day),
        habits.addWater(375, date: day),
      ]);
      await habits.addWater(500, date: other);
      await habits.undoWater(date: day);
      expect(container.read(habitLogProvider).day(day).waterMl, 250);
      expect(container.read(habitLogProvider).day(other).waterMl, 500);
      await habits.setGoals(waterMl: 2500, steps: 9000);
      await habits.saveSleep(date: day, hours: 7.5, feeling: 'Rested');
      await habits.saveSleep(date: day, hours: 8);
      expect(container.read(habitLogProvider).day(day).feeling, isNull);
      hive.failSettings = true;
      await expectLater(habits.addWater(300, date: day), throwsStateError);
      expect(container.read(habitLogProvider).day(day).waterMl, 250);
      hive.failSettings = false;
      final restored = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(hive)],
      );
      addTearDown(restored.dispose);
      expect(restored.read(habitLogProvider).waterGoalMl, 2500);
      expect(restored.read(habitLogProvider).day(day).sleepHours, 8);
      expect(
        jsonDecode(hive.settings[HabitLogNotifier.storageKey]! as String),
        isA<Map>(),
      );
    },
  );

  test('tempo is opt-in and unilateral confirmation records separate reps', () {
    session.startSession(initialExercises: [exercise(unilateral: true)]);
    final tempo = container.read(tempoPacerProvider.notifier);
    expect(container.read(tempoAutoLogProvider), false);
    tempo.startSession(
      exerciseName: 'row',
      exerciseId: 'row',
      setIndex: 0,
      targetReps: 10,
      skipCountdown: true,
    );
    tempo.confirmRepsAndRest(9);
    expect(container.read(activeSessionProvider).completedSetCount, 0);
    tempo.confirmRepsAndRest(9, rightReps: 7);
    final set = container
        .read(activeSessionProvider)
        .exercises
        .single
        .sets
        .first;
    expect(set.isCompleted, true);
    expect(set.reps, 9);
    expect(set.repsRight, 7);
  });

  test('stale tempo confirmation cannot log a replacement set', () {
    session.startSession(initialExercises: [exercise()]);
    final tempo = container.read(tempoPacerProvider.notifier);
    tempo.startSession(
      exerciseName: 'row',
      exerciseId: 'row',
      setIndex: 0,
      targetReps: 10,
    );
    session.addSingleWarmupSet('row');
    tempo.confirmRepsAndRest(9);
    expect(container.read(activeSessionProvider).completedSetCount, 0);
    expect(container.read(tempoPacerProvider).isActive, false);
  });

  test('restarted tempo cancels the previous completion callback', () async {
    session.startSession(initialExercises: [exercise()]);
    final tempo = container.read(tempoPacerProvider.notifier);
    container.read(tempoAutoLogProvider.notifier).setEnabled(true);
    tempo.startSession(
      exerciseName: 'row',
      exerciseId: 'row',
      setIndex: 0,
      targetReps: 1,
      preset: TempoPreset.explosive,
      skipCountdown: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 2150));
    expect(container.read(tempoPacerProvider).phase, TempoPhase.completed);
    tempo.startSession(
      exerciseName: 'row',
      exerciseId: 'row',
      setIndex: 1,
      targetReps: 10,
      skipCountdown: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    expect(container.read(activeSessionProvider).completedSetCount, 0);
  });
}
