import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/history/widgets/edit_workout_sheet.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/hive_service.dart';
import '../../helpers/memory_hive_service.dart';

final original = WorkoutModel(
  id: 'log',
  userId: 'guest',
  name: 'Pull day',
  date: DateTime(2026, 10, 1),
  notes: 'Original note',
  trainingPlan: const {'splitId': 'original_plan'},
  exercises: [
    const WorkoutExercise(
      exerciseId: 'row',
      exerciseName: 'Row',
      muscleGroup: 'Back',
      rpe: 8,
      supersetGroupId: 'pair',
      sets: [
        WorkoutSet(
          weightKg: 40,
          reps: 10,
          weightKgRight: 35,
          repsRight: 8,
          rpe: 7.5,
        ),
      ],
    ),
    const WorkoutExercise(
      exerciseId: 'warmup',
      exerciseName: 'Warm-up row',
      muscleGroup: 'Back',
      isWarmup: true,
      rpe: 5,
      sets: [WorkoutSet(weightKg: 10, reps: 5, isWarmup: true, rpe: 4)],
    ),
  ],
);

void main() {
  testWidgets(
    'large-text keyboard editing saves both sides and keeps actions reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hive = MemoryHiveService();
      await hive.put(
        AppConstants.hiveBoxWorkouts,
        original.id,
        original.toJson(),
      );
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(hive)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(2),
                viewInsets: const EdgeInsets.only(bottom: 300),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => EditWorkoutSheet.show(context, original),
                  child: const Text('Open editor'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      final rightWeight = find.byWidgetPredicate(
        (w) =>
            w is TextField && double.tryParse(w.controller?.text ?? '') == 35,
      );
      await tester.ensureVisible(rightWeight);
      await tester.pumpAndSettle();
      expect(tester.getSize(rightWeight).width, greaterThan(200));
      await tester.enterText(rightWeight, '36.25');
      await tester.pumpAndSettle();
      final rightReps = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == '8',
      );
      await tester.ensureVisible(rightReps);
      await tester.pumpAndSettle();
      await tester.enterText(rightReps, '9');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'DELETE'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(OutlinedButton, 'DELETE').hitTestable(),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();
      expect(find.text('SAVE CHANGES').hitTestable(), findsOneWidget);
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();
      final saved = container.read(historyWorkoutsProvider).single;
      expect(saved.exercises.first.sets.single.weightKg, 40);
      expect(saved.exercises.first.sets.single.weightKgRight, 36.25);
      expect(saved.exercises.first.sets.single.repsRight, 9);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed save retains input; retry preserves metadata and separately edited right side',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hive = MemoryHiveService();
      await hive.put(
        AppConstants.hiveBoxWorkouts,
        original.id,
        original.toJson(),
      );
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(hive)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => EditWorkoutSheet.show(context, original),
                  child: const Text('Open editor'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'WORKOUT NAME',
        ),
        'Edited pull',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Right kg',
        ),
        '36',
      );
      hive.documentGate = Completer<void>();
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pump();
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'SAVE CHANGES'),
            )
            .onPressed,
        isNull,
      );
      expect(container.read(historyWorkoutsProvider).single.name, 'Pull day');
      await tester.dragFrom(
        tester.getCenter(find.text('EDIT WORKOUT LOG')),
        const Offset(0, 650),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(find.byType(EditWorkoutSheet), findsOneWidget);
      hive.failDocuments = true;
      hive.documentGate!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save.'), findsOneWidget);
      expect(find.text('EDIT WORKOUT LOG'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == 'Edited pull',
        ),
        findsOneWidget,
      );
      hive.failDocuments = false;
      hive.documentGate = null;
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();
      expect(find.text('EDIT WORKOUT LOG'), findsNothing);
      final saved = container.read(historyWorkoutsProvider).single;
      expect(saved.name, 'Edited pull');
      expect(saved.notes, original.notes);
      expect(saved.trainingPlan, original.trainingPlan);
      expect(saved.exercises.first.supersetGroupId, 'pair');
      expect(saved.exercises.first.rpe, 8);
      expect(saved.exercises.first.sets.single.rpe, 7.5);
      expect(saved.exercises.first.sets.single.weightKg, 40);
      expect(saved.exercises.first.sets.single.weightKgRight, 36);
      expect(saved.exercises.first.sets.single.repsRight, 8);
      expect(saved.exercises.last.isWarmup, isTrue);
      expect(saved.exercises.last.sets.single.isWarmup, isTrue);
      expect(saved.totalVolumeKg, 688);
      expect(saved.averageRpe, 7.5);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'added unilateral sets keep both inputs; invalid reps do not drop a set',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hive = MemoryHiveService();
      await hive.put(
        AppConstants.hiveBoxWorkouts,
        original.id,
        original.toJson(),
      );
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(hive)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => EditWorkoutSheet.show(context, original),
                  child: const Text('Open editor'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'ADD SET').first);
      await tester.pumpAndSettle();
      Finder input(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      expect(input('Right kg'), findsNWidgets(2));
      await tester.enterText(input('Right kg').last, '30');
      await tester.enterText(input('Right reps').last, '0');
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save.'), findsOneWidget);
      expect(
        container.read(historyWorkoutsProvider).single.exercises.first.sets,
        hasLength(1),
      );
      expect(input('Right kg'), findsNWidgets(2));
      await tester.enterText(input('Right reps').last, '6');
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();
      final saved = container.read(historyWorkoutsProvider).single;
      expect(saved.exercises.first.sets, hasLength(2));
      expect(saved.exercises.first.sets.last.weightKgRight, 30);
      expect(saved.exercises.first.sets.last.repsRight, 6);
      expect(saved.totalVolumeKg, 1260);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed delete keeps the sheet and original workout available', (
    tester,
  ) async {
    final hive = MemoryHiveService();
    await hive.put(
      AppConstants.hiveBoxWorkouts,
      original.id,
      original.toJson(),
    );
    final container = ProviderContainer(
      overrides: [hiveServiceProvider.overrideWithValue(hive)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => EditWorkoutSheet.show(context, original),
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    hive.failDelete = true;
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'DELETE'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'DELETE'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'DELETE'));
    await tester.pumpAndSettle();
    expect(find.text('EDIT WORKOUT LOG'), findsOneWidget);
    expect(
      find.textContaining('Could not delete the workout.'),
      findsOneWidget,
    );
    expect(container.read(historyWorkoutsProvider).single.id, original.id);
    expect(tester.takeException(), isNull);
  });
}
