import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/active_session_provider.dart';
import '../widgets/active_session_header.dart';
import '../widgets/exercise_picker_modal.dart';
import '../widgets/exercise_sequence_card.dart';
import '../widgets/floating_rest_timer_bar.dart';
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
        ref.read(activeSessionProvider.notifier).startSession(
              splitName: 'PUSH DAY // WORKOUT A',
            );
      }
    });
  }

  void _handleCancelWorkout() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141722),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        title: Text(
          'Cancel Workout?',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        content: Text(
          'All sets logged in this workout session will be discarded.',
          style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'KEEP GOING',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
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
              foregroundColor: Colors.white,
            ),
            child: Text(
              'DISCARD',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
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
          ref.read(activeSessionProvider.notifier).finishSession();
          if (mounted) Navigator.of(context).maybePop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(activeSessionProvider);
    final notifier = ref.read(activeSessionProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black, // True OLED black
      body: Stack(
        children: [
          // Main Scrollable Area
          Column(
            children: [
              // Sticky Active Header
              ActiveSessionHeader(
                onFinishPressed: _handleFinishWorkout,
                onCancelPressed: _handleCancelWorkout,
              ),

              // Action Toolbar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (ctx) => ExercisePickerModal(
                            onExerciseSelected: (newEx) {
                              notifier.addExercise(newEx);
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16, color: Colors.black),
                      label: Text(
                        '+ ADD EXERCISE',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: const Size(0, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            'Hold ≡ to reorder',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Reorderable Exercise Sequence List
              Expanded(
                child: sessionState.exercises.isEmpty
                    ? Center(
                        child: Text(
                          'No exercises in workout.\nTap "+ ADD EXERCISE" above.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: const Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        physics: const BouncingScrollPhysics(),
                        itemCount: sessionState.exercises.length,
                        // ignore: deprecated_member_use
                        onReorder: notifier.reorderExercises,
                        itemBuilder: (context, index) {
                          final exercise = sessionState.exercises[index];
                          final isExpanded =
                              sessionState.expandedExerciseId == exercise.exerciseId;

                          return ExerciseSequenceCard(
                            key: ValueKey(exercise.exerciseId),
                            exercise: exercise,
                            index: index,
                            isExpanded: isExpanded,
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
