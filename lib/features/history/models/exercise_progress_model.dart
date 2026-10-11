/// Progressive Overload and Strength Progress models for LEON.
library;

class StrengthDataPoint {
  const StrengthDataPoint({
    required this.date,
    required this.weightKg,
    required this.reps,
    required this.estimated1RM,
    required this.volumeKg,
  });

  final DateTime date;
  final double weightKg;
  final int reps;
  final double estimated1RM;
  final double volumeKg;
}

class PrMilestone {
  const PrMilestone({
    required this.exerciseName,
    required this.recordType,
    required this.valueFormatted,
    required this.date,
    required this.deltaFormatted,
  });

  final String exerciseName;
  final String recordType; // e.g., "1RM Record", "Volume PR", "Rep Record"
  final String valueFormatted; // e.g. "105.0 KG" or "36 KG × 8"
  final DateTime date;
  final String deltaFormatted; // e.g. "+5.0 KG" or "+2 reps"
}

class ExerciseProgressModel {
  const ExerciseProgressModel({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.dataPoints,
    required this.allTimeBest1RM,
    required this.recentDeltaPercent,
  });

  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final List<StrengthDataPoint> dataPoints;
  final double allTimeBest1RM;
  final double recentDeltaPercent;
}
