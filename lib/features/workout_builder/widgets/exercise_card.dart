import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// A compact exercise card for the Workout Builder grid.
/// Displays exercise name, muscle group badge, and sets/reps.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.name,
    required this.muscleGroup,
    this.sets = 0,
    this.reps = 0,
    this.onTap,
    this.onRemove,
  });

  final String name;
  final String muscleGroup;
  final int sets;
  final int reps;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppTypography.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.textMuted),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            _MuscleTag(muscleGroup: muscleGroup),
            const SizedBox(height: 8),
            Text(
              '$sets × $reps',
              style: AppTypography.monoSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MuscleTag extends StatelessWidget {
  const _MuscleTag({required this.muscleGroup});
  final String muscleGroup;

  Color _color() => switch (muscleGroup.toLowerCase()) {
        'push' => AppColors.chartPush,
        'pull' => AppColors.chartPull,
        'legs' => AppColors.chartLegs,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        muscleGroup.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }
}
