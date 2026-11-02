import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/providers/local_date_provider.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/models/daily_telemetry_model.dart';
import 'package:leon/features/dashboard/providers/calorie_history_provider.dart';
import 'package:leon/features/dashboard/providers/habit_log_provider.dart';
import 'package:leon/features/dashboard/providers/step_history_provider.dart';
import 'package:leon/features/dashboard/widgets/steps_bento_card.dart';
import 'package:leon/features/health_tracking/models/health_import.dart';
import 'package:leon/features/health_tracking/providers/health_tracking_provider.dart';
import 'package:leon/features/health_tracking/screens/health_tracking_screen.dart';
import 'package:leon/features/recovery/providers/recovery_provider.dart';
import 'package:leon/services/health_sync_service.dart';
import 'package:leon/services/hive_service.dart';
import 'package:leon/services/pedometer_service.dart';
import '../helpers/memory_hive_service.dart';

class FakeHealth implements HealthSyncService {
  HealthAvailability available = HealthAvailability.ready;
  final values = <HealthMetric, HealthReading>{};
  final errors = <HealthMetric>{};
  final calls = <HealthMetric>[];
  Completer<HealthReading>? readGate;
  Completer<void>? authorizationGate;
  int authorizations = 0;
  @override
  Future<HealthAvailability> availability() async => available;
  @override
  Future<void> openSettings() async {}
  @override
  Future<void> requestPermissions(Set<HealthMetric> metrics) async {
    authorizations++;
    await authorizationGate?.future;
  }

  @override
  Future<HealthReading> read(HealthMetric metric, HealthWindow window) async {
    calls.add(metric);
    if (readGate != null) return readGate!.future;
    if (errors.contains(metric)) throw StateError('offline read failed');
    return values[metric] ??
        const HealthReading(
          state: HealthReadState.noData,
          access: HealthAccess.unknown,
        );
  }
}

HealthReading data(num value) => HealthReading(
  state: HealthReadState.data,
  access: HealthAccess.granted,
  value: value,
  platform: 'Health Connect',
  sources: const ['Watch'],
);
ProviderContainer scope(MemoryHiveService hive, FakeHealth service) =>
    ProviderContainer(
      overrides: [
        hiveServiceProvider.overrideWithValue(hive),
        healthSyncServiceProvider.overrideWithValue(service),
      ],
    );
