import '../../../models/user_model.dart';
import '../data/split_presets.dart';
import 'split_model.dart';

String resolveSplitId(String value) => switch (value) {
  'PPL' || 'Push / Pull / Legs' => 'split_ppl',
  'Upper/Lower' || 'Upper / Lower' => 'split_upper_lower',
  'Full Body' => 'split_full_body',
  'Arnold Split' => 'split_arnold',
  'Bro Split' ||
  'Body Part Split' ||
  '5-Day Bro Split (Body Part)' => 'split_bro_split',
  _ => value,
};

TrainingSplitModel get fullBodySplit {
  final ppl = kPresetSplits.first;
  final exercises = [
    for (final day in ppl.workouts.take(3)) ...day.exercises.take(2),
  ];
  return TrainingSplitModel(
    id: 'split_full_body',
    name: 'Full Body',
    shortName: 'Full Body',
    daysPerWeek: 3,
    description: 'Rotate full body workouts on your selected training days.',
    plannedMuscleSets: const {},
    workouts: [
      for (var i = 0; i < 3; i++)
        SplitWorkoutDay(
          id: 'full_body_$i',
          name: 'Full Body ${i + 1}',
          targetMuscles: const ['Chest', 'Back', 'Legs'],
          exercises: exercises,
        ),
    ],
  );
}

TrainingSplitModel configureProgramme(
  TrainingSplitModel split,
  UserModel? user,
) {
  if (user == null || split.isCustom || user.trainingDaysPerWeek == null) {
    return split;
  }
  split = split.id == 'split_full_body'
      ? fullBodySplit
      : kPresetSplits.where((s) => s.id == split.id).firstOrNull ?? split;
  final gear = user.equipment.map((e) => e.toLowerCase()).toSet();
  bool available(PlannedExercise e) {
    if (gear.contains('full gym')) return true;
    final equipment = e.equipment.toLowerCase();
    final base =
        equipment == 'bodyweight' ||
        equipment == 'none' ||
        gear.any(
          (g) =>
              g == equipment || g == '${equipment}s' || g.contains(equipment),
        );
    if (!base) return false;
    if (e.exerciseName.toLowerCase().replaceAll('-', ' ').contains('pull up') &&
        !gear.contains('pull-up bar')) {
      return false;
    }
    if ((e.exerciseName.toLowerCase().contains('bench') ||
            e.exerciseName.toLowerCase().contains('incline')) &&
        !gear.contains('bench')) {
      return false;
    }
    return true;
  }

  return split.copyWith(
    daysPerWeek: user.trainingDaysPerWeek ?? split.daysPerWeek,
    description:
        'Uses your available equipment and weekly frequency. Injury notes are saved for your review; exercises are not medically screened.',
    workouts: [
      for (final day in split.workouts.where((d) => !d.isRestDay))
        day.copyWith(exercises: day.exercises.where(available).toList()),
    ],
  );
}
