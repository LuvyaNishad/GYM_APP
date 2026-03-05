/// Dashboard feature — local view model.
/// Holds the computed summary stats displayed on the dashboard.
class DashboardModel {
  const DashboardModel({
    this.totalWorkoutsThisWeek = 0,
    this.totalVolumeThisWeekKg = 0.0,
    this.currentStreak = 0,
  });

  final int totalWorkoutsThisWeek;
  final double totalVolumeThisWeekKg;
  final int currentStreak;

  DashboardModel copyWith({
    int? totalWorkoutsThisWeek,
    double? totalVolumeThisWeekKg,
    int? currentStreak,
  }) =>
      DashboardModel(
        totalWorkoutsThisWeek:
            totalWorkoutsThisWeek ?? this.totalWorkoutsThisWeek,
        totalVolumeThisWeekKg:
            totalVolumeThisWeekKg ?? this.totalVolumeThisWeekKg,
        currentStreak: currentStreak ?? this.currentStreak,
      );
}
