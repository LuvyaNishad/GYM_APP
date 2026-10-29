import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/core/providers/local_date_provider.dart';
import 'package:leon/features/dashboard/providers/home_workout_view_provider.dart';
import 'package:leon/features/dashboard/providers/workout_rotation_provider.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/features/workout_builder/models/split_model.dart';
import 'package:leon/features/workout_builder/providers/splits_provider.dart';
import 'package:leon/features/workout_builder/providers/routine_draft_provider.dart';
import 'package:leon/features/workout_builder/providers/weekly_volume_provider.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/hive_service.dart';
import '../../helpers/memory_hive_service.dart';

const split = TrainingSplitModel(
  id: 'ab',
  name: 'AB',
  shortName: 'AB',
  daysPerWeek: 3,
  description: '',
  plannedMuscleSets: {},
  workouts: [
    SplitWorkoutDay(id: 'a', name: 'Push A', targetMuscles: ['Chest']),
    SplitWorkoutDay(
      id: 'rest',
      name: 'Rest',
      targetMuscles: [],
      isRestDay: true,
    ),
    SplitWorkoutDay(id: 'b', name: 'Push B', targetMuscles: ['Chest']),
  ],
);

void main() {
  final today = DateTime(2026, 10, 20);
  ProviderContainer setup(List<WorkoutModel> history) {
    final container = ProviderContainer(
      overrides: [
        hiveServiceProvider.overrideWithValue(MemoryHiveService()),
        localDateProvider.overrideWithValue(today),
        historyWorkoutsProvider.overrideWith(() => _History(history)),
        splitsProvider.overrideWith(() => _Splits()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  WorkoutModel workout(String id, String name, int daysAgo, {int hour = 10}) =>
      WorkoutModel(
        id: id,
        userId: 'guest',
        name: name,
        date: today
            .subtract(Duration(days: daysAgo))
            .add(Duration(hours: hour)),
      );

  test('A/B rotation uses the latest matching session on the same date', () {
    final c = setup([
      workout('first', 'AB ● Push A', 1),
      workout('last', 'AB ● Push B', 1, hour: 18),
    ]);
    expect(c.read(workoutRotationProvider).selectedDay.id, 'a');
  });
  test(
    'recovery day lasts one calendar day, then the next training day remains queued',
    () {
      expect(
        setup([
          workout('yesterday', 'AB ● Push A', 1),
        ]).read(workoutRotationProvider).selectedDay.id,
        'rest',
      );
      expect(
        setup([
          workout('older', 'AB ● Push A', 2),
        ]).read(workoutRotationProvider).selectedDay.id,
        'b',
      );
    },
  );
  test(
    'unrelated split does not advance matching day names and manual selection resets on split switch',
    () {
      final c = setup([workout('other', 'OTHER ● Push B', 1)]);
      expect(c.read(workoutRotationProvider).selectedDay.id, 'a');
      c.read(workoutRotationProvider.notifier).selectDayByIndex(2);
      (c.read(splitsProvider.notifier) as _Splits).change();
      expect(c.read(workoutRotationProvider).dayIndex, 0);
    },
  );
  test(
    'selected past day keeps every saved session and future preview follows rotation',
    () {
      final c = setup([
        workout('one', 'AB ● Push A', 1),
        workout('two', 'AB ● Push B', 1, hour: 18),
      ]);
      c
          .read(selectedCalendarDateProvider.notifier)
          .select(today.subtract(const Duration(days: 1)));
      expect(c.read(homeWorkoutViewProvider).logged.length, 2);
      expect(c.read(homeWorkoutViewProvider).day, isNull);
      c
          .read(selectedCalendarDateProvider.notifier)
          .select(today.add(const Duration(days: 1)));
      expect(c.read(homeWorkoutViewProvider).isPast, false);
      expect(c.read(homeWorkoutViewProvider).day!.id, 'rest');
    },
  );
  test(
    'draft customization is isolated and weekly frequency is independent of rotation length',
    () {
      final c = setup([]);
      final provider =
          NotifierProvider<RoutineDraftNotifier, TrainingSplitModel>(
            () => RoutineDraftNotifier(split),
          );
      final draft = c.read(provider.notifier);
      expect(c.read(provider).isCustom, true);
      expect(c.read(provider).id, isNot(split.id));
      draft.rename('My AB');
      draft.setWeeklyDays(5);
      expect(c.read(provider).workouts.length, 3);
      expect(c.read(provider).daysPerWeek, 5);
      expect(c.read(splitsProvider).customSplits, isEmpty);
    },
  );
  test(
    'weekly volume excludes warmups and sessions outside the current week',
    () {
      WorkoutModel logged(String id, DateTime date) => WorkoutModel(
        id: id,
        userId: 'guest',
        name: 'Workout',
        date: date,
        exercises: [
          WorkoutExercise(
            exerciseId: 'row',
            exerciseName: 'Row',
            muscleGroup: 'Back',
            sets: [
              WorkoutSet(reps: 10, weightKg: 20),
              WorkoutSet(reps: 10, weightKg: 10, isWarmup: true),
            ],
          ),
        ],
      );
      expect(
        completedWeeklyMuscleSets([
          logged('now', today),
          logged('old', today.subtract(const Duration(days: 8))),
        ], today),
        {
          'Back': 1,
          'Legs': 0,
          'Chest': 0,
          'Arms': 0,
          'Core': 0,
          'Shoulders': 0,
        },
      );
    },
  );
}

class _Splits extends SplitsNotifier {
  @override
  SplitsState build() =>
      const SplitsState(splits: [split], activeSplitId: 'ab', loggedVolume: {});
  void change() => state = SplitsState(
    splits: [split.copyWith(id: 'new')],
    activeSplitId: 'new',
    loggedVolume: {},
  );
}

class _History extends HistoryWorkoutsNotifier {
  _History(this.initial);
  final List<WorkoutModel> initial;
  @override
  List<WorkoutModel> build() => initial;
}
