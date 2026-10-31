import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/progress_model.dart';
import '../../../models/workout_model.dart';
import '../../../core/providers/local_date_provider.dart';
import '../../../services/analytics_service.dart';
import '../../../state/app_providers.dart';
import '../../history/providers/history_provider.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../../workout_builder/models/training_schedule.dart';
import '../../workout_builder/models/split_model.dart';
import '../models/weekly_consistency_model.dart';
import 'workout_rotation_provider.dart';

/// Drives the dashboard radar chart and summary stats.
///
/// The hand-rolled `DashboardState` this replaced carried its own
/// `isLoading`/`error` fields; `AsyncValue` models those states already, so
/// the state class and its `copyWith` are gone.
///
/// `build` watches [currentUserIdProvider], so signing in or out re-runs it
/// automatically. A null user yields null radar data rather than an error —
/// a guest simply has nothing logged yet.
class DashboardNotifier extends AsyncNotifier<RadarSnapshot?> {
  @override
  Future<RadarSnapshot?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;

    final analytics = ref.watch(analyticsServiceProvider);
    return analytics.getCurrentWeekRadar(userId);
  }

  /// Re-run [build], picking up any dependency changes.
  void refresh() => ref.invalidateSelf();
}

/// Provides [DashboardNotifier], scoped to the current user.
final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, RadarSnapshot?>(
      DashboardNotifier.new,
    );

/// Provider for dates on which a gym workout session was completed/logged.
/// Directly derived from [historyWorkoutsProvider] ensuring 100% synchronization
/// between the Dashboard calendar/contribution graph, the History calendar,
/// and the logged workout feed. Every green date has an actual workout session.
final loggedWorkoutDatesProvider = Provider<Set<DateTime>>((ref) {
  final workouts = ref.watch(historyWorkoutsProvider);
  final dates = <DateTime>{};
  for (final w in workouts) {
    dates.add(DateTime(w.date.year, w.date.month, w.date.day));
  }
  return dates;
});

/// Planned training dates for the displayed week, bounded by activation dates
/// and explicit recovery days. Completed sessions remain independent evidence.
final workoutCalendarPlanProvider = Provider<WorkoutCalendarPlan>((ref) {
  final today = ref.watch(localDateProvider);
  final splits = ref.watch(
    splitsProvider.select(
      (state) => (split: state.activeSplit, schedules: state.schedules),
    ),
  );
  final history = ref.watch(historyWorkoutsProvider);
  final schedules = splits.schedules.isEmpty
      ? [TrainingSchedule.fromLegacy(splits.split, history, today)]
      : splits.schedules;
  return WorkoutCalendarPlan(
    today: today,
    split: splits.split,
    schedules: schedules,
    history: history,
    rotation: ref.watch(workoutRotationProvider),
  );
});

/// Shared date rules for Home, the full History calendar and weekly targets.
class WorkoutCalendarPlan {
  const WorkoutCalendarPlan({
    required this.today,
    required this.split,
    required this.schedules,
    required this.history,
    required this.rotation,
  });
  final DateTime today;
  final TrainingSplitModel split;
  final List<TrainingSchedule> schedules;
  final List<WorkoutModel> history;
  final WorkoutRotationState rotation;

  bool isPausedOn(DateTime date) =>
      trainingScheduleForDate(schedules, date)?.isPaused == true;

  bool isTrainingDay(DateTime date) {
    if (isPausedOn(date)) return false;
    final loggedDay = loggedScheduleDay(
      split: split,
      schedules: schedules,
      history: history,
      date: date,
    );
    if (date.isBefore(today)) {
      return loggedDay == null
          ? isScheduledTrainingDay(schedules, date)
          : !loggedDay.isRestDay;
    }
    if (split.workouts.any((day) => day.isRestDay)) {
      // A completed session belongs to today; the recommendation is next up.
      if (date == today &&
          loggedDay != null &&
          history.any(
            (workout) => scheduleDate(workout.date.toLocal()) == date,
          )) {
        return !loggedDay.isRestDay;
      }
      return !rotation.dayForDate(date, today).isRestDay;
    }
    return isScheduledTrainingDay(schedules, date);
  }
}

