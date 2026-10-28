import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/features/workout_session/providers/rest_timer_provider.dart';
import 'package:leon/features/workout_session/services/live_activity_service.dart';
import 'package:leon/features/workout_session/services/notification_service.dart';

class _FakeWorkoutNotificationService extends WorkoutNotificationService {
  String? lastExerciseName;
  int? lastSetNumber;
  int? lastRemainingSeconds;
  int? lastTotalDuration;
  bool isRestNotificationActive = false;
  bool isAlertTriggered = false;
  bool lastIsWarmup = false;
  int alertCount = 0;
  bool allCancelled = false;

  @override
  Future<void> showRestTimerNotification({
    required String? exerciseName,
    required int? setNumber,
    bool isWarmup = false,
    required int remainingSeconds,
    required int totalDurationSeconds,
    DateTime? targetEndTime,
  }) async {
    lastExerciseName = exerciseName;
    lastSetNumber = setNumber;
    lastRemainingSeconds = remainingSeconds;
    lastTotalDuration = totalDurationSeconds;
    lastIsWarmup = isWarmup;
    isRestNotificationActive = true;
  }

  @override
  Future<void> showRestCompletedNotification({
    required String? exerciseName,
    required int? nextSetNumber,
    bool isWarmup = false,
  }) async {
    lastExerciseName = exerciseName;
    lastSetNumber = nextSetNumber;
    isRestNotificationActive = false;
    isAlertTriggered = true;
    lastIsWarmup = isWarmup;
    alertCount++;
  }

  @override
  Future<void> cancelRestNotification() async {
    isRestNotificationActive = false;
  }

  @override
  Future<void> cancelRestCompletedNotification() async {
    isAlertTriggered = false;
  }

  @override
  Future<void> cancelAll() async {
    allCancelled = true;
    isRestNotificationActive = false;
    isAlertTriggered = false;
  }
}

class _FakeLiveActivityService extends LiveActivityService {
  bool isActivityRunning = false;
  int? lastRemainingSeconds;
  String? lastExercise;
  int? lastTotalSets;

  @override
  Future<void> startLiveActivity({
    required String workoutTitle,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    required int remainingSeconds,
    required int totalDurationSeconds,
    double targetWeightKg = 0.0,
    int targetReps = 0,
    String plateBreakdown = '',
    bool isResting = true,
  }) async {
    isActivityRunning = true;
    lastRemainingSeconds = remainingSeconds;
    lastExercise = exerciseName;
    lastTotalSets = totalSets;
  }

  @override
  Future<void> updateLiveActivity({
    required int remainingSeconds,
    required int totalDurationSeconds,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
    double targetWeightKg = 0.0,
    int targetReps = 0,
    String plateBreakdown = '',
    bool isResting = true,
  }) async {
    lastRemainingSeconds = remainingSeconds;
    lastExercise = exerciseName;
    lastTotalSets = totalSets;
  }

  @override
  Future<void> stopLiveActivity() async {
    isActivityRunning = false;
  }
}

class _MemoryHive extends HiveService {
  final settings = <String, Object?>{};

  @override
  T? getSetting<T>(String key, {T? fallback}) =>
      settings[key] as T? ?? fallback;

  @override
  Future<void> putSettingChecked(String key, Object? value) async {
    settings[key] = value;
  }

  @override
  Future<void> deleteSettingChecked(String key) async {
    settings.remove(key);
  }
}

