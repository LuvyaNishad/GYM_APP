import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/active_session_provider.dart';
import '../widgets/active_session_header.dart';
import '../widgets/exercise_picker_modal.dart';
import '../widgets/exercise_sequence_card.dart';
import '../widgets/floating_rest_timer_bar.dart';
import '../../../services/workout_service.dart';
import '../../dashboard/providers/workout_rotation_provider.dart';
import '../../history/providers/history_provider.dart';
import '../widgets/workout_summary_dialog.dart';

/// Active Workout Session screen — "Active Mode."
///
/// Features:
/// - True OLED black canvas (#000000) for maximum battery efficiency and focus
/// - Live ActiveSessionHeader with elapsed stopwatch and progress indicator
/// - Reorderable exercise sequence cards with inline accordion set logging
/// - Action bar for rapidly adding or replacing exercises
/// - Docked floating glass rest countdown timer bar with ±10s controls
class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  ConsumerState<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(activeSessionProvider);
      if (!session.isActive) {
        final rotation = ref.read(workoutRotationProvider);
        final day = rotation.selectedDay;
        final exercises =
            day.exercises.map((e) => e.toActiveExerciseState()).toList();
        ref.read(activeSessionProvider.notifier).startSession(
              splitName:
                  '${rotation.split.shortName} ● ${day.name.toUpperCase()}',
              initialExercises: exercises,
            );
      }
    });
  }

  void _handleCancelWorkout() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.onyx,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.steel),
        ),
        title: Text(
          'Cancel Workout?',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.pureWhite),
        ),
        content: Text(
          'All sets logged in this workout session will be discarded.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.platinum),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'KEEP GOING',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.platinum,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              ref.read(activeSessionProvider.notifier).finishSession();
              if (mounted) Navigator.of(context).maybePop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.pureWhite,
            ),
            child: Text(
              'DISCARD',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleFinishWorkout() {
    final session = ref.read(activeSessionProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => WorkoutSummaryDialog(
        session: session,
        onConfirmedSave: () {
          final workout =
              ref.read(activeSessionProvider.notifier).finishSession();
          ref.read(workoutServiceProvider).saveWorkout(workout);
          ref.invalidate(historyWorkoutsProvider);
          if (mounted) Navigator.of(context).maybePop();
        },
      ),
    );
  }

  void _openAddExerciseModal() {
    final notifier = ref.read(activeSessionProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ExercisePickerModal(
        onExerciseSelected: (newEx) {
          notifier.addExercise(newEx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises =
        ref.watch(activeSessionProvider.select((s) => s.exercises));
    final expandedExerciseId =
        ref.watch(activeSessionProvider.select((s) => s.expandedExerciseId));
    final notifier = ref.read(activeSessionProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black, // True OLED black
      body: Stack(
        children: [
          // Main Scrollable Area
          Column(
            children: [
              // Sticky Active Header with live stats and quick + Add action
              ActiveSessionHeader(
                onFinishPressed: _handleFinishWorkout,
                onCancelPressed: _handleCancelWorkout,
                onAddExercisePressed: _openAddExerciseModal,
              ),

              // Reorderable Exercise Sequence List — immediately visible with zero vertical buffer
              Expanded(
                child: exercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'No exercises in workout.\nTap "+ ADD EXERCISE" below.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.platinum,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _openAddExerciseModal,
                              icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.onPrimary),
                              label: Text(
                                'ADD EXERCISE',
                                style: AppTypography.monoSmall.copyWith(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onPrimary,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        physics: const BouncingScrollPhysics(),
                        itemCount: exercises.length,
                        // ignore: deprecated_member_use
                        onReorder: notifier.reorderExercises,
                        footer: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          child: OutlinedButton.icon(
                            onPressed: _openAddExerciseModal,
                            icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.pureWhite),
                            label: Text(
                              'ADD EXERCISE',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.pureWhite,
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.steel, width: 1.2),
                              backgroundColor: AppColors.charcoal.withValues(alpha: 0.6),
                              foregroundColor: AppColors.pureWhite,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          final isExpanded =
                              expandedExerciseId == exercise.exerciseId;
                          final isSuperset = exercise.supersetGroupId != null;
                          final hasPrevSuperset = isSuperset &&
                              index > 0 &&
                              exercises[index - 1].supersetGroupId ==
                                  exercise.supersetGroupId;

                          return ExerciseSequenceCard(
                            key: ValueKey(exercise.exerciseId),
                            exercise: exercise,
                            index: index,
                            isExpanded: isExpanded,
                            isLinkedWithPrevious: hasPrevSuperset,
                            onToggleExpand: () {
                              notifier.toggleExerciseExpand(exercise.exerciseId);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),

          // Docked Floating Rest Timer Bar at Bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingRestTimerBar(),
          ),
        ],
      ),
    );
  }
}
