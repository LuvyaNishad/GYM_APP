import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/exercise_library/models/exercise_library_item.dart';
import 'package:leon/features/exercise_library/widgets/add_to_routine_dialog.dart';
import 'package:leon/features/workout_builder/models/split_model.dart';
import 'package:leon/features/workout_builder/providers/splits_provider.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/hive_service.dart';
import '../../helpers/memory_hive_service.dart';

const exercise = ExerciseLibraryItem(
  id: 'cable-lateral',
  name: 'Cable lateral raise',
  category: 'Shoulders',
  description: 'Cable raise',
  primaryEquipment: 'cable',
);
const custom = TrainingSplitModel(
  id: 'custom',
  name: 'Upper body',
  shortName: 'Upper',
  daysPerWeek: 3,
  description: '',
  isCustom: true,
  workouts: [
    SplitWorkoutDay(
      id: 'upper',
      name: 'Upper day',
      targetMuscles: ['Shoulders'],
    ),
  ],
  plannedMuscleSets: {},
);

class TestSplits extends SplitsNotifier {
  TestSplits(this.routine);
  final TrainingSplitModel routine;
  @override
  SplitsState build() => SplitsState(
    splits: [routine],
    activeSplitId: routine.id,
    loggedVolume: const {},
  );
}

class CountingHive extends MemoryHiveService {
  int attempts = 0;
  @override
  Future<void> put(String box, String key, Map<String, dynamic> value) {
    attempts++;
    return super.put(box, key, value);
  }
}

void main() {
  Future<ProviderContainer> mount(
    WidgetTester tester,
    CountingHive hive, {
    TrainingSplitModel routine = custom,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        hiveServiceProvider.overrideWithValue(hive),
        splitsProvider.overrideWith(() => TestSplits(routine)),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AddToRoutineDialog(exercise: exercise),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> selectRoutine(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upper: Upper day').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('CONFIRM & ADD'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'one pending submission survives back/barrier, fails visibly and retries once',
    (tester) async {
      final hive = CountingHive();
      final container = await mount(tester, hive);
      await tester.enterText(find.byType(TextField), '12.5');
      await selectRoutine(tester);
      hive.documentGate = Completer<void>();
      final submit = tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'CONFIRM & ADD'),
          )
          .onPressed!;
      submit();
      submit();
      await tester.pump();
      expect(hive.attempts, 1);
      expect(find.text('SAVING…'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(find.byType(AddToRoutineDialog), findsOneWidget);
      hive.failDocuments = true;
      hive.documentGate!.complete();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not save the exercise.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '12.5',
      );
      expect(
        container.read(splitsProvider).activeSplit.workouts.single.exercises,
        isEmpty,
      );
      hive.failDocuments = false;
      hive.documentGate = null;
      await tester.ensureVisible(find.text('CONFIRM & ADD'));
      await tester.tap(find.text('CONFIRM & ADD'));
      await tester.pumpAndSettle();
      final saved = hive.read(
        AppConstants.hiveBoxSplits,
        'custom',
        TrainingSplitModel.fromJson,
      )!;
      expect(saved.workouts.single.exercises.single.exerciseId, exercise.id);
      expect(saved.workouts.single.exercises.single.targetWeightKg, 12.5);
      expect(hive.documentWrites, 1);
      expect(container.read(activeSessionProvider).isActive, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'template addition saves one complete custom copy without changing the active plan',
    (tester) async {
      final hive = CountingHive();
      final preset = custom.copyWith(id: 'template', isCustom: false);
      final container = await mount(tester, hive, routine: preset);
      await selectRoutine(tester);
      await tester.tap(find.text('CONFIRM & ADD'));
      await tester.pumpAndSettle();
      expect(hive.attempts, 1);
      expect(container.read(splitsProvider).activeSplitId, 'template');
      final saved = hive
          .readAll(AppConstants.hiveBoxSplits, TrainingSplitModel.fromJson)
          .single;
      expect(saved.isCustom, isTrue);
      expect(saved.workouts.single.exercises.single.exerciseId, exercise.id);
      expect(saved.workouts.single.exercises.single.targetWeightKg, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new workout contains only the chosen exercise and failed draft-save retry does not add it twice',
    (tester) async {
      final hive = CountingHive();
      await hive.put(
        AppConstants.hiveBoxWorkouts,
        'previous',
        WorkoutModel(
          id: 'previous',
          userId: 'local',
          name: 'Earlier workout',
          date: DateTime(2026, 11, 1),
          exercises: [
            WorkoutExercise(
              exerciseId: exercise.id,
              exerciseName: exercise.name,
              muscleGroup: exercise.category,
              sets: [WorkoutSet(weightKg: 60, reps: 8)],
            ),
          ],
        ).toJson(),
      );
      final container = await mount(tester, hive);
      await tester.enterText(find.byType(TextField), '1.25');
      await tester.ensureVisible(find.text('START CUSTOM WORKOUT'));
      await tester.pumpAndSettle();
      hive.failSettings = true;
      await tester.tap(find.text('START CUSTOM WORKOUT'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.textContaining('Could not save the exercise.'),
        findsOneWidget,
      );
      final added = container.read(activeSessionProvider).exercises.single;
      expect(added.exerciseId, exercise.id);
      expect(added.sets.first.weightKg, 1.25);
      expect(added.sets.first.previousWeightKg, 60);
      hive.failSettings = false;
      await tester.ensureVisible(find.text('RETRY SAVE'));
      await tester.tap(find.text('RETRY SAVE'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byType(AddToRoutineDialog), findsNothing);
      expect(container.read(activeSessionProvider).exercises, hasLength(1));
      final draft = hive.settings[AppConstants.settingActiveSessionData] as Map;
      expect(draft['exercises'], hasLength(1));
      expect(tester.takeException(), isNull);
      container.read(activeSessionProvider.notifier).togglePause();
      await container
          .read(activeSessionProvider.notifier)
          .flushPendingChanges();
      await tester.pump();
    },
  );
}
