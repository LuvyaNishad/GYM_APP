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

  group('Wall-Clock Timer Synchronization Tests', () {
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
      'RestTimer targetEndTime ensures accurate countdown across background minimization',
      () {
        final notifier = container.read(restTimerProvider.notifier);
        notifier.startTimer(
          durationSeconds: 90,
          exerciseName: 'Barbell Bench Press',
        );

        final initialState = container.read(restTimerProvider);
        expect(initialState.isRunning, isTrue);
        expect(initialState.remainingSeconds, 90);
        expect(initialState.targetEndTime, isNotNull);

        // Simulate app was minimized and backgrounded:
        // Call resyncWithWallClock directly
        notifier.resyncWithWallClock();
        final syncedState = container.read(restTimerProvider);
        expect(syncedState.isRunning, isTrue);
        expect(syncedState.remainingSeconds, inInclusiveRange(88, 90));
      },
    );

    test(
      'RestTimer automatically completes when targetEndTime has passed while minimized',
      () {
        final notifier = container.read(restTimerProvider.notifier);
        // Start with 1 second remaining
        notifier.startTimer(durationSeconds: 1, exerciseName: 'Incline Press');

        // Add a negative duration so targetEndTime is now in the past
        notifier.addSeconds(-10);

        final state = container.read(restTimerProvider);
        expect(state.isRunning, isFalse);
        expect(state.remainingSeconds, 0);
      },
    );

    test(
      'ActiveSession elapsedSeconds synchronizes accurately with wall-clock time on resume',
      () {
        final notifier = container.read(activeSessionProvider.notifier);
        notifier.startSession(splitName: 'Leg Day // Squats');

        final initialState = container.read(activeSessionProvider);
        expect(initialState.isActive, isTrue);
        expect(initialState.elapsedSeconds, 0);
        expect(initialState.lastResumedAt, isNotNull);

        // Trigger resyncWithWallClock
        notifier.resyncWithWallClock();
        final syncedState = container.read(activeSessionProvider);
        expect(syncedState.elapsedSeconds, inInclusiveRange(0, 1));
      },
    );
  });
}