ActiveExerciseState _exercise(
  String id, {
  int count = 2,
  bool warmup = false,
  bool unilateral = false,
  String? superset,
}) => ActiveExerciseState(
  exerciseId: id,
  name: id,
  muscleGroup: 'pull',
  isUnilateral: unilateral,
  supersetGroupId: superset,
  sets: List.generate(
    count,
    (index) => ActiveSetState(
      setNumber: index + 1,
      weightKg: 20,
      reps: 10,
      isWarmup: warmup && index == 0,
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Epic 2: Lock Screen Live Activity & Persistent Notifications', () {
    late _FakeWorkoutNotificationService fakeNotifications;
    late _FakeLiveActivityService fakeLiveActivity;

    setUp(() {
      fakeNotifications = _FakeWorkoutNotificationService();
      fakeLiveActivity = _FakeLiveActivityService();
    });

    ProviderContainer startWorkout(List<ActiveExerciseState> exercises) {
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(_MemoryHive()),
          workoutNotificationServiceProvider.overrideWithValue(
            fakeNotifications,
          ),
          liveActivityServiceProvider.overrideWithValue(fakeLiveActivity),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeSessionProvider.notifier)
          .startSession(initialExercises: exercises);
      return container;
    }

    test('set 2 of 2 points to the next exercise, never set 3', () {
      final c = startWorkout([_exercise('Row'), _exercise('Pulldown')]);
      final session = c.read(activeSessionProvider.notifier);
      final rest = c.read(restTimerProvider.notifier);
      session.logSet(exerciseId: 'Row', setIndex: 0);
      expect(fakeNotifications.lastSetNumber, 2);
      expect(fakeLiveActivity.lastTotalSets, 2);
      rest.addSeconds(-9999);
      expect(fakeNotifications.lastExerciseName, 'Row');
      expect(fakeNotifications.lastSetNumber, 2);
      session.logSet(exerciseId: 'Row', setIndex: 1);
      expect(fakeNotifications.isAlertTriggered, isFalse);
      expect(fakeNotifications.lastExerciseName, 'Pulldown');
      expect(fakeNotifications.lastSetNumber, 1);
      rest.addSeconds(-9999);
      expect(fakeNotifications.lastExerciseName, 'Pulldown');
      expect(fakeNotifications.lastSetNumber, 1);
      expect(fakeNotifications.isAlertTriggered, isTrue);
    });

    test('finishing every set clears an earlier countdown and its alerts', () {
      final c = startWorkout([_exercise('Row')]);
      final session = c.read(activeSessionProvider.notifier);
      session.logSet(exerciseId: 'Row', setIndex: 0);
      session.logSet(exerciseId: 'Row', setIndex: 1);
      expect(c.read(restTimerProvider).isRunning, isFalse);
      expect(fakeNotifications.allCancelled, isTrue);
      expect(c.read(activeSessionProvider).nextPendingSet(), isNull);
      c.read(restTimerProvider.notifier).addSeconds(30);
      c.read(restTimerProvider.notifier).resyncWithWallClock();
      expect(c.read(restTimerProvider).isRunning, isFalse);
      expect(fakeNotifications.alertCount, 0);
    });

    test('out-of-order logging selects a real unfinished set', () {
      final c = startWorkout([_exercise('Row'), _exercise('Pulldown')]);
      c
          .read(activeSessionProvider.notifier)
          .logSet(exerciseId: 'Row', setIndex: 1);
      c.read(restTimerProvider.notifier).addSeconds(-9999);
      expect(fakeNotifications.lastExerciseName, 'Row');
      expect(fakeNotifications.lastSetNumber, 1);
    });

    test('warmups are identified and working set numbers match the table', () {
      final c = startWorkout([
        _exercise('Pulldown', count: 3, warmup: true),
        _exercise('Row'),
      ]);
      final rest = c.read(restTimerProvider.notifier);
      rest.startTimer(durationSeconds: 90);
      expect(fakeNotifications.lastIsWarmup, isTrue);
      expect(fakeNotifications.lastSetNumber, 1);
      c
          .read(activeSessionProvider.notifier)
          .logSet(exerciseId: 'Pulldown', setIndex: 0);
      expect(fakeNotifications.lastIsWarmup, isFalse);
      expect(fakeNotifications.lastSetNumber, 2);
      expect(fakeLiveActivity.lastTotalSets, 3);
      c
          .read(activeSessionProvider.notifier)
          .logSet(exerciseId: 'Pulldown', setIndex: 1);
      c
          .read(activeSessionProvider.notifier)
          .logSet(exerciseId: 'Pulldown', setIndex: 2);
      rest.addSeconds(-9999);
      expect(fakeNotifications.lastExerciseName, 'Row');
      expect(fakeNotifications.lastSetNumber, 1);
    });

    for (final unilateral in [false, true]) {
      test('superset rest targets the partner (unilateral: $unilateral)', () {
        final c = startWorkout([
          _exercise('Row', unilateral: unilateral, superset: 'pair'),
          _exercise('Press', superset: 'pair'),
        ]);
        final session = c.read(activeSessionProvider.notifier);
        if (unilateral) {
          session.logSetSide(exerciseId: 'Row', setIndex: 0, isLeft: true);
          expect(c.read(restTimerProvider).isRunning, isFalse);
          session.logSetSide(exerciseId: 'Row', setIndex: 0, isLeft: false);
        } else {
          session.logSet(exerciseId: 'Row', setIndex: 0);
        }
        c.read(restTimerProvider.notifier).addSeconds(-9999);
        expect(fakeNotifications.lastExerciseName, 'Press');
        expect(fakeNotifications.lastSetNumber, 1);
      });
    }

    test(
      'undoing the source set cancels rest even after an exercise transition',
      () {
        final c = startWorkout([
          _exercise('Row', count: 1),
          _exercise('Press'),
        ]);
        final session = c.read(activeSessionProvider.notifier);
        session.logSet(exerciseId: 'Row', setIndex: 0);
        c.read(restTimerProvider.notifier).pause();
        session.logSet(exerciseId: 'Row', setIndex: 0);
        expect(c.read(restTimerProvider).remainingSeconds, 0);
        expect(fakeNotifications.isRestNotificationActive, isFalse);
      },
    );

    test(
      'removing the next exercise revalidates before the completion alert',
      () {
        final c = startWorkout([
          _exercise('Row', count: 1),
          _exercise('Press'),
          _exercise('Curl'),
        ]);
        final session = c.read(activeSessionProvider.notifier);
        session.logSet(exerciseId: 'Row', setIndex: 0);
        session.removeExercise('Press');
        c.read(restTimerProvider.notifier).addSeconds(-9999);
        expect(fakeNotifications.lastExerciseName, 'Curl');
        expect(fakeNotifications.lastSetNumber, 1);
      },
    );

    test(
      'discarding the workout clears countdown and completion notifications',
      () async {
        final c = startWorkout([_exercise('Row')]);
        final session = c.read(activeSessionProvider.notifier);
        session.logSet(exerciseId: 'Row', setIndex: 0);
        c.read(restTimerProvider.notifier).addSeconds(-9999);
        await session.discardSession();
        expect(fakeNotifications.allCancelled, isTrue);
        expect(fakeNotifications.isAlertTriggered, isFalse);
        expect(c.read(restTimerProvider).isRunning, isFalse);
      },
    );

    test('manual rest starts with fresh context', () {
      final c = startWorkout([_exercise('Row')]);
      final rest = c.read(restTimerProvider.notifier);
      c
          .read(activeSessionProvider.notifier)
          .logSet(exerciseId: 'Row', setIndex: 0);
      rest.skip();
      rest.startTimer(durationSeconds: 90);
      expect(c.read(restTimerProvider).sourceExerciseId, isNull);
      expect(fakeNotifications.lastSetNumber, 2);
    });

    test(
      'Starting rest timer triggers persistent notification and Live Activity',
      () {
        final container = ProviderContainer(
          overrides: [
            workoutNotificationServiceProvider.overrideWithValue(
              fakeNotifications,
            ),
            liveActivityServiceProvider.overrideWithValue(fakeLiveActivity),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(restTimerProvider.notifier);

        // Start 90s rest timer for Incline Dumbbell Press Set 2
        notifier.startTimer(
          durationSeconds: 90,
          exerciseName: 'Incline Dumbbell Press',
          setNumber: 2,
          totalSets: 4,
          targetWeightKg: 32.0,
          targetReps: 10,
          plateBreakdown: 'Dumbbells',
        );

        final state = container.read(restTimerProvider);
        expect(state.isRunning, isTrue);
        expect(state.remainingSeconds, 90);
        expect(state.exerciseName, 'Incline Dumbbell Press');

        // Notification service was invoked
        expect(fakeNotifications.isRestNotificationActive, isTrue);
        expect(fakeNotifications.lastExerciseName, 'Incline Dumbbell Press');
        expect(fakeNotifications.lastSetNumber, 2);
        expect(fakeNotifications.lastRemainingSeconds, 90);

        // Live Activity was invoked
        expect(fakeLiveActivity.isActivityRunning, isTrue);
        expect(fakeLiveActivity.lastExercise, 'Incline Dumbbell Press');
        expect(fakeLiveActivity.lastRemainingSeconds, 90);

        notifier.skip();
      },
    );

    test(
      'Interactive notification action "+30s" increments timer duration and updates notification',
      () {
        final container = ProviderContainer(
          overrides: [
            workoutNotificationServiceProvider.overrideWithValue(
              fakeNotifications,
            ),
            liveActivityServiceProvider.overrideWithValue(fakeLiveActivity),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(restTimerProvider.notifier);

        notifier.startTimer(
          durationSeconds: 60,
          exerciseName: 'Barbell Bench Press',
          setNumber: 3,
        );

        expect(container.read(restTimerProvider).remainingSeconds, 60);

        // Simulate tapping "+30s" on the Android notification action button
        fakeNotifications.onActionTapped?.call('add_30');

        expect(container.read(restTimerProvider).remainingSeconds, 90);
        expect(fakeNotifications.lastRemainingSeconds, 90);

        notifier.skip();
      },
    );

    test(
      'Interactive notification action "Skip Rest" dismisses notification and terminates Live Activity',
      () {
        final container = ProviderContainer(
          overrides: [
            workoutNotificationServiceProvider.overrideWithValue(
              fakeNotifications,
            ),
            liveActivityServiceProvider.overrideWithValue(fakeLiveActivity),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(restTimerProvider.notifier);

        notifier.startTimer(
          durationSeconds: 60,
          exerciseName: 'Barbell Squat',
          setNumber: 1,
        );

        expect(fakeNotifications.isRestNotificationActive, isTrue);
        expect(fakeLiveActivity.isActivityRunning, isTrue);

        // Simulate tapping "Skip Rest" on the notification action button
        fakeNotifications.onActionTapped?.call('skip_rest');

        expect(container.read(restTimerProvider).remainingSeconds, 0);
        expect(container.read(restTimerProvider).isRunning, isFalse);
        expect(fakeNotifications.isRestNotificationActive, isFalse);
        expect(fakeLiveActivity.isActivityRunning, isFalse);
      },
    );

    test(
      'MethodChannel bridge invocation for LiveActivityService handles calls gracefully',
      () async {
        const channel = MethodChannel('leon/live_activity');
        final log = <MethodCall>[];

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              log.add(methodCall);
              if (methodCall.method == 'areActivitiesEnabled') {
                return true;
              }
              if (methodCall.method == 'startLiveActivity') {
                return 'activity-12345';
              }
              return true;
            });

        final service = LiveActivityService();

        await service.startLiveActivity(
          workoutTitle: "TODAY'S WORKOUT",
          exerciseName: 'Deadlift',
          setNumber: 1,
          totalSets: 3,
          remainingSeconds: 120,
          totalDurationSeconds: 120,
        );

        await service.updateLiveActivity(
          remainingSeconds: 110,
          totalDurationSeconds: 120,
          exerciseName: 'Deadlift',
          setNumber: 1,
          totalSets: 3,
        );

        await service.stopLiveActivity();

        // Ensure proper method calls were dispatched
        expect(service.currentActivityId, isNull);
      },
    );
  });
}
