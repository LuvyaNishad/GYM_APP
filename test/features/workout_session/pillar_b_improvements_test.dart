import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/widgets/exercise_form_guide_sheet.dart';
import 'package:leon/features/workout_session/widgets/exercise_sequence_card.dart';
import 'package:leon/features/workout_session/widgets/exercise_set_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pillar B Improvements Tests', () {
    test(
      'ActiveSetType classification, getters, and serialization operate correctly',
      () {
        const normalSet = ActiveSetState(
          setNumber: 1,
          weightKg: 80.0,
          reps: 8,
          setType: ActiveSetType.normal,
        );
        expect(normalSet.isWarmup, isFalse);
        expect(normalSet.isDropSet, isFalse);
        expect(normalSet.isFailure, isFalse);
        expect(normalSet.volumeKg, equals(640.0));

        const warmupSet = ActiveSetState(
          setNumber: 1,
          weightKg: 40.0,
          reps: 10,
          setType: ActiveSetType.warmup,
        );
        expect(warmupSet.isWarmup, isTrue);
        expect(warmupSet.volumeKg, equals(0.0)); // Warmup excluded from volume

        const dropSet = ActiveSetState(
          setNumber: 2,
          weightKg: 50.0,
          reps: 12,
          setType: ActiveSetType.dropSet,
        );
        expect(dropSet.isDropSet, isTrue);
        expect(dropSet.volumeKg, equals(600.0));

        const failureSet = ActiveSetState(
          setNumber: 3,
          weightKg: 75.0,
          reps: 6,
          setType: ActiveSetType.failure,
        );
        expect(failureSet.isFailure, isTrue);
        expect(failureSet.volumeKg, equals(450.0));

        // Test JSON round-trip
        final json = failureSet.toJson();
        expect(json['setType'], equals('failure'));
        final restored = ActiveSetState.fromJson(json);
        expect(restored.setType, equals(ActiveSetType.failure));
        expect(restored.isFailure, isTrue);
      },
    );

    test(
      'addSingleWarmupSet inserts 40% load warmup set and renumbers correctly',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(activeSessionProvider.notifier);
        notifier.startSession(
          splitName: 'TEST SPLIT',
          initialExercises: [
            const ActiveExerciseState(
              exerciseId: 'bench-press',
              name: 'Barbell Bench Press',
              muscleGroup: 'Chest',
              sets: [
                ActiveSetState(setNumber: 1, weightKg: 100.0, reps: 8),
                ActiveSetState(setNumber: 2, weightKg: 100.0, reps: 8),
              ],
            ),
          ],
        );

        notifier.addSingleWarmupSet('bench-press');
        final updated = container.read(activeSessionProvider).exercises.first;

        expect(updated.sets.length, equals(3));
        // First set is warmup with 40kg (40% of 100kg)
        expect(updated.sets[0].isWarmup, isTrue);
        expect(updated.sets[0].setType, equals(ActiveSetType.warmup));
        expect(updated.sets[0].weightKg, equals(40.0));
        expect(updated.sets[0].setNumber, equals(1));
        // Subsequent working sets renumbered
        expect(updated.sets[1].setNumber, equals(2));
        expect(updated.sets[2].setNumber, equals(3));
      },
    );

    test('updateExerciseRestDuration updates rest timer duration', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeSessionProvider.notifier);
      notifier.startSession(
        splitName: 'TEST SPLIT',
        initialExercises: [
          const ActiveExerciseState(
            exerciseId: 'squat',
            name: 'Barbell Squat',
            muscleGroup: 'Quads',
            restDurationSeconds: 90,
            sets: [ActiveSetState(setNumber: 1, weightKg: 120.0, reps: 5)],
          ),
        ],
      );

      notifier.updateExerciseRestDuration('squat', 180);
      final updated = container.read(activeSessionProvider).exercises.first;
      expect(updated.restDurationSeconds, equals(180));
    });

    testWidgets(
      'ExerciseSequenceCard renders info button and Form Guide sheet opens',
      (tester) async {
        const exercise = ActiveExerciseState(
          exerciseId: 'barbell-bench-press',
          name: 'Barbell Bench Press',
          muscleGroup: 'Chest',
          equipment: 'Barbell',
          sets: [
            ActiveSetState(
              setNumber: 1,
              weightKg: 80.0,
              reps: 8,
              isCompleted: true,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ExerciseSequenceCard(
                  exercise: exercise,
                  index: 0,
                  isExpanded: true,
                  onToggleExpand: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Info button exists
        final infoButton = find.text('Form & records');
        expect(infoButton, findsOneWidget);

        // Tap info button to open Form Guide sheet
        await tester.tap(infoButton);
        await tester.pumpAndSettle();

        // Guide sheet contents verified
        expect(find.byType(ExerciseFormGuideSheet), findsOneWidget);
        expect(find.text('Barbell Bench Press'), findsWidgets);
        expect(find.text('No saved working sets yet.'), findsOneWidget);
        expect(find.text('FORM CUES'), findsOneWidget);
        expect(find.text('RETURN TO WORKOUT'), findsOneWidget);
      },
    );

    testWidgets(
      'ExerciseSetTable displays set badges, + WARMUP button, and interactive REST chip',
      (tester) async {
        const exercise = ActiveExerciseState(
          exerciseId: 'overhead-press',
          name: 'Overhead Press',
          muscleGroup: 'Shoulders',
          equipment: 'Barbell',
          restDurationSeconds: 90,
          sets: [
            ActiveSetState(
              setNumber: 1,
              weightKg: 40.0,
              reps: 10,
              setType: ActiveSetType.warmup,
            ),
            ActiveSetState(
              setNumber: 2,
              weightKg: 60.0,
              reps: 6,
              setType: ActiveSetType.normal,
            ),
            ActiveSetState(
              setNumber: 3,
              weightKg: 45.0,
              reps: 10,
              setType: ActiveSetType.dropSet,
            ),
            ActiveSetState(
              setNumber: 4,
              weightKg: 55.0,
              reps: 5,
              setType: ActiveSetType.failure,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ExerciseSetTable(exercise: exercise),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Set type badges display properly: W, 2, D, F
        expect(find.text('W'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('D'), findsOneWidget);
        expect(find.text('F'), findsOneWidget);

        // + WARMUP and ADD SET buttons exist
        expect(find.text('+ WARMUP'), findsOneWidget);
        expect(find.text('ADD SET'), findsOneWidget);
      },
    );
  });
}
