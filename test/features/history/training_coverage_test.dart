import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leon/core/constants/app_constants.dart';
import 'package:leon/features/exercise_library/models/exercise_library_item.dart';
import 'package:leon/features/history/models/training_coverage.dart';
import 'package:leon/features/history/providers/training_coverage_provider.dart';
import 'package:leon/features/workout_builder/models/split_model.dart';
import 'package:leon/features/workout_session/models/active_session_state.dart';
import 'package:leon/features/workout_session/providers/active_session_provider.dart';
import 'package:leon/models/workout_model.dart';
import 'package:leon/services/hive_service.dart';
import '../../helpers/memory_hive_service.dart';

const press = PlannedExercise(
  exerciseId: 'press',
  exerciseName: 'Shoulder Press',
  muscleGroup: 'Shoulders',
);
const lateral = PlannedExercise(
  exerciseId: 'lateral',
  exerciseName: 'Lateral Raise',
  muscleGroup: 'Shoulders',
);
const rear = PlannedExercise(
  exerciseId: 'rear',
  exerciseName: 'Reverse Fly',
  muscleGroup: 'Shoulders',
);
const row = PlannedExercise(
  exerciseId: 'row',
  exerciseName: 'Cable Row',
  muscleGroup: 'Back',
);
const curl = PlannedExercise(
  exerciseId: 'curl',
  exerciseName: 'Biceps Curl',
  muscleGroup: 'Biceps',
);
const pulldown = PlannedExercise(
  exerciseId: 'pulldown',
  exerciseName: 'Lat Pulldown',
  muscleGroup: 'Back',
);
const push = SplitWorkoutDay(
  id: 'push',
  name: 'Push Day',
  targetMuscles: ['Shoulders'],
  exercises: [press, lateral, rear],
);
const pull = SplitWorkoutDay(
  id: 'pull',
  name: 'Pull Day',
  targetMuscles: ['Back', 'Biceps'],
  exercises: [row, curl, pulldown],
);
const split = TrainingSplitModel(
  id: 'custom',
  name: 'My Split',
  shortName: 'MY',
  daysPerWeek: 3,
  description: '',
  workouts: [push, pull],
  plannedMuscleSets: {},
);
const catalog = [
  ExerciseLibraryItem(
    id: 'press',
    name: 'Shoulder Press',
    category: 'Shoulders',
    description: '',
    primaryMuscles: ['anterior deltoid'],
    secondaryMuscles: ['medial deltoid', 'triceps'],
  ),
  ExerciseLibraryItem(
    id: 'lateral',
    name: 'Lateral Raise',
    category: 'Shoulders',
    description: '',
    primaryMuscles: ['medial deltoid'],
  ),
  ExerciseLibraryItem(
    id: 'rear',
    name: 'Reverse Fly',
    category: 'Shoulders',
    description: '',
    primaryMuscles: ['rear deltoid'],
    secondaryMuscles: ['rhomboids'],
  ),
  ExerciseLibraryItem(
    id: 'row',
    name: 'Cable Row',
    category: 'Back',
    description: '',
    primaryMuscles: ['rhomboids'],
    secondaryMuscles: ['rear deltoid', 'biceps', 'lats'],
  ),
  ExerciseLibraryItem(
    id: 'pulldown',
    name: 'Lat Pulldown',
    category: 'Back',
    description: '',
    primaryMuscles: ['lats'],
    secondaryMuscles: ['biceps', 'rear deltoid'],
  ),
  ExerciseLibraryItem(
    id: 'curl',
    name: 'Biceps Curl',
    category: 'Arms',
    description: '',
    primaryMuscles: ['biceps'],
    secondaryMuscles: ['forearms'],
  ),
  ExerciseLibraryItem(
    id: 'substitute',
    name: 'Chest Supported Row',
    category: 'Back',
    description: '',
    primaryMuscles: ['rhomboids'],
    secondaryMuscles: ['biceps', 'lats'],
  ),
];

