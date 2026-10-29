import '../../../models/workout_model.dart';
import '../../../models/muscle_radar_data.dart';
import '../models/split_model.dart';

String? muscleAxis(String group, String exerciseName) {
  final category = radarMuscleCategory(group);
  if (category != null) return category;
  final n = exerciseName.toLowerCase();
  if (n.contains('romanian') ||
      n.contains('squat') ||
      n.contains('hip thrust')) {
    return 'Legs';
  }
  if (n.contains('row') || n.contains('pull-up') || n.contains('chin-up')) {
    return 'Back';
  }
  if (n.contains('lateral raise') ||
      n.contains('overhead press') ||
      n.contains('reverse fly') ||
      n.contains('face pull')) {
    return 'Shoulders';
  }
  if (n.contains('bench press') || n.contains('push-up')) return 'Chest';
  if (n.contains('crunch') || n.contains('plank')) return 'Core';
  return radarMuscleCategory(exerciseName);
}

Map<String, int> completedWeeklyMuscleSets(
  Iterable<WorkoutModel> workouts,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(Duration(days: today.weekday - 1));
  final end = start.add(const Duration(days: 7));
  final totals = {for (final category in muscleRadarCategories) category: 0};
  for (final workout in workouts) {
    if (workout.date.isBefore(start) ||
        !workout.date.isBefore(end) ||
        workout.date.isAfter(now)) {
      continue;
    }
    for (final ex in workout.exercises) {
      if (ex.isWarmup) continue;
      final axis = muscleAxis(ex.muscleGroup, ex.exerciseName);
      if (axis == null) continue;
      totals[axis] =
          totals[axis]! +
          ex.sets.where((s) => !s.isWarmup && s.reps > 0).length;
    }
  }
  return totals;
}

Map<String, int> plannedWeeklyMuscleSets(TrainingSplitModel split) {
  final totals = {for (final category in muscleRadarCategories) category: 0};
  final days = split.workouts.where((d) => !d.isRestDay).toList();
  for (final day in days) {
    for (final ex in day.exercises) {
      final axis = muscleAxis(ex.muscleGroup, ex.exerciseName);
      if (axis == null) continue;
      totals[axis] = (totals[axis] ?? 0) + ex.targetSets;
    }
  }
  final factor = days.isEmpty ? 0.0 : split.daysPerWeek / days.length;
  return totals.map((k, v) => MapEntry(k, (v * factor).round()));
}
