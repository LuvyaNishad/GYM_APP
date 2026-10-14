/// Model representing no-shame weekly workout consistency for LEON.
library;

class WeekDayStatus {
  const WeekDayStatus({
    required this.dayLabel,
    required this.date,
    required this.isCompleted,
    required this.isToday,
  });

  final String dayLabel;
  final DateTime date;
  final bool isCompleted;
  final bool isToday;
}

class WeeklyConsistencyModel {
  const WeeklyConsistencyModel({
    required this.completedThisWeek,
    required this.plannedThisWeek,
    required this.complianceRate,
    required this.days,
    required this.fourWeekHistory,
    required this.supportiveMessage,
  });

  final int completedThisWeek;
  final int plannedThisWeek;
  final double complianceRate;
  final List<WeekDayStatus> days;
  final List<double> fourWeekHistory; // 4 weeks of compliance fractions
  final String supportiveMessage;
}
