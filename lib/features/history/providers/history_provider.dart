/// History and analytics data providers for LEON.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/strength_math.dart';
import '../../../models/workout_model.dart';
import '../../../services/hive_service.dart';
import '../models/exercise_progress_model.dart';
import '../models/history_summary_model.dart';
import '../models/muscle_balance_model.dart';

/// Active segment index in the History Screen:
/// 0 = SESSIONS (Workout Log & Attendance Heatmap)
/// 1 = OVERLOAD (Progressive Overload & 1RM Progression)
/// 2 = RADAR (Muscle Symmetry & Recovery Primed State)
class HistoryActiveSegment extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final historyActiveSegmentProvider =
    NotifierProvider<HistoryActiveSegment, int>(HistoryActiveSegment.new);

/// Currently selected exercise for the Progressive Overload graph.
class SelectedOverloadExerciseId extends Notifier<String> {
  @override
  String build() => 'ex_bench_press';

  void select(String id) => state = id;
}

final selectedOverloadExerciseIdProvider =
    NotifierProvider<SelectedOverloadExerciseId, String>(
        SelectedOverloadExerciseId.new);

/// Currently selected calendar date in the History screen.
/// Null = no single-day filter (shows all sessions).
class SelectedCalendarDate extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime? date) {
    // Idempotent selection: tapping an already selected date retains the selection
    state = date;
  }

  void clear() => state = null;
}

final selectedCalendarDateProvider =
    NotifierProvider<SelectedCalendarDate, DateTime?>(
        SelectedCalendarDate.new);

/// Notifier for all completed workouts, newest first.
/// Enforces strictly 1 workout per calendar day and supports historical edits.
class HistoryWorkoutsNotifier extends Notifier<List<WorkoutModel>> {
  @override
  List<WorkoutModel> build() {
    return _loadWorkouts();
  }

  List<WorkoutModel> _loadWorkouts() {
    final hive = ref.watch(hiveServiceProvider);
    List<WorkoutModel> stored = [];
    try {
      stored = hive.readAll(
        AppConstants.hiveBoxWorkouts,
        WorkoutModel.fromJson,
      );
    } catch (_) {
      stored = [];
    }

    if (stored.isNotEmpty) {
      // Deduplicate: strictly 1 workout per calendar day (keep newest for each day)
      final Map<String, WorkoutModel> dayMap = {};
      for (final w in stored) {
        final key =
            '${w.date.year}-${w.date.month.toString().padLeft(2, '0')}-${w.date.day.toString().padLeft(2, '0')}';
        if (!dayMap.containsKey(key) || w.date.isAfter(dayMap[key]!.date)) {
          dayMap[key] = w;
        }
      }
      final deduplicated = dayMap.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return deduplicated;
    }

    // Clean initial state: zero fake workouts
    return [];
  }

  /// Updates a historical workout in Hive and synchronizes state.
  Future<void> updateWorkout(WorkoutModel updated) async {
    final hive = ref.read(hiveServiceProvider);
    try {
      await hive.put(
        AppConstants.hiveBoxWorkouts,
        updated.id,
        updated.toJson(),
      );
    } catch (_) {}

    state = [
      for (final w in state)
        if (w.id == updated.id) updated else w,
    ];
  }

  /// Deletes a historical workout from Hive and local state.
  Future<void> deleteWorkout(String workoutId) async {
    final hive = ref.read(hiveServiceProvider);
    try {
      await hive.delete(AppConstants.hiveBoxWorkouts, workoutId);
    } catch (_) {}

    state = state.where((w) => w.id != workoutId).toList();
  }

  /// Re-syncs from persistent storage.
  void refresh() {
    state = _loadWorkouts();
  }
}

final historyWorkoutsProvider =
    NotifierProvider<HistoryWorkoutsNotifier, List<WorkoutModel>>(
        HistoryWorkoutsNotifier.new);

