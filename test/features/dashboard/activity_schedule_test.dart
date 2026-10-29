import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/providers/local_date_provider.dart';
import 'package:leon/core/theme/app_colors.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/providers/dashboard_provider.dart';
import 'package:leon/features/dashboard/widgets/retractable_calendar_header.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/features/workout_builder/models/split_model.dart';
import 'package:leon/features/workout_builder/models/training_schedule.dart';
import 'package:leon/features/workout_builder/providers/splits_provider.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/hive_service.dart';
import '../../helpers/memory_hive_service.dart';

const recoverySplit = TrainingSplitModel(
  id: 'recovery',
  name: 'Recovery split',
  shortName: 'REC',
  daysPerWeek: 2,
  description: '',
  plannedMuscleSets: {},
  workouts: [
    SplitWorkoutDay(id: 'push', name: 'Push', targetMuscles: ['Chest']),
    SplitWorkoutDay(
      id: 'rest',
      name: 'Recovery',
      targetMuscles: [],
      isRestDay: true,
    ),
    SplitWorkoutDay(id: 'pull', name: 'Pull', targetMuscles: ['Back']),
  ],
);

class _History extends HistoryWorkoutsNotifier {
  _History(this.workouts);
  final List<WorkoutModel> workouts;
  @override
  List<WorkoutModel> build() => workouts;
}

Color? dayColor(WidgetTester tester, DateTime date) =>
    (tester
                .widget<Container>(
                  find.byKey(
                    ValueKey(
                      'activity-day-${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                )
                .decoration
            as BoxDecoration)
        .color;

void main() {
  test(
    'A schedule starting on the 28th never schedules the 26th or 27th and preserves recovery',
    () {
      final schedule = TrainingSchedule.fromSplit(
        recoverySplit,
        DateTime(2026, 10, 28, 18),
      );
      expect(schedule.isTrainingDay(DateTime(2026, 10, 26)), isFalse);
      expect(schedule.isTrainingDay(DateTime(2026, 10, 27)), isFalse);
      expect(schedule.isTrainingDay(DateTime(2026, 10, 28)), isTrue);
      expect(schedule.isTrainingDay(DateTime(2026, 10, 29)), isFalse);
      expect(schedule.isTrainingDay(DateTime(2026, 10, 30)), isTrue);
    },
  );

  test(
    'Workout-only plans include rest days from the weekly target; switches preserve past dates',
    () {
      final weekly = recoverySplit.copyWith(
        id: 'weekly',
        daysPerWeek: 5,
        workouts: [recoverySplit.workouts.first],
      );
      final started = TrainingSchedule.fromSplit(
        weekly,
        DateTime(2026, 10, 28),
      );
      expect(started.isTrainingDay(DateTime(2026, 11, 1)), isTrue);
      expect(started.isTrainingDay(DateTime(2026, 11, 2)), isFalse);
      expect(started.isTrainingDay(DateTime(2026, 11, 3)), isFalse);
      final timeline = startTrainingSchedule(
        [started],
        recoverySplit,
        DateTime(2026, 11, 4),
      );
      final saved = TrainingSchedule.decode(TrainingSchedule.encode(timeline));
      expect(isScheduledTrainingDay(saved, DateTime(2026, 11, 2)), isFalse);
      expect(isScheduledTrainingDay(saved, DateTime(2026, 11, 4)), isTrue);
      expect(isScheduledTrainingDay(saved, DateTime(2026, 11, 5)), isFalse);
    },
  );

  testWidgets(
    'Legacy start is migrated from actual history and survives restart and split switches',
    (tester) async {
      final now = scheduleDate(DateTime.now());
      final started = DateTime(now.year, now.month, now.day - 1);
      final store = MemoryHiveService();
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(store),
          localDateProvider.overrideWithValue(now),
          historyWorkoutsProvider.overrideWith(
            () => _History([
              WorkoutModel(
                id: 'first',
                userId: 'local',
                name: 'Push Day A',
                date: started,
              ),
            ]),
          ),
        ],
      );
      final initial = container.read(splitsProvider);
      expect(initial.schedules.single.startedOn, started);
      expect(store.settings[AppConstants.settingTrainingSchedules], isNotNull);
      expect(
        isScheduledTrainingDay(
          initial.schedules,
          DateTime(started.year, started.month, started.day - 1),
        ),
        isFalse,
      );
      final weekly = container.read(scheduledWorkoutDatesProvider);
      for (final day in weekly) {
        expect(day.isBefore(started), isFalse);
      }
      container
          .read(splitsProvider.notifier)
          .switchActiveSplit('split_upper_lower');
      final switched = container.read(splitsProvider);
      expect(switched.schedules.first.startedOn, started);
      expect(switched.schedules.last.startedOn, now);
      container.dispose();
      final restored = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(store),
          historyWorkoutsProvider.overrideWith(() => _History([])),
        ],
      );
      expect(restored.read(splitsProvider).schedules.first.startedOn, started);
      expect(restored.read(splitsProvider).activeSplitId, 'split_upper_lower');
      restored.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'Only missed scheduled past days are red; rest and before-start stay neutral',
    (tester) async {
      final today = scheduleDate(DateTime.now());
      final monday = DateTime(
        today.year,
        today.month,
        today.day - today.weekday + 1,
      );
      DateTime at(int day) =>
          DateTime(monday.year, monday.month, monday.day + day);
      // Display last week: completed Monday, rest Tuesday, missed Wednesday,
      // and unscheduled Thursday-Sunday. Selecting an unscheduled day remains amber.
      final previousMonday = DateTime(
        monday.year,
        monday.month,
        monday.day - 7,
      );
      DateTime previous(int day) => DateTime(
        previousMonday.year,
        previousMonday.month,
        previousMonday.day + day,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: RetractableCalendarHeader(
              userName: 'Leon',
              selectedDate: previous(6),
              loggedWorkoutDates: {previous(0)},
              scheduledWorkoutDates: {previous(0), previous(2)},
            ),
          ),
        ),
      );
      expect(dayColor(tester, previous(0)), AppColors.gymGreen);
      expect(dayColor(tester, previous(1)), AppColors.charcoal);
      expect(dayColor(tester, previous(2)), AppColors.gymRed);
      expect(dayColor(tester, previous(3)), AppColors.charcoal);
      expect(dayColor(tester, previous(6)), AppColors.warning);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: RetractableCalendarHeader(
              userName: 'Leon',
              selectedDate: today,
              scheduledWorkoutDates: {today, at(6)},
            ),
          ),
        ),
      );
      expect(dayColor(tester, today), AppColors.warning);
      if (at(6).isAfter(today)) {
        expect(dayColor(tester, at(6)), AppColors.charcoal);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
