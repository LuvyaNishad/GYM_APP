import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/models/daily_telemetry_model.dart';
import 'package:leon/features/dashboard/providers/habit_log_provider.dart';
import 'package:leon/features/dashboard/providers/step_history_provider.dart';
import 'package:leon/features/dashboard/widgets/telemetry_detail_sheets.dart';
import 'package:leon/services/pedometer_service.dart';
import 'package:leon/shared/widgets/daily_activity_chart.dart';

class _Totals extends DailyTelemetryNotifier {
  _Totals(this.initial);
  final DailyTelemetry initial;
  @override
  DailyTelemetry build() => initial;
}

ActivityBarPainter stepPainter(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byKey(const ValueKey('step-bars'))).painter!
        as ActivityBarPainter;

String? stepTotal(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('step-total'))).data;

void main() {
  testWidgets(
    'Unavailable today keeps saved days and cached totals after sync failure',
    (tester) async {
      final now = DateUtils.dateOnly(DateTime.now());
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final container = ProviderContainer(
        overrides: [
          dailyTelemetryProvider.overrideWith(
            () => _Totals(
              DailyTelemetry(
                steps: 348,
                historicalDays: {habitDateKey(yesterday): 1500},
              ),
            ),
          ),
        ],
      );
      final subscription = container.listen(
        stepHistoryProvider((days: 7, page: 0)),
        (_, _) {},
      );
      container
          .read(stepTrackingStatusProvider.notifier)
          .setStatus(StepTrackingStatus.syncFailed);
      container
          .read(stepSyncInfoProvider.notifier)
          .update('Realme phone tracker', now);
      expect(
        container.read(stepHistoryProvider((days: 7, page: 0))).values.last,
        348,
      );
      container
          .read(stepSyncInfoProvider.notifier)
          .update('Realme phone tracker', yesterday);
      expect(
        container.read(stepHistoryProvider((days: 7, page: 0))).values.last,
        isNull,
      );
      container
          .read(stepTrackingStatusProvider.notifier)
          .setStatus(StepTrackingStatus.permissionDenied);
      final history = container.read(stepHistoryProvider((days: 7, page: 0)));
      expect(history.values[5], 1500);
      expect(history.values.last, isNull);
      subscription.close();
      container.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'daily chart selects dates, distinguishes zero and missing, and updates today',
    (tester) async {
      final now = DateUtils.dateOnly(DateTime.now());
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final initial = DailyTelemetry(
        steps: 348,
        historicalDays: {habitDateKey(yesterday): 0},
      );
      final container = ProviderContainer(
        overrides: [
          dailyTelemetryProvider.overrideWith(() => _Totals(initial)),
        ],
      );
      container
          .read(stepTrackingStatusProvider.notifier)
          .setStatus(StepTrackingStatus.active);
      container
          .read(stepSyncInfoProvider.notifier)
          .update('Realme phone tracker', DateTime.now());
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showStepsDetailSheet(context, initial),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        container.exists(stepHistoryProvider((days: 7, page: 0))),
        isFalse,
      );
      expect(find.byType(DailyActivityChart), findsNothing);
      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(stepPainter(tester).reveal.value, 0);
      await tester.pump(const Duration(milliseconds: 380));
      expect(stepPainter(tester).reveal.value, greaterThan(0));
      expect(stepPainter(tester).reveal.value, lessThan(1));
      await tester.pumpAndSettle();
      expect(stepTotal(tester), '348');
      expect(find.text('All'), findsOneWidget);
      expect(find.text('00:00'), findsNothing);
      expect(find.text('23:00'), findsNothing);
      final chart = find.byKey(const ValueKey('step-bars'));
      final origin = tester.getTopLeft(chart);
      final slot = tester.getSize(chart).width / 7;
      await tester.tapAt(origin + Offset(slot * 5.5, 90));
      await tester.pumpAndSettle();
      expect(stepTotal(tester), '0');
      expect(stepPainter(tester).values[5], 0);
      expect(stepPainter(tester).reveal.value, 1);
      await tester.tapAt(origin + Offset(slot * 4.5, 90));
      await tester.pumpAndSettle();
      expect(stepTotal(tester), '—');
      expect(stepPainter(tester).values[4], isNull);
      expect(find.text('No step record for this day'), findsOneWidget);
      container.read(dailyTelemetryProvider.notifier).updateSteps(600, .42);
      await tester.pumpAndSettle();
      expect(stepPainter(tester).values.last, 600);
      await tester.tap(find.byTooltip('Next day'));
      await tester.pump();
      await tester.tap(find.byTooltip('Next day'));
      await tester.pumpAndSettle();
      expect(stepTotal(tester), '600');
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(
        container.exists(stepHistoryProvider((days: 7, page: 0))),
        isFalse,
      );
      expect(find.byType(DailyActivityChart), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );

  testWidgets(
    'daily and full-history charts fit compact phone with 1.5x text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateUtils.dateOnly(DateTime.now());
      final initial = DailyTelemetry(
        steps: 348,
        historicalDays: {
          for (var i = 1; i <= 130; i++)
            habitDateKey(DateTime(now.year, now.month, now.day - i)): i * 10,
        },
      );
      final container = ProviderContainer(
        overrides: [
          dailyTelemetryProvider.overrideWith(() => _Totals(initial)),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showStepsDetailSheet(context, initial),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('All'));
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (var page = 0; page <= 4; page++) {
        final series = container.read(
          stepHistoryProvider((days: 0, page: page)),
        );
        expect(series.values.length, lessThanOrEqualTo(30));
        expect(series.page, page);
        expect(tester.takeException(), isNull);
        if (page < 4) {
          await tester.ensureVisible(find.byTooltip('Older days'));
          await tester.tap(find.byTooltip('Older days'));
          await tester.pumpAndSettle();
        } else {
          expect(series.start, DateTime(now.year, now.month, now.day - 130));
          expect(series.values.first, 1300);
          expect(
            tester
                .widget<IconButton>(
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is IconButton && widget.tooltip == 'Older days',
                  ),
                )
                .onPressed,
            isNull,
          );
        }
      }
      await tester.tap(find.byTooltip('Newer days'));
      await tester.pumpAndSettle();
      expect(stepPainter(tester).values, hasLength(30));
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );
}
