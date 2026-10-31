import 'package:flutter_test/flutter_test.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/workout_history.dart';
import 'package:leon/services/workout_service.dart';

WorkoutModel log(
  String id,
  int day,
  List<WorkoutSet> sets, {
  String user = 'guest',
  bool warmup = false,
}) => WorkoutModel(
  id: id,
  userId: user,
  name: 'Workout',
  date: DateTime(2026, 10, day),
  notes: 'Original note',
  trainingPlan: const {'target': 3},
  exercises: [
    WorkoutExercise(
      exerciseId: 'row',
      exerciseName: 'Row',
      muscleGroup: 'Back',
      supersetGroupId: 'pair',
      rpe: 8,
      isWarmup: warmup,
      sets: sets,
    ),
  ],
);

void main() {
  test(
    'chronological PRs change when an old baseline is edited or deleted',
    () {
      final first = log('first', 1, [const WorkoutSet(weightKg: 40, reps: 10)]);
      final second = log('second', 2, [
        const WorkoutSet(weightKg: 50, reps: 10),
      ]);
      final third = log('third', 3, [
        const WorkoutSet(weightKg: 45, reps: 10, isPr: true),
      ]);
      var history = recalculateWorkoutHistory([third, first, second]);
      expect(history.map((w) => w.exercises.single.sets.single.isPr), [
        false,
        true,
        false,
      ]);
      final edited = log('second', 2, [
        const WorkoutSet(weightKg: 42, reps: 10),
      ]);
      history = recalculateWorkoutHistory([first, edited, third]);
      expect(history.first.exercises.single.sets.single.isPr, isTrue);
      expect(
        recalculateWorkoutHistory([
          third,
        ]).single.exercises.single.sets.single.isPr,
        isFalse,
      );
    },
  );

  test(
    'unilateral volume and PRs compare each side independently and preserve metadata',
    () {
      final first = log('first', 1, [
        const WorkoutSet(
          weightKg: 40,
          reps: 10,
          weightKgRight: 20,
          repsRight: 8,
          rpe: 7.5,
        ),
      ]);
      final second = log('second', 2, [
        const WorkoutSet(
          weightKg: 40,
          reps: 10,
          weightKgRight: 25,
          repsRight: 8,
          rpe: 8.5,
        ),
      ]);
      final history = recalculateWorkoutHistory([first, second]);
      final latest = history.first;
      expect(latest.totalVolumeKg, 600);
      expect(latest.averageRpe, 8.5);
      expect(latest.exercises.single.sets.single.isPr, isTrue);
      expect(latest.exercises.single.supersetGroupId, 'pair');
      expect(latest.exercises.single.rpe, 8);
      expect(latest.notes, 'Original note');
      expect(latest.trainingPlan, {'target': 3});
      expect(WorkoutService.totalVolumeKg(latest), latest.totalVolumeKg);
    },
  );

  test(
    'warmups cannot inflate volume or establish PR baselines; users remain separate',
    () {
      final warmup = log('warmup', 1, [
        const WorkoutSet(weightKg: 100, reps: 10),
      ], warmup: true);
      final first = log('first', 2, [
        const WorkoutSet(weightKg: 40, reps: 10),
        WorkoutSet(weightKg: 200, reps: 10, isWarmup: true, isPr: true),
      ]);
      final other = log('other', 3, [
        const WorkoutSet(weightKg: 50, reps: 10),
      ], user: 'other');
      final history = recalculateWorkoutHistory([warmup, first, other]);
      expect(history.first.exercises.single.sets.single.isPr, isFalse);
      expect(history[1].totalVolumeKg, 400);
      expect(history[1].exercises.single.sets.map((s) => s.isPr), [
        false,
        false,
      ]);
      expect(history.last.totalVolumeKg, 0);
      expect(WorkoutService.totalVolumeKg(history.last), 0);
    },
  );

  test(
    'one-rep estimates, bodyweight rep records, and legacy partial right data are consistent',
    () {
      final first = log('first', 1, [const WorkoutSet(weightKg: 0, reps: 10)]);
      final next = log('next', 2, [const WorkoutSet(weightKg: 0, reps: 12)]);
      expect(
        recalculateWorkoutHistory([
          first,
          next,
        ]).first.exercises.single.sets.single.isPr,
        isTrue,
      );
      final partial = log('partial', 3, [
        const WorkoutSet(weightKg: 10, reps: 5, weightKgRight: 8),
      ]);
      expect(recalculateWorkoutHistory([partial]).single.totalVolumeKg, 90);
      expect(WorkoutService.totalVolumeKg(partial), 90);
      final repsOnly = log('repsOnly', 4, [
        const WorkoutSet(weightKg: 10, reps: 5, repsRight: 8),
      ]);
      expect(recalculateWorkoutHistory([repsOnly]).single.totalVolumeKg, 130);
      expect(WorkoutService.totalVolumeKg(repsOnly), 130);
      final invalid = log('invalid', 5, [
        const WorkoutSet(
          weightKg: double.nan,
          reps: 5,
          weightKgRight: 10,
          repsRight: 8,
        ),
      ]);
      expect(recalculateWorkoutHistory([invalid]).single.totalVolumeKg, 80);
      expect(WorkoutService.totalVolumeKg(invalid), 80);
    },
  );
}
