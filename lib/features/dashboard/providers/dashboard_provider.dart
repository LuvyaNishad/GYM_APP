import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/progress_model.dart';
import '../../../services/analytics_service.dart';
import '../../../state/app_providers.dart';
import '../../history/providers/history_provider.dart';
import '../models/weekly_consistency_model.dart';

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

/// Computes no-shame weekly workout consistency data.
final weeklyConsistencyProvider = Provider<WeeklyConsistencyModel>((ref) {
  final loggedDates = ref.watch(loggedWorkoutDatesProvider);
  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);
  final monday = todayMidnight.subtract(Duration(days: now.weekday - 1));

  const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final days = <WeekDayStatus>[];
  int completedThisWeek = 0;

  for (int i = 0; i < 7; i++) {
    final d = monday.add(Duration(days: i));
    final isDone = loggedDates.contains(d);
    if (isDone) completedThisWeek++;
    final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
    days.add(
      WeekDayStatus(
        dayLabel: dayLabels[i],
        date: d,
        isCompleted: isDone,
        isToday: isToday,
      ),
    );
  }

  const plannedThisWeek = 4;
  final complianceRate = (completedThisWeek / plannedThisWeek).clamp(0.0, 1.0);

  // Compute 4-week compliance history
  final fourWeekHistory = <double>[];
  for (int w = 3; w >= 0; w--) {
    final weekMonday = monday.subtract(Duration(days: w * 7));
    int count = 0;
    for (int dayIdx = 0; dayIdx < 7; dayIdx++) {
      final targetDate = weekMonday.add(Duration(days: dayIdx));
      if (loggedDates.contains(targetDate)) count++;
    }
    final rate = (count / plannedThisWeek).clamp(0.0, 1.0);
    fourWeekHistory.add(rate);
  }

  final String supportiveMessage;
  if (completedThisWeek >= plannedThisWeek) {
    supportiveMessage = 'Weekly target achieved! Outstanding consistency.';
  } else if (completedThisWeek == 0) {
    supportiveMessage = 'Fresh week ahead. Start when you feel ready — zero pressure.';
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

