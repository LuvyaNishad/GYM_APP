import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/features/workout_session/providers/rest_timer_provider.dart';
import 'package:leon/features/workout_session/services/native_rest_service.dart';
import 'package:leon/features/workout_session/services/notification_service.dart';
import 'package:leon/features/workout_session/services/workout_cue_service.dart';
import 'package:leon/models/user_model.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/state/app_providers.dart';
import '../../helpers/memory_hive_service.dart';

class FakeNativeRest extends NativeRestService {
  Map<String, dynamic>? timer;
  bool fail = false;
  int scheduled = 0, claims = 0;
  @override
  bool get supported => true;
  @override
  Future<void> schedule(Map<String, dynamic> value) async {
    if (fail) throw StateError('native scheduler failed');
    scheduled++;
    timer = {...value, 'phase': 'running', 'delivered': false};
  }

  @override
  Future<Map<String, dynamic>?> read() async =>
      timer == null ? null : {...timer!};
  @override
  Future<void> cancel([String? timerId]) async {
    if (timerId == null || timer?['timerId'] == timerId) timer = null;
  }

  @override
  Future<bool> complete(String timerId, {bool background = false}) async {
    if (timer?['timerId'] != timerId || timer?['delivered'] == true) {
      return false;
    }
    if ((timer?['deadline'] as num).toInt() >
        DateTime.now().millisecondsSinceEpoch + 100) {
      return false;
    }
    timer!['phase'] = 'completed';
    timer!['delivered'] = true;
    claims++;
    return true;
  }
}

