import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/local_date_provider.dart';
import '../../dashboard/providers/habit_log_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../workout_builder/models/training_schedule.dart';
import '../models/recovery_factor.dart';

class RecoverySummary {
  const RecoverySummary({
    required this.score,
    required this.habits,
    required this.recentVolumeKg,
    required this.recentSessions,
    this.lastWorkout,
    this.baselineVolumeKg,
    required this.missingInputs,
  });
  final RecoveryScore? score;
  final DayHabits habits;
  final double recentVolumeKg;
  final int recentSessions;
  final DateTime? lastWorkout;
  final double? baselineVolumeKg;
  final List<String> missingInputs;
}

final recoverySummaryProvider = Provider<RecoverySummary>((ref) {
  final today = ref.watch(localDateProvider);
  final habitsLog = ref.watch(habitLogProvider);
  final habits = habitsLog.day(today);
  final workouts = ref
      .watch(historyWorkoutsProvider)
      .where((w) => !scheduleDate(w.date).isAfter(today))
      .toList();
  final recent = workouts.where(
    (w) =>
        !scheduleDate(w.date).isBefore(today.subtract(const Duration(days: 6))),
  );
  final volume = recent.fold<double>(
    0,
    (sum, w) => sum + (w.totalVolumeKg ?? 0),
  );
  final baselineLogs = workouts.where(
    (w) =>
        scheduleDate(
          w.date,
        ).isBefore(today.subtract(const Duration(days: 6))) &&
        !scheduleDate(
          w.date,
        ).isBefore(today.subtract(const Duration(days: 27))),
  );
  final baseline =
      workouts.length >= 4 &&
          workouts.any(
            (w) => !scheduleDate(
              w.date,
            ).isAfter(today.subtract(const Duration(days: 27))),
          )
      ? baselineLogs.fold<double>(0, (sum, w) => sum + (w.totalVolumeKg ?? 0)) /
            3
      : null;
  final missing = <String>[
    if (!habits.sleepLogged) 'Sleep',
    if (habits.water.isEmpty) 'Hydration',
    if (habits.soreness == null) 'Soreness',
  ];
  final factors = <RecoveryFactor>[
    if (workouts.isNotEmpty)
      RestDaysFactor(
        today.difference(scheduleDate(workouts.first.date)).inDays,
      ),
    if (baseline != null && baseline > 0)
      VolumeLoadFactor(recentVolumeKg: volume, baselineVolumeKg: baseline),
    if (habits.sleepLogged)
      ManualRecoveryFactor(
        'SLEEP',
        -((habitsLog.sleepGoalHours - habits.sleepHours).clamp(0.0, 8.0)) * 5,
        '${habits.sleepHours.toStringAsFixed(1)} h logged; your target is ${habitsLog.sleepGoalHours.toStringAsFixed(1)} h.',
      ),
    if (habits.water.isNotEmpty)
      ManualRecoveryFactor(
        'HYDRATION',
        -15 * (1 - (habits.waterMl / habitsLog.waterGoalMl).clamp(0.0, 1.0)),
        '${habits.waterMl} ml logged against your ${habitsLog.waterGoalMl} ml target.',
      ),
    if (habits.soreness != null)
      ManualRecoveryFactor(
        'SORENESS',
        -habits.soreness! * 3.0,
        'Your self-rating is ${habits.soreness}/10.',
      ),
  ];
  return RecoverySummary(
    score: missing.isEmpty ? RecoveryScore(factors: factors) : null,
    habits: habits,
    recentVolumeKg: volume,
    recentSessions: recent.length,
    lastWorkout: workouts.firstOrNull?.date,
    baselineVolumeKg: baseline,
    missingInputs: missing,
  );
});

final recoveryProvider = Provider<RecoveryScore?>(
  (ref) => ref.watch(recoverySummaryProvider).score,
);
final recoveryScoreProvider = Provider<int?>(
  (ref) => ref.watch(recoveryProvider)?.value,
);
