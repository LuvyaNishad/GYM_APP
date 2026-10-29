import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leon/features/exercise_library/models/exercise_library_item.dart';
import 'package:leon/features/history/models/muscle_workload.dart';
import 'package:leon/features/history/models/training_coverage.dart';
import 'package:leon/features/history/providers/history_provider.dart';
import 'package:leon/features/history/providers/training_coverage_provider.dart';
import 'package:leon/features/history/widgets/muscle_radar_tab_view.dart';
import 'package:leon/features/history/widgets/muscle_workload_chart.dart';
import 'package:leon/models/workout_model.dart';
import 'training_coverage_test.dart' as fixtures;

class _History extends HistoryWorkoutsNotifier {
  _History(this.workouts);
  final List<WorkoutModel> workouts;
  @override
  List<WorkoutModel> build() => workouts;
}

void main() {
  test(
    'compound sets count once per category, with supporting work separated',
    () {
      final index = TrainingCoverageIndex(fixtures.split, [
        ...fixtures.catalog,
        const ExerciseLibraryItem(
          id: 'squat',
          name: 'Squat',
          category: 'Legs',
          description: '',
          primaryMuscles: ['quadriceps', 'glutes'],
          secondaryMuscles: ['hamstrings', 'abdominals'],
        ),
      ]);
      final workout = fixtures.workout(
        exercises: [
          fixtures.logged(fixtures.row, 3),
          const WorkoutExercise(
            exerciseId: 'squat',
            exerciseName: 'Squat',
            muscleGroup: 'Legs',
            sets: [
              WorkoutSet(reps: 8, weightKg: 50),
              WorkoutSet(reps: 8, weightKg: 20, isWarmup: true),
              WorkoutSet(reps: 0, weightKg: 50),
            ],
          ),
          fixtures.logged(fixtures.curl, 2, warmup: true),
        ],
      );
      final result = MuscleWorkload.fromWorkout(workout, index);
      final back = result.muscles.firstWhere((m) => m.name == 'Back');
      final legs = result.muscles.firstWhere((m) => m.name == 'Legs');
      final arms = result.muscles.firstWhere((m) => m.name == 'Arms');
      expect(
        back.direct,
        3,
        reason: 'Lats and rhomboids must not duplicate a row set',
      );
      expect(back.supporting, 0);
      expect(
        legs.completed,
        1,
        reason: 'Quads, glutes and hamstrings share one category',
      );
      expect(arms.direct, 0);
      expect(arms.supporting, closeTo(1.05, .001));
      expect(result.muscles.firstWhere((m) => m.name == 'Core').completed, .35);
      expect(result.workingSets, 4);
      expect(result.volumeKg, 1120);
    },
  );

  test(
    'saved plan targets use one contribution per exercise and broad category',
    () {
      final index = TrainingCoverageIndex(fixtures.split, fixtures.catalog);
      final plan = CoveragePlan(
        splitId: 'custom',
        dayId: 'pull',
        dayName: 'Pull',
        exercises: [
          CoverageExercisePlan(
            id: 'row',
            name: 'Cable Row',
            sets: 3,
            weights: {'Lats': 1, 'Mid back': 1, 'Biceps': .35},
          ),
        ],
      );
      final result = MuscleWorkload.fromWorkout(
        fixtures.workout(),
        index,
        plan: plan,
      );
      expect(result.muscles.firstWhere((m) => m.name == 'Back').planned, 3);
      expect(
        result.muscles.firstWhere((m) => m.name == 'Arms').planned,
        closeTo(1.05, .001),
      );
      expect(result.hasPlan, true);
    },
  );

  test(
    'weekly workload sums sessions and estimates supporting routine targets',
    () {
      final index = TrainingCoverageIndex(
        fixtures.split.copyWith(workouts: [fixtures.pull], daysPerWeek: 1),
        fixtures.catalog,
      );
      final one = MuscleWorkload.fromWorkout(fixtures.workout(), index);
      final week = MuscleWorkload.combine([
        one,
        one,
      ], targets: weeklyWorkloadTargets(index));
      expect(week.workoutCount, 2);
      expect(week.workingSets, 18);
      expect(week.muscles.firstWhere((m) => m.name == 'Back').direct, 12);
      expect(week.muscles.firstWhere((m) => m.name == 'Back').planned, 6);
      expect(
        week.muscles.firstWhere((m) => m.name == 'Arms').planned,
        closeTo(5.1, .001),
      );
      expect(muscleWorkloadScale([one, week]), 20);
      expect(muscleWorkloadScale([week], minimum: 60), 60);
    },
  );

  testWidgets(
    'tap details reveal zero and supporting work without replaying animation',
    (tester) async {
      final index = TrainingCoverageIndex(fixtures.split, fixtures.catalog);
      final result = MuscleWorkload.fromWorkout(fixtures.workout(), index);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MuscleWorkloadChart(workload: result, maxSets: 20),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shoulders'));
      await tester.pumpAndSettle();
      expect(find.text('SHOULDERS WORKLOAD'), findsOneWidget);
      expect(
        find.text('Supporting work from other exercises.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Core'));
      await tester.pumpAndSettle();
      expect(find.text('CORE WORKLOAD'), findsOneWidget);
      expect(
        find.text('No work logged for this muscle in this view.'),
        findsOneWidget,
      );
      expect(tester.binding.hasScheduledFrame, false);
    },
  );

  testWidgets(
    'week scope excludes other weeks and future workouts and avoids historical targets',
    (tester) async {
      final index = TrainingCoverageIndex(fixtures.split, fixtures.catalog);
      final workouts = [
        fixtures.workout(id: 'one', date: DateTime(2026, 10, 26)),
        fixtures.workout(id: 'two', date: DateTime(2026, 10, 28)),
        fixtures.workout(id: 'old', date: DateTime(2026, 10, 18)),
        fixtures.workout(
          id: 'future',
          date: DateTime.now().add(const Duration(days: 10)),
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          trainingCoverageIndexProvider.overrideWithValue(index),
          historyWorkoutsProvider.overrideWith(() => _History(workouts)),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(selectedCalendarDateProvider.notifier)
          .select(DateTime(2026, 10, 28));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: MuscleRadarTabView()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('This week'));
      await tester.pumpAndSettle();
      final chart = tester.widget<MuscleWorkloadChart>(
        find.byType(MuscleWorkloadChart),
      );
      expect(chart.workload.workoutCount, 2);
      expect(chart.workload.workingSets, 18);
      expect(find.text('MUSCLE BREAKDOWN'), findsNothing);
      container
          .read(selectedCalendarDateProvider.notifier)
          .select(DateTime(2026, 10, 18));
      await tester.pumpAndSettle();
      final past = tester.widget<MuscleWorkloadChart>(
        find.byType(MuscleWorkloadChart),
      );
      expect(past.workload.workoutCount, 1);
      expect(past.workload.hasPlan, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
