import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/progress_model.dart';
import '../../../services/analytics_service.dart';
import '../../../state/app_providers.dart';

/// Dashboard state — holds the radar snapshot for the current week.
class DashboardState {
  const DashboardState({this.radar, this.isLoading = false, this.error});

  final RadarSnapshot? radar;
  final bool isLoading;
  final String? error;

  DashboardState copyWith({
    RadarSnapshot? radar,
    bool? isLoading,
    String? error,
  }) =>
      DashboardState(
        radar: radar ?? this.radar,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// Notifier that drives the dashboard radar chart and summary stats.
class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier(this._analytics, this._userId)
      : super(const DashboardState()) {
    _load();
  }

  final AnalyticsService _analytics;
  final String? _userId;

  Future<void> _load() async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final snapshot = await _analytics.getCurrentWeekRadar(_userId);
      state = state.copyWith(radar: snapshot, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void refresh() => _load();
}

/// Provides [DashboardNotifier], scoped to the current user.
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  final userId = ref.watch(currentUserIdProvider);
  return DashboardNotifier(analytics, userId);
});
