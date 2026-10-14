import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// The 4 standard fitness goals supported across LEON.
enum TrainingGoalType {
  buildMuscle,
  strength,
  loseFat,
  athletic;

  static TrainingGoalType fromString(String? val) {
    if (val == null) return TrainingGoalType.buildMuscle;
    final upper = val.toUpperCase().trim();
    if (upper == 'STRENGTH' || upper == 'INCREASE STRENGTH') {
      return TrainingGoalType.strength;
    }
    if (upper == 'LOSE FAT' || upper == 'FAT LOSS' || upper == 'CUT') {
      return TrainingGoalType.loseFat;
    }
    if (upper == 'ATHLETIC' ||
        upper == 'ATHLETIC PERF.' ||
        upper == 'CONDITIONING') {
      return TrainingGoalType.athletic;
    }
    return TrainingGoalType.buildMuscle;
  }
}

/// Unified goal accommodation model that configures app-wide behavior:
/// - Rest timer defaults (180s for Strength, 120s for Muscle, 60s for Fat Loss)
/// - Target rep ranges
/// - Dashboard metric emphasis (1RM PRs vs. Hypertrophy Sets vs. Step Deficit)
/// - Motivational, evidence-based post-workout feedback
class TrainingGoalConfig {
  const TrainingGoalConfig({
    required this.type,
    required this.displayName,
    required this.subtitle,
    required this.defaultRestSeconds,
    required this.targetRepRange,
    required this.primaryMetricLabel,
    required this.primaryMetricSubtitle,
    required this.accentColor,
    required this.completionFeedback,
    required this.summaryHighlight,
  });

  final TrainingGoalType type;
  final String displayName;
  final String subtitle;
  final int defaultRestSeconds;
  final String targetRepRange;
  final String primaryMetricLabel;
  final String primaryMetricSubtitle;
  final Color accentColor;
  final String completionFeedback;
  final String summaryHighlight;

  static TrainingGoalConfig fromGoal(String? goal) {
    final type = TrainingGoalType.fromString(goal);
    switch (type) {
      case TrainingGoalType.strength:
        return const TrainingGoalConfig(
          type: TrainingGoalType.strength,
          displayName: 'STRENGTH',
          subtitle: 'Maximal Power & Heavy PRs',
          defaultRestSeconds: 180, // 3:00 for full ATP-CP recovery
          targetRepRange: '3 - 6 Reps',
          primaryMetricLabel: 'ESTIMATED 1RM & LOAD',
          primaryMetricSubtitle: 'Peak output on compound lifts',
          accentColor: AppColors.primary,
          completionFeedback: 'Maximal intensity targets achieved!',
          summaryHighlight: 'Peak strength stimulus and PRs logged.',
        );
      case TrainingGoalType.loseFat:
        return const TrainingGoalConfig(
          type: TrainingGoalType.loseFat,
          displayName: 'LOSE FAT',
          subtitle: 'Caloric Deficit & High Density',
          defaultRestSeconds: 60, // 1:00 for training density & metabolic burn
          targetRepRange: '10 - 15 Reps',
          primaryMetricLabel: 'DAILY STEPS & DEFICIT',
          primaryMetricSubtitle: 'Active calorie burn & step pace',
          accentColor: AppColors.secondary,
          completionFeedback:
              'High-density session logged. Muscle mass preserved!',
          summaryHighlight:
              'Metabolic work logged without compromising lean mass.',
        );
      case TrainingGoalType.athletic:
        return const TrainingGoalConfig(
          type: TrainingGoalType.athletic,
          displayName: 'ATHLETIC',
          subtitle: 'Conditioning & Performance',
          defaultRestSeconds: 90,
          targetRepRange: '6 - 10 Reps',
          primaryMetricLabel: 'WORK CAPACITY & BALANCE',
          primaryMetricSubtitle: 'Movement symmetry & tempo output',
          accentColor: AppColors.primary,
          completionFeedback: 'Athletic conditioning work logged!',
          summaryHighlight: 'Full movement symmetry & conditioning logged.',
        );
      case TrainingGoalType.buildMuscle:
        return const TrainingGoalConfig(
          type: TrainingGoalType.buildMuscle,
          displayName: 'BUILD MUSCLE',
          subtitle: 'Hypertrophy & Volume Accumulation',
          defaultRestSeconds: 120, // 2:00 for hypertrophy
          targetRepRange: '8 - 12 Reps',
          primaryMetricLabel: 'HYPERTROPHY VOLUME',
          primaryMetricSubtitle: 'Direct sets per muscle group',
          accentColor: AppColors.primary,
          completionFeedback: 'Effective hypertrophy stimulus achieved!',
          summaryHighlight: 'Optimal hypertrophy volume logged.',
        );
    }
  }
}
