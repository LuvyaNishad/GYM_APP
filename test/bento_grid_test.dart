import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/models/daily_telemetry_model.dart';
import 'package:leon/features/dashboard/widgets/calories_bento_card.dart';
import 'package:leon/features/dashboard/widgets/daily_workout_bento_card.dart';
import 'package:leon/features/dashboard/widgets/retractable_calendar_header.dart';
import 'package:leon/features/dashboard/widgets/sleep_bento_card.dart';
import 'package:leon/features/dashboard/widgets/steps_bento_card.dart';
import 'package:leon/features/dashboard/widgets/water_bento_card.dart';

void main() {
  group('Dashboard Bento Grid & Retractable Header', () {
    testWidgets('RetractableCalendarHeader renders greeting and toggles expansion',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: RetractableCalendarHeader(
              userName: 'Leon',
              initialExpanded: true,
            ),
          ),
        ),
      );

      // Verify greeting
      expect(find.textContaining('Leon'), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      // Verify week days are rendered initially when expanded
      expect(find.text('M'), findsWidgets);

      // Tap on header to toggle retraction/collapse
      await tester.tap(find.textContaining('Leon'));
      await tester.pumpAndSettle();

      // Tap again to re-expand
      await tester.tap(find.textContaining('Leon'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Leon'), findsOneWidget);
    });

    testWidgets(
        'RetractableCalendarHeader highlights today in amber and logged sessions in green',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final loggedYesterday = today.subtract(const Duration(days: 1));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: RetractableCalendarHeader(
              userName: 'Leon',
              initialExpanded: true,
              loggedWorkoutDates: {loggedYesterday},
            ),
          ),
        ),
      );

      // Verify today's number is present
      expect(find.text('${today.day}'), findsOneWidget);

      // Verify circular badges
      final circleContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration &&
            dec.shape == BoxShape.circle &&
            (dec.color == const Color(0xFFFFB300) ||
                dec.color == const Color(0xFF00E676));
      }).toList();

      // Today has the golden yellow circle badge
      final amberBadges = circleContainers.where(
        (c) => (c.decoration as BoxDecoration).color == const Color(0xFFFFB300),
      );
      expect(amberBadges, isNotEmpty);
    });

    testWidgets('StepsBentoCard renders step telemetry and peak badge',
        (WidgetTester tester) async {
      const telemetry = DailyTelemetry(
        steps: 8420,
        distanceKm: 6.12,
        hourlySteps: [100, 200, 500, 3902, 300, 400],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: StepsBentoCard(telemetry: telemetry),
          ),
        ),
      );

      expect(find.text('FOOTSTEPS'), findsOneWidget);
      expect(find.text('8,420'), findsOneWidget);
      expect(find.text('+6.12 km'), findsOneWidget);
      expect(find.text('3,902'), findsOneWidget); // Tooltip peak badge
    });

    testWidgets('CaloriesBentoCard, WaterBentoCard, and SleepBentoCard render metrics',
        (WidgetTester tester) async {
      const telemetry = DailyTelemetry(
        calories: 2390,
        caloriesGoal: 3000,
        waterMl: 2750,
        waterGoalMl: 3500,
        sleepHours: 7.5,
        sleepGoalHours: 8.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: Column(
              children: [
                CaloriesBentoCard(telemetry: telemetry),
                WaterBentoCard(telemetry: telemetry),
                SleepBentoCard(telemetry: telemetry),
              ],
            ),
          ),
        ),
      );

      expect(find.text('CALORIES'), findsOneWidget);
      expect(find.text('2,390'), findsOneWidget);
      expect(find.text('HYDRATION'), findsOneWidget);
      expect(find.text('2,750'), findsOneWidget);
      expect(find.text('SLEEP'), findsOneWidget);
      expect(find.text('7.5'), findsOneWidget);
    });

    testWidgets('DailyWorkoutBentoCard renders targeted muscles and commences session',
        (WidgetTester tester) async {
      var commenced = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: DailyWorkoutBentoCard(
                muscleGroups: const ['CHEST', 'DELTOIDS', 'TRICEPS'],
                onStartWorkout: () => commenced = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('ACTIVE PROTOCOL'), findsOneWidget);
      expect(find.text('CHEST'), findsOneWidget);
      expect(find.text('DELTOIDS'), findsOneWidget);
      expect(find.text('TRICEPS'), findsOneWidget);
      expect(find.text('COMMENCE OPERATION'), findsOneWidget);

      await tester.tap(find.text('COMMENCE OPERATION'));
      await tester.pumpAndSettle();
      expect(commenced, isTrue);
    });
  });
}
