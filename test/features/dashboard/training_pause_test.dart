import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/core/providers/local_date_provider.dart';
import 'package:leon/core/theme/app_theme.dart';
import 'package:leon/features/dashboard/providers/dashboard_provider.dart';
import 'package:leon/features/dashboard/providers/home_workout_view_provider.dart';
import 'package:leon/features/dashboard/providers/workout_rotation_provider.dart';
import 'package:leon/features/dashboard/widgets/daily_workout_bento_card.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/features/history/widgets/leon_monthly_calendar.dart';
import 'package:leon/features/workout_builder/models/split_model.dart';
import 'package:leon/features/workout_builder/models/training_schedule.dart';
import 'package:leon/features/workout_builder/providers/splits_provider.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/hive_service.dart';

import '../../helpers/memory_hive_service.dart';

const _split = TrainingSplitModel(
  id: 'custom_pause_ppl',
  name: 'My PPL',
  shortName: 'PPL',
  isCustom: true,
  description: '',
  daysPerWeek: 5,
  plannedMuscleSets: {},
  workouts: [
    SplitWorkoutDay(id: 'push', name: 'Push', targetMuscles: ['Chest']),
    SplitWorkoutDay(id: 'pull', name: 'Pull', targetMuscles: ['Back']),
    SplitWorkoutDay(id: 'legs', name: 'Legs', targetMuscles: ['Legs']),
    SplitWorkoutDay(
      id: 'rest',
      name: 'Recovery',
      targetMuscles: [],
      isRestDay: true,
    ),
  ],
);

WorkoutModel _workout(String day, DateTime date) => WorkoutModel(
  id: day,
  userId: 'guest',
  name: 'PPL · $day',
  date: date,
  trainingPlan: {'splitId': _split.id, 'dayId': day},
);

Future<MemoryHiveService> _storage({
  TrainingSplitModel split = _split,
  List<WorkoutModel>? history,
}) async {
  final hive = MemoryHiveService();
  await hive.put(AppConstants.hiveBoxSplits, split.id, split.toJson());
  hive.settings[AppConstants.settingActiveSplitId] = split.id;
  hive.settings[AppConstants.settingTrainingSchedules] =
      TrainingSchedule.encode([
        TrainingSchedule.fromSplit(split, DateTime(2026, 10, 28)),
      ]);
  for (final workout
      in history ?? [_workout('legs', DateTime(2026, 10, 29, 20))]) {
    await hive.put(AppConstants.hiveBoxWorkouts, workout.id, workout.toJson());
  }
  return hive;
}

ProviderContainer _container(
  MemoryHiveService hive,
  DateTime Function() date,
) => ProviderContainer(
  overrides: [
    hiveServiceProvider.overrideWithValue(hive),
    localDateProvider.overrideWith((ref) => date()),
  ],
);

