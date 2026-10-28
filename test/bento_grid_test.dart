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
import 'package:leon/shared/widgets/glass_card.dart';

void main() {
  group('Dashboard Bento Grid & Retractable Header', () {
    testWidgets(
      'RetractableCalendarHeader renders greeting, consistency tracker, and date actions',
      (WidgetTester tester) async {
        DateTime? selectedDate;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: RetractableCalendarHeader(
                userName: 'Leon',
                initialExpanded: true,
                onDateSelected: (d) => selectedDate = d,
              ),
            ),
          ),
        );

        // Verify branding and greeting
        expect(find.text('AEON'), findsOneWidget);
        expect(find.textContaining('Leon'), findsOneWidget);

        // Verify account circle is removed, calendar month button is present
        expect(find.byIcon(Icons.account_circle_outlined), findsNothing);
        expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);

        // Verify consistency tracker and week days are permanently rendered
        expect(find.textContaining('THIS WEEK'), findsOneWidget);
        expect(find.text('M'), findsWidgets);

        // Tap a day capsule to select date
        await tester.tap(find.text('M').first);
        await tester.pumpAndSettle();
        expect(selectedDate, isNotNull);
      },
    );

    testWidgets(
      'RetractableCalendarHeader highlights selected day in amber and marks logged sessions',
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

        final selectedBadges = tester
            .widgetList<Container>(find.byType(Container))
            .where(
              (c) =>
                  c.decoration is BoxDecoration &&
                  (c.decoration as BoxDecoration).color == AppColors.warning,
            );
        expect(selectedBadges, hasLength(1));
        // Verify tick icon is removed per user specification
        expect(find.byIcon(Icons.check_rounded), findsNothing);

        // Verify gym day indicator uses green fill for logged session
        if (today.weekday > 1) {
          final greenBadges = tester
              .widgetList<Container>(find.byType(Container))
              .where(
                (c) =>
                    c.decoration is BoxDecoration &&
                    (c.decoration as BoxDecoration).color == AppColors.gymGreen,
              );
          expect(greenBadges, isNotEmpty);
        }
      },
    );

    testWidgets(
      'RetractableCalendarHeader marks completed days green, missed days red, and omits ticks',
      (WidgetTester tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final mondayThisWeek = today.subtract(
          Duration(days: today.weekday - 1),
        );
        final loggedDates = {mondayThisWeek};

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: RetractableCalendarHeader(
                userName: 'Leon',
                initialExpanded: true,
                selectedDate: today,
                loggedWorkoutDates: loggedDates,
              ),
            ),
          ),
        );

        // Verify tick checkmarks are completely removed
        expect(find.byIcon(Icons.check_rounded), findsNothing);

        // Find day capsules
        final decorations = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) => c.decoration is BoxDecoration)
            .map((c) => c.decoration as BoxDecoration)
            .toList();

        // Expect green capsule for hit gym day
        expect(decorations.any((d) => d.color == AppColors.gymGreen), isTrue);

        // Expect amber / warning for selected day
        expect(decorations.any((d) => d.color == AppColors.warning), isTrue);
      },
    );

    testWidgets('GymContributionChart renders heatmap and day labels', (
      WidgetTester tester,
    ) async {
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

    testWidgets('StepsBentoCard renders minimal step count and triggers tap', (
      WidgetTester tester,
    ) async {
      const telemetry = DailyTelemetry(
        steps: 8420,
        distanceKm: 6.12,
        hourlySteps: [100, 200, 500, 3902, 300, 400],
      );

      var tapped = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: StepsBentoCard(
                telemetry: telemetry,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Steps'), findsOneWidget);
      expect(find.text('8420'), findsOneWidget);

      await tester.tap(find.text('Steps'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets(
      'CaloriesBentoCard, WaterBentoCard, and SleepBentoCard render metrics and tap',
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
          ProviderScope(
            child: MaterialApp(
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
          ),
        );

        expect(find.text('Calories'), findsOneWidget);
        expect(find.text('2390 kcal'), findsOneWidget);
        expect(find.text('Active burn · manual log'), findsOneWidget);
        expect(find.text('Water'), findsOneWidget);
        expect(find.text('2750 ml'), findsOneWidget);
        expect(find.text('of 3500 ml today'), findsOneWidget);
        expect(find.text('Sleep'), findsOneWidget);
        expect(find.text('7.5 h'), findsOneWidget);
        expect(find.textContaining('8.0 h goal'), findsOneWidget);

        await tester.tap(find.text('Calories'));
        await tester.pumpAndSettle();
        expect(calTapped, isTrue);

        await tester.tap(find.text('Water'));
        await tester.pumpAndSettle();
        expect(waterTapped, isTrue);

        await tester.tap(find.text('Sleep'));
        await tester.pumpAndSettle();
        expect(sleepTapped, isTrue);
      },
    );

    testWidgets('Tapping StepsBentoCard opens StepsDetailSheet modal', (
      WidgetTester tester,
    ) async {
      const telemetry = DailyTelemetry(
        steps: 8420,
        distanceKm: 6.12,
        hourlySteps: [100, 200, 500, 3902, 300, 400],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: StepsBentoCard(telemetry: telemetry)),
          ),
        ),
      );

      await tester.tap(find.text('Steps'));
      await tester.pumpAndSettle();

      expect(find.text('Steps'), findsWidgets);
      expect(find.text('Edit step goal'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('30 days'), findsOneWidget);
    });

    testWidgets(
      'DailyWorkoutBentoCard is clutter-free and opens detail modal on tap',
      (WidgetTester tester) async {
        var commenced = false;

        final container = ProviderContainer();
        container.read(workoutRotationProvider.notifier).selectDayByIndex(0);

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

        expect(find.text('NEXT WORKOUT'), findsOneWidget);
        expect(find.text('Push Day A'), findsOneWidget);
        expect(find.textContaining('5 exercises'), findsOneWidget);
        expect(find.text('START WORKOUT'), findsOneWidget);
        expect(find.textContaining('TARGET RPE'), findsNothing);
        expect(find.textContaining('5 EXERCISES'), findsNothing);

        // Tap START WORKOUT directly from card
        await tester.tap(find.text('START WORKOUT'));
        await tester.pumpAndSettle();
        expect(commenced, isTrue);

        // Tap card body to open detail sheet
        await tester.tap(find.text('Push Day A'));
        await tester.pumpAndSettle();

        expect(find.text('EDIT'), findsOneWidget);
        expect(find.text('Barbell Bench Press'), findsOneWidget);
        expect(find.textContaining('3 sets ×'), findsWidgets);
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
      },
    );

    testWidgets(
      'DailyWorkoutBentoCard renders with specular acrylic streak glint',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(body: DailyWorkoutBentoCard()),
            ),
          ),
        );

        final glassCard = tester.widget<GlassCard>(
          find.byType(GlassCard).first,
        );
        expect(glassCard.border, isTrue);

        final customPaints = tester.widgetList<CustomPaint>(
          find.byType(CustomPaint),
        );
        expect(
          customPaints.any(
            (cp) => cp.foregroundPainter is AcrylicStreakPainter,
          ),
          isTrue,
        );

        container.dispose();
      },
    );
  });
}
