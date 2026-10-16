import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/active_session_state.dart';
import '../providers/active_session_provider.dart';
import 'exercise_form_guide_sheet.dart';
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
    this.isLinkedWithPrevious = false,
    required this.onToggleExpand,
  });

  final ActiveExerciseState exercise;
  final int index;
  final bool isExpanded;
  final bool isLinkedWithPrevious;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(activeSessionProvider.notifier);
    final isDone = exercise.isFullyCompleted;
    final topSet = exercise.topCompletedSet;
    final isSuperset = exercise.supersetGroupId != null;

    final borderColor = isExpanded
        ? AppColors.pureWhite
        : (isDone
            ? AppColors.pureWhite.withValues(alpha: 0.50)
            : AppColors.steel);

    final cardBorderColor = isSuperset
        ? const Color(0xFF00E5FF)
        : borderColor;

    final cardWidget = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor,
          width: isExpanded || isSuperset ? 1.5 : 1.0,
        ),
        boxShadow: isExpanded || isSuperset
            ? [
                BoxShadow(
                  color: isSuperset
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                      : AppColors.pureWhite.withValues(alpha: 0.08),
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
                                if (isSuperset)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF00E5FF), width: 1.0),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bolt, size: 12, color: Color(0xFF00E5FF)),
                                        SizedBox(width: 2),
                                        Text(
                                          'SUPERSET',
                                          style: TextStyle(
                                            fontFamily: AppTypography.fontMono,
                                            fontSize: 11.0,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF00E5FF),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

                      // Quick Form Guide & PRs 1-Tap Info Button
                      IconButton(
                        icon: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.platinum,
                          size: 20,
                        ),
                        tooltip: 'Form Guide & PRs',
                        onPressed: () {
                          ExerciseFormGuideSheet.show(
                            context: context,
                            ref: ref,
                            exercise: exercise,
                          );
                        },
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
                          if (value == 'guide') {
                            ExerciseFormGuideSheet.show(
                              context: context,
                              ref: ref,
                              exercise: exercise,
                            );
                          } else if (value == 'substitute') {
                            showExerciseSubstitutionSheet(
                              context: context,
                              currentExercise: exercise,
                            );
                          } else if (value == 'pair_superset') {
                            _showPairSupersetSheet(context, ref);
                          } else if (value == 'unlink_superset') {
                            notifier.unlinkSuperset(exercise.exerciseId);
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
                            value: 'guide',
                            child: Row(
                              children: [
                                const Icon(Icons.menu_book_rounded, size: 18, color: AppColors.pureWhite),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Form Guide & PRs',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.pureWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSuperset)
                            PopupMenuItem(
                              value: 'unlink_superset',
                              child: Row(
                                children: [
                                  const Icon(Icons.link_off, size: 18, color: Color(0xFFFFB300)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Unlink from Superset',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.pureWhite,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            PopupMenuItem(
                              value: 'pair_superset',
                              child: Row(
                                children: [
                                  const Icon(Icons.link, size: 18, color: Color(0xFF00E5FF)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Pair as Superset...',
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

    if (isLinkedWithPrevious) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 0, bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 2.5,
                  height: 14,
                  color: const Color(0xFF00E5FF),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                      width: 1.0,
                    ),
                  ),
                  child: const Text(
                    'LINKED SUPERSET',
                    style: TextStyle(
                      fontFamily: AppTypography.fontMono,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00E5FF),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          cardWidget,
        ],
      );
    }

    return cardWidget;
  }

  void _showPairSupersetSheet(BuildContext context, WidgetRef ref) {
    final session = ref.read(activeSessionProvider);
    final availablePartners = session.exercises
        .where((e) => e.exerciseId != exercise.exerciseId)
        .toList();

    if (availablePartners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one more exercise to workout to pair as a superset.'),
          backgroundColor: AppColors.charcoal,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.steel),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PAIR AS SUPERSET',
                      style: TextStyle(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                        letterSpacing: 0.8,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.platinum, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Select an exercise to pair with "${exercise.name}":',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontBody,
                    fontSize: 12.0,
                    color: AppColors.platinum,
                  ),
                ),
                const SizedBox(height: 12),
                ...availablePartners.map((partner) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        ref.read(activeSessionProvider.notifier).createSuperset(
                              exercise.exerciseId,
                              partner.exerciseId,
                            );
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.charcoal,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.steel),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fitness_center, size: 18, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    partner.name,
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontBody,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.pureWhite,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${partner.muscleGroup.toUpperCase()} • ${partner.sets.length} SETS',
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontMono,
                                      fontSize: 11.0,
                                      color: AppColors.platinum,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.add_link, color: Color(0xFF00E5FF), size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
