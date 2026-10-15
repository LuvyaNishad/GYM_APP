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

              // Session Telemetry Strip (Available after starting workout)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.onyx,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.steel.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SessionSummaryItem(
                        icon: Icons.fitness_center_rounded,
                        label: '${sessionState.exercises.length} EXERCISES',
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 1,
                        height: 11,
                        color: AppColors.steel,
                      ),
                      const _SessionSummaryItem(
                        icon: Icons.timer_outlined,
                        label: '~48 MIN',
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 1,
                        height: 11,
                        color: AppColors.steel,
                      ),
                      const _SessionSummaryItem(
                        icon: Icons.bolt_rounded,
                        label: 'HYPERTROPHY',
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 1,
                        height: 11,
                        color: AppColors.steel,
                      ),
                      const _SessionSummaryItem(
                        icon: Icons.speed_rounded,
                        label: 'TARGET RPE 8.5',
                      ),
                    ],
                  ),
                ),
              ),

              // Action Toolbar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
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
                      icon: const Icon(Icons.add, size: 16, color: AppColors.onPrimary),
                      label: Text(
                        'ADD EXERCISE',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
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
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.steel,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.platinum),
                          const SizedBox(width: 4),
                          Text(
                            'Hold ≡ to reorder',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              color: AppColors.platinum,
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
                            color: AppColors.platinum,
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
                          final isSuperset = exercise.supersetGroupId != null;
                          final hasPrevSuperset = isSuperset &&
                              index > 0 &&
                              sessionState.exercises[index - 1].supersetGroupId ==
                                  exercise.supersetGroupId;

                          final card = ExerciseSequenceCard(
                            key: ValueKey(exercise.exerciseId),
                            exercise: exercise,
                            index: index,
                            isExpanded: isExpanded,
                            onToggleExpand: () {
                              notifier.toggleExerciseExpand(exercise.exerciseId);
                            },
                          );

                          if (hasPrevSuperset) {
                            return Column(
                              key: ValueKey(exercise.exerciseId),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 32, top: 2, bottom: 2),
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
                                          color: const Color(0xFF00E5FF)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: const Color(0xFF00E5FF)
                                                .withValues(alpha: 0.40),
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
                                card,
                              ],
                            );
                          }

                          return card;
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

class _SessionSummaryItem extends StatelessWidget {
  const _SessionSummaryItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: AppColors.platinum,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