WorkoutExercise logged(
  PlannedExercise exercise,
  int count, {
  bool warmup = false,
}) => WorkoutExercise(
  exerciseId: exercise.exerciseId,
  exerciseName: exercise.exerciseName,
  muscleGroup: exercise.muscleGroup,
  isWarmup: warmup,
  sets: List.generate(count, (_) => const WorkoutSet(reps: 8, weightKg: 30)),
);
WorkoutModel workout({
  String id = 'w1',
  SplitWorkoutDay day = pull,
  List<WorkoutExercise>? exercises,
  DateTime? date,
  CoveragePlan? plan,
}) => WorkoutModel(
  id: id,
  userId: 'u',
  name: 'MY · ${day.name}',
  date: date ?? DateTime(2026, 10, 28),
  exercises:
      exercises ?? [logged(row, 3), logged(curl, 3), logged(pulldown, 3)],
  trainingPlan: plan?.toJson(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final index = TrainingCoverageIndex(split, catalog);

  test(
    'routine day names with internal separators keep their full identity',
    () {
      final namedDay = pull.copyWith(name: 'Pull Day ● Workout A');
      final named = TrainingCoverageIndex(
        split.copyWith(workouts: [push, namedDay]),
        catalog,
      );
      expect(
        named.match(workout().copyWith(name: 'MY · Pull Day ● Workout A'))?.id,
        'pull',
      );
      expect(
        named.match(workout().copyWith(name: 'Pull Day ● Workout A'))?.id,
        'pull',
      );
      expect(muscleArea('biceps femoris'), 'Hamstrings');
      expect(
        index.match(
          workout(exercises: [logged(row, 1)]).copyWith(name: 'Freestyle'),
        ),
        isNull,
      );
    },
  );

  test(
    'all shoulder heads stay on Push; indirect Pull work never creates shoulder gaps',
    () {
      expect(
        index.planFor(push).targets.keys,
        containsAll(['Front delts', 'Side delts', 'Rear delts']),
      );
      final plan = index.planFor(pull);
      expect(
        plan.targets.keys,
        unorderedEquals(['Mid back', 'Lats', 'Biceps']),
      );
      final coverage = coverageFor(workout(exercises: [logged(row, 1)]), index);
      expect(
        coverage.gaps.map((m) => m.name),
        unorderedEquals(['Mid back', 'Lats', 'Biceps']),
      );
      expect(
        coverage.muscles.any((m) => muscleFamily(m.name) == 'Shoulders'),
        false,
      );
    },
  );

  test('moving rear-delt exercise to Pull makes it a Pull target', () {
    final moved = split.copyWith(
      workouts: [
        push.copyWith(exercises: [press, lateral]),
        pull.copyWith(exercises: [row, curl, pulldown, rear]),
      ],
    );
    final adaptive = TrainingCoverageIndex(moved, catalog);
    expect(
      adaptive.planFor(moved.workouts.last).targets,
      contains('Rear delts'),
    );
    expect(
      adaptive.planFor(moved.workouts.first).targets,
      isNot(contains('Rear delts')),
    );
  });

  test(
    'warmups and zero-rep sets excluded; mapped substitute credits planned muscles',
    () {
      final completed = workout(
        exercises: [
          logged(row, 8, warmup: true),
          const WorkoutExercise(
            exerciseId: 'substitute',
            exerciseName: 'Chest Supported Row',
            muscleGroup: 'Back',
            sets: [
              WorkoutSet(reps: 8, weightKg: 20),
              WorkoutSet(reps: 0, weightKg: 20),
              WorkoutSet(reps: 8, weightKg: 10, isWarmup: true),
            ],
          ),
        ],
      );
      final coverage = coverageFor(completed, index);
      expect(
        coverage.muscles.firstWhere((m) => m.name == 'Mid back').completed,
        1,
      );
      expect(
        coverage.muscles.firstWhere((m) => m.name == 'Biceps').completed,
        .35,
      );
      expect(coverage.gaps.length, 3);
    },
  );

  test('unmatched workout has no invented deficiencies', () {
    final unmatched = workout(
      exercises: [
        const WorkoutExercise(
          exerciseId: 'other',
          exerciseName: 'Unknown Move',
          muscleGroup: 'Mystery',
        ),
      ],
    ).copyWith(name: 'Freestyle');
    final coverage = coverageFor(unmatched, index);
    expect(coverage.plan, isNull);
    expect(coverage.gaps, isEmpty);
    expect(CoveragePlan.fromJson({'broken': true}), isNull);
    expect(
      recommendTraining(index, pull, [unmatched], DateTime(2026, 10, 30)),
      isNull,
    );
  });

  test(
    'ambiguous A/B overlap and unrelated split prefixes do not guess a routine',
    () {
      final ambiguous = TrainingCoverageIndex(
        split.copyWith(
          workouts: [
            pull,
            pull.copyWith(id: 'pull_b', name: 'Pull B'),
          ],
        ),
        catalog,
      );
      expect(ambiguous.match(workout().copyWith(name: 'Freestyle')), isNull);
      expect(index.match(workout().copyWith(name: 'OTHER · Pull Day')), isNull);
    },
  );

  test(
    'gap returns on next compatible workout; unrelated day ignores it and newest full session clears it',
    () {
      final partial = workout(exercises: [logged(row, 3), logged(pulldown, 3)]);
      final next = recommendTraining(index, pull, [
        partial,
      ], DateTime(2026, 10, 30));
      expect(next!.muscle.name, 'Biceps');
      expect(next.exercise.id, 'curl');
      expect(
        recommendTraining(index, push, [partial], DateTime(2026, 10, 30)),
        isNull,
      );
      final full = workout(id: 'new', date: DateTime(2026, 10, 29));
      expect(
        recommendTraining(index, pull, [partial, full], DateTime(2026, 10, 30)),
        isNull,
      );
      expect(
        recommendTraining(index, pull, [
          partial,
          full,
        ], DateTime(2026, 10, 28, 23)),
        isNotNull,
      );
      final changedSplit = TrainingCoverageIndex(
        split.copyWith(id: 'different'),
        catalog,
      );
      expect(
        recommendTraining(changedSplit, pull, [
          partial.copyWith(trainingPlan: index.planFor(pull).toJson()),
        ], DateTime(2026, 10, 30)),
        isNull,
      );
    },
  );

  test(
    'saved targets survive draft recovery, routine edits and final workout serialization',
    () async {
      final hive = MemoryHiveService();
      final container = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(hive),
          trainingCoverageIndexProvider.overrideWithValue(index),
        ],
      );
      final notifier = container.read(activeSessionProvider.notifier);
      notifier.startSession(
        splitName: 'MY · Pull Day',
        initialExercises: pull.exercises
            .map((e) => e.toActiveExerciseState())
            .toList(),
      );
      await notifier.flushPendingChanges();
      final stored =
          jsonDecode(
                jsonEncode(
                  hive.settings[AppConstants.settingActiveSessionData],
                ),
              )
              as Map<String, dynamic>;
      final restored = ActiveSessionState.fromJson(stored);
      expect(
        CoveragePlan.fromJson(restored.trainingPlan)!.targets,
        index.planFor(pull).targets,
      );
      notifier.logSet(exerciseId: 'row', setIndex: 0, completed: true);
      final snapshot = WorkoutModel.fromJson(
        jsonDecode(jsonEncode(notifier.snapshotWorkout().toJson()))
            as Map<String, dynamic>,
      );
      await notifier.saveSession();
      final saved = hive
          .readAll(AppConstants.hiveBoxWorkouts, WorkoutModel.fromJson)
          .single;
      expect(saved.trainingPlan, snapshot.trainingPlan);
      container.dispose();
      final changedIndex = TrainingCoverageIndex(
        split.copyWith(
          workouts: [
            push,
            pull.copyWith(exercises: [row]),
          ],
        ),
        catalog,
      );
      final coverage = coverageFor(snapshot, changedIndex);
      expect(coverage.usesSavedPlan, true);
      expect(coverage.plan!.targets, index.planFor(pull).targets);
      expect(coverage.gaps.map((m) => m.name), contains('Biceps'));
      expect(
        ActiveSessionState.fromJson({'startTime': '2026-10-28'}).trainingPlan,
        isNull,
      );
    },
  );

  test(
    'real catalog gives direct shoulder coverage only where planned',
    () async {
      final json =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/data/exercise_catalog.json',
                ),
              )
              as List;
      final real = json
          .map((e) => ExerciseLibraryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final realIndex = TrainingCoverageIndex(split, real);
      expect(
        realIndex
            .planFor(pull)
            .targets
            .keys
            .any((m) => muscleFamily(m) == 'Shoulders'),
        false,
      );
      expect(
        realIndex
            .planFor(push)
            .targets
            .keys
            .any((m) => muscleFamily(m) == 'Shoulders'),
        true,
      );
    },
  );
}
