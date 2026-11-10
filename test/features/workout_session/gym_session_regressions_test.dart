import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/widgets/exercise_set_table.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/features/workout_builder/models/split_model.dart';
import 'package:leon/features/workout_builder/providers/splits_provider.dart';
import 'package:leon/features/dashboard/providers/workout_rotation_provider.dart';
import 'package:leon/features/dashboard/providers/home_workout_view_provider.dart';
import 'package:leon/models/user_model.dart';
import 'package:leon/state/app_providers.dart';
import '../../helpers/memory_hive_service.dart';

ActiveExerciseState planned({bool unilateral = false}) => ActiveExerciseState(
  exerciseId: 'bench',
  name: 'Bench Press',
  muscleGroup: 'Chest',
  isUnilateral: unilateral,
  sets: List.generate(
    4,
    (i) => ActiveSetState(
      setNumber: i + 1,
      weightKg: 0,
      reps: 10,
      weightKgRight: unilateral ? 0 : null,
      repsRight: unilateral ? 10 : null,
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryHiveService hive;
  late ProviderContainer container;
  late ActiveSessionNotifier session;
  List<ActiveSetState> sets() =>
      container.read(activeSessionProvider).exercises.single.sets;
  setUp(() {
    hive = MemoryHiveService();
    container = ProviderContainer(
      overrides: [hiveServiceProvider.overrideWithValue(hive)],
    );
    session = container.read(activeSessionProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('drop and warmup rows do not consume working-set numbers', () {
    session.startSession(initialExercises: [planned()]);
    session.updateSetValues(
      exerciseId: 'bench',
      setIndex: 1,
      setType: ActiveSetType.dropSet,
    );
    expect(sets().map((s) => s.setNumber), [1, 1, 2, 3]);
    session.addSingleWarmupSet('bench');
    expect(sets().map((s) => s.setNumber), [1, 1, 1, 2, 3]);
    session.removeSet('bench', 2);
    expect(sets().map((s) => s.setNumber), [1, 1, 2, 3]);
    session.updateSetValues(
      exerciseId: 'bench',
      setIndex: 1,
      setType: ActiveSetType.dropSet,
    );
    session.addSet('bench');
    expect(sets().last.setNumber, 3);
  });

  test(
    'new sets use the last working load rather than the preceding drop load',
    () {
      session.startSession(initialExercises: [planned()]);
      session.updateSetValues(exerciseId: 'bench', setIndex: 2, weightKg: 40);
      session.updateSetValues(
        exerciseId: 'bench',
        setIndex: 3,
        setType: ActiveSetType.dropSet,
        weightKg: 20,
      );
      session.addSet('bench');
      expect(sets().last.weightKg, 40);
    },
  );

  test(
    'changing a load carries forward only to untouched working rows',
    () async {
      session.startSession(initialExercises: [planned()]);
      session.updateSetValues(exerciseId: 'bench', setIndex: 2, weightKg: 17.5);
      session.updateSetValues(
        exerciseId: 'bench',
        setIndex: 3,
        setType: ActiveSetType.dropSet,
        weightKg: 12.5,
      );
      session.updateSetValues(
        exerciseId: 'bench',
        setIndex: 0,
        weightKg: 30.25,
      );
      expect(sets().map((s) => s.weightKg), [30.25, 30.25, 17.5, 12.5]);
      session.logSet(exerciseId: 'bench', setIndex: 1, completed: true);
      await session.flushPendingChanges();
      container.dispose();
      container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(hive)],
      );
      session = container.read(activeSessionProvider.notifier);
      session.updateSetValues(exerciseId: 'bench', setIndex: 0, weightKg: 35);
      expect(sets().map((s) => s.weightKg), [35, 30.25, 17.5, 12.5]);
    },
  );

  test(
    'left and right defaults carry independently without replacing logged sides',
    () {
      session.startSession(initialExercises: [planned(unilateral: true)]);
      session.updateSetValues(
        exerciseId: 'bench',
        setIndex: 0,
        weightKg: 14,
        weightKgRight: 12,
      );
      expect(sets()[1].weightKg, 14);
      expect(sets()[1].weightKgRight, 12);
      session.logSetSide(exerciseId: 'bench', setIndex: 1, isLeft: true);
      session.updateSetValues(
        exerciseId: 'bench',
        setIndex: 0,
        weightKg: 16,
        weightKgRight: 13,
      );
      expect(sets()[1].weightKg, 14);
      expect(sets()[1].weightKgRight, 13);
    },
  );

  test(
    'latest useful history prefills every working set, including added rows',
    () async {
      final now = DateTime.now();
      for (final workout in [
        WorkoutModel(
          id: 'older',
          userId: 'guest',
          name: 'Old workout',
          date: now.subtract(const Duration(days: 2)),
          exercises: const [
            WorkoutExercise(
              exerciseId: 'bench',
              exerciseName: 'Bench Press',
              muscleGroup: 'Chest',
              sets: [WorkoutSet(weightKg: 35, reps: 8)],
            ),
          ],
        ),
        WorkoutModel(
          id: 'latest',
          userId: 'guest',
          name: 'Luvya routine',
          date: now.subtract(const Duration(days: 1)),
          exercises: const [
            WorkoutExercise(
              exerciseId: 'bench',
              exerciseName: 'Bench Press',
              muscleGroup: 'Chest',
              sets: [
                WorkoutSet(weightKg: 40.25, reps: 9),
                WorkoutSet(weightKg: 42.5, reps: 7),
              ],
            ),
          ],
        ),
        WorkoutModel(
          id: 'empty',
          userId: 'guest',
          name: 'No work',
          date: now,
          exercises: const [
            WorkoutExercise(
              exerciseId: 'bench',
              exerciseName: 'Bench Press',
              muscleGroup: 'Chest',
            ),
          ],
        ),
      ]) {
        await hive.put(
          AppConstants.hiveBoxWorkouts,
          workout.id,
          workout.toJson(),
        );
      }
      container.invalidate(historyWorkoutsProvider);
      session.startSession(initialExercises: [planned()]);
      expect(sets().map((s) => s.weightKg), [40.25, 42.5, 42.5, 42.5]);
      expect(sets().map((s) => s.reps), [9, 7, 7, 7]);
      expect(sets().any((s) => s.isCompleted || s.effortLogged), isFalse);
      session.addSet('bench');
      expect(sets().last.weightKg, 42.5);
    },
  );

  testWidgets(
    'inputs display actual zero and exact fractional loads without writing defaults',
    (tester) async {
      container.dispose();
      container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(hive)],
      );
      session = container.read(activeSessionProvider.notifier);
      session.startSession(initialExercises: [planned()]);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Consumer(
                builder: (_, ref, _) => SingleChildScrollView(
                  child: ExerciseSetTable(
                    exercise: ref.watch(activeSessionProvider).exercises.single,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final inputs = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(inputs.first.controller!.text, '0');
      session.updateSetValues(
        exerciseId: 'bench',
        setIndex: 0,
        weightKg: 12.25,
      );
      await tester.pump();
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .first
            .controller!
            .text,
        '12.25',
      );
      expect(sets()[1].weightKg, 12.25);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );

  test(
    'custom default survives restart and unrelated profile edits; new launch preserves existing draft',
    () async {
      await container
          .read(userProfileProvider.notifier)
          .load(
            const UserModel(
              id: 'user',
              email: '',
              displayName: 'Luvya',
              onboardingComplete: true,
              preferredSplit: 'split_ppl',
              trainingDaysPerWeek: 7,
            ),
          );
      final routine = TrainingSplitModel(
        id: 'custom_luvya',
        name: 'Luvya routine',
        shortName: 'Luvya',
        plannedMuscleSets: const {'Chest': 3},
        daysPerWeek: 7,
        description: '',
        isCustom: true,
        workouts: const [
          SplitWorkoutDay(
            id: 'luvya_day',
            name: 'My workout',
            targetMuscles: ['Chest'],
            exercises: [
              PlannedExercise(
                exerciseId: 'bench',
                exerciseName: 'Bench Press',
                muscleGroup: 'Chest',
                repRange: '6–8',
                targetWeightKg: 0,
              ),
            ],
          ),
        ],
      );
      await container.read(splitsProvider.notifier).saveCustomSplit(routine);
      await container
          .read(splitsProvider.notifier)
          .switchActiveSplit(routine.id);
      await container
          .read(userProfileProvider.notifier)
          .update((user) => user.copyWith(displayName: 'Updated name'));
      container.dispose();
      container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(hive)],
      );
      session = container.read(activeSessionProvider.notifier);
      expect(container.read(splitsProvider).activeSplit.name, 'Luvya routine');
      final rotation = container.read(workoutRotationProvider);
      expect(rotation.split.id, routine.id);
      expect(container.read(homeWorkoutViewProvider).day!.id, 'luvya_day');
      final day = rotation.selectedDay;
      session.startSession(
        splitName: '${rotation.split.name} ● ${day.name}',
        initialExercises: day.exercises
            .map((e) => e.toActiveExerciseState())
            .toList(),
      );
      expect(sets().first.reps, 6);
      session.updateSetValues(exerciseId: 'bench', setIndex: 0, weightKg: 32.5);
      final workoutId = container.read(activeSessionProvider).workoutId;
      session.startSession(splitName: 'Other workout', initialExercises: []);
      expect(container.read(activeSessionProvider).workoutId, workoutId);
      expect(sets().first.weightKg, 32.5);
    },
  );

  test(
    'saved drop and failure types survive history JSON without consuming working numbers',
    () async {
      session.startSession(initialExercises: [planned()]);
      session.updateSetValues(
        exerciseId: 'bench',
        setIndex: 1,
        setType: ActiveSetType.dropSet,
      );
      session.updateSetValues(
        exerciseId: 'bench',
        setIndex: 2,
        setType: ActiveSetType.failure,
      );
      for (var i = 0; i < 3; i++) {
        session.logSet(exerciseId: 'bench', setIndex: i, completed: true);
      }
      final snapshot = WorkoutModel.fromJson(
        jsonDecode(jsonEncode(session.snapshotWorkout().toJson()))
            as Map<String, dynamic>,
      );
      expect(snapshot.exercises.single.sets.map((s) => s.setType), [
        'normal',
        'dropSet',
        'failure',
      ]);
      await session.saveSession();
      final saved = hive
          .readAll(AppConstants.hiveBoxWorkouts, WorkoutModel.fromJson)
          .single;
      expect(saved.exercises.single.sets.map((s) => s.setType), [
        'normal',
        'dropSet',
        'failure',
      ]);
      session.startSession(initialExercises: [planned()]);
      expect(sets().map((s) => s.setNumber), [1, 2, 3, 4]);
    },
  );
}
