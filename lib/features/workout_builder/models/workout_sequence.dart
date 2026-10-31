import '../../../models/workout_model.dart';
import 'split_model.dart';

String _normalized(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Saved routine/day IDs are authoritative. Older logs use exact day names,
/// accepting the separators used by every workout launch point.
int matchWorkoutDay(TrainingSplitModel split, WorkoutModel workout) {
  final plan = workout.trainingPlan;
  if (plan?['splitId'] is String && plan?['dayId'] is String) {
    if (plan!['splitId'] != split.id) return -1;
    return split.workouts.indexWhere((day) => day.id == plan['dayId']);
  }
  int matchName(String title) => split.workouts.indexWhere(
    (day) =>
        _normalized(day.name) == _normalized(title) ||
        _normalized(day.id) == _normalized(title),
  );
  final exact = matchName(workout.name);
  if (exact >= 0) return exact;
  final separator = RegExp(r'\s*[●•·]\s*|\s*//\s*').firstMatch(workout.name);
  if (separator == null ||
      _normalized(workout.name.substring(0, separator.start)) !=
          _normalized(split.shortName)) {
    return -1;
  }
  return matchName(workout.name.substring(separator.end));
}

/// Count local calendar dates, including daylight-saving transitions.
int workoutDateDifference(DateTime later, DateTime earlier) {
  final localLater = later.toLocal();
  final localEarlier = earlier.toLocal();
  return DateTime.utc(localLater.year, localLater.month, localLater.day)
      .difference(
        DateTime.utc(localEarlier.year, localEarlier.month, localEarlier.day),
      )
      .inDays;
}

typedef CompletedSplitDay = ({WorkoutModel workout, int index});

CompletedSplitDay? latestCompletedSplitDay(
  TrainingSplitModel split,
  Iterable<WorkoutModel> history,
  DateTime date, {
  DateTime? since,
}) {
  CompletedSplitDay? latest;
  for (final workout in history) {
    if (workoutDateDifference(date, workout.date) < 0 ||
        (since != null && workoutDateDifference(workout.date, since) < 0)) {
      continue;
    }
    final index = matchWorkoutDay(split, workout);
    if (index < 0) continue;
    if (latest == null || workout.date.isAfter(latest.workout.date)) {
      latest = (workout: workout, index: index);
    }
  }
  return latest;
}

/// Recovery consumes calendar days; an uncompleted training day stays queued.
int nextWorkoutDayIndex(
  TrainingSplitModel split,
  CompletedSplitDay completed,
  DateTime date,
) {
  var index = (completed.index + 1) % split.workouts.length;
  var elapsedRecovery = workoutDateDifference(date, completed.workout.date) - 1;
  var skipped = 0;
  while (split.workouts[index].isRestDay &&
      elapsedRecovery > 0 &&
      skipped < split.workouts.length) {
    index = (index + 1) % split.workouts.length;
    elapsedRecovery--;
    skipped++;
  }
  return index;
}
