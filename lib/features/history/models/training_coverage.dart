import 'package:flutter/foundation.dart';

import '../../../models/workout_model.dart';
import '../../../models/muscle_radar_data.dart';
import '../../exercise_library/models/exercise_library_item.dart';
import '../../workout_builder/models/split_model.dart';

String _name(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

String? muscleArea(String muscle) {
  final m = muscle.toLowerCase();
  if (m.contains('rear') || m.contains('posterior delt')) return 'Rear delts';
  if (m.contains('lateral delt') ||
      m.contains('middle delt') ||
      m.contains('medial delt') ||
      m.contains('side delt')) {
    return 'Side delts';
  }
  if (m.contains('anterior delt') || m.contains('front delt')) {
    return 'Front delts';
  }
  if (m.contains('delt') || m.contains('shoulder')) return 'Shoulders';
  if (m.contains('latissimus') || m == 'lats' || m.contains('lat muscle')) {
    return 'Lats';
  }
  if (m.contains('rhomboid') ||
      m.contains('middle trap') ||
      m.contains('lower trap') ||
      m.contains('mid back')) {
    return 'Mid back';
  }
  if (m.contains('trap') || m.contains('upper back')) return 'Upper traps';
  if (m.contains('erector') || m.contains('lower back')) return 'Lower back';
  if (m.contains('back')) return 'Back';
  if (m.contains('brachioradialis') ||
      m.contains('forearm') ||
      m.contains('wrist')) {
    return 'Forearms';
  }
  if ((m.contains('bicep') && !m.contains('femoris')) ||
      m.contains('brachialis')) {
    return 'Biceps';
  }
  if (m.contains('tricep')) return 'Triceps';
  if (m == 'arms' || m == 'arm') return 'Arms';
  if (m.contains('pector') || m.contains('chest') || m == 'pecs') {
    return 'Chest';
  }
  if (m.contains('hamstring') ||
      m.contains('biceps femoris') ||
      m.contains('semitend') ||
      m.contains('semimembr')) {
    return 'Hamstrings';
  }
  if (m.contains('quad') ||
      m.contains('rectus femoris') ||
      m.contains('vastus')) {
    return 'Quads';
  }
  if (m.contains('glut')) return 'Glutes';
  if (m.contains('calf') ||
      m.contains('calves') ||
      m.contains('gastrocnemius') ||
      m.contains('soleus')) {
    return 'Calves';
  }
  if (m.contains('adductor')) return 'Adductors';
  if (m.contains('abdom') ||
      m.contains('oblique') ||
      m.contains('core') ||
      m == 'abs') {
    return 'Core';
  }
  return radarMuscleCategory(muscle);
}

String muscleFamily(String area) {
  if (area.contains('delts') || area == 'Shoulders') return 'Shoulders';
  if ([
    'Lats',
    'Mid back',
    'Upper traps',
    'Lower back',
    'Back',
  ].contains(area)) {
    return 'Back';
  }
  return area;
}

@immutable
class CoverageExercisePlan {
  CoverageExercisePlan({
    required this.id,
    required this.name,
    required this.sets,
    required Map<String, double> weights,
  }) : weights = Map.unmodifiable(weights);
  final String id, name;
  final int sets;
  final Map<String, double> weights;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sets': sets,
    'weights': weights,
  };
  factory CoverageExercisePlan.fromJson(Map json) => CoverageExercisePlan(
    id: json['id'] as String,
    name: json['name'] as String,
    sets: (json['sets'] as num).toInt(),
    weights: (json['weights'] as Map).map(
      (key, value) => MapEntry(key as String, (value as num).toDouble()),
    ),
  );
}

