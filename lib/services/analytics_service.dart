/// LEON Analytics Service (placeholder)
///
/// Computes derived metrics: radar chart data, volume trends, PRs, streaks.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/progress_model.dart';

/// Provider that exposes the AnalyticsService singleton.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);

/// Placeholder analytics service.
class AnalyticsService {
  AnalyticsService();

  /// Returns radar chart data for the current week.
  Future<RadarSnapshot> getCurrentWeekRadar(String userId) async {
    // TODO(backend): aggregate workout_exercises grouped by muscle_group.
    return RadarSnapshot(
      weekStart: DateTime.now(),
    );
  }

  /// Returns the last N progress entries for a given exercise.
  Future<List<ProgressModel>> getProgressHistory({
    required String userId,
    required String exerciseId,
    int limit = 12,
  }) async {
    // TODO(backend): query Supabase 'progress' table.
    return [];
  }
}
