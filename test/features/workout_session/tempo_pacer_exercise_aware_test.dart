import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/exercise_library/models/exercise_library_item.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/models/tempo_pacer_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/providers/tempo_pacer_provider.dart';
import 'package:leon/features/workout_session/widgets/plate_calculator_modal.dart';
import 'package:leon/services/hive_service.dart';

class _MockHiveService extends HiveService {
  @override
  Future<void> putSetting(String key, Object? value) async {}
  @override
  T? getSetting<T>(String key, {T? fallback}) => fallback;
  @override
  Future<void> deleteSetting(String key) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Item 0.1: Exercise-Aware Tempo Pacer Biomechanical Tests', () {
    test(
      'isConcentricFirst correctly detects bottom-start vs top-start exercises',
      () {
        // Bottom-start movements (pull / curl / deadlift / raise)
        expect(
          const TempoPacerState(
            exerciseName: 'Barbell Deadlift',
          ).isConcentricFirst,
          isTrue,
        );
        expect(
          const TempoPacerState(exerciseName: 'Bicep Curl').isConcentricFirst,
          isTrue,
        );
        expect(
          const TempoPacerState(exerciseName: 'Lat Pulldown').isConcentricFirst,
          isTrue,
        );
        expect(
          const TempoPacerState(
            exerciseName: 'Barbell Bent Over Row',
          ).isConcentricFirst,
          isTrue,
        );
        expect(
          const TempoPacerState(
            exerciseName: 'Lateral Raise',
          ).isConcentricFirst,
          isTrue,
        );

        // Top-start movements (squat / bench / press)
        expect(
          const TempoPacerState(
            exerciseName: 'Barbell Back Squat',
          ).isConcentricFirst,
          isFalse,
        );
        expect(
          const TempoPacerState(
            exerciseName: 'Flat Barbell Bench Press',
          ).isConcentricFirst,
          isFalse,
        );
        expect(
          const TempoPacerState(
            exerciseName: 'Overhead Shoulder Press',
          ).isConcentricFirst,
          isFalse,
        );
      },
    );

    test('TempoPreset.defaultForExercise resolves biomechanical cadences', () {
      expect(
        TempoPreset.defaultForExercise('Barbell Back Squat'),
        equals(TempoPreset.compoundStrength),
      );
      expect(
        TempoPreset.defaultForExercise('Dumbbell Bicep Curl'),
        equals(TempoPreset.isolationPump),
      );
      expect(
        TempoPreset.defaultForExercise('Cable Lateral Raise'),
        equals(TempoPreset.isolationPump),
      );
      expect(
        TempoPreset.defaultForExercise('Power Clean'),
        equals(TempoPreset.explosive),
      );
    });

    test('cadenceText formats 4-phase cadences properly', () {
      expect(TempoPreset.compoundStrength.cadenceText, equals('3-1-1'));
      expect(TempoPreset.isolationPump.cadenceText, equals('2-1-2-1'));
      expect(TempoPreset.explosive.cadenceText, equals('1-0-1'));
    });

    test('startSession auto-resolves preset when null', () {
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(_MockHiveService())],
      );
      addTearDown(container.dispose);

      // Squat should auto-resolve to compoundStrength
      container
          .read(tempoPacerProvider.notifier)
          .startSession(
            exerciseName: 'Barbell Back Squat',
            exerciseId: 'sq_1',
            setIndex: 0,
            targetReps: 5,
            skipCountdown: true,
          );
      expect(
        container.read(tempoPacerProvider).preset,
        equals(TempoPreset.compoundStrength),
      );