@immutable
class CoveragePlan {
  CoveragePlan({
    required this.splitId,
    required this.dayId,
    required this.dayName,
    required List<CoverageExercisePlan> exercises,
  }) : exercises = List.unmodifiable(exercises);
  final String splitId, dayId, dayName;
  final List<CoverageExercisePlan> exercises;
  Map<String, double> get targets {
    final result = <String, double>{};
    for (final ex in exercises) {
      for (final entry in ex.weights.entries) {
        result[entry.key] = (result[entry.key] ?? 0) + ex.sets * entry.value;
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
    'splitId': splitId,
    'dayId': dayId,
    'dayName': dayName,
    'exercises': exercises.map((ex) => ex.toJson()).toList(),
  };
  static CoveragePlan? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return CoveragePlan(
        splitId: json['splitId'] as String,
        dayId: json['dayId'] as String,
        dayName: json['dayName'] as String,
        exercises: (json['exercises'] as List)
            .map((ex) => CoverageExercisePlan.fromJson(ex as Map))
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Catalog lookups are indexed once. Muscle eligibility follows the routine's
/// declared targets, so indirect rear-delt work never creates a Pull-day gap
/// when the routine assigns shoulders to Push.
class TrainingCoverageIndex {
  TrainingCoverageIndex(this.split, List<ExerciseLibraryItem> catalog) {
    for (final ex in catalog) {
      _byId[ex.id] = ex;
      _byName[_name(ex.name)] = ex;
    }
    for (final day in split.workouts.where((day) => !day.isRestDay)) {
      for (final target in day.targetMuscles) {
        final area = muscleArea(target);
        if (area != null) {
          _owners.putIfAbsent(muscleFamily(area), () => <String>{}).add(day.id);
        }
      }
    }
  }
  final TrainingSplitModel split;
  final _byId = <String, ExerciseLibraryItem>{};
  final _byName = <String, ExerciseLibraryItem>{};
  final _owners = <String, Set<String>>{};

  Map<String, double> weights(String id, String name, String group) {
    final item = _byId[id] ?? _byName[_name(name)];
    final primary =
        item?.primaryMuscles.map(muscleArea).whereType<String>().toSet() ??
        <String>{};
    final secondary =
        item?.secondaryMuscles.map(muscleArea).whereType<String>().toSet() ??
        <String>{};
    if (primary.isEmpty) {
      final n = name.toLowerCase();
      final inferred =
          n.contains('reverse fly') ||
              n.contains('rear delt') ||
              n.contains('face pull')
          ? 'Rear delts'
          : n.contains('lateral raise')
          ? 'Side delts'
          : n.contains('shoulder press') ||
                n.contains('overhead press') ||
                n.contains('front raise')
          ? 'Front delts'
          : n.contains('pulldown') ||
                n.contains('pull-up') ||
                n.contains('pull up') ||
                n.contains('chin-up')
          ? 'Lats'
          : n.contains('row')
          ? 'Mid back'
          : n.contains('shrug')
          ? 'Upper traps'
          : n.contains('leg curl') || n.contains('romanian')
          ? 'Hamstrings'
          : n.contains('squat') ||
                n.contains('leg press') ||
                n.contains('leg extension')
          ? 'Quads'
          : n.contains('hip thrust')
          ? 'Glutes'
          : n.contains('calf')
          ? 'Calves'
          : n.contains('tricep') || n.contains('pushdown')
          ? 'Triceps'
          : n.contains('curl') && !n.contains('leg')
          ? 'Biceps'
          : muscleArea(group);
      if (inferred != null) primary.add(inferred);
    }
    return {
      for (final area in secondary) area: .35,
      for (final area in primary) area: 1,
    };
  }

  CoveragePlan planFor(SplitWorkoutDay day) {
    if (day.isRestDay) {
      return CoveragePlan(
        splitId: split.id,
        dayId: day.id,
        dayName: day.name,
        exercises: [],
      );
    }
    final raw = {
      for (final ex in day.exercises)
        ex.exerciseId: weights(ex.exerciseId, ex.exerciseName, ex.muscleGroup),
    };
    final directAreas = <String>{};
    for (final mapping in raw.values) {
      for (final entry in mapping.entries) {
        final owners = _owners[muscleFamily(entry.key)];
        final explicitlyAssigned = day.exercises.any(
          (ex) =>
              muscleFamily(muscleArea(ex.muscleGroup) ?? '') ==
                  muscleFamily(entry.key) &&
              raw[ex.exerciseId]?[entry.key] == 1,
        );
        if (entry.value == 1 &&
            (owners == null || owners.contains(day.id) || explicitlyAssigned)) {
          directAreas.add(entry.key);
        }
      }
    }
    return CoveragePlan(
      splitId: split.id,
      dayId: day.id,
      dayName: day.name,
      exercises: [
        for (final ex in day.exercises)
          CoverageExercisePlan(
            id: ex.exerciseId,
            name: ex.exerciseName,
            sets: ex.targetSets,
            weights: {
              for (final entry in raw[ex.exerciseId]!.entries)
                if (directAreas.contains(entry.key)) entry.key: entry.value,
            },
          ),
      ],
    );
  }

  SplitWorkoutDay? match(WorkoutModel workout) {
    final saved = CoveragePlan.fromJson(workout.trainingPlan);
    if (saved != null && saved.splitId != split.id) return null;
    if (saved != null) {
      final exact = split.workouts
          .where((day) => day.id == saved.dayId)
          .firstOrNull;
      if (exact != null) return exact;
      return null;
    }
    final unprefixed = split.workouts
        .where(
          (day) =>
              _name(day.name) == _name(workout.name) ||
              _name(day.id) == _name(workout.name),
        )
        .firstOrNull;
    if (unprefixed != null) return unprefixed;
    final separator = RegExp(r'\s*[●•·]\s*|\s*//\s*').firstMatch(workout.name);
    var title = workout.name;
    if (separator != null) {
      if (_name(workout.name.substring(0, separator.start)) !=
          _name(split.shortName)) {
        return null;
      }
      title = workout.name.substring(separator.end);
    }
    final exact = split.workouts
        .where(
          (day) =>
              _name(day.name) == _name(title) || _name(day.id) == _name(title),
        )
        .firstOrNull;
    if (exact != null) return exact;
    var best = 0;
    SplitWorkoutDay? found;
    var tied = false;
    for (final day in split.workouts.where((day) => !day.isRestDay)) {
      final matches = workout.exercises
          .where(
            (logged) => day.exercises.any(
              (planned) =>
                  planned.exerciseId == logged.exerciseId ||
                  _name(planned.exerciseName) == _name(logged.exerciseName),
            ),
          )
          .length;
      if (matches > best) {
        best = matches;
        found = day;
        tied = false;
      } else if (matches == best && matches > 0) {
        tied = true;
      }
    }
    return !tied && best >= 2 && best >= workout.exercises.length / 2
        ? found
        : null;
  }
}

@immutable
class MuscleCoverage {
  const MuscleCoverage({
    required this.name,
    required this.planned,
    required this.completed,
  });
  final String name;
  final double planned, completed;
  double get fraction => planned <= 0 ? 0 : (completed / planned).clamp(0, 1);
  bool get hasGap => planned > 0 && completed + .01 < planned;
}

class TrainingCoverage {
  TrainingCoverage({
    required this.workout,
    required this.plan,
    required this.usesSavedPlan,
    required List<MuscleCoverage> muscles,
    required List<CoverageExercisePlan> unfinished,
  }) : muscles = List.unmodifiable(muscles),
       unfinished = List.unmodifiable(unfinished);
  final WorkoutModel workout;
  final CoveragePlan? plan;
  final bool usesSavedPlan;
  final List<MuscleCoverage> muscles;
  final List<CoverageExercisePlan> unfinished;
  List<MuscleCoverage> get gaps =>
      muscles.where((muscle) => muscle.hasGap).toList();

  factory TrainingCoverage.compare(
    WorkoutModel workout,
    CoveragePlan? plan,
    TrainingCoverageIndex index, {
    bool saved = false,
  }) {
    final completed = <String, double>{};
    final targets = plan?.targets ?? <String, double>{};
    for (final ex in workout.exercises.where((ex) => !ex.isWarmup)) {
      final count = ex.sets
          .where((set) => !set.isWarmup && set.reps > 0)
          .length;
      final planned = plan?.exercises
          .where(
            (planned) =>
                planned.id == ex.exerciseId ||
                _name(planned.name) == _name(ex.exerciseName),
          )
          .firstOrNull;
      final mapping =
          planned?.weights ??
          index.weights(ex.exerciseId, ex.exerciseName, ex.muscleGroup);
      for (final entry in mapping.entries) {
        if (plan == null || targets.containsKey(entry.key)) {
          completed[entry.key] =
              (completed[entry.key] ?? 0) + count * entry.value;
        }
      }
    }
    final areas = (plan == null ? completed.keys : targets.keys).toList()
      ..sort();
    final unfinished = <CoverageExercisePlan>[];
    for (final planned in plan?.exercises ?? <CoverageExercisePlan>[]) {
      final count = workout.exercises
          .where(
            (ex) =>
                !ex.isWarmup &&
                (ex.exerciseId == planned.id ||
                    _name(ex.exerciseName) == _name(planned.name)),
          )
          .fold<int>(
            0,
            (count, ex) =>
                count +
                ex.sets.where((set) => !set.isWarmup && set.reps > 0).length,
          );
      if (count < planned.sets && planned.weights.isNotEmpty) {
        unfinished.add(planned);
      }
    }
    return TrainingCoverage(
      workout: workout,
      plan: plan,
      usesSavedPlan: saved,
      muscles: [
        for (final area in areas)
          MuscleCoverage(
            name: area,
            planned: targets[area] ?? 0,
            completed: completed[area] ?? 0,
          ),
      ],
      unfinished: unfinished,
    );
  }
}
