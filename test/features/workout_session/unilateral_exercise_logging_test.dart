import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  group('Unilateral Exercise Logging Tests', () {
    late ProviderContainer container;
    late _FakeHiveService fakeHive;

    setUp(() {
      fakeHive = _FakeHiveService();
      container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(fakeHive)],
      );
    });

    tearDown(() {
      container.read(activeSessionProvider.notifier).cancelSession();
      container.read(restTimerProvider.notifier).skip();
      container.dispose();
    });

    test(
      'User can toggle an exercise between Unilateral and Bilateral mode',
      () {
        final notifier = container.read(activeSessionProvider.notifier);
        notifier.startSession();

        final initialExercise = container
            .read(activeSessionProvider)
            .exercises
            .first;
        expect(initialExercise.isUnilateral, isFalse);

        // Toggle to Unilateral
        notifier.toggleUnilateral(initialExercise.exerciseId);
        final unilateralEx = container
            .read(activeSessionProvider)
            .exercises
            .first;
        expect(unilateralEx.isUnilateral, isTrue);
        // Right weights and reps should be initialized from Left
        expect(
          unilateralEx.sets.first.weightKgRight,
          equals(unilateralEx.sets.first.weightKg),
        );
        expect(
          unilateralEx.sets.first.repsRight,
          equals(unilateralEx.sets.first.reps),
        );

        // Toggle back to Bilateral
        notifier.toggleUnilateral(initialExercise.exerciseId);
        final bilateralEx = container
            .read(activeSessionProvider)
            .exercises
            .first;
        expect(bilateralEx.isUnilateral, isFalse);
      },
    );

    test(
      'Option A Two-Stage Logging: Left side completion does not trigger rest timer; Right side completion does',
      () {
        final notifier = container.read(activeSessionProvider.notifier);
        notifier.startSession();

        final exercise = container.read(activeSessionProvider).exercises.first;
        notifier.toggleUnilateral(exercise.exerciseId);

        // Log Left side for Set 1
        notifier.logSetSide(
          exerciseId: exercise.exerciseId,
          setIndex: 0,
          isLeft: true,
        );

        var currentExercise = container
            .read(activeSessionProvider)
            .exercises
            .first;
        var currentSet = currentExercise.sets.first;
        expect(currentSet.isLeftCompleted, isTrue);
        expect(currentSet.isRightCompleted, isFalse);
        expect(currentSet.isCompleted, isFalse);
        // Rest timer should NOT be running yet
        expect(container.read(restTimerProvider).isRunning, isFalse);

        // Now log Right side for Set 1
        notifier.logSetSide(
          exerciseId: exercise.exerciseId,
          setIndex: 0,
          isLeft: false,
        );

        currentExercise = container.read(activeSessionProvider).exercises.first;
        currentSet = currentExercise.sets.first;
        expect(currentSet.isLeftCompleted, isTrue);
        expect(currentSet.isRightCompleted, isTrue);
        expect(currentSet.isCompleted, isTrue);

        // Rest timer should now be running!
        expect(container.read(restTimerProvider).isRunning, isTrue);
        expect(
          container.read(restTimerProvider).remainingSeconds,
          greaterThan(0),
        );
      },
    );

    test(
      'Independent weights and reps can be logged for Left and Right sides',
      () {
        final notifier = container.read(activeSessionProvider.notifier);
        notifier.startSession();

        final exercise = container.read(activeSessionProvider).exercises.first;
        notifier.toggleUnilateral(exercise.exerciseId);

        // Update Left to 12.5 kg x 10 reps, Right to 15.0 kg x 12 reps
        notifier.updateSetValues(
          exerciseId: exercise.exerciseId,
          setIndex: 0,
          weightKg: 12.5,
          reps: 10,
          weightKgRight: 15.0,
          repsRight: 12,
        );

        final currentSet = container
            .read(activeSessionProvider)
            .exercises
            .first
            .sets
            .first;
        expect(currentSet.weightKg, 12.5);
        expect(currentSet.reps, 10);
        expect(currentSet.weightKgRight, 15.0);
        expect(currentSet.repsRight, 12);

        // Volume must sum both sides: (12.5 * 10) + (15.0 * 12) = 125 + 180 = 305 kg
        expect(currentSet.volumeKg, 305.0);
      },
    );
  });
}