/// Computes streak, compliance, tonnage, and gamification ranks.
final historySummaryProvider = Provider<HistorySummaryModel>((ref) {
  final workouts = ref.watch(historyWorkoutsProvider);

  if (workouts.isEmpty) {
    return const HistorySummaryModel(
      currentStreakDays: 0,
      longestStreakDays: 0,
      completedWorkoutsCount: 0,
      missedWorkoutsCount: 0,
      complianceRate: 0.0,
      totalTonnageKg: 0.0,
      prCount: 0,
      gamificationLevel: 1,
      gamificationRankTitle: 'Iron Initiate',
      nextLevelTonnageTarget: 6000.0,
    );
  }

  double totalTonnage = 0;
  int prCount = 0;

  for (final w in workouts) {
    totalTonnage += w.totalVolumeKg ?? 0;
    for (final ex in w.exercises) {
      for (final s in ex.sets) {
        if (s.isPr) prCount++;
      }
    }
  }

  // Tonnage-based gamification ranks
  int level = 1 + (totalTonnage / 6000).floor();
  if (level > 50) level = 50;

  String rankTitle = 'Iron Initiate';
  if (level >= 15) {
    rankTitle = 'Titan Elite';
  } else if (level >= 10) {
    rankTitle = 'Apex Lifter';
  } else if (level >= 6) {
    rankTitle = 'Iron Veteran';
  } else if (level >= 3) {
    rankTitle = 'Vanguard Athlete';
  }

  final nextTarget = (level * 6000.0);

  // Compute active streak from workout dates
  final sortedDates = workouts
      .map((w) => DateTime(w.date.year, w.date.month, w.date.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  int currentStreak = 0;
  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);
  final yesterdayMidnight = todayMidnight.subtract(const Duration(days: 1));

  if (sortedDates.isNotEmpty &&
      (sortedDates.first == todayMidnight || sortedDates.first == yesterdayMidnight)) {
    var checkDate = sortedDates.first;
    for (final d in sortedDates) {
      if (d == checkDate) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (d.isBefore(checkDate)) {
        break;
      }
    }
  }

  final completed = workouts.length;
  const missed = 0;
  final totalPlanned = completed + missed;
  final compliance = totalPlanned > 0 ? (completed / totalPlanned) : 1.0;

  return HistorySummaryModel(
    currentStreakDays: currentStreak,
    longestStreakDays: currentStreak,
    completedWorkoutsCount: completed,
    missedWorkoutsCount: missed,
    complianceRate: compliance,
    totalTonnageKg: totalTonnage,
    prCount: prCount,
    gamificationLevel: level,
    gamificationRankTitle: rankTitle,
    nextLevelTonnageTarget: nextTarget,
  );
});

/// Available exercises for progressive overload selection.
final availableOverloadExercisesProvider = Provider<List<ExerciseProgressModel>>((ref) {
  final workouts = ref.watch(historyWorkoutsProvider);
  if (workouts.isEmpty) return const [];

  final Map<String, List<StrengthDataPoint>> pointsByEx = {};
  final Map<String, String> namesByEx = {};
  final Map<String, String> muscleByEx = {};

  final chronological = workouts.reversed.toList();
  for (final w in chronological) {
    for (final ex in w.exercises) {
      final key = ex.exerciseId;
      namesByEx[key] = ex.exerciseName;
      muscleByEx[key] = ex.muscleGroup;

      double maxWeight = 0;
      int maxReps = 0;
      double exVolume = 0;

      for (final s in ex.sets) {
        if (s.isWarmup) continue;
        exVolume += s.weightKg * s.reps;
        if (s.weightKg > maxWeight) {
          maxWeight = s.weightKg;
          maxReps = s.reps;
        }
      }

      if (maxWeight > 0) {
        final e1rm = StrengthMath.calculateEpley1RM(maxWeight, maxReps);
        pointsByEx.putIfAbsent(key, () => []).add(
              StrengthDataPoint(
                date: w.date,
                weightKg: maxWeight,
                reps: maxReps,
                estimated1RM: double.parse(e1rm.toStringAsFixed(1)),
                volumeKg: exVolume,
              ),
            );
      }
    }
  }

  final results = <ExerciseProgressModel>[];
  for (final entry in namesByEx.entries) {
    final pts = pointsByEx[entry.key] ?? [];
    if (pts.isEmpty) continue;

    double best1rm = 0;
    for (final p in pts) {
      if (p.estimated1RM > best1rm) best1rm = p.estimated1RM;
    }

    double deltaPercent = 0.0;
    if (pts.length >= 2) {
      final first = pts.first.estimated1RM;
      final last = pts.last.estimated1RM;
      if (first > 0) {
        deltaPercent = ((last - first) / first) * 100;
      }
    }

    results.add(
      ExerciseProgressModel(
        exerciseId: entry.key,
        exerciseName: entry.value,
        muscleGroup: muscleByEx[entry.key] ?? 'Chest',
        dataPoints: pts,
        allTimeBest1RM: best1rm,
        recentDeltaPercent: double.parse(deltaPercent.toStringAsFixed(1)),
      ),
    );
  }

  return results;
});

/// Recent PR breakthroughs for the trophy wall.
final recentPrMilestonesProvider = Provider<List<PrMilestone>>((ref) {
  final workouts = ref.watch(historyWorkoutsProvider);
  final milestones = <PrMilestone>[];

  for (final w in workouts) {
    for (final ex in w.exercises) {
      for (final s in ex.sets) {
        if (s.isPr) {
          milestones.add(
            PrMilestone(
              exerciseName: ex.exerciseName,
              recordType: 'Set PR',
              valueFormatted: '${s.weightKg} KG × ${s.reps} Reps',
              date: w.date,
              deltaFormatted: 'NEW PR',
            ),
          );
        }
      }
    }
  }

  return milestones;
});

/// Computes muscle balance volume and detects lagging muscles.
final muscleBalanceProvider = Provider<MuscleBalanceModel>((ref) {
  final workouts = ref.watch(historyWorkoutsProvider);

  double chest = 0;
  double back = 0;
  double shoulders = 0;
  double quads = 0;
  double hamstrings = 0;
  double arms = 0;

  final Map<String, ({DateTime date, String sessionName})> lastHitByMuscle = {};

  for (final w in workouts) {
    for (final ex in w.exercises) {
      double vol = 0;
      for (final s in ex.sets) {
        if (!s.isWarmup) vol += (s.weightKg * s.reps);
      }
      final group = ex.muscleGroup.toLowerCase();
      String muscleCategory = 'Chest & Triceps';

      if (group.contains('chest')) {
        chest += vol;
        muscleCategory = 'Chest & Triceps';
      } else if (group.contains('back') || group.contains('lat')) {
        back += vol;
        muscleCategory = 'Back & Lats';
      } else if (group.contains('deltoid') || group.contains('shoulder')) {
        shoulders += vol;
        muscleCategory = 'Deltoids';
      } else if (group.contains('quad') || group.contains('leg')) {
        quads += vol;
        muscleCategory = 'Quads & Calves';
      } else if (group.contains('hamstring')) {
        hamstrings += vol;
        muscleCategory = 'Hamstrings';
      } else if (group.contains('tricep') || group.contains('bicep') || group.contains('arm')) {
        arms += vol;
        muscleCategory = 'Arms';
      } else {
        chest += vol * 0.5;
        arms += vol * 0.5;
      }

      if (!lastHitByMuscle.containsKey(muscleCategory) ||
          w.date.isAfter(lastHitByMuscle[muscleCategory]!.date)) {
        lastHitByMuscle[muscleCategory] = (date: w.date, sessionName: w.name);
      }
    }
  }

  // Detect lagging muscles if volume exists
  final laggingAdvisories = <LaggingMuscleAdvisory>[];
  if (quads > 0 && (hamstrings / quads) < 0.6) {
    laggingAdvisories.add(
      LaggingMuscleAdvisory(
        muscleName: 'Hamstrings',
        relativeRatio: double.parse((hamstrings / quads).toStringAsFixed(2)),
        recommendedExercises: const [
          'Romanian Deadlift (RDL)',
          'Seated Leg Curls (Lengthened Bias)',
        ],
        rationale:
            'Posterior chain volume is below anterior quads.',
      ),
    );
  }

  if (back > 0 && (shoulders / back) < 0.55) {
    laggingAdvisories.add(
      LaggingMuscleAdvisory(
        muscleName: 'Lateral Deltoids',
        relativeRatio: double.parse((shoulders / back).toStringAsFixed(2)),
        recommendedExercises: const [
          'Cable Lateral Raises (B-Stance)',
          'Dumbbell Y-Raises',
        ],
        rationale:
            'Deltoid stimulus volume is below weekly hyper-volume threshold.',
      ),
    );
  }

  // Recovery states computed from real workouts
  final now = DateTime.now();
  final recoveryStates = <MuscleRecoveryState>[];

  lastHitByMuscle.forEach((muscle, info) {
    final hours = now.difference(info.date).inHours;
    final RecoveryStatus status;
    if (hours < 24) {
      status = RecoveryStatus.recovering;
    } else if (hours <= 96) {
      status = RecoveryStatus.ready;
    } else {
      status = RecoveryStatus.overdue;
    }

    recoveryStates.add(
      MuscleRecoveryState(
        muscleName: muscle,
        hoursSinceLastTrained: hours,
        status: status,
        lastSessionName: info.sessionName,
      ),
    );
  });

  return MuscleBalanceModel(
    chestVolume: chest,
    backVolume: back,
    shouldersVolume: shoulders,
    quadsVolume: quads,
    hamstringsVolume: hamstrings,
    armsVolume: arms,
    laggingAdvisories: laggingAdvisories,
    recoveryStates: recoveryStates,
  );
});
