import 'package:flutter/material.dart';
import 'package:leon/core/theme/app_colors.dart';
import 'package:leon/core/theme/app_typography.dart';

import '../../../models/exercise_model.dart';

/// A tile card displaying a single [ExerciseModel] in the Exercise Library.
///
/// Shows the exercise name, primary muscle group, equipment type,
/// and a warm-up badge if applicable.
class ExerciseCardWidget extends StatelessWidget {
  const ExerciseCardWidget({super.key, required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          // ── Muscle group colour indicator ──────────────────────────────
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: _muscleGroupColor(exercise.primaryMuscleGroup),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(width: 16),

          // ── Exercise details ───────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontBody,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (exercise.isWarmup)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'WARM-UP',
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 11,
                            color: AppColors.warning,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.primaryMuscleGroup.toUpperCase()} · ${exercise.equipment.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 11,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // ── RPE badge ─────────────────────────────────────────────────
          if (exercise.rpe != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'RPE',
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 11,
                      color: Color(0xFF00E5FF),
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '${exercise.rpe}',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontMono,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Color _muscleGroupColor(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'push':
      case 'chest':
      case 'shoulders':
      case 'triceps':
        return AppColors.chartPush;
      case 'pull':
      case 'back':
      case 'biceps':
        return AppColors.chartPull;
      case 'legs':
      case 'quads':
      case 'hamstrings':
      case 'glutes':
        return AppColors.chartLegs;
      case 'core':
        return AppColors.chartCore;
      default:
        return AppColors.textMuted;
    }
  }
}
