import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../models/active_session_state.dart';
import '../providers/active_session_provider.dart';
import 'exercise_form_guide_sheet.dart';
import 'exercise_set_table.dart';
import 'exercise_substitution_sheet.dart';
import 'plate_calculator_modal.dart';
import 'tempo_pacer_overlay.dart';

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
  final bool isExpanded, isLinkedWithPrevious;
  final VoidCallback onToggleExpand;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(activeSessionProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderColor: isExpanded
            ? AppColors.primary.withValues(alpha: .5)
            : AppColors.steel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onToggleExpand,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const SizedBox(
                        width: 24,
                        height: 48,
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          size: 18,
                          color: AppColors.platinum,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: AppTypography.headlineSmall.copyWith(
                              color: exercise.isFullyCompleted
                                  ? AppColors.platinum
                                  : AppColors.pureWhite,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${exercise.completedSetsCount}/${exercise.totalSetsCount} sets${exercise.isUnilateral ? ' · Left / right' : ''}${exercise.supersetGroupId != null ? ' · Superset' : ''}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Exercise options',
                      onSelected: (value) {
                        if (value == 'replace') {
                          showExerciseSubstitutionSheet(
                            context: context,
                            currentExercise: exercise,
                          );
                        }
                        if (value == 'tools') _tools(context, ref);
                        if (value == 'pair') _pair(context, ref);
                        if (value == 'unlink') {
                          notifier.unlinkSuperset(exercise.exerciseId);
                        }
                        if (value == 'remove') _remove(context, ref);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'replace',
                          child: Text('Replace exercise'),
                        ),
                        const PopupMenuItem(
                          value: 'tools',
                          child: Text('Workout tools'),
                        ),
                        PopupMenuItem(
                          value: exercise.supersetGroupId == null
                              ? 'pair'
                              : 'unlink',
                          child: Text(
                            exercise.supersetGroupId == null
                                ? 'Pair as superset'
                                : 'Unlink superset',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove exercise'),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: AppColors.platinum,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () => ExerciseFormGuideSheet.show(
                        context: context,
                        ref: ref,
                        exercise: exercise,
                      ),
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('Form & records'),
                    ),
                    TextButton.icon(
                      onPressed: () => _tools(context, ref),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Tools'),
                    ),
                  ],
                ),
              ),
              ExerciseSetTable(exercise: exercise),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    if (exercise.sets.any(
      (s) => s.isCompleted || s.isLeftCompleted || s.isRightCompleted,
    )) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove logged exercise?'),
          content: const Text(
            'Its sets will be removed from this workout draft.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    ref
        .read(activeSessionProvider.notifier)
        .removeExercise(exercise.exerciseId);
  }

  void _tools(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(activeSessionProvider.notifier);
    final next = exercise.sets.indexWhere((s) => !s.isCompleted);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppSheet(
        title: 'Workout tools',
        children: [
          if (exercise.equipment == 'barbell')
            ListTile(
              leading: const Icon(Icons.fitness_center_rounded),
              title: const Text('Plate calculator'),
              subtitle: Text(
                next < 0 ? 'All sets logged' : 'Apply to set ${next + 1}',
              ),
              onTap: next < 0
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => PlateCalculatorModal(
                          initialTotalWeightKg: exercise.sets[next].weightKg,
                          applyTarget: '${exercise.name} · Set ${next + 1}',
                          onWeightSelected: (weight) =>
                              notifier.updateSetValues(
                                exerciseId: exercise.exerciseId,
                                setIndex: next,
                                weightKg: weight,
                              ),
                        ),
                      );
                    },
            ),
          ListTile(
            leading: const Icon(Icons.speed_rounded),
            title: const Text('Tempo pacer'),
            subtitle: const Text('Time your reps; confirm them before logging'),
            onTap: next < 0
                ? null
                : () {
                    Navigator.pop(ctx);
                    TempoPacerOverlay.show(
                      context,
                      exerciseName: exercise.name,
                      exerciseId: exercise.exerciseId,
                      setIndex: next,
                      targetReps: exercise.sets[next].reps,
                      weightKg: exercise.sets[next].weightKg,
                    );
                  },
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text('Rest between sets · ${exercise.restDurationSeconds}s'),
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (sheet) => AppSheet(
                  title: 'Rest between sets',
                  children: [
                    for (final seconds in [30, 60, 90, 120, 180, 240, 300])
                      ListTile(
                        title: Text('$seconds seconds'),
                        trailing: exercise.restDurationSeconds == seconds
                            ? const Icon(Icons.check_rounded)
                            : null,
                        onTap: () {
                          notifier.updateExerciseRestDuration(
                            exercise.exerciseId,
                            seconds,
                          );
                          Navigator.pop(sheet);
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.compare_arrows_rounded),
            title: Text(
              exercise.isUnilateral
                  ? 'Log both sides together'
                  : 'Log left and right separately',
            ),
            subtitle:
                exercise.sets.any(
                  (s) =>
                      s.isCompleted || s.isLeftCompleted || s.isRightCompleted,
                )
                ? const Text('Unlog sets before changing side tracking.')
                : null,
            onTap:
                exercise.sets.any(
                  (s) =>
                      s.isCompleted || s.isLeftCompleted || s.isRightCompleted,
                )
                ? null
                : () {
                    notifier.toggleUnilateral(exercise.exerciseId);
                    Navigator.pop(ctx);
                  },
          ),
        ],
      ),
    );
  }

  void _pair(BuildContext context, WidgetRef ref) {
    final others = ref
        .read(activeSessionProvider)
        .exercises
        .where((e) => e.exerciseId != exercise.exerciseId)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppSheet(
        title: 'Pair as superset',
        children: [
          if (others.isEmpty)
            const Text('Add another exercise to make a superset.'),
          for (final item in others)
            ListTile(
              title: Text(item.name),
              subtitle: Text(item.muscleGroup),
              onTap: () {
                ref
                    .read(activeSessionProvider.notifier)
                    .createSuperset(exercise.exerciseId, item.exerciseId);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }
}
