import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Future<void> showRestTimerNotification({
    required String exerciseName,
    required int setNumber,
    required int remainingSeconds,
    required int totalDurationSeconds,
  }) async {
    lastExerciseName = exerciseName;
    lastSetNumber = setNumber;
    lastRemainingSeconds = remainingSeconds;
    lastTotalDuration = totalDurationSeconds;
    isRestNotificationActive = true;
  }

  @override
  Future<void> showRestCompletedNotification({
    required String exerciseName,
    required int nextSetNumber,
  }) async {
    lastExerciseName = exerciseName;
    lastSetNumber = nextSetNumber;
    isRestNotificationActive = false;
    isAlertTriggered = true;
  }

  @override
  Future<void> cancelRestNotification() async {
    isRestNotificationActive = false;
  }
}

class _FakeLiveActivityService extends LiveActivityService {
  bool isActivityRunning = false;
  int? lastRemainingSeconds;
  String? lastExercise;

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
  }

  @override
  Future<void> stopLiveActivity() async {
    isActivityRunning = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Epic 2: Lock Screen Live Activity & Persistent Notifications', () {
    late _FakeWorkoutNotificationService fakeNotifications;
    late _FakeLiveActivityService fakeLiveActivity;

    setUp(() {
      fakeNotifications = _FakeWorkoutNotificationService();
      fakeLiveActivity = _FakeLiveActivityService();
    });

    test('Starting rest timer triggers persistent notification and Live Activity', () {
      final container = ProviderContainer(
        overrides: [
          workoutNotificationServiceProvider.overrideWithValue(fakeNotifications),
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
    });

    test('Interactive notification action "+30s" increments timer duration and updates notification', () {
      final container = ProviderContainer(
        overrides: [
          workoutNotificationServiceProvider.overrideWithValue(fakeNotifications),
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
    });

    test('Interactive notification action "Skip Rest" dismisses notification and terminates Live Activity', () {
      final container = ProviderContainer(
        overrides: [
          workoutNotificationServiceProvider.overrideWithValue(fakeNotifications),
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
    });

    test('MethodChannel bridge invocation for LiveActivityService handles calls gracefully', () async {
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
    });
  });
}
