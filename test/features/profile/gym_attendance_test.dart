import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/theme/app_colors.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/widgets/gym_contribution_chart.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/models/workout_model.dart';
import '../../helpers/memory_hive_service.dart';
import 'account_layout_test.dart' as account;

void main() {
  testWidgets(
    'attendance counts local gym days and leaves future days neutral',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: GymContributionChart(
              today: DateTime(2026, 11, 3),
              loggedWorkoutDates: {
                DateTime(2026, 11, 3, 10),
                DateTime(2026, 11, 3, 0, 30).toUtc(),
                DateTime(2026, 11, 2, 19),
                DateTime(2026, 11, 4),
                DateTime(2025, 11, 1),
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 gym days in the last 52 weeks'), findsOneWidget);
      Color? color(String day) =>
          (tester
                      .widget<Container>(
                        find.byKey(ValueKey('gym-day-${day}T00:00:00.000')),
                      )
                      .decoration
                  as BoxDecoration)
              .color;
      expect(color('2026-11-03'), AppColors.primary);
      expect(color('2026-11-02'), AppColors.primary);
      expect(color('2026-11-01'), AppColors.surfaceSecondary);
      expect(color('2026-11-04'), AppColors.surfaceSecondary);
      expect(find.textContaining('Scheduled'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Account attendance follows saved workout edits and deletions', (
    tester,
  ) async {
    final storage = MemoryHiveService();
    final workout = WorkoutModel(
      id: 'one',
      userId: 'guest',
      name: 'Push day',
      date: DateTime(2026, 11, 3, 9),
    );
    for (final entry in [workout, workout.copyWith(id: 'two')]) {
      await storage.put(AppConstants.hiveBoxWorkouts, entry.id, entry.toJson());
    }
    final container = await account.mountAccount(tester, storage: storage);
    expect(find.text('1 gym day in the last 52 weeks'), findsOneWidget);
    final history = container.read(historyWorkoutsProvider.notifier);
    await history.updateWorkout(workout.copyWith(date: DateTime(2026, 11, 2)));
    await tester.pumpAndSettle();
    expect(find.text('2 gym days in the last 52 weeks'), findsOneWidget);
    await history.deleteWorkout('two');
    await tester.pumpAndSettle();
    expect(find.text('1 gym day in the last 52 weeks'), findsOneWidget);
    await history.deleteWorkout('one');
    await tester.pumpAndSettle();
    expect(find.text('0 gym days in the last 52 weeks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