final scheduledWorkoutDatesProvider = Provider<Set<DateTime>>((ref) {
  final plan = ref.watch(workoutCalendarPlanProvider);
  final selected = ref.watch(selectedCalendarDateProvider) ?? plan.today;
  final monday = DateTime(
    selected.year,
    selected.month,
    selected.day - selected.weekday + 1,
  );
  return {
    for (var i = 0; i < 7; i++)
      if (plan.isTrainingDay(
        DateTime(monday.year, monday.month, monday.day + i),
      ))
        DateTime(monday.year, monday.month, monday.day + i),
  };
});

final pausedWorkoutDatesProvider = Provider<Set<DateTime>>((ref) {
  final plan = ref.watch(workoutCalendarPlanProvider);
  final selected = ref.watch(selectedCalendarDateProvider) ?? plan.today;
  final monday = DateTime(
    selected.year,
    selected.month,
    selected.day - selected.weekday + 1,
  );
  return {
    for (var i = 0; i < 7; i++)
      if (plan.isPausedOn(DateTime(monday.year, monday.month, monday.day + i)))
        DateTime(monday.year, monday.month, monday.day + i),
  };
});

/// Computes no-shame weekly workout consistency data.
final weeklyConsistencyProvider = Provider<WeeklyConsistencyModel>((ref) {
  final loggedDates = ref.watch(loggedWorkoutDatesProvider);
  final now = ref.watch(localDateProvider);
  final plan = ref.watch(workoutCalendarPlanProvider);
  final todayMidnight = now;
  final monday = todayMidnight.subtract(Duration(days: now.weekday - 1));

  const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final days = <WeekDayStatus>[];
  int completedThisWeek = 0;

  for (int i = 0; i < 7; i++) {
    final d = monday.add(Duration(days: i));
    final isDone = loggedDates.contains(d);
    if (isDone) completedThisWeek++;
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    days.add(
      WeekDayStatus(
        dayLabel: dayLabels[i],
        date: d,
        isCompleted: isDone,
        isToday: isToday,
      ),
    );
  }

  final weeklyTarget = ref
      .watch(splitsProvider.select((s) => s.activeSplit.daysPerWeek))
      .clamp(1, 7);
  int targetForWeek(DateTime start) {
    final dates = List.generate(
      7,
      (i) => DateTime(start.year, start.month, start.day + i),
    );
    if (!dates.any(plan.isPausedOn)) return weeklyTarget;
    return dates
        .where((date) => loggedDates.contains(date) || plan.isTrainingDay(date))
        .length;
  }

  final plannedThisWeek = targetForWeek(monday);
  final complianceRate = plannedThisWeek == 0
      ? 1.0
      : (completedThisWeek / plannedThisWeek).clamp(0.0, 1.0);

  // Compute 4-week compliance history
  final fourWeekHistory = <double>[];
  for (int w = 3; w >= 0; w--) {
    final weekMonday = monday.subtract(Duration(days: w * 7));
    int count = 0;
    for (int dayIdx = 0; dayIdx < 7; dayIdx++) {
      final targetDate = weekMonday.add(Duration(days: dayIdx));
      if (loggedDates.contains(targetDate)) count++;
    }
    final target = targetForWeek(weekMonday);
    final rate = target == 0 ? 1.0 : (count / target).clamp(0.0, 1.0);
    fourWeekHistory.add(rate);
  }

  final String supportiveMessage;
  if (plan.isPausedOn(now)) {
    supportiveMessage = 'Training paused. Resume when you feel ready.';
  } else if (completedThisWeek >= plannedThisWeek) {
    supportiveMessage = 'Weekly target achieved! Outstanding consistency.';
  } else if (completedThisWeek == 0) {
    supportiveMessage =
        'Fresh week ahead. Start when you feel ready — zero pressure.';
  } else {
    supportiveMessage = 'Life happens. You are on track — resume when ready.';
  }

  return WeeklyConsistencyModel(
    completedThisWeek: completedThisWeek,
    plannedThisWeek: plannedThisWeek,
    complianceRate: complianceRate,
    days: days,
    fourWeekHistory: fourWeekHistory,
    supportiveMessage: supportiveMessage,
  );
});
