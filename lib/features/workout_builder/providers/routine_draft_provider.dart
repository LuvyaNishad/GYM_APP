import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/split_model.dart';
import 'weekly_volume_provider.dart';

/// A routine stays local to its editor until Save is explicitly selected.
class RoutineDraftNotifier extends Notifier<TrainingSplitModel> {
  RoutineDraftNotifier(this.initial);
  final TrainingSplitModel? initial;
  @override
  TrainingSplitModel build() {
    final seed = initial;
    final id = 'custom_split_${DateTime.now().microsecondsSinceEpoch}';
    if (seed != null) {
      return seed.copyWith(
        id: seed.isCustom ? seed.id : id,
        name: seed.isCustom ? seed.name : '${seed.name} (Custom)',
        isCustom: true,
        workouts: [...seed.workouts],
      );
    }
    return TrainingSplitModel(
      id: id,
      name: 'My Routine',
      shortName: 'CUSTOM',
      daysPerWeek: 2,
      description: 'Custom training routine.',
      isCustom: true,
      workouts: List.generate(
        2,
        (i) => SplitWorkoutDay(
          id: '${id}_$i',
          name: 'Workout ${i + 1}',
          targetMuscles: const [],
          exercises: const [],
          estimatedDurationMinutes: 0,
        ),
      ),
      plannedMuscleSets: const {},
    );
  }

  void rename(String name) => state = state.copyWith(name: name);
  void setWeeklyDays(int count) =>
      state = state.copyWith(daysPerWeek: count.clamp(1, 7));
  void addDay() => state = state.copyWith(
    workouts: [
      ...state.workouts,
      SplitWorkoutDay(
        id: 'day_${DateTime.now().microsecondsSinceEpoch}',
        name: 'Workout ${state.workouts.length + 1}',
        targetMuscles: const [],
        exercises: const [],
        estimatedDurationMinutes: 0,
      ),
    ],
  );
  void removeDay(String id) {
    if (state.workouts.length > 1) {
      state = state.copyWith(
        workouts: state.workouts.where((d) => d.id != id).toList(),
      );
    }
  }

  void updateDay(SplitWorkoutDay day) => state = state.copyWith(
    workouts: [for (final d in state.workouts) d.id == day.id ? day : d],
  );
  void setExercises(String dayId, List<PlannedExercise> exercises) {
    final day = state.workouts.firstWhere((d) => d.id == dayId);
    final seconds = exercises.fold<int>(
      0,
      (sum, e) => sum + e.targetSets * (40 + e.restSeconds),
    );
    updateDay(
      day.copyWith(
        exercises: exercises,
        targetMuscles: exercises.map((e) => e.muscleGroup).toSet().toList(),
        estimatedDurationMinutes: (seconds / 60).ceil(),
      ),
    );
  }

  TrainingSplitModel snapshot() => state.copyWith(
    name: state.name.trim(),
    shortName: state.name.trim().split(' ').take(2).join(' ').toUpperCase(),
    plannedMuscleSets: plannedWeeklyMuscleSets(state),
  );
}
