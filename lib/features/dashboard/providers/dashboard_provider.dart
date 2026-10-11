import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/progress_model.dart';
import '../../../services/analytics_service.dart';
import '../../../state/app_providers.dart';
import '../../history/providers/history_provider.dart';

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

