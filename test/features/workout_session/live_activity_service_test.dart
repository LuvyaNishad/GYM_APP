import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/features/workout_session/services/live_activity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('leon/live_activity_test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late LiveActivityService service;
  late List<MethodCall> calls;
  setUp(() {
    calls = [];
    service = LiveActivityService(channel: channel, supported: true);
    service.configureIdentity(
      'workout-a',
      DateTime.now().add(const Duration(minutes: 2)),
      'lbs',
    );
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'areActivitiesEnabled'
          ? true
          : call.method == 'startLiveActivity'
          ? 'activity-a'
          : null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  Future<void> start() => service.startLiveActivity(
    workoutTitle: 'Push day',
    exerciseName: 'Bench press',
    setNumber: 2,
    totalSets: 3,
    remainingSeconds: 90,
    totalDurationSeconds: 90,
    targetWeightKg: 30,
    targetReps: 10,
  );
  test(
    'start carries absolute deadline, identity and canonical weight with display unit',
    () async {
      await start();
      final args = calls.last.arguments as Map;
      expect(service.currentActivityId, 'activity-a');
      expect(args['workoutId'], 'workout-a');
      expect(
        args['targetEndTime'],
        greaterThan(DateTime.now().millisecondsSinceEpoch),
      );
      expect(args['targetWeightKg'], 30);
      expect(args['weightUnit'], 'lb');
      await service.stopLiveActivity();
      expect(calls.last.arguments['activityId'], 'activity-a');
      expect(service.currentActivityId, null);
    },
  );
  test('disabled or expired Live Activities never send a start', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return false;
    });
    await start();
    expect(calls.map((c) => c.method), ['areActivitiesEnabled']);
    calls.clear();
    service.configureIdentity(
      'workout-a',
      DateTime.now().subtract(const Duration(seconds: 1)),
    );
    await start();
    expect(calls, isEmpty);
  });
  test('stop while permission check waits cancels the queued start', () async {
    final gate = Completer<bool>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'areActivitiesEnabled' ? gate.future : null;
    });
    final starting = start();
    await Future<void>.delayed(Duration.zero);
    final stopping = service.stopLiveActivity();
    gate.complete(true);
    await Future.wait([starting, stopping]);
    expect(calls.map((c) => c.method), [
      'areActivitiesEnabled',
      'stopLiveActivity',
    ]);
    expect(service.currentActivityId, null);
  });
  test(
    'an update during authorization waits until the activity exists',
    () async {
      final gate = Completer<bool>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'areActivitiesEnabled') return gate.future;
        return call.method == 'startLiveActivity' ? 'activity-a' : null;
      });
      final starting = start();
      await Future<void>.delayed(Duration.zero);
      final deadline = DateTime.now().add(const Duration(minutes: 3));
      service.configureIdentity('workout-a', deadline, 'lbs');
      final updating = service.updateLiveActivity(
        remainingSeconds: 120,
        totalDurationSeconds: 120,
        exerciseName: 'Bench press',
        setNumber: 2,
        totalSets: 3,
      );
      gate.complete(true);
      await Future.wait([starting, updating]);
      expect(calls.map((c) => c.method), [
        'areActivitiesEnabled',
        'startLiveActivity',
        'updateLiveActivity',
      ]);
      expect(
        calls.last.arguments['targetEndTime'],
        deadline.millisecondsSinceEpoch,
      );
    },
  );
  test(
    'identity change cleans up an in-flight activity without stopping the new workout',
    () async {
      final gate = Completer<String>();
      final entered = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'areActivitiesEnabled') return true;
        if (call.method == 'startLiveActivity') {
          entered.complete();
          return gate.future;
        }
        return null;
      });
      final starting = start();
      await entered.future;
      service.configureIdentity(
        'workout-b',
        DateTime.now().add(const Duration(minutes: 1)),
      );
      gate.complete('old-activity');
      await starting;
      expect(service.currentActivityId, null);
      expect(calls.last.method, 'stopLiveActivity');
      expect(calls.last.arguments, {'activityId': 'old-activity'});
    },
  );
}
