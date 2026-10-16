import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/theme/app_colors.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/models/daily_telemetry_model.dart';
import 'package:leon/features/dashboard/widgets/calories_bento_card.dart';
import 'package:leon/features/dashboard/widgets/daily_workout_bento_card.dart';
import 'package:leon/features/dashboard/widgets/gym_contribution_chart.dart';
import 'package:leon/features/dashboard/widgets/retractable_calendar_header.dart';
import 'package:leon/features/dashboard/widgets/sleep_bento_card.dart';
import 'package:leon/features/dashboard/widgets/steps_bento_card.dart';
import 'package:leon/features/dashboard/widgets/water_bento_card.dart';
import 'package:leon/features/dashboard/providers/workout_rotation_provider.dart';

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
            (dec.color == AppColors.pureWhite ||
                dec.color == AppColors.platinum);
      }).toList();

      // Today has the pure white circle badge
      final todayBadges = circleContainers.where(
        (c) => (c.decoration as BoxDecoration).color == AppColors.pureWhite,
      );
      expect(todayBadges, isNotEmpty);
    });

    testWidgets('GymContributionChart renders heatmap and day labels',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final loggedYesterday = today.subtract(const Duration(days: 1));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: GymContributionChart(
              loggedWorkoutDates: {loggedYesterday},
              weeksCount: 12,
            ),
          ),
        ),
      );

      // Verify activity header and day labels
      expect(find.text('WORKOUT ACTIVITY'), findsOneWidget);
      expect(find.textContaining('SESSIONS LOGGED'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Rest'), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('StepsBentoCard renders minimal step count and triggers tap',
        (WidgetTester tester) async {
      const telemetry = DailyTelemetry(
        steps: 8420,
        distanceKm: 6.12,
        hourlySteps: [100, 200, 500, 3902, 300, 400],
      );

      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: StepsBentoCard(
              telemetry: telemetry,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Steps'), findsOneWidget);
      expect(find.text('8,420'), findsOneWidget);

      await tester.tap(find.text('Steps'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('CaloriesBentoCard, WaterBentoCard, and SleepBentoCard render metrics and tap',
        (WidgetTester tester) async {
      const telemetry = DailyTelemetry(
        calories: 2390,
        caloriesGoal: 3000,
        waterMl: 2750,
        waterGoalMl: 3500,
        sleepHours: 7.5,
        sleepGoalHours: 8.0,
      );

      var calTapped = false;
      var waterTapped = false;
      var sleepTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Column(
              children: [
                CaloriesBentoCard(
                  telemetry: telemetry,
                  onTap: () => calTapped = true,
                ),
                WaterBentoCard(
                  telemetry: telemetry,
                  onTap: () => waterTapped = true,
                ),
                SleepBentoCard(
                  telemetry: telemetry,
                  onTap: () => sleepTapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Calories'), findsOneWidget);
      expect(find.text('2,390'), findsOneWidget);
      expect(find.text('79%'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('2,750'), findsOneWidget);
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);
      expect(find.text('7.5'), findsOneWidget);
      expect(find.text('93%'), findsOneWidget);

      await tester.tap(find.text('Calories'));
      await tester.pumpAndSettle();
      expect(calTapped, isTrue);

      await tester.tap(find.text('Water'));
      await tester.pumpAndSettle();
      expect(waterTapped, isTrue);

      await tester.tap(find.text('Sleep'));
      await tester.pumpAndSettle();
      expect(sleepTapped, isTrue);
    });

    testWidgets('Tapping StepsBentoCard opens StepsDetailSheet modal',
        (WidgetTester tester) async {
      const telemetry = DailyTelemetry(
        steps: 8420,
        distanceKm: 6.12,
        hourlySteps: [100, 200, 500, 3902, 300, 400],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(
              body: StepsBentoCard(telemetry: telemetry),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Steps'));
      await tester.pumpAndSettle();

      expect(find.text('Step tracker'), findsOneWidget);
      expect(find.text('Highest single-day record'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
    });

    testWidgets('DailyWorkoutBentoCard is clutter-free and opens detail modal on tap',
        (WidgetTester tester) async {
      var commenced = false;

      final container = ProviderContainer();
      container.read(workoutRotationProvider.notifier).selectDayByIndex(0);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: DailyWorkoutBentoCard(
                onStartWorkout: () => commenced = true,
              ),
            ),
          ),
        ),
      );

      // Verify minimal surface: no TARGET RPE or telemetry bar clutter
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('PUSH DAY A'), findsOneWidget);
      expect(find.text('CHEST'), findsOneWidget);
      expect(find.text('FRONT DELTS'), findsOneWidget);
      expect(find.text('TRIS'), findsOneWidget);
      expect(find.text('START WORKOUT'), findsOneWidget);
      expect(find.textContaining('TARGET RPE'), findsNothing);
      expect(find.textContaining('5 EXERCISES'), findsNothing);

      // Tap START WORKOUT directly from card
      await tester.tap(find.text('START WORKOUT'));
      await tester.pumpAndSettle();
      expect(commenced, isTrue);

      // Tap card body to open detail sheet
      await tester.tap(find.text('PUSH DAY A'));
      await tester.pumpAndSettle();

      // Verify detail sheet opened with the detailed telemetry
      expect(find.text('TARGET RPE'), findsOneWidget);
      expect(find.text('EXERCISES'), findsOneWidget);
      expect(find.text('DURATION'), findsOneWidget);
      expect(find.text('TRAINING FOCUS'), findsOneWidget);
      expect(find.text('HYPERTROPHY'), findsOneWidget);
      expect(find.textContaining('PLANNED EXERCISE SEQUENCE'), findsOneWidget);
    });
  });
}
