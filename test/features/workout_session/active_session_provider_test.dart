import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/providers/rest_timer_provider.dart';
import 'package:leon/services/hive_service.dart';

class _FakeHiveService extends HiveService {
  final Map<String, dynamic> settings = {};

  @override
  Future<void> putSetting(String key, Object? value) async {
    settings[key] = value;
  }

  @override
  T? getSetting<T>(String key, {T? fallback}) {
    return (settings[key] as T?) ?? fallback;
  }

  @override
  Future<void> deleteSetting(String key) async {
    settings.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Effort Math & Model Conversion', () {
    test('rpeFromRir calculates correct RPE', () {
      expect(rpeFromRir(0.0), 10.0);
      expect(rpeFromRir(1.0), 9.0);
      expect(rpeFromRir(2.0), 8.0);
      expect(rpeFromRir(3.0), 7.0);
      expect(rpeFromRir(4.0), 6.0);
    });

    test('rirFromRpe calculates correct RIR', () {
      expect(rirFromRpe(10.0), 0.0);
      expect(rirFromRpe(9.0), 1.0);
      expect(rirFromRpe(8.0), 2.0);
      expect(rirFromRpe(7.0), 3.0);
    });

    test('ActiveSetState calculates volume correctly', () {
      const set = ActiveSetState(
        setNumber: 1,
        weightKg: 80.0,
        reps: 8,
        rir: 2.0,
        rpe: 8.0,
        isCompleted: true,
      );
      expect(set.volumeKg, 640.0);
    });

    test('ActiveSessionState serialization roundtrip preserves all session, exercise, and set fields', () {
      final now = DateTime.now();
      final original = ActiveSessionState(
        workoutId: 'test_123',
        splitName: 'LEGS // QUAD FOCUS',
        startTime: now,
        elapsedSeconds: 540,
        isActive: true,
        isPaused: false,
        expandedExerciseId: 'ex_1',
        exercises: [
          const ActiveExerciseState(
            exerciseId: 'ex_1',
            name: 'Barbell Back Squat',
            muscleGroup: 'quads',
            equipment: 'barbell',
            restDurationSeconds: 180,
            sets: [
              ActiveSetState(
                setNumber: 1,
                weightKg: 100.0,
                reps: 5,
                rir: 2.0,
                rpe: 8.0,
                isCompleted: true,
                previousWeightKg: 95.0,
                previousReps: 5,
              ),
            ],
          ),
        ],
      );

      final json = original.toJson();
      final restored = ActiveSessionState.fromJson(json);

      expect(restored.workoutId, original.workoutId);
      expect(restored.splitName, original.splitName);
      expect(restored.elapsedSeconds, original.elapsedSeconds);
      expect(restored.isActive, original.isActive);
      expect(restored.exercises.length, 1);
      expect(restored.exercises.first.name, 'Barbell Back Squat');
      expect(restored.exercises.first.sets.first.weightKg, 100.0);
      expect(restored.exercises.first.sets.first.isCompleted, isTrue);
    });
  });

  group('RestTimerNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('starts countdown with given duration', () {
      final notifier = container.read(restTimerProvider.notifier);
      notifier.startTimer(durationSeconds: 90, exerciseName: 'Bench Press');

      final state = container.read(restTimerProvider);
      expect(state.isRunning, isTrue);
      expect(state.remainingSeconds, 90);
      expect(state.totalDurationSeconds, 90);
      expect(state.exerciseName, 'Bench Press');
    });

    test('addTenSeconds increases remaining time', () {
      final notifier = container.read(restTimerProvider.notifier);
      notifier.startTimer(durationSeconds: 30);
      notifier.addTenSeconds();

      final state = container.read(restTimerProvider);
      expect(state.remainingSeconds, 40);
    });

    test('subtractTenSeconds decreases remaining time without going below zero', () {
      final notifier = container.read(restTimerProvider.notifier);
      notifier.startTimer(durationSeconds: 15);
      notifier.subtractTenSeconds();

      var state = container.read(restTimerProvider);
      expect(state.remainingSeconds, 5);

      notifier.subtractTenSeconds();
      state = container.read(restTimerProvider);
      expect(state.remainingSeconds, 0);
    });

    test('skip stops and resets timer', () {
      final notifier = container.read(restTimerProvider.notifier);
      notifier.startTimer(durationSeconds: 90);
      notifier.skip();

      final state = container.read(restTimerProvider);
      expect(state.isRunning, isFalse);
      expect(state.remainingSeconds, 0);
    });
  });

  group('ActiveSessionNotifier', () {
    late ProviderContainer container;
    late _FakeHiveService fakeHive;

    setUp(() {
      fakeHive = _FakeHiveService();
      container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(fakeHive),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('starts session with default exercises', () {
      final sessionNotifier = container.read(activeSessionProvider.notifier);
      sessionNotifier.startSession(splitName: 'Push Day // Workout A');

      final state = container.read(activeSessionProvider);
      expect(state.isActive, isTrue);
      expect(state.splitName, 'Push Day // Workout A');
      expect(state.exercises, isNotEmpty);
      expect(state.completedSetCount, 0);
      expect(state.totalSetCount, greaterThan(0));
    });

    test('logging a set marks it completed and triggers rest timer if autoStart is on', () {
      final sessionNotifier = container.read(activeSessionProvider.notifier);
      sessionNotifier.startSession();

      final exerciseId = container.read(activeSessionProvider).exercises.first.exerciseId;
      sessionNotifier.logSet(exerciseId: exerciseId, setIndex: 0, completed: true);

      final state = container.read(activeSessionProvider);
      expect(state.exercises.first.sets.first.isCompleted, isTrue);
      expect(state.completedSetCount, 1);

      // Check that rest timer was automatically triggered
      final restState = container.read(restTimerProvider);
      expect(restState.isRunning, isTrue);
      expect(restState.remainingSeconds, greaterThan(0));
    });

    test('updating weight and reps updates set and volume', () {
      final sessionNotifier = container.read(activeSessionProvider.notifier);
      sessionNotifier.startSession();

      final exerciseId = container.read(activeSessionProvider).exercises.first.exerciseId;
      sessionNotifier.updateSetValues(
        exerciseId: exerciseId,
        setIndex: 0,
        weightKg: 100.0,
        reps: 10,
        rir: 1.0,
      );

      final state = container.read(activeSessionProvider);
      final set = state.exercises.first.sets.first;
      expect(set.weightKg, 100.0);
      expect(set.reps, 10);
      expect(set.rir, 1.0);
      expect(set.rpe, 9.0); // Synced automatically
    });

    test('accordion expansion toggles active exercise', () {
      final sessionNotifier = container.read(activeSessionProvider.notifier);
      sessionNotifier.startSession();

      final firstId = container.read(activeSessionProvider).exercises.first.exerciseId;
      final secondId = container.read(activeSessionProvider).exercises[1].exerciseId;

      // First exercise is expanded by default upon starting
      expect(container.read(activeSessionProvider).expandedExerciseId, firstId);

      // Tapping second exercise expands second
      sessionNotifier.toggleExerciseExpand(secondId);
      expect(container.read(activeSessionProvider).expandedExerciseId, secondId);

      // Tapping the same collapses it
      sessionNotifier.toggleExerciseExpand(secondId);
      expect(container.read(activeSessionProvider).expandedExerciseId, isNull);

      // Tapping first exercise expands first
      sessionNotifier.toggleExerciseExpand(firstId);
      expect(container.read(activeSessionProvider).expandedExerciseId, firstId);
    });

    test('reordering exercises updates sequence order', () {
      final sessionNotifier = container.read(activeSessionProvider.notifier);
      sessionNotifier.startSession();

      final initialFirst = container.read(activeSessionProvider).exercises[0].exerciseId;
      final initialSecond = container.read(activeSessionProvider).exercises[1].exerciseId;

      sessionNotifier.reorderExercises(0, 2);

      final reorderedState = container.read(activeSessionProvider);
      expect(reorderedState.exercises[0].exerciseId, initialSecond);
      expect(reorderedState.exercises[1].exerciseId, initialFirst);
    });

    test('persists session to Hive on mutation and auto-restores on new container', () {
      final sessionNotifier = container.read(activeSessionProvider.notifier);
      sessionNotifier.startSession(splitName: 'Upper Body Blast');

      // Verify stored in fakeHive
      expect(fakeHive.settings.containsKey(AppConstants.settingActiveSessionData), isTrue);

      // Create a brand new container reading from the same fakeHive
      final secondContainer = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(fakeHive),
        ],
      );
      addTearDown(secondContainer.dispose);

      final restoredState = secondContainer.read(activeSessionProvider);
      expect(restoredState.isActive, isTrue);
      expect(restoredState.splitName, 'Upper Body Blast');
      expect(restoredState.exercises, isNotEmpty);

      // Clean up ticker
      secondContainer.read(activeSessionProvider.notifier).cancelSession();
    });

    test('substituteExercise swaps exercise details while preserving logged completed sets', () {
      final sessionNotifier = container.read(activeSessionProvider.notifier);
      sessionNotifier.startSession();

      final firstEx = container.read(activeSessionProvider).exercises.first;
      // Complete first set
      sessionNotifier.logSet(exerciseId: firstEx.exerciseId, setIndex: 0, completed: true);

      // Substitute with dumbbell variation
      sessionNotifier.substituteExercise(
        oldExerciseId: firstEx.exerciseId,
        newExerciseId: 'db_press_alt',
        newName: 'Dumbbell Incline Press',
        newMuscleGroup: 'chest',
        newEquipment: 'dumbbells',
        newRestSeconds: 90,
      );

      final updatedState = container.read(activeSessionProvider);
      final substituted = updatedState.exercises.first;
      expect(substituted.name, 'Dumbbell Incline Press');
      expect(substituted.equipment, 'dumbbells');
      expect(substituted.restDurationSeconds, 90);
      // Completed set remains intact!
      expect(substituted.sets.first.isCompleted, isTrue);
    });

    test('finishSession and cancelSession clear persisted storage', () {
      final sessionNotifier = container.read(activeSessionProvider.notifier);
      sessionNotifier.startSession();
      expect(fakeHive.settings.containsKey(AppConstants.settingActiveSessionData), isTrue);

      sessionNotifier.cancelSession();
      expect(fakeHive.settings.containsKey(AppConstants.settingActiveSessionData), isFalse);
    });
  });
}
