import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/progress_model.dart';
import '../../../models/workout_model.dart';
import '../../../services/analytics_service.dart';
import '../../../services/hive_service.dart';
import '../../../state/app_providers.dart';

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
///
/// Watches Hive storage for real saved workouts. When no workouts have been
/// stored yet (guest / demo mode), seeds realistic completed training sessions
/// prior to today in the current week (e.g. Mon, Wed, Fri) so the
/// calendar visually demonstrates completed workout session tracking.
class LoggedWorkoutDatesNotifier extends Notifier<Set<DateTime>> {
  @override
  Set<DateTime> build() {
    ref.keepAlive();
    final hive = ref.watch(hiveServiceProvider);
    final workouts = hive.readAll(
      AppConstants.hiveBoxWorkouts,
      WorkoutModel.fromJson,
    );

    final dates = <DateTime>{};
    for (final w in workouts) {
      dates.add(DateTime(w.date.year, w.date.month, w.date.day));
    }

    if (dates.isEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: now.weekday % 7));

      // Populate completed workout sessions prior to today in the current week
      final currentWeekdayIndex = now.weekday % 7;
      for (int i = 0; i < currentWeekdayIndex; i++) {
        // Mon (1), Wed (3), Fri (5)
        if (i % 2 == 1) {
          dates.add(startOfWeek.add(Duration(days: i)));
        }
      }

      // If today is Monday or earlier, ensure at least one recent session exists
      if (dates.isEmpty && currentWeekdayIndex > 0) {
        dates.add(today.subtract(const Duration(days: 1)));
      }

      // Seed realistic historical training sessions across the past 26 weeks (~6 months)
      // so the extended GitHub-style contribution graph shows rich gym activity
      for (int week = 1; week <= 26; week++) {
        final pastWeekStart = startOfWeek.subtract(Duration(days: week * 7));
        dates.add(pastWeekStart.add(const Duration(days: 1))); // Mon
        dates.add(pastWeekStart.add(const Duration(days: 3))); // Wed
        dates.add(pastWeekStart.add(const Duration(days: 5))); // Fri
        if (week % 2 == 0) {
          dates.add(pastWeekStart.add(const Duration(days: 2))); // Tue
        } else if (week % 3 == 0) {
          dates.add(pastWeekStart.add(const Duration(days: 6))); // Sat
        }
      }
    }

    return dates;
  }

  /// Mark [date] as a completed workout day.
  void markCompleted(DateTime date) {
    state = {...state, DateTime(date.year, date.month, date.day)};
  }
}

final loggedWorkoutDatesProvider =
    NotifierProvider<LoggedWorkoutDatesNotifier, Set<DateTime>>(
  LoggedWorkoutDatesNotifier.new,
);

