import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/progress_model.dart';
import '../../../services/analytics_service.dart';
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
