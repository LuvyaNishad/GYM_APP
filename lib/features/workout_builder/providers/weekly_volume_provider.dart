import '../../../models/workout_model.dart';
import '../models/split_model.dart';

String muscleAxis(String group, String exerciseName) {
  final m = group.toLowerCase();
  final n = exerciseName.toLowerCase();
  if (m.contains('bicep') || m.contains('tricep') || m.contains('arm')) {
    return 'Arms';
  }
  if (m.contains('delt') || m.contains('shoulder')) return 'Shoulders';
  if (m.contains('chest') || m.contains('pec')) return 'Chest';
  if (m.contains('back') || m.contains('lat')) return 'Back';
  if (m.contains('ham') ||
      n.contains('romanian') ||
      n.contains('hamstring') ||
      n.contains('leg curl')) {
    return 'Hamstrings';
  }
  if (m.contains('calf') || m.contains('calves') || n.contains('calf')) {
    return 'Calves';
  }
  if (m.contains('glute') || n.contains('hip thrust')) return 'Glutes';
  if (m.contains('quad') || m.contains('leg')) return 'Quads';
  if (m.contains('core') || m.contains('abs') || m.contains('abdominal')) {
    return 'Core';
  }
  return group;
}

Map<String, int> completedWeeklyMuscleSets(
  Iterable<WorkoutModel> workouts,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(Duration(days: today.weekday - 1));
  final end = start.add(const Duration(days: 7));
  final totals = <String, int>{};
  for (final workout in workouts) {
    if (workout.date.isBefore(start) ||
        !workout.date.isBefore(end) ||
        workout.date.isAfter(now)) {
      continue;
    }
    for (final ex in workout.exercises) {
      final axis = muscleAxis(ex.muscleGroup, ex.exerciseName);
      totals[axis] =
          (totals[axis] ?? 0) + ex.sets.where((s) => !s.isWarmup).length;
    }
  }
  return totals;
}

Map<String, int> plannedWeeklyMuscleSets(TrainingSplitModel split) {
  final totals = <String, int>{};
  final days = split.workouts.where((d) => !d.isRestDay).toList();
  for (final day in days) {
    for (final ex in day.exercises) {
      final axis = muscleAxis(ex.muscleGroup, ex.exerciseName);
      totals[axis] = (totals[axis] ?? 0) + ex.targetSets;
    }
  }
  final factor = days.isEmpty ? 0.0 : split.daysPerWeek / days.length;
  return totals.map((k, v) => MapEntry(k, (v * factor).round()));
}
