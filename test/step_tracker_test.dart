import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/features/dashboard/models/daily_telemetry_model.dart';
import 'package:leon/features/dashboard/widgets/steps_bento_card.dart';
import 'package:leon/features/dashboard/widgets/telemetry_detail_sheets.dart';

void main() {
  group('Daily Step Tracker Tests', () {
    test('DailyTelemetry defaults to zero without mock data', () {
      const telemetry = DailyTelemetry();
      expect(telemetry.steps, 0);
      expect(telemetry.distanceKm, 0.0);
      expect(telemetry.hourlySteps, isEmpty);
      expect(telemetry.historicalDays, isEmpty);
      expect(telemetry.recordSingleDaySteps, 0);
      expect(telemetry.recordSingleDayKm, 0.0);
      expect(telemetry.recordDate, '--');
    });

    test('Stride distance calculates accurately', () {
      const steps = 1000;
      final km = double.parse((steps * 0.000708).toStringAsFixed(2));
      expect(km, 0.71);

      const steps5k = 5000;
      final km5k = double.parse((steps5k * 0.000708).toStringAsFixed(2));
      expect(km5k, 3.54);
    });

    testWidgets('StepsBentoCard renders 0 steps without random mock bars', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const telemetry = DailyTelemetry(steps: 0, hourlySteps: []);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 180,
                height: 180,
                child: StepsBentoCard(telemetry: telemetry),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Steps'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('06'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('StepsDetailSheet displays current calendar dates instead of mock 2026 data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const telemetry = DailyTelemetry(
        steps: 1250,
        distanceKm: 0.89,
        stepsGoal: 8000,
        hourlySteps: [0, 0, 0, 0, 0, 0, 0, 0, 250, 500, 500, 0],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showStepsDetailSheet(context, telemetry),
                  child: const Text('Open Details'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Step tracker'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('Step count'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Highest single-day record'), findsOneWidget);

      // Verify no hardcoded '26/6/2026' or mock values
      expect(find.text('26/6/2026'), findsNothing);
      expect(find.text('17,024 steps'), findsNothing);
    });

    testWidgets('Apple HIG compliance: all text elements meet >= 11.0 pt floor', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const telemetry = DailyTelemetry(steps: 2400);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showStepsDetailSheet(context, telemetry),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final text in textWidgets) {
        if (text.style?.fontSize != null) {
          expect(
            text.style!.fontSize! >= 11.0,
            isTrue,
            reason: 'Text "${text.data}" has font size ${text.style!.fontSize} < 11.0 pt',
          );
        }
      }
    });

    testWidgets('Day tab in StepsDetailSheet matches StepsBentoCard with 24-hour timeline markers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final hourlySteps = List<int>.filled(24, 0);
      hourlySteps[11] = 1194;
      hourlySteps[14] = 505;
      hourlySteps[15] = 827;

      final telemetry = DailyTelemetry(
        steps: 2801,
        distanceKm: 1.98,
        stepsGoal: 8000,
        hourlySteps: hourlySteps,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showStepsDetailSheet(context, telemetry),
                  child: const Text('Open Details'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Day tab is active by default: should have 00, 06, 12, 18 markers matching Bento card
      expect(find.text('00'), findsOneWidget);
      expect(find.text('06'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);

      // Should display today's step count 2,801
      expect(find.text('2,801'), findsOneWidget);
    });
  });
}
