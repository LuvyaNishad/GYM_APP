import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/features/dashboard/models/daily_telemetry_model.dart';
import 'package:leon/features/dashboard/providers/habit_log_provider.dart';
import 'package:leon/services/daily_steps_platform.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/services/pedometer_service.dart';

import 'helpers/memory_hive_service.dart';

class _Phone implements DailyStepsPlatform {
  bool allowed = true;
  bool grant = false;
  int reads = 0;
  final events = <String>[];
  DailyStepsSnapshot? snapshot;
  Object? error;
  Completer<DailyStepsSnapshot?>? gate;
  @override
  Future<bool> hasMotionPermission() async {
    events.add('permission');
    return allowed;
  }

  @override
  Future<bool> requestMotionPermission() async {
    events.add('request');
    return allowed = grant;
  }

  @override
  Future<DailyStepsSnapshot?> readDailySteps() async {
    events.add('read');
    reads++;
    if (error != null) throw error!;
    return gate == null ? snapshot : gate!.future;
  }
}

void main() {
  test(
    'platform snapshot accepts zeroes and rejects malformed/future counts',
    () {
      const base = {'date': '2026-10-29', 'source': 'Realme phone tracker'};
      expect(
        DailyStepsSnapshot.fromMap({
          ...base,
          'days': {'2026-10-29': 0},
        }).days['2026-10-29'],
        0,
      );
      for (final days in [
        {'2026-10-29': -1},
        {'2026-10-29': 1.5},
        {'2026-10-29': 0, '2026-10-30': 5},
        {'2026-02-30': 7, '2026-10-29': 0},
        {'2026-10-28': 8},
      ]) {
        expect(
          () => DailyStepsSnapshot.fromMap({...base, 'days': days}),
          throwsFormatException,
        );
      }
    },
  );

  late DateTime now;
  late _Phone phone;
  late MemoryHiveService hive;
  late ProviderContainer container;
  late PedometerService service;

  DailyStepsSnapshot snapshot(
    int today, {
    Map<String, int> history = const {},
  }) => DailyStepsSnapshot(
    date: DailyStepsSnapshot.dateKey(now),
    days: {...history, DailyStepsSnapshot.dateKey(now): today},
    source: 'Realme phone tracker',
  );

  void create() {
    container = ProviderContainer(
      overrides: [
        hiveServiceProvider.overrideWithValue(hive),
        dailyStepsPlatformProvider.overrideWithValue(phone),
        pedometerServiceProvider.overrideWith((ref) {
          final value = PedometerService(ref, now: () => now);
          ref.onDispose(value.dispose);
          return value;
        }),
      ],
    );
    service = container.read(pedometerServiceProvider);
  }

  setUp(() {
    now = DateTime.now();
    phone = _Phone();
    hive = MemoryHiveService();
  });

  testWidgets(
    'imports past days, checks permission first, replaces totals without duplicates',
    (tester) async {
      final yesterday = DailyStepsSnapshot.dateKey(
        DateTime(now.year, now.month, now.day - 1),
      );
      phone.snapshot = snapshot(348, history: {yesterday: 2277});
      create();
      addTearDown(container.dispose);
      await service.initialize();
      await tester.pump();
      expect(phone.events.take(2), ['permission', 'read']);
      expect(container.read(dailyTelemetryProvider).steps, 348);
      expect(
        container.read(dailyTelemetryProvider).historicalDays[yesterday],
        2277,
      );
      expect(container.read(dailyTelemetryProvider).hourlySteps, isEmpty);
      await service.syncWithInbuiltPedometer();
      await tester.pump();
      expect(container.read(dailyTelemetryProvider).steps, 348);
      phone.snapshot = snapshot(400, history: {yesterday: 2200});
      await service.syncWithInbuiltPedometer();
      await tester.pump();
      expect(container.read(dailyTelemetryProvider).steps, 400);
      expect(
        container.read(dailyTelemetryProvider).historicalDays[yesterday],
        2200,
      );
      expect(container.read(dailyTelemetryProvider).recordSingleDaySteps, 2200);
      phone.snapshot = snapshot(0, history: {yesterday: 0});
      await service.syncWithInbuiltPedometer();
      await tester.pump();
      expect(container.read(dailyTelemetryProvider).steps, 0);
      expect(
        container.read(dailyTelemetryProvider).historicalDays[yesterday],
        0,
      );
      expect(container.read(dailyTelemetryProvider).recordSingleDaySteps, 0);
      container.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'refreshes every 30 seconds, pauses in background and catches up on resume',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      phone.snapshot = snapshot(348);
      create();
      addTearDown(container.dispose);
      await service.initialize();
      await tester.pump();
      phone.snapshot = snapshot(500);
      await tester.pump(const Duration(seconds: 29));
      expect(phone.reads, 1);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(phone.reads, 2);
      expect(container.read(dailyTelemetryProvider).steps, 500);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 2));
      expect(phone.reads, 2);
      phone.snapshot = snapshot(650);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(phone.reads, 3);
      expect(container.read(dailyTelemetryProvider).steps, 650);
      container.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'cached history survives restart, goal rebuild and failed refresh',
    (tester) async {
      phone.snapshot = snapshot(348);
      create();
      await service.initialize();
      await tester.pump();
      await container.read(habitLogProvider.notifier).setGoals(steps: 9000);
      await tester.pump();
      expect(container.read(dailyTelemetryProvider).steps, 348);
      expect(container.read(dailyTelemetryProvider).stepsGoal, 9000);
      final saved = hive.settings[AppConstants.settingStepDailySnapshot];
      container.dispose();
      phone.error = PlatformException(code: 'step_sync_failed');
      create();
      addTearDown(container.dispose);
      await service.initialize();
      await tester.pump();
      expect(container.read(dailyTelemetryProvider).steps, 348);
      expect(
        container.read(stepTrackingStatusProvider),
        StepTrackingStatus.syncFailed,
      );
      expect(
        container.read(stepSyncInfoProvider).source,
        'Realme phone tracker',
      );
      expect(hive.settings[AppConstants.settingStepDailySnapshot], saved);
      phone.error = null;
      phone.snapshot = snapshot(600);
      await service.syncWithInbuiltPedometer();
      await tester.pump();
      expect(container.read(dailyTelemetryProvider).steps, 600);
      expect(
        container.read(stepTrackingStatusProvider),
        StepTrackingStatus.active,
      );
      container.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'denied permission prevents reads and retries after user grants access',
    (tester) async {
      phone.allowed = false;
      phone.snapshot = snapshot(348);
      create();
      addTearDown(container.dispose);
      await service.initialize();
      expect(phone.reads, 0);
      expect(
        container.read(stepTrackingStatusProvider),
        StepTrackingStatus.permissionDenied,
      );
      phone.grant = true;
      expect(await service.requestPermission(), isTrue);
      await tester.pump();
      expect(phone.reads, 1);
      expect(container.read(dailyTelemetryProvider).steps, 348);
      container.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'failed checked write keeps the previous complete snapshot and displayed total',
    (tester) async {
      phone.snapshot = snapshot(348);
      create();
      addTearDown(container.dispose);
      await service.initialize();
      await tester.pump();
      final saved = hive.settings[AppConstants.settingStepDailySnapshot];
      hive.failSettings = true;
      phone.snapshot = snapshot(700);
      await service.syncWithInbuiltPedometer();
      await tester.pump();
      expect(hive.settings[AppConstants.settingStepDailySnapshot], saved);
      expect(container.read(dailyTelemetryProvider).steps, 348);
      expect(
        container.read(stepTrackingStatusProvider),
        StepTrackingStatus.syncFailed,
      );
      container.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'coalesces overlapping refreshes and ignores completion after disposal',
    (tester) async {
      phone.snapshot = snapshot(348);
      create();
      await service.initialize();
      final saved = hive.settings[AppConstants.settingStepDailySnapshot];
      phone.gate = Completer<DailyStepsSnapshot?>();
      final first = service.syncWithInbuiltPedometer();
      final second = service.syncWithInbuiltPedometer();
      await tester.pump();
      expect(phone.reads, 2);
      container.dispose();
      phone.gate!.complete(snapshot(900));
      await Future.wait([first, second]);
      await tester.pump();
      expect(hive.settings[AppConstants.settingStepDailySnapshot], saved);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'midnight and missed days use dated source totals, not accumulated sensor deltas',
    (tester) async {
      final yesterday = DailyStepsSnapshot.dateKey(now);
      phone.snapshot = snapshot(348);
      create();
      addTearDown(container.dispose);
      await service.initialize();
      now = DateTime(now.year, now.month, now.day + 3);
      // A response made before midnight must not become the new day's total.
      await service.syncWithInbuiltPedometer();
      await tester.pump();
      expect(container.read(dailyTelemetryProvider).steps, 0);
      expect(
        container.read(stepTrackingStatusProvider),
        StepTrackingStatus.syncFailed,
      );
      final missed = DailyStepsSnapshot.dateKey(
        DateTime(now.year, now.month, now.day - 1),
      );
      phone.snapshot = snapshot(15, history: {yesterday: 500, missed: 2000});
      await service.syncWithInbuiltPedometer();
      await tester.pump();
      expect(container.read(dailyTelemetryProvider).steps, 15);
      expect(
        container.read(dailyTelemetryProvider).historicalDays[yesterday],
        500,
      );
      expect(
        container.read(dailyTelemetryProvider).historicalDays[missed],
        2000,
      );
      final saved = DailyStepsSnapshot.fromMap(
        jsonDecode(
              hive.settings[AppConstants.settingStepDailySnapshot] as String,
            )
            as Map,
      );
      expect(saved.date, DailyStepsSnapshot.dateKey(now));
      container.dispose();
      await tester.pump();
    },
  );
}
