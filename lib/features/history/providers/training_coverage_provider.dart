import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/local_date_provider.dart';
import '../../../models/workout_model.dart';
import '../../dashboard/providers/home_workout_view_provider.dart';
import '../../exercise_library/providers/exercise_library_provider.dart';
import '../../workout_builder/models/split_model.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../models/training_coverage.dart';
import 'history_provider.dart';

final trainingCoverageIndexProvider = Provider<TrainingCoverageIndex>((ref) {
  final split = ref.watch(splitsProvider.select((s) => s.activeSplit));
  final catalog = ref.watch(
    exerciseLibraryProvider.select((s) => s.allExercises),
  );
  return TrainingCoverageIndex(split, catalog);
});

TrainingCoverage coverageFor(
  WorkoutModel workout,
  TrainingCoverageIndex index,
) {
  final saved = CoveragePlan.fromJson(workout.trainingPlan);
  final day = saved == null ? index.match(workout) : null;
  return TrainingCoverage.compare(
    workout,
    saved ?? (day == null ? null : index.planFor(day)),
    index,
    saved: saved != null,
  );
}

final sessionCoverageProvider = Provider.autoDispose
    .family<TrainingCoverage, WorkoutModel>(
      (ref, workout) =>
          coverageFor(workout, ref.watch(trainingCoverageIndexProvider)),
    );

class TrainingRecommendation {
  const TrainingRecommendation({
    required this.day,
    required this.previous,
    required this.muscle,
    required this.exercise,
  });
  final SplitWorkoutDay day;
  final TrainingCoverage previous;
  final MuscleCoverage muscle;
  final CoverageExercisePlan exercise;
}

/// Only the latest compatible session can supply a gap. A newer full session
/// clears it; changing splits or moving a muscle out of this day removes it.
TrainingRecommendation? recommendTraining(
  TrainingCoverageIndex index,
  SplitWorkoutDay day,
  List<WorkoutModel> history,
  DateTime through,
) {
  if (day.isRestDay) return null;
  final next = index.planFor(day);
  if (next.targets.isEmpty) return null;
  final candidates = history.where((w) => !w.date.isAfter(through)).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  for (final workout in candidates) {
    final matched = index.match(workout);
    if (matched == null) continue;
    final coverage = coverageFor(workout, index);
    final old = coverage.plan;
    if (old == null || old.splitId != index.split.id) continue;
    // A/B variants may share a recommendation only with identical target areas
    // and substantial exercise overlap. Generic "Pull" names are insufficient.
    if (matched.id != day.id) {
      final overlap = next.exercises
          .where(
            (e) => old.exercises.any(
              (p) =>
                  p.id == e.id || p.name.toLowerCase() == e.name.toLowerCase(),
            ),
          )
          .length;
      if (next.targets.length != old.targets.length ||
          !next.targets.keys.every(old.targets.containsKey) ||
          overlap < next.exercises.length / 2) {
        continue;
      }
    }
    final gaps =
        coverage.gaps
            .where(
              (m) =>
                  next.targets.containsKey(m.name) &&
                  m.completed + .01 < next.targets[m.name]!,
            )
            .toList()
          ..sort((a, b) => a.fraction.compareTo(b.fraction));
    for (final gap in gaps) {
      final options =
          next.exercises
              .where((e) => (e.weights[gap.name] ?? 0) > 0 && e.sets > 0)
              .toList()
            ..sort((a, b) {
              final aSkipped = coverage.unfinished.any((p) => p.id == a.id);
              final bSkipped = coverage.unfinished.any((p) => p.id == b.id);
              if (aSkipped != bSkipped) return aSkipped ? -1 : 1;
              return (b.weights[gap.name] ?? 0).compareTo(
                a.weights[gap.name] ?? 0,
              );
            });
      if (options.isNotEmpty) {
        return TrainingRecommendation(
          day: day,
          previous: coverage,
          muscle: gap,
          exercise: options.first,
        );
      }
    }
    return null;
  }
  return null;
}

final homeTrainingRecommendationProvider = Provider<TrainingRecommendation?>((
  ref,
) {
  final view = ref.watch(homeWorkoutViewProvider);
  if (view.isPast || view.day == null) return null;
  final today = ref.watch(localDateProvider);
  return recommendTraining(
    ref.watch(trainingCoverageIndexProvider),
    view.day!,
    ref.watch(historyWorkoutsProvider),
    today
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1)),
  );
});