Future<void> select(ProviderContainer c, Iterable<HealthMetric> metrics) async {
  for (final metric in metrics) {
    await c.read(healthPreferencesProvider.notifier).select(metric, true);
  }
  await c.read(healthImportProvider.future);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'an older read cannot publish data while the authorization sheet is open',
    () async {
      final service = FakeHealth()
        ..readGate = Completer<HealthReading>()
        ..authorizationGate = Completer<void>();
      final c = scope(MemoryHiveService(), service);
      addTearDown(c.dispose);
      await c
          .read(healthPreferencesProvider.notifier)
          .select(HealthMetric.steps, true);
      c.read(healthImportProvider);
      await Future<void>.delayed(Duration.zero);
      final authorization = c.read(healthImportProvider.notifier).authorize();
      service.readGate!.complete(data(800));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(currentHealthImportProvider), isNull);
      expect(c.read(healthImportProvider).isLoading, true);
      service.readGate = null;
      service.authorizationGate!.complete();
      await authorization;
      await c.read(healthImportProvider.future);
      expect(
        c.read(currentHealthImportProvider)!.reading(HealthMetric.steps).value,
        isNull,
      );
    },
  );
  test(
    'opt-in only; partial permissions and missing reads remain per metric',
    () async {
      final hive = MemoryHiveService();
      final service = FakeHealth();
      final c = scope(hive, service);
      addTearDown(c.dispose);
      await c.read(healthImportProvider.future);
      expect(service.calls, isEmpty);
      expect(service.authorizations, 0);
      service.values[HealthMetric.steps] = data(1234);
      service.values[HealthMetric.sleep] = const HealthReading(
        state: HealthReadState.denied,
        access: HealthAccess.denied,
      );
      await select(c, [
        HealthMetric.steps,
        HealthMetric.sleep,
        HealthMetric.heartRate,
      ]);
      final imported = c.read(currentHealthImportProvider)!;
      expect(imported.reading(HealthMetric.steps).value, 1234);
      expect(
        imported.reading(HealthMetric.sleep).state,
        HealthReadState.denied,
      );
      expect(
        imported.reading(HealthMetric.heartRate).access,
        HealthAccess.unknown,
      );
      expect(
        imported.reading(HealthMetric.heartRate).statusLabel,
        contains('No readable data'),
      );
      expect(
        imported.reading(HealthMetric.activeCalories).state,
        HealthReadState.disabled,
      );
    },
  );
  test(
    'revocation clears imported sleep and recovery, retaining manual hydration/soreness',
    () async {
      final hive = MemoryHiveService();
      final service = FakeHealth()..values[HealthMetric.sleep] = data(7.5);
      final c = scope(hive, service);
      addTearDown(c.dispose);
      await c.read(habitLogProvider.notifier).addWater(1000);
      await c
          .read(habitLogProvider.notifier)
          .saveRecoveryCheckIn(date: DateTime.now(), soreness: 2);
      await select(c, [HealthMetric.sleep]);
      expect(c.read(recoverySummaryProvider).score, isNotNull);
      service.values[HealthMetric.sleep] = const HealthReading(
        state: HealthReadState.denied,
        access: HealthAccess.denied,
      );
      c.read(healthImportProvider.notifier).refresh();
      expect(c.read(currentHealthImportProvider), isNull);
      await c.read(healthImportProvider.future);
      final recovery = c.read(recoverySummaryProvider);
      expect(recovery.score, isNull);
      expect(recovery.missingInputs, ['Sleep']);
      expect(recovery.habits.waterMl, 1000);
      expect(recovery.habits.soreness, 2);
    },
  );
  test(
    'manual zero beats sleep/calorie imports without changing stored habits',
    () async {
      final hive = MemoryHiveService();
      final service = FakeHealth()
        ..values[HealthMetric.sleep] = data(8)
        ..values[HealthMetric.activeCalories] = data(400);
      final c = scope(hive, service);
      addTearDown(c.dispose);
      await select(c, [HealthMetric.sleep, HealthMetric.activeCalories]);
      expect(c.read(dailyTelemetryProvider).sleepHours, 8);
      expect(c.read(dailyTelemetryProvider).calories, 400);
      expect(c.read(habitLogProvider).day(DateTime.now()).sleepLogged, false);
      await c
          .read(habitLogProvider.notifier)
          .saveRecoveryCheckIn(date: DateTime.now(), hours: 0, soreness: null);
      await c.read(habitLogProvider.notifier).addCalories(0);
      final metrics = c.read(dailyTelemetryProvider);
      expect(metrics.sleepHours, 0);
      expect(metrics.sleepRecorded, true);
      expect(metrics.calories, 0);
      expect(metrics.caloriesRecorded, true);
      expect(metrics.sleepSource, 'Manual log');
      expect(metrics.caloriesSource, 'Manual log');
      expect(c.read(healthTrackingProvider).sleepHours, 0);
      expect(c.read(calorieHistoryProvider(7)).values.last, 0);
      expect(c.read(recoverySummaryProvider).habits.sleepHours, 0);
    },
  );
  test(
    'platform steps replace phone count and survive sensor updates; charts agree',
    () async {
      final hive = MemoryHiveService();
      final now = DateTime.now();
      hive.settings[AppConstants.settingStepDate] = habitDateKey(now);
      hive.settings[AppConstants.settingStepTodayCount] = 900;
      final service = FakeHealth()..values[HealthMetric.steps] = data(5000);
      final c = scope(hive, service);
      addTearDown(c.dispose);
      await select(c, [HealthMetric.steps]);
      c
          .read(stepTrackingStatusProvider.notifier)
          .setStatus(StepTrackingStatus.permissionDenied);
      expect(c.read(healthTrackingProvider).steps, 5000);
      c.read(dailyTelemetryProvider.notifier).updateSteps(2000, 1.4);
      expect(c.read(dailyTelemetryProvider).steps, 5000);
      expect(c.read(stepHistoryProvider((days: 7, page: 0))).values.last, 5000);
      await c
          .read(healthPreferencesProvider.notifier)
          .select(HealthMetric.steps, false);
      expect(c.read(dailyTelemetryProvider).steps, 900);
      expect(c.read(healthTrackingProvider).steps, isNull);
    },
  );
  test(
    'refresh errors clear old totals while keeping per-metric successes',
    () async {
      final service = FakeHealth()
        ..values[HealthMetric.steps] = data(10)
        ..values[HealthMetric.sleep] = data(6);
      final c = scope(MemoryHiveService(), service);
      addTearDown(c.dispose);
      await select(c, [HealthMetric.steps, HealthMetric.sleep]);
      service.errors.add(HealthMetric.steps);
      c.read(healthImportProvider.notifier).refresh();
      await c.read(healthImportProvider.future);
      expect(
        c.read(currentHealthImportProvider)!.reading(HealthMetric.steps).state,
        HealthReadState.error,
      );
      expect(c.read(dailyTelemetryProvider).importedSteps, false);
      expect(c.read(dailyTelemetryProvider).sleepHours, 6);
    },
  );
  test(
    'disabled import cannot return through an older in-flight read',
    () async {
      final service = FakeHealth()..readGate = Completer<HealthReading>();
      final c = scope(MemoryHiveService(), service);
      addTearDown(c.dispose);
      await c
          .read(healthPreferencesProvider.notifier)
          .select(HealthMetric.steps, true);
      c.read(healthImportProvider);
      await Future<void>.delayed(Duration.zero);
      await c
          .read(healthPreferencesProvider.notifier)
          .select(HealthMetric.steps, false);
      await c.read(healthImportProvider.future);
      service.readGate!.complete(data(6000));
      await Future<void>.delayed(Duration.zero);
      expect(
        c.read(currentHealthImportProvider)!.reading(HealthMetric.steps).value,
        isNull,
      );
      expect(c.read(dailyTelemetryProvider).importedSteps, false);
    },
  );
  test(
    'authorization is serialized and never treats request completion as a grant',
    () async {
      final service = FakeHealth()..authorizationGate = Completer<void>();
      final c = scope(MemoryHiveService(), service);
      addTearDown(c.dispose);
      await select(c, [HealthMetric.sleep]);
      final first = c.read(healthImportProvider.notifier).authorize();
      await c.read(healthImportProvider.notifier).authorize();
      expect(service.authorizations, 1);
      service.authorizationGate!.complete();
      await first;
      await c.read(healthImportProvider.future);
      expect(
        c.read(currentHealthImportProvider)!.reading(HealthMetric.sleep).access,
        HealthAccess.unknown,
      );
      expect(c.read(healthTrackingProvider).sleepHours, isNull);
    },
  );
  test(
    'unsupported or install-required platforms preserve local habits',
    () async {
      for (final availability in [
        HealthAvailability.unsupported,
        HealthAvailability.installRequired,
      ]) {
        final service = FakeHealth()..available = availability;
        final c = scope(MemoryHiveService(), service);
        await c
            .read(habitLogProvider.notifier)
            .saveSleep(date: DateTime.now(), hours: 5);
        await select(c, [HealthMetric.sleep]);
        expect(service.calls, isEmpty);
        expect(c.read(dailyTelemetryProvider).sleepHours, 5);
        expect(c.read(currentHealthImportProvider)!.availability, availability);
        c.dispose();
      }
    },
  );
  test(
    'a resumed new day excludes an old snapshot before fetching finishes',
    () async {
      final now = DateTime.now();
      var day = DateTime(now.year, now.month, now.day);
      final service = FakeHealth()..values[HealthMetric.sleep] = data(8);
      final c = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(MemoryHiveService()),
          healthSyncServiceProvider.overrideWithValue(service),
          localDateProvider.overrideWith((ref) => day),
        ],
      );
      addTearDown(c.dispose);
      await select(c, [HealthMetric.sleep]);
      service.readGate = Completer();
      day = DateTime(day.year, day.month, day.day + 1);
      c.invalidate(localDateProvider);
      expect(c.read(currentHealthImportProvider), isNull);
      service.readGate!.complete(
        const HealthReading(state: HealthReadState.noData),
      );
      await c.read(healthImportProvider.future);
      expect(
        c.read(currentHealthImportProvider)!.reading(HealthMetric.sleep).value,
        isNull,
      );
    },
  );
  test(
    'real Hive restart retains opt-ins, never imported values; failed save is retryable',
    () async {
      final dir = await Directory.systemTemp.createTemp('leon_health_');
      addTearDown(() async {
        await Hive.close();
        await dir.delete(recursive: true);
      });
      await HiveService.init(storagePath: dir.path);
      var c = ProviderContainer();
      await c
          .read(healthPreferencesProvider.notifier)
          .select(HealthMetric.sleep, true);
      c.dispose();
      await Hive.close();
      await HiveService.init(storagePath: dir.path);
      c = ProviderContainer();
      expect(c.read(healthPreferencesProvider), {HealthMetric.sleep});
      expect(
        const HiveService().getSetting<String>(
          HealthPreferencesNotifier.storageKey,
        ),
        '["sleep"]',
      );
      await Hive.close();
      await expectLater(
        c
            .read(healthPreferencesProvider.notifier)
            .select(HealthMetric.steps, true),
        throwsA(isA<HiveError>()),
      );
      expect(c.read(healthPreferencesProvider), {HealthMetric.sleep});
      await HiveService.init(storagePath: dir.path);
      await c
          .read(healthPreferencesProvider.notifier)
          .select(HealthMetric.steps, true);
      expect(c.read(healthPreferencesProvider), {
        HealthMetric.sleep,
        HealthMetric.steps,
      });
      c.dispose();
    },
  );
  test(
    'calendar windows handle month boundaries and real DST midnight/noon',
    () {
      tzdata.initializeTimeZones();
      final location = tz.getLocation('America/New_York');
      for (final date in [
        tz.TZDateTime(location, 2026, 3, 8, 12),
        tz.TZDateTime(location, 2026, 11, 1, 12),
      ]) {
        final window = HealthWindow.forMetric(
          HealthMetric.sleep,
          date,
          calendar: (y, m, d, h) => tz.TZDateTime(location, y, m, d, h),
        );
        expect(window.start.hour, 12);
        expect(window.end.hour, 12);
        expect(
          window.end.difference(window.start).inHours,
          date.month == 3 ? 23 : 25,
        );
      }
      final window = HealthWindow.forMetric(
        HealthMetric.sleep,
        DateTime(2026, 11, 1, 8),
      );
      expect(window.start, DateTime(2026, 10, 31, 12));
      expect(window.end, DateTime(2026, 11, 1, 8));
    },
  );
  test(
    'native bridge clips and merges sleep from overlapping stages/sources; zero is distinct from empty',
    () async {
      const channel = MethodChannel('test/health');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final start = DateTime(2026, 11, 1);
      final end = DateTime(2026, 11, 1, 8);
      Map<String, Object?> raw = {
        'access': 'unknown',
        'platform': 'Apple Health',
        'intervals': [
          [
            start.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
            start.add(const Duration(hours: 4)).millisecondsSinceEpoch,
          ],
          [
            start.add(const Duration(hours: 2)).millisecondsSinceEpoch,
            end.add(const Duration(hours: 1)).millisecondsSinceEpoch,
          ],
        ],
        'sources': ['Phone', 'Watch'],
      };
      messenger.setMockMethodCallHandler(channel, (call) async => raw);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final service = NativeHealthSyncService(
        channel: channel,
        supported: true,
      );
      final reading = await service.read(
        HealthMetric.sleep,
        HealthWindow(start, end),
      );
      expect(reading.value, 8);
      expect(reading.access, HealthAccess.unknown);
      expect(reading.sources, ['Phone', 'Watch']);
      raw = {'access': 'granted', 'value': 0};
      expect(
        (await service.read(
          HealthMetric.activeCalories,
          HealthWindow(start, end),
        )).state,
        HealthReadState.data,
      );
      raw = {'access': 'unknown'};
      expect(
        (await service.read(
          HealthMetric.activeCalories,
          HealthWindow(start, end),
        )).state,
        HealthReadState.noData,
      );
      raw = {'access': 'granted', 'value': -1};
      await expectLater(
        service.read(HealthMetric.steps, HealthWindow(start, end)),
        throwsFormatException,
      );
    },
  );
  test(
    'legacy positive calories remain authored, explicit zero survives JSON',
    () {
      expect(DayHabits.fromJson({'calories': 150}).caloriesLogged, true);
      expect(
        DayHabits.fromJson(
          const DayHabits(caloriesLogged: true).toJson(),
        ).caloriesLogged,
        true,
      );
      expect(DayHabits.fromJson({'calories': 0}).caloriesLogged, false);
    },
  );
  testWidgets(
    'health controls and imported steps render with denied phone motion at large text',
    (tester) async {
      final hive = MemoryHiveService();
      hive.settings[HealthPreferencesNotifier.storageKey] = jsonEncode([
        'steps',
      ]);
      final service = FakeHealth()..values[HealthMetric.steps] = data(5000);
      final c = scope(hive, service);
      addTearDown(c.dispose);
      await c.read(healthImportProvider.future);
      c
          .read(stepTrackingStatusProvider.notifier)
          .setStatus(StepTrackingStatus.permissionDenied);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const HealthTrackingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('PHONE HEALTH DATA'), findsOneWidget);
      expect(find.text('Read access allowed'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('CALORIES'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: StepsBentoCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('5000'), findsOneWidget);
      expect(find.text('Permission needed'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
  );
}
