import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/exercise_library_item.dart';

/// Compact directory row. Full exercise metadata lives in the detail sheet.
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassCard(
        blur: true,
        sharedBackdrop: true,
        repaintBoundary: true,
        border: false,
        borderRadius: 16,
        boxShadow: const [],
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap();
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name, style: AppTypography.headlineSmall),
                      const SizedBox(height: 5),
                      Text(
                        '${exercise.category} · ${exercise.primaryEquipment}',
                        style: AppTypography.bodySmall,
                      ),
                      if (exercise.isCustom) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Custom exercise',
                          style: AppTypography.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Quick add ${exercise.name} to routine',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onQuickAdd();
                },
                icon: const Icon(Icons.add_rounded, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
