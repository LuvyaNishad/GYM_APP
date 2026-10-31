import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/features/exercise_library/models/exercise_library_item.dart';
import 'package:leon/features/exercise_library/repositories/exercise_repository.dart';
import 'package:leon/features/exercise_library/providers/exercise_library_provider.dart';
import 'package:leon/features/exercise_library/screens/exercise_detail_screen.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/models/workout_model.dart';
import '../../helpers/memory_hive_service.dart';

void main() {
  testWidgets(
    'custom edit retries with the same ID and removal retains routine/history snapshots',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hive = MemoryHiveService();
      final repository = ExerciseRepository(hive: hive)..setCatalog([]);
      const custom = ExerciseLibraryItem(
        id: 'custom_row',
        name: 'Custom row',
        category: 'Back',
        description: 'Original description',
        instructions: ['First cue', 'Second cue'],
        isCustom: true,
      );
      await repository.addCustomExercise(custom);
      await hive.put(AppConstants.hiveBoxSplits, 'routine', {
        'exerciseId': custom.id,
        'exerciseName': custom.name,
      });
      await hive.put(
        AppConstants.hiveBoxWorkouts,
        'log',
        WorkoutModel(
          id: 'log',
          userId: 'guest',
          name: 'Pull',
          date: DateTime(2026, 10, 1),
          exercises: [
            WorkoutExercise(
              exerciseId: custom.id,
              exerciseName: custom.name,
              muscleGroup: 'Back',
            ),
          ],
        ).toJson(),
      );
      final routine = Map.of(hive.documents[AppConstants.hiveBoxSplits]!);
      final log = Map.of(hive.documents[AppConstants.hiveBoxWorkouts]!);
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(hive),
          exerciseRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const ExerciseDetailScreen(exercise: custom),
                    ),
                  ),
                  child: const Text('Open custom'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open custom'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Custom exercise actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit custom exercise'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Renamed row');
      hive.failDocuments = true;
      await tester.ensureVisible(find.text('SAVE CUSTOM EXERCISE'));
      await tester.tap(find.text('SAVE CUSTOM EXERCISE'));
      await tester.pumpAndSettle();
      expect(find.text('EDIT CUSTOM EXERCISE'), findsOneWidget);
      expect(
        find.textContaining('Could not save the exercise.'),
        findsOneWidget,
      );
      expect(repository.getById(custom.id)!.name, 'Custom row');
      hive.failDocuments = false;
      await tester.tap(find.text('SAVE CUSTOM EXERCISE'));
      await tester.pumpAndSettle();
      expect(repository.getById(custom.id)!.name, 'Renamed row');
      expect(
        repository.getById(custom.id)!.description,
        'Original description',
      );
      expect(repository.getById(custom.id)!.instructions, [
        'First cue',
        'Second cue',
      ]);
      expect(repository.allExercises, hasLength(1));
      await tester.tap(find.byTooltip('Custom exercise actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REMOVE'));
      await tester.pumpAndSettle();
      expect(repository.getById(custom.id), isNull);
      expect(hive.documents[AppConstants.hiveBoxSplits], routine);
      expect(hive.documents[AppConstants.hiveBoxWorkouts], log);
      expect(find.text('Open custom'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
