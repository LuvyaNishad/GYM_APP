import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/features/workout_session/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  Completer<bool>? initialization;
  late WorkoutNotificationService service;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    initialization = null;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initialize') {
            return initialization == null ? true : await initialization!.future;
          }
          return null;
        });
    service = WorkoutNotificationService();
  });

  tearDown(() async {
    await service.cancelAll();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> publishAll() async {
    await service.showRestTimerNotification(
      exerciseName: 'Row',
      setNumber: 2,
      remainingSeconds: 60,
      totalDurationSeconds: 90,
    );
    await service.showRestCompletedNotification(
      exerciseName: 'Row',
      nextSetNumber: 2,
    );
    await service.showActiveWorkoutNotification(
      splitName: 'Pull',
      currentExerciseName: 'Row',
      currentSet: 2,
      totalSets: 2,
    );
  }

  for (final state in [AppLifecycleState.resumed, AppLifecycleState.inactive]) {
    test('no workout notifications while visible: $state', () async {
      service.updateAppLifecycleState(state);
      await publishAll();
      expect(calls.where((call) => call.method == 'show'), isEmpty);
    });
  }

  for (final state in [AppLifecycleState.hidden, AppLifecycleState.paused]) {
    test(
      'rest and workout notifications are allowed in background: $state',
      () async {
        service.updateAppLifecycleState(state);
        await publishAll();
        final shown = calls.where((call) => call.method == 'show');
        expect(shown.map((call) => call.arguments['id']), [
          WorkoutNotificationIds.restTimer,
          WorkoutNotificationIds.restCompletedAlert,
          WorkoutNotificationIds.activeWorkout,
        ]);
      },
    );
  }

  test(
    'returning clears notifications and opening the shade does not recreate them',
    () async {
      service.updateAppLifecycleState(AppLifecycleState.paused);
      await publishAll();
      calls.clear();
      service.updateAppLifecycleState(AppLifecycleState.inactive);
      service.updateAppLifecycleState(AppLifecycleState.resumed);
      service.updateAppLifecycleState(AppLifecycleState.inactive);
      await publishAll();
      await service.cancelAll();
      expect(calls.any((call) => call.method == 'cancelAll'), isTrue);
      expect(calls.where((call) => call.method == 'show'), isEmpty);
    },
  );

  test(
    'returning before plugin initialization drops the queued notification',
    () async {
      // Drain the service created in setUp before delaying a new initialization.
      await service.cancelAll();
      initialization = Completer<bool>();
      service = WorkoutNotificationService();
      service.updateAppLifecycleState(AppLifecycleState.hidden);
      final pending = service.showRestTimerNotification(
        exerciseName: 'Row',
        setNumber: 2,
        remainingSeconds: 60,
        totalDurationSeconds: 90,
      );
      service.updateAppLifecycleState(AppLifecycleState.resumed);
      initialization!.complete(true);
      await pending;
      await service.cancelAll();
      expect(calls.where((call) => call.method == 'show'), isEmpty);
    },
  );
}