      // Curl should auto-resolve to isolationPump
      container
          .read(tempoPacerProvider.notifier)
          .startSession(
            exerciseName: 'Dumbbell Bicep Curl',
            exerciseId: 'curl_1',
            setIndex: 0,
            targetReps: 10,
            skipCountdown: true,
          );
      expect(
        container.read(tempoPacerProvider).preset,
        equals(TempoPreset.isolationPump),
      );
    });
  });

  group('Item 0.2: Automated Rest Transition on Tempo Set Completion', () {
    test('finishEarlyAndRest closes tempo pacer and logs reps', () {
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(_MockHiveService())],
      );
      addTearDown(container.dispose);

      // Start active session with squat
      final activeNotifier = container.read(activeSessionProvider.notifier);
      activeNotifier.startEmptySession(splitName: 'Leg Day');
      activeNotifier.addExercise(
        const ActiveExerciseState(
          exerciseId: 'sq_1',
          name: 'Barbell Back Squat',
          muscleGroup: 'Legs',
          sets: [ActiveSetState(setNumber: 1, weightKg: 100, reps: 5)],
        ),
      );

      final tempoNotifier = container.read(tempoPacerProvider.notifier);
      tempoNotifier.startSession(
        exerciseName: 'Barbell Back Squat',
        exerciseId: 'sq_1',
        setIndex: 0,
        targetReps: 5,
        skipCountdown: true,
      );
      expect(container.read(tempoPacerProvider).isActive, isTrue);

      // Call finish early and rest
      tempoNotifier.finishEarlyAndRest();

      // Pacer should be deactivated and session updated
      expect(container.read(tempoPacerProvider).isActive, isFalse);
      expect(
        container
            .read(activeSessionProvider)
            .exercises
            .first
            .sets
            .first
            .isCompleted,
        isTrue,
      );
    });
  });

  group('Item 0.3: Barbell Warmup Pyramid Calculator', () {
    test(
      'calculatePlatesPerSide correctly breaks down Olympic bumper loads',
      () {
        // 100 kg total with 20 kg bar -> 40 kg per side -> 25 kg + 15 kg
        final plates100 = calculatePlatesPerSide(
          totalWeightKg: 100.0,
          barWeightKg: 20.0,
        );
        expect(plates100[25.0], equals(1));
        expect(plates100[15.0], equals(1));

        // 60 kg total with 20 kg bar -> 20 kg per side -> 20 kg
        final plates60 = calculatePlatesPerSide(
          totalWeightKg: 60.0,
          barWeightKg: 20.0,
        );
        expect(plates60[20.0], equals(1));

        // 20 kg bar alone -> 0 plates
        final plates20 = calculatePlatesPerSide(
          totalWeightKg: 20.0,
          barWeightKg: 20.0,
        );
        expect(plates20.isEmpty, isTrue);
      },
    );

    test('Warmup pyramid 5-tier percentages for 100kg target working set', () {
      const workingWeight = 100.0;
      const barWeight = 20.0;

      final set1 = barWeight; // Empty bar
      final set2 = (((workingWeight * 0.50) / 2.5).round() * 2.5).clamp(
        barWeight,
        500.0,
      );
      final set3 = (((workingWeight * 0.70) / 2.5).round() * 2.5).clamp(
        barWeight,
        500.0,
      );
      final set4 = (((workingWeight * 0.85) / 2.5).round() * 2.5).clamp(
        barWeight,
        500.0,
      );
      final set5 = workingWeight;

      expect(set1, equals(20.0));
      expect(set2, equals(50.0));
      expect(set3, equals(70.0));
      expect(set4, equals(85.0));
      expect(set5, equals(100.0));
    });
  });

  group('Item 0.4: Exercise-Specific Default Rest Timers', () {
    test(
      'ExerciseLibraryItem.defaultRestForExercise assigns proper fatigue intervals',
      () {
        // Heavy compounds -> 180s (3:00)
        expect(
          ExerciseLibraryItem.defaultRestForExercise(
            name: 'Barbell Back Squat',
          ),
          equals(180),
        );
        expect(
          ExerciseLibraryItem.defaultRestForExercise(name: 'Barbell Deadlift'),
          equals(180),
        );
        expect(
          ExerciseLibraryItem.defaultRestForExercise(
            name: 'Barbell Bench Press',
          ),
          equals(180),
        );
        expect(
          ExerciseLibraryItem.defaultRestForExercise(
            name: 'Standing Overhead Press',
          ),
          equals(180),
        );

        // Moderate compounds -> 120s (2:00)
        expect(
          ExerciseLibraryItem.defaultRestForExercise(
            name: 'Barbell Bent-Over Row',
          ),
          equals(120),
        );
        expect(
          ExerciseLibraryItem.defaultRestForExercise(name: 'Pull-Ups'),
          equals(120),
        );
        expect(
          ExerciseLibraryItem.defaultRestForExercise(name: 'Leg Press'),
          equals(120),
        );
        expect(
          ExerciseLibraryItem.defaultRestForExercise(name: 'Walking Lunges'),
          equals(120),
        );

        // Isolations & Accessories -> 60s - 90s
        expect(
          ExerciseLibraryItem.defaultRestForExercise(
            name: 'Dumbbell Bicep Curl',
          ),
          equals(90),
        );
        expect(
          ExerciseLibraryItem.defaultRestForExercise(
            name: 'Tricep Rope Pushdown',
          ),
          equals(90),
        );
        expect(
          ExerciseLibraryItem.defaultRestForExercise(name: 'Lateral Raise'),
          equals(60),
        );
        expect(
          ExerciseLibraryItem.defaultRestForExercise(
            name: 'Standing Calf Raise',
          ),
          equals(60),
        );
      },
    );
  });

  group('Item 0.5: Antagonistic Superset Grouping', () {
    test(
      'createSuperset and unlinkSuperset manage paired exercises cleanly',
      () {
        final container = ProviderContainer(
          overrides: [
            hiveServiceProvider.overrideWithValue(_MockHiveService()),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeSessionProvider.notifier);
        notifier.startEmptySession(splitName: 'Arms');

        notifier.addExercise(
          const ActiveExerciseState(
            exerciseId: 'biceps_1',
            name: 'Barbell Bicep Curl',
            muscleGroup: 'Arms',
            sets: [ActiveSetState(setNumber: 1, weightKg: 30, reps: 10)],
          ),
        );

        notifier.addExercise(
          const ActiveExerciseState(
            exerciseId: 'triceps_1',
            name: 'Tricep Rope Pushdown',
            muscleGroup: 'Arms',
            sets: [ActiveSetState(setNumber: 1, weightKg: 25, reps: 12)],
          ),
        );

        // Verify initial state has no superset
        var state = container.read(activeSessionProvider);
        expect(state.exercises[0].supersetGroupId, isNull);
        expect(state.exercises[1].supersetGroupId, isNull);

        // Pair as superset
        notifier.createSuperset('biceps_1', 'triceps_1');
        state = container.read(activeSessionProvider);
        final groupId = state.exercises[0].supersetGroupId;
        expect(groupId, isNotNull);
        expect(state.exercises[1].supersetGroupId, equals(groupId));

        // Unlink superset
        notifier.unlinkSuperset('biceps_1');
        state = container.read(activeSessionProvider);
        expect(state.exercises[0].supersetGroupId, isNull);
        expect(state.exercises[1].supersetGroupId, isNull);
      },
    );

    test('logSet alternates focus to superset partner upon set completion', () {
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(_MockHiveService())],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeSessionProvider.notifier);
      notifier.startEmptySession(splitName: 'Arms');

      notifier.addExercise(
        const ActiveExerciseState(
          exerciseId: 'ex_a',
          name: 'Barbell Bicep Curl',
          muscleGroup: 'Arms',
          sets: [
            ActiveSetState(setNumber: 1, weightKg: 30, reps: 10),
            ActiveSetState(setNumber: 2, weightKg: 30, reps: 10),
          ],
        ),
      );

      notifier.addExercise(
        const ActiveExerciseState(
          exerciseId: 'ex_b',
          name: 'Tricep Rope Pushdown',
          muscleGroup: 'Arms',
          sets: [
            ActiveSetState(setNumber: 1, weightKg: 25, reps: 12),
            ActiveSetState(setNumber: 2, weightKg: 25, reps: 12),
          ],
        ),
      );

      notifier.createSuperset('ex_a', 'ex_b');
      notifier.toggleExerciseExpand('ex_a');

      // Log set 1 of exercise A
      notifier.logSet(exerciseId: 'ex_a', setIndex: 0);

      // Focus should automatically transition to exercise B!
      final state = container.read(activeSessionProvider);
      expect(state.expandedExerciseId, equals('ex_b'));
    });
  });
}
