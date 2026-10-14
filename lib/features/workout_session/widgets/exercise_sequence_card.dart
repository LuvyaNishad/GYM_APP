import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/active_session_state.dart';
import '../providers/active_session_provider.dart';
import 'exercise_picker_modal.dart';
import 'exercise_set_table.dart';
import 'exercise_substitution_sheet.dart';

/// Interactive Sequence Card representing an exercise in the active workout.
///
/// Supports:
/// - Inline Accordion expansion/collapse
/// - Quick metrics preview when collapsed (completed sets, top set lifted)
/// - Drag-and-drop reordering handle
/// - 3-dot menu (Replace, Superset, Remove)
/// - Embedded ExerciseSetTable when expanded
class ExerciseSequenceCard extends ConsumerWidget {
  const ExerciseSequenceCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  final ActiveExerciseState exercise;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(activeSessionProvider.notifier);
    final isDone = exercise.isFullyCompleted;
    final topSet = exercise.topCompletedSet;

    final borderColor = isExpanded
        ? AppColors.pureWhite
        : (isDone
            ? AppColors.pureWhite.withValues(alpha: 0.50)
            : AppColors.steel);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isExpanded ? 1.5 : 1.0),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: AppColors.pureWhite.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Header / Collapsed Summary Bar
              InkWell(
                onTap: onToggleExpand,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      // Reorder Drag Handle
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(
                            Icons.drag_indicator,
                            color: AppColors.platinum,
                            size: 20,
                          ),
                        ),
                      ),

                      // Index indicator
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.pureWhite.withValues(alpha: 0.15)
                              : AppColors.steel,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone
                                ? AppColors.pureWhite
                                : AppColors.steel,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isDone ? '✓' : '${index + 1}',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: isDone ? AppColors.pureWhite : AppColors.platinum,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Exercise Name & Muscle Tag & Top Set summary
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    exercise.name,
                                    style: AppTypography.headlineSmall.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 6,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  exercise.muscleGroup.toUpperCase(),
                                  style: AppTypography.monoSmall.copyWith(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                                Text(
                                  '· ${exercise.completedSetsCount}/${exercise.totalSetsCount} SETS',
                                  style: AppTypography.monoSmall.copyWith(
                                    fontSize: 11.0,
                                    color: AppColors.platinum,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (topSet != null)
                                  Text(
                                    '· Top: ${topSet.weightKg.toInt()}kg × ${topSet.reps}',
                                    style: AppTypography.monoSmall.copyWith(
                                      fontSize: 11.0,
                                      color: AppColors.platinum,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 3-Dot Options Menu
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.platinum,
                          size: 20,
                        ),
                        color: AppColors.onyx,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: AppColors.steel,
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'substitute') {
                            showExerciseSubstitutionSheet(
                              context: context,
                              currentExercise: exercise,
                            );
                          } else if (value == 'replace') {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (ctx) => ExercisePickerModal(
                                onExerciseSelected: (newEx) {
                                  notifier.replaceExercise(
                                    exercise.exerciseId,
                                    newEx,
                                  );
                                },
                              ),
                            );
                          } else if (value == 'delete') {
                            notifier.removeExercise(exercise.exerciseId);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'substitute',
                            child: Row(
                              children: [
                                const Icon(Icons.cached_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Substitute Exercise',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.pureWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'replace',
                            child: Row(
                              children: [
                                const Icon(Icons.swap_horiz, size: 18, color: AppColors.pureWhite),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Replace Exercise',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.pureWhite),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Remove Exercise',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Expand / Collapse Chevron
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.platinum,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Set Logger Table
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Column(
                        children: [
                          const Divider(
                            height: 1,
                            color: AppColors.steel,
                          ),
                          ExerciseSetTable(exercise: exercise),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
