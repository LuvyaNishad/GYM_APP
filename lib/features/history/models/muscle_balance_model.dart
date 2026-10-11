/// Muscle balance, lagging muscle detection, and recovery readiness models.
library;

enum RecoveryStatus {
  ready,
  recovering,
  overdue,
}

class MuscleRecoveryState {
  const MuscleRecoveryState({
    required this.muscleName,
    required this.hoursSinceLastTrained,
    required this.status,
    required this.lastSessionName,
  });

  final String muscleName;
  final int hoursSinceLastTrained;
  final RecoveryStatus status;
  final String lastSessionName;
}

class LaggingMuscleAdvisory {
  const LaggingMuscleAdvisory({
    required this.muscleName,
    required this.relativeRatio,
    required this.recommendedExercises,
    required this.rationale,
  });

  final String muscleName;
  final double relativeRatio;
  final List<String> recommendedExercises;
  final String rationale;
}

class MuscleBalanceModel {
  const MuscleBalanceModel({
    required this.chestVolume,
    required this.backVolume,
    required this.shouldersVolume,
    required this.quadsVolume,
    required this.hamstringsVolume,
    required this.armsVolume,
    required this.laggingAdvisories,
    required this.recoveryStates,
  });

  final double chestVolume;
  final double backVolume;
  final double shouldersVolume;
  final double quadsVolume;
  final double hamstringsVolume;
  final double armsVolume;

  final List<LaggingMuscleAdvisory> laggingAdvisories;
  final List<MuscleRecoveryState> recoveryStates;
}
