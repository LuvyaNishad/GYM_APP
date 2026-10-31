/// Summary statistics and gamification data for LEON History.
library;

class HistorySummaryModel {
  const HistorySummaryModel({
    required this.currentStreakDays,
    required this.completedWorkoutsCount,
    required this.totalTonnageKg,
    required this.prCount,
    required this.gamificationLevel,
    required this.gamificationRankTitle,
    required this.nextLevelTonnageTarget,
  });

  /// Current consecutive days or active streak.
  final int currentStreakDays;

  /// Total completed workouts.
  final int completedWorkoutsCount;

  /// Total lifetime or period weight lifted (kg).
  final double totalTonnageKg;

  /// Number of PRs achieved.
  final int prCount;

  /// Current user level (1 to 50).
  final int gamificationLevel;

  /// Tactical rank name (e.g. "Titan Lifter", "Iron Pioneer").
  final String gamificationRankTitle;

  /// Target tonnage for the next level.
  final double nextLevelTonnageTarget;

  double get levelProgress {
    if (nextLevelTonnageTarget <= 0) return 1.0;
    return (totalTonnageKg / nextLevelTonnageTarget).clamp(0.0, 1.0);
  }
}
