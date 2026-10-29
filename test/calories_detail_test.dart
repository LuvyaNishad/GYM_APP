import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/models/daily_telemetry_model.dart';
import 'package:leon/features/dashboard/providers/calorie_history_provider.dart';
import 'package:leon/features/dashboard/providers/habit_log_provider.dart';
import 'package:leon/features/dashboard/widgets/calories_bento_card.dart';
import 'package:leon/features/dashboard/widgets/calories_detail_sheet.dart';
import 'package:leon/shared/widgets/daily_activity_chart.dart';
import 'package:leon/services/hive_service.dart';

import 'helpers/memory_hive_service.dart';

MemoryHiveService historyStore() {
  final now = DateTime.now();
  return MemoryHiveService()
    ..settings[HabitLogNotifier.storageKey] = jsonEncode(
      HabitLog(
        days: {
          for (var i = 0; i < 30; i++)
            if (i != 4)
              habitDateKey(
                DateTime(now.year, now.month, now.day - i),
              ): DayHabits(
                calories: [420, 280, 610, 350, 180, 490, 540][i % 7],
              ),
        },
      ).toJson(),
    );
}

ActivityBarPainter painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(find.byKey(const ValueKey('calorie-bars')))
            .painter!
        as ActivityBarPainter;

Widget host(ProviderContainer container, Widget child, {double scale = 1}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    );

Future<void> unmount(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox.shrink());
  container.dispose();
  await tester.pump();
}

void main() {
  test('History crosses month boundaries and preserves missing days', () {
    final history = CalorieHistory.fromLog(
      const HabitLog(
        days: {
          '2026-09-29': DayHabits(calories: 320),
          '2026-09-30': DayHabits(sleepHours: 8),
          '2026-10-01': DayHabits(calories: 450),
        },
      ),
      DateTime(2026, 10, 1, 23),
      3,
    );
    expect(history.start, DateTime(2026, 9, 29));
    expect(history.values, [320, null, 450]);
    expect(history.dateAt(2), DateTime(2026, 10, 1));
  });

  testWidgets('History ignores other habits and updates after a calorie save', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [hiveServiceProvider.overrideWithValue(historyStore())],
    );
    var updates = 0;
    final subscription = container.listen(
      calorieHistoryProvider(7),
      (_, _) => updates++,
    );
    final notifier = container.read(habitLogProvider.notifier);
    await notifier.addWater(250);
    await notifier.saveSleep(date: DateTime.now(), hours: 8);
    await notifier.setGoals(steps: 10000);
    container.read(calorieHistoryProvider(7));
    expect(updates, 0);
    await notifier.addCalories(100);
    expect(container.read(calorieHistoryProvider(7)).values.last, 520);
    expect(updates, 1);
    subscription.close();
    container.dispose();
    await tester.pump();
  });

  testWidgets('Calories grid opens history lazily and releases it on close', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [hiveServiceProvider.overrideWithValue(historyStore())],
    );
    await tester.pumpWidget(
      host(
        container,
        const CaloriesBentoCard(telemetry: DailyTelemetry(calories: 420)),
      ),
    );
    expect(container.exists(calorieHistoryProvider(7)), isFalse);
    expect(find.byType(DailyActivityChart), findsNothing);
    await tester.tap(find.text('Calories'));
    await tester.pumpAndSettle();
    expect(container.exists(calorieHistoryProvider(7)), isTrue);
    expect(find.byType(DailyActivityChart), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(container.exists(calorieHistoryProvider(7)), isFalse);
    expect(find.byType(DailyActivityChart), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    await unmount(tester, container);
  });

  testWidgets(
    'Reveal repaints without rebuilding the parent and finishes once',
    (tester) async {
      var builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (_) {
                builds++;
                return DailyActivityChart(
                  paintKey: const ValueKey('calorie-bars'),
                  values: const [200, 600, 400],
                  selected: 2,
                  onSelected: (_) {},
                );
              },
            ),
          ),
        ),
      );
      final reveal = painter(tester).reveal;
      expect(reveal.value, 0);
      await tester.pump(const Duration(milliseconds: 380));
      expect(reveal.value, closeTo(.5, .01));
      expect(builds, 1);
      await tester.pump(const Duration(milliseconds: 400));
      expect(reveal.value, 1);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Background updates wait for resume and reduced motion skips reveal',
    (tester) async {
      Future<void> mount(List<int?> values, {bool reduced = false}) =>
          tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: reduced),
                child: Scaffold(
                  body: DailyActivityChart(
                    paintKey: const ValueKey('calorie-bars'),
                    values: values,
                    selected: 0,
                    onSelected: (_) {},
                  ),
                ),
              ),
            ),
          );
      await mount([200]);
      await tester.pump(const Duration(milliseconds: 200));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await mount([400]);
      expect(painter(tester).reveal.value, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(painter(tester).reveal.value, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(painter(tester).reveal.value, 1);
      await mount([600], reduced: true);
      expect(painter(tester).reveal.value, 1);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Day and period selection do not replay reveal; save failure preserves data',
    (tester) async {
      final store = historyStore();
      final container = ProviderContainer(
        overrides: [hiveServiceProvider.overrideWithValue(store)],
      );
      await tester.pumpWidget(
        host(container, CaloriesDetailSheet(requestCalories: (_) async => 100)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('calorie-total'))).data,
        '280',
      );
      expect(painter(tester).reveal.value, 1);
      await tester.tap(find.text('30d'));
      await tester.pumpAndSettle();
      expect(painter(tester).values, hasLength(30));
      store.failSettings = true;
      await tester.ensureVisible(find.text('LOG CALORIES'));
      await tester.tap(find.text('LOG CALORIES'));
      await tester.pumpAndSettle();
      expect(find.text('Could not save. Try again.'), findsOneWidget);
      expect(container.read(calorieHistoryProvider(30)).values.last, 420);
      store.failSettings = false;
      await tester.ensureVisible(find.text('LOG CALORIES'));
      await tester.tap(find.text('LOG CALORIES'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('calorie-total'))).data,
        '520',
      );
      expect(find.text('Could not save. Try again.'), findsNothing);
      await unmount(tester, container);
    },
  );

  testWidgets('Compact and large-text layouts fit with honest empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      for (final family in ['Outfit', 'JetBrainsMono']) {
        final loader = FontLoader(family);
        for (final weight in ['Regular', 'Medium', 'Bold']) {
          loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
        }
        await loader.load();
      }
    });
    for (final populated in [false, true]) {
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(
            populated ? historyStore() : MemoryHiveService(),
          ),
        ],
      );
      for (final scale in [1.0, 1.5]) {
        await tester.pumpWidget(
          host(
            container,
            RepaintBoundary(
              key: const ValueKey('preview'),
              child: CaloriesDetailSheet(requestCalories: (_) async => null),
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (!populated) {
          expect(find.text('No active calories logged'), findsOneWidget);
          expect(painter(tester).values.every((v) => v == null), isTrue);
        }
        if (populated && scale == 1) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('preview')),
          );
          await tester.runAsync(() async {
            final preview = await boundary.toImage(pixelRatio: 2);
            final bytes = await preview.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              'build/calories_populated_preview.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            preview.dispose();
          });
        }
        await tester.ensureVisible(find.text('LOG CALORIES'));
        await tester.tap(find.text('LOG CALORIES'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      await unmount(tester, container);
    }
  });
}