class FakeCues extends WorkoutCueService {
  final calls = <(WorkoutCue, bool, bool)>[];
  final intensities = <double>[];
  @override
  Future<void> play(
    WorkoutCue cue, {
    required bool sound,
    required bool vibrate,
    double intensity = 1,
  }) async {
    calls.add((cue, sound, vibrate));
    intensities.add(intensity);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryHiveService hive;
  late FakeNativeRest native;
  late FakeCues cues;
  late ProviderContainer container;
  ProviderContainer create() => ProviderContainer(
    overrides: [
      hiveServiceProvider.overrideWithValue(hive),
      nativeRestServiceProvider.overrideWithValue(native),
      workoutCueServiceProvider.overrideWithValue(cues),
      workoutNotificationServiceProvider.overrideWithValue(
        WorkoutNotificationService(initialize: () async => false),
      ),
    ],
  );
  setUp(() {
    hive = MemoryHiveService();
    native = FakeNativeRest();
    cues = FakeCues();
    container = create();
  });
  tearDown(() => container.dispose());
  void start() => container
      .read(activeSessionProvider.notifier)
      .startSession(
        initialExercises: [
          const ActiveExerciseState(
            exerciseId: 'row',
            name: 'Row',
            muscleGroup: 'Back',
            sets: [ActiveSetState(setNumber: 1, weightKg: 30, reps: 10)],
          ),
        ],
      );
  Future<void> drain() =>
      container.read(restTimerProvider.notifier).flushNativeChanges();

  test(
    'last five seconds ramp once per second; extending, pausing and skipping suppress stale cues',
    () async {
      start();
      final notifier = container.read(restTimerProvider.notifier);
      notifier.startTimer(durationSeconds: 90);
      await drain();
      expect(cues.calls, isEmpty);
      for (var remaining = 5; remaining > 0; remaining--) {
        native.timer!['deadline'] = DateTime.now()
            .add(Duration(seconds: remaining))
            .millisecondsSinceEpoch;
        notifier.resyncWithWallClock();
        await drain();
        notifier.resyncWithWallClock();
        await drain();
      }
      expect(cues.calls, List.filled(5, (WorkoutCue.countdown, true, true)));
      expect(cues.intensities, [.18, .32, .5, .72, 1]);
      notifier.addSeconds(30);
      await drain();
      notifier.resyncWithWallClock();
      await drain();
      expect(cues.calls.length, 5);
      notifier.pause();
      await drain();
      notifier.resyncWithWallClock();
      await drain();
      expect(cues.calls.length, 5);
      notifier.skip();
      await drain();
      notifier.resyncWithWallClock();
      await drain();
      expect(cues.calls.length, 5);
    },
  );

  test(
    'countdown respects current vibration-only preferences and does not play in background',
    () async {
      start();
      await container
          .read(userProfileProvider.notifier)
          .load(
            const UserModel(
              id: 'guest',
              email: '',
              displayName: '',
              audioCuesEnabled: false,
              hapticFeedbackEnabled: true,
            ),
          );
      final notifier = container.read(restTimerProvider.notifier);
      notifier.startTimer(durationSeconds: 5);
      await drain();
      expect(cues.calls.single, (WorkoutCue.countdown, false, true));
      container
          .read(workoutNotificationServiceProvider)
          .updateAppLifecycleState(AppLifecycleState.paused);
      native.timer!['deadline'] = DateTime.now()
          .add(const Duration(seconds: 2))
          .millisecondsSinceEpoch;
      notifier.resyncWithWallClock();
      await drain();
      expect(cues.calls.length, 1);
      notifier.skip();
      await drain();
    },
  );

  test(
    'native rest survives provider/process recreation with the same session',
    () async {
      start();
      final notifier = container.read(restTimerProvider.notifier);
      notifier.startTimer(durationSeconds: 90);
      await drain();
      final timerId = native.timer!['timerId'];
      final deadline = native.timer!['deadline'];
      container.dispose();
      container = create();
      container.read(restTimerProvider);
      await Future<void>.delayed(Duration.zero);
      await drain();
      expect(container.read(restTimerProvider).isRunning, true);
      expect(container.read(restTimerProvider).exerciseName, 'Row');
      expect(native.timer!['timerId'], timerId);
      expect(native.timer!['deadline'], deadline);
      expect(container.read(activeSessionProvider).isActive, true);
    },
  );
  test(
    'background +30s and Skip changes reconcile without overwriting native deadline',
    () async {
      start();
      final notifier = container.read(restTimerProvider.notifier);
      notifier.startTimer(durationSeconds: 90);
      await drain();
      final deadline = (native.timer!['deadline'] as int) + 30000;
      native.timer!['deadline'] = deadline;
      native.timer!['total'] = 120;
      native.onChanged?.call();
      await drain();
      expect(
        container.read(restTimerProvider).targetEndTime!.millisecondsSinceEpoch,
        deadline,
      );
      expect(native.timer!['deadline'], deadline);
      native.timer = null;
      native.onChanged?.call();
      await drain();
      expect(container.read(restTimerProvider).isRunning, false);
    },
  );
  test(
    'a stale timer for a different workout is cancelled on restart',
    () async {
      start();
      container
          .read(restTimerProvider.notifier)
          .startTimer(durationSeconds: 90);
      await drain();
      native.timer!['workoutId'] = 'old_workout';
      container.dispose();
      container = create();
      container.read(restTimerProvider);
      await Future<void>.delayed(Duration.zero);
      await drain();
      expect(native.timer, null);
      expect(container.read(restTimerProvider).isRunning, false);
    },
  );
  test(
    'native completion delivered while absent is not replayed on resume',
    () async {
      start();
      container
          .read(restTimerProvider.notifier)
          .startTimer(durationSeconds: 90);
      await drain();
      native.timer!['deadline'] = DateTime.now().millisecondsSinceEpoch - 1000;
      native.timer!['phase'] = 'completed';
      native.timer!['delivered'] = true;
      container.dispose();
      container = create();
      container.read(restTimerProvider);
      await Future<void>.delayed(Duration.zero);
      await drain();
      expect(container.read(restTimerProvider).isRunning, false);
      expect(cues.calls, isEmpty);
    },
  );
  test(
    'completion is claimed only once and obeys silent preferences',
    () async {
      await hive.put(
        'user',
        'local',
        const UserModel(
          id: 'guest',
          email: '',
          displayName: '',
          audioCuesEnabled: false,
          hapticFeedbackEnabled: false,
        ).toJson(),
      );
      start();
      final notifier = container.read(restTimerProvider.notifier);
      notifier.startTimer(durationSeconds: 90);
      await drain();
      native.timer!['deadline'] = DateTime.now().millisecondsSinceEpoch - 1;
      notifier.resyncWithWallClock();
      await drain();
      notifier.resyncWithWallClock();
      await drain();
      expect(native.claims, 1);
      expect(cues.calls, [(WorkoutCue.complete, false, false)]);
    },
  );
  test(
    'pause and discard cancel durable alarms; scheduling failure is visible and retryable',
    () async {
      start();
      final notifier = container.read(restTimerProvider.notifier);
      native.fail = true;
      notifier.startTimer(durationSeconds: 90);
      await drain();
      expect(
        container.read(restTimerProvider).alertError,
        contains('unavailable'),
      );
      native.fail = false;
      notifier.retryAlerts();
      await drain();
      expect(container.read(restTimerProvider).alertError, null);
      notifier.pause();
      await drain();
      expect(native.timer, null);
      notifier.resume();
      await drain();
      expect(native.timer, isNotNull);
      notifier.skip();
      await drain();
      expect(native.timer, null);
    },
  );
  test(
    'subtracting through zero cancels the native deadline instead of reviving rest',
    () async {
      start();
      final notifier = container.read(restTimerProvider.notifier);
      notifier.startTimer(durationSeconds: 30);
      await drain();
      notifier.addSeconds(-40);
      await drain();
      expect(native.timer, null);
      expect(container.read(restTimerProvider).remainingSeconds, 0);
      expect(container.read(restTimerProvider).isRunning, false);
    },
  );
  for (final (sound, vibrate) in [
    (true, true),
    (false, true),
    (false, false),
  ]) {
    test(
      'cue preferences apply at playback time: sound=$sound vibrate=$vibrate',
      () async {
        await hive.put(
          'user',
          'local',
          UserModel(
            id: 'g',
            email: '',
            displayName: '',
            audioCuesEnabled: sound,
            hapticFeedbackEnabled: vibrate,
          ).toJson(),
        );
        await container
            .read(workoutFeedbackProvider)
            .play(WorkoutCue.countdown);
        expect(cues.calls.single, (WorkoutCue.countdown, sound, vibrate));
        await container
            .read(userProfileProvider.notifier)
            .transform(
              (u) => u!.copyWith(
                audioCuesEnabled: false,
                hapticFeedbackEnabled: false,
              ),
            );
        await container.read(workoutFeedbackProvider).play(WorkoutCue.bell);
        expect(cues.calls.last, (WorkoutCue.bell, false, false));
      },
    );
  }
}
