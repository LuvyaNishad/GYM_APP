import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/providers/rest_timer_provider.dart';

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

    setUp(() {
      container = ProviderContainer();
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
  });
}