void main() {
  test(
    'workout-only plans restart their weekly pattern and do not skip sessions over rest',
    () async {
      var today = DateTime(2026, 10, 31);
      final split = _split.copyWith(
        daysPerWeek: 3,
        workouts: _split.workouts.where((day) => !day.isRestDay).toList(),
      );
      final c = _container(await _storage(split: split), () => today);
      addTearDown(c.dispose);
      await c
          .read(splitsProvider.notifier)
          .pauseTraining(resumeOn: DateTime(2026, 11, 3));
      final expected = [
        'push',
        'pull',
        'legs',
        'scheduled_rest',
        'scheduled_rest',
        'scheduled_rest',
        'scheduled_rest',
        'push',
      ];
      for (var i = 0; i < expected.length; i++) {
        final date = DateTime(2026, 11, 3 + i);
        c.read(selectedCalendarDateProvider.notifier).select(date);
        expect(c.read(homeWorkoutViewProvider).day!.id, expected[i]);
        expect(
          c.read(workoutCalendarPlanProvider).isTrainingDay(date),
          expected[i] != 'scheduled_rest',
        );
      }
      today = DateTime(2026, 11, 6);
      c.invalidate(localDateProvider);
      c.read(selectedCalendarDateProvider.notifier).clear();
      expect(c.read(homeWorkoutViewProvider).day!.id, 'scheduled_rest');
    },
  );

  test(
    'indefinite break survives restart and keeps logs and paused dates intact',
    () async {
      var today = DateTime(2026, 10, 30);
      final hive = await _storage();
      var c = _container(hive, () => today);
      expect(c.read(homeWorkoutViewProvider).day!.id, 'rest');
      await c.read(splitsProvider.notifier).pauseTraining();
      c.dispose();

      today = DateTime(2026, 12, 1);
      c = _container(hive, () => today);
      addTearDown(c.dispose);
      expect(c.read(homeWorkoutViewProvider).isPaused, isTrue);
      expect(c.read(homeWorkoutViewProvider).day, isNull);
      expect(c.read(scheduledWorkoutDatesProvider), isEmpty);
      final plan = c.read(workoutCalendarPlanProvider);
      expect(plan.isPausedOn(DateTime(2026, 11, 10)), isTrue);
      expect(plan.isTrainingDay(DateTime(2026, 11, 10)), isFalse);
      expect(
        c.read(historyWorkoutsProvider).single.date,
        DateTime(2026, 10, 29, 20),
      );
      expect(c.read(weeklyConsistencyProvider).plannedThisWeek, 0);
      expect(c.read(weeklyConsistencyProvider).complianceRate.isFinite, isTrue);
    },
  );

  test(
    'resuming after Legs and recovery queues Push and preserves subsequent rest',
    () async {
      var today = DateTime(2026, 10, 30);
      final c = _container(await _storage(), () => today);
      addTearDown(c.dispose);
      await c.read(splitsProvider.notifier).pauseTraining();
      today = DateTime(2026, 11, 3);
      c.invalidate(localDateProvider);
      await c.read(splitsProvider.notifier).resumeTraining();
      expect(c.read(homeWorkoutViewProvider).day!.id, 'push');
      final expected = ['push', 'pull', 'legs', 'rest', 'push'];
      for (var i = 0; i < expected.length; i++) {
        final date = DateTime(today.year, today.month, today.day + i);
        c.read(selectedCalendarDateProvider.notifier).select(date);
        expect(c.read(homeWorkoutViewProvider).day!.id, expected[i]);
        expect(
          c.read(workoutCalendarPlanProvider).isTrainingDay(date),
          expected[i] != 'rest',
        );
      }
      expect(
        c.read(workoutCalendarPlanProvider).isPausedOn(DateTime(2026, 10, 30)),
        isTrue,
      );
      expect(
        c
            .read(workoutCalendarPlanProvider)
            .isTrainingDay(DateTime(2026, 10, 30)),
        isFalse,
      );
    },
  );

  test('resuming early preserves every remaining recovery day', () async {
    var today = DateTime(2026, 10, 30);
    final split = _split.copyWith(
      workouts: [
        ..._split.workouts,
        const SplitWorkoutDay(
          id: 'rest2',
          name: 'Recovery 2',
          targetMuscles: [],
          isRestDay: true,
        ),
      ],
    );
    final c = _container(await _storage(split: split), () => today);
    addTearDown(c.dispose);
    await c.read(splitsProvider.notifier).pauseTraining();
    await c.read(splitsProvider.notifier).resumeTraining();
    expect(c.read(homeWorkoutViewProvider).day!.id, 'rest');
    today = DateTime(2026, 10, 31);
    c.invalidate(localDateProvider);
    expect(c.read(homeWorkoutViewProvider).day!.id, 'rest2');
    today = DateTime(2026, 11, 1);
    c.invalidate(localDateProvider);
    expect(c.read(homeWorkoutViewProvider).day!.id, 'push');
  });

  test(
    'chosen return date previews and automatically resumes from the last workout',
    () async {
      var today = DateTime(2026, 10, 31);
      final hive = await _storage();
      var c = _container(hive, () => today);
      final resumeOn = DateTime(2026, 11, 4);
      await c.read(splitsProvider.notifier).pauseTraining(resumeOn: resumeOn);
      c.dispose();
      c = _container(hive, () => today);
      addTearDown(c.dispose);
      expect(c.read(workoutRotationProvider).isTrainingPaused, isTrue);
      c.read(selectedCalendarDateProvider.notifier).select(resumeOn);
      expect(c.read(homeWorkoutViewProvider).isPaused, isFalse);
      expect(c.read(homeWorkoutViewProvider).day!.id, 'push');
      today = resumeOn;
      c.invalidate(localDateProvider);
      expect(c.read(workoutRotationProvider).isTrainingPaused, isFalse);
      expect(c.read(homeWorkoutViewProvider).day!.id, 'push');
      expect(
        c.read(workoutCalendarPlanProvider).isPausedOn(DateTime(2026, 11, 3)),
        isTrue,
      );
    },
  );

  test(
    'return date can be extended indefinitely or resumed early without phantom dates',
    () async {
      var today = DateTime(2026, 10, 31);
      final c = _container(await _storage(), () => today);
      addTearDown(c.dispose);
      await c
          .read(splitsProvider.notifier)
          .pauseTraining(resumeOn: DateTime(2026, 11, 3));
      today = DateTime(2026, 11, 2);
      c.invalidate(localDateProvider);
      await c.read(splitsProvider.notifier).pauseTraining();
      expect(
        trainingResumeDate(c.read(splitsProvider).schedules, today),
        isNull,
      );
      expect(
        c.read(workoutCalendarPlanProvider).isPausedOn(DateTime(2026, 11, 10)),
        isTrue,
      );
      await c.read(splitsProvider.notifier).resumeTraining();
      expect(c.read(homeWorkoutViewProvider).day!.id, 'push');
      expect(
        c.read(workoutCalendarPlanProvider).isPausedOn(DateTime(2026, 11, 1)),
        isTrue,
      );
    },
  );

  test(
    'edited history controls the return workout and future logs are ignored',
    () async {
      final today = DateTime(2026, 10, 31);
      final c = _container(
        await _storage(
          history: [
            _workout('legs', DateTime(2026, 10, 29, 20)),
            _workout('push', DateTime(2026, 11, 10, 20)),
          ],
        ),
        () => today,
      );
      addTearDown(c.dispose);
      c.read(workoutRotationProvider.notifier).selectDayByIndex(1);
      await c.read(splitsProvider.notifier).pauseTraining();
      final original = c
          .read(historyWorkoutsProvider)
          .firstWhere((w) => w.id == 'legs');
      await c
          .read(historyWorkoutsProvider.notifier)
          .updateWorkout(
            original.copyWith(
              name: 'Renamed workout',
              trainingPlan: {'splitId': _split.id, 'dayId': 'pull'},
            ),
          );
      await c.read(splitsProvider.notifier).resumeTraining();
      expect(c.read(homeWorkoutViewProvider).day!.id, 'legs');
      expect(c.read(workoutRotationProvider).isManuallyOverridden, isFalse);
    },
  );

  test(
    'switching and editing the split keep a break and its chosen return date',
    () async {
      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);
      final returnDate = DateTime(date.year, date.month, date.day + 7);
      final c = _container(await _storage(), () => date);
      addTearDown(c.dispose);
      await c.read(splitsProvider.notifier).pauseTraining(resumeOn: returnDate);
      c.read(splitsProvider.notifier).switchActiveSplit('split_upper_lower');
      expect(c.read(workoutRotationProvider).isTrainingPaused, isTrue);
      expect(c.read(workoutRotationProvider).resumeOn, returnDate);
      final custom = await c
          .read(splitsProvider.notifier)
          .duplicateSplit('split_upper_lower');
      c.read(splitsProvider.notifier).switchActiveSplit(custom.id);
      await c
          .read(splitsProvider.notifier)
          .saveCustomSplit(custom.copyWith(daysPerWeek: 5));
      expect(c.read(workoutRotationProvider).isTrainingPaused, isTrue);
      expect(c.read(workoutRotationProvider).resumeOn, returnDate);
    },
  );

  test('failed persistence leaves the original schedule unchanged', () async {
    final today = DateTime(2026, 10, 31);
    final hive = await _storage();
    final c = _container(hive, () => today);
    addTearDown(c.dispose);
    final original = c.read(splitsProvider).schedules;
    hive.failSettings = true;
    await expectLater(
      c.read(splitsProvider.notifier).pauseTraining(),
      throwsStateError,
    );
    expect(c.read(splitsProvider).schedules, same(original));
    expect(c.read(homeWorkoutViewProvider).isPaused, isFalse);
  });

  test(
    'a break before the first workout returns to the start without inventing history',
    () async {
      var today = DateTime(2026, 10, 31);
      final c = _container(await _storage(history: []), () => today);
      addTearDown(c.dispose);
      await c.read(splitsProvider.notifier).pauseTraining();
      today = DateTime(2026, 11, 10);
      c.invalidate(localDateProvider);
      await c.read(splitsProvider.notifier).resumeTraining();
      expect(c.read(homeWorkoutViewProvider).day!.id, 'push');
      expect(c.read(historyWorkoutsProvider), isEmpty);
    },
  );

  test('old schedule JSON still decodes without pause fields', () {
    final schedule = TrainingSchedule.decode(
      jsonEncode([
        {
          'splitId': 'old',
          'startedOn': '2026-10-28T00:00:00.000',
          'trainingDays': [true, false],
        },
      ]),
    ).single;
    expect(schedule.isPaused, isFalse);
    expect(schedule.historyStartedOn, schedule.startedOn);
  });

  testWidgets('Home offers a complete pause, preview and resume flow', (
    tester,
  ) async {
    final today = DateTime(2026, 10, 31);
    final c = _container(await _storage(), () => today);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SingleChildScrollView(child: DailyWorkoutBentoCard()),
          ),
        ),
      ),
    );
    await tester.tap(find.text('PAUSE TRAINING'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PAUSE UNTIL I RESUME'));
    await tester.pumpAndSettle();
    expect(find.text('Training paused'), findsOneWidget);
    expect(find.text('START WORKOUT'), findsNothing);
    await tester.tap(find.text('RESUME TRAINING'));
    await tester.pumpAndSettle();
    expect(find.text('IF YOU RESUME TODAY'), findsOneWidget);
    expect(find.text('Push'), findsWidgets);
    expect(find.text('Recovery'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'RESUME TRAINING').last);
    await tester.pumpAndSettle();
    expect(find.text('Push'), findsOneWidget);
    expect(c.read(homeWorkoutViewProvider).isPaused, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('History calendar identifies paused days across the month', (
    tester,
  ) async {
    var today = DateTime(2026, 10, 30);
    final c = _container(await _storage(), () => today);
    addTearDown(c.dispose);
    await c.read(splitsProvider.notifier).pauseTraining();
    today = DateTime(2026, 11, 10);
    c.invalidate(localDateProvider);
    await c.read(splitsProvider.notifier).resumeTraining();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: LeonMonthlyCalendar(
              initialMonth: DateTime(2026, 11, 1),
              initialCollapsed: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('November 2, 2026, training paused')),
      findsOneWidget,
    );
    expect(find.text('PAUSED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
