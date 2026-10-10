import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/exercise_library_item.dart';

/// Interactive exercise card in the Exercise Library directory.
class ExerciseLibraryCard extends StatelessWidget {
  const ExerciseLibraryCard({
    super.key,
    required this.exercise,
    required this.onTap,
    required this.onQuickAdd,
  });

  final ExerciseLibraryItem exercise;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.primary.withValues(alpha: 0.10),
          highlightColor: AppColors.primary.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.steel,
                width: 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Main Exercise Information ────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Exercise Title & Custom Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: AppTypography.headlineMedium.copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: AppColors.pureWhite,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (exercise.isCustom) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.steel,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CUSTOM',
                                style: AppTypography.monoSmall.copyWith(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Metadata Tags (Category, Type, Equipment, Difficulty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildTag(
                            label: exercise.category.toUpperCase(),
                            color: AppColors.pureWhite,
                            isFilled: true,
                          ),
                          _buildTag(
                            label: exercise.exerciseType.toUpperCase(),
                            color: AppColors.platinum,
                            isFilled: false,
                          ),
                          _buildTag(
                            label: exercise.primaryEquipment.toUpperCase(),
                            color: AppColors.platinum,
                            isFilled: false,
                          ),
                          _buildTag(
                            label: exercise.difficultyDisplay.toUpperCase(),
                            color: AppColors.platinum,
                            isFilled: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Target Muscle Breakdown
                      Text(
                        'Target: ${exercise.primaryMusclesDisplay}',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.platinum,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // ── Quick Add (+) Action Button ──────────────────────────
                Semantics(
                  button: true,
                  label: 'Quick add ${exercise.name} to routine',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onQuickAdd,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.steel,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.steel,
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 24,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required Color color,
    required bool isFilled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFilled ? AppColors.steel : AppColors.onyx,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.steel,
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.monoSmall.copyWith(
          fontSize: 11.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: isFilled ? AppColors.pureWhite : AppColors.platinum,
        ),
      ),
    );
  }
}
