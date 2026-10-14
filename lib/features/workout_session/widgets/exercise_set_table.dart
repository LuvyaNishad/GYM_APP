import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../models/active_session_state.dart';
import '../providers/active_session_provider.dart';
import 'effort_picker_modal.dart';
import 'plate_calculator_modal.dart';
import 'tempo_pacer_overlay.dart';

/// Detailed Set Logger table for an individual exercise.
///
/// Features:
/// - Columns: SET #, PREVIOUS (ghost performance), KG, REPS, EFFORT (RIR/RPE), LOG (Checkmark)
/// - 1-tap autofill from previous ghost performance
/// - RIR/RPE synchronized sheet picker
/// - Plate calculator launcher for barbell exercises
/// - Warm-up set generator and dynamic set addition/deletion
class ExerciseSetTable extends ConsumerWidget {
  const ExerciseSetTable({
    super.key,
    required this.exercise,
  });

  final ActiveExerciseState exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(activeSessionProvider.notifier);
    final goalConfig = ref.watch(trainingGoalConfigProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Equipment & Goal Target Bar
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.steel,
                  ),
                ),
                child: Text(
                  exercise.equipment.toUpperCase(),
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.platinum,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.steel,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.adjust_rounded,
                      size: 11.0,
                      color: goalConfig.accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'TARGET: ${goalConfig.targetRepRange.toUpperCase()}',
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: goalConfig.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.steel,
                  ),
                ),
                child: Text(
                  'REST: ${exercise.restDurationSeconds}s',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.platinum,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: const BoxDecoration(
            color: AppColors.charcoal,
            border: Border(
              bottom: BorderSide(
                color: AppColors.steel,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                child: Text(
                  'SET',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.platinum,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'PREVIOUS',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.platinum,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'KG',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.platinum,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'REPS',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.platinum,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'EFFORT',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.platinum,
                  ),
                ),
              ),
              const SizedBox(
                width: 44,
                child: Center(
                  child: Text(
                    'LOG',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.platinum,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Set Rows (Zero phantom padding)
        for (int i = 0; i < exercise.sets.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              color: AppColors.steel,
            ),
          _buildSetRow(
            context: context,
            ref: ref,
            set: exercise.sets[i],
            setIndex: i,
            notifier: notifier,
          ),
        ],

        const SizedBox(height: 8),

        // Bottom Action Controls: 4 Cohesive Options Together
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Row 1: Add Set & Warmup Sets
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => notifier.addSet(exercise.exerciseId),
                      icon: const Icon(Icons.add, size: 16, color: AppColors.pureWhite),
                      label: Text(
                        'ADD SET',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.steel),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(0, 42),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => notifier.addWarmupSets(exercise.exerciseId),
                      icon: const Icon(Icons.fitness_center, size: 16, color: AppColors.platinum),
                      label: Text(
                        'WARMUP SETS',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.platinum,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.steel),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(0, 42),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 2: Tempo Pacer & Plate Calculator (Placed below Add Set & Warmup Sets)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final activeSetIndex =
                            exercise.sets.indexWhere((s) => !s.isCompleted);
                        final targetSetIndex =
                            activeSetIndex != -1 ? activeSetIndex : 0;
                        final targetSet = exercise.sets.isNotEmpty
                            ? exercise.sets[targetSetIndex]
                            : null;
                        final targetReps = targetSet?.reps ?? 8;
                        final targetWeight = targetSet?.weightKg ?? 20.0;

                        TempoPacerOverlay.show(
                          context,
                          exerciseName: exercise.name,
                          exerciseId: exercise.exerciseId,
                          setIndex: targetSetIndex,
                          targetReps: targetReps,
                          weightKg: targetWeight,
                        );
                      },
                      icon: const Icon(
                        Icons.speed,
                        size: 16,
                        color: Color(0xFF00E5FF),
                      ),
                      label: Text(
                        'TEMPO PACER',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00E5FF),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(0, 42),
                      ),
                    ),
                  ),
                  if (exercise.equipment.toLowerCase() == 'barbell') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final activeSetIndex =
                              exercise.sets.indexWhere((s) => !s.isCompleted);
                          final targetSetIndex =
                              activeSetIndex != -1 ? activeSetIndex : 0;
                          final targetSet = exercise.sets.isNotEmpty
                              ? exercise.sets[targetSetIndex]
                              : null;
                          final targetWeight = targetSet?.weightKg ?? 60.0;
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (ctx) => PlateCalculatorModal(
                              initialTotalWeightKg: targetWeight,
                              onWeightSelected: (newWeight) {
                                notifier.updateSetValues(
                                  exerciseId: exercise.exerciseId,
                                  setIndex: targetSetIndex,
                                  weightKg: newWeight,
                                );
                              },
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.calculate_outlined,
                          size: 16,
                          color: AppColors.pureWhite,
                        ),
                        label: Text(
                          'PLATE CALC',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.steel),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 42),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSetRow({
    required BuildContext context,
    required WidgetRef ref,
    required ActiveSetState set,
    required int setIndex,
    required ActiveSessionNotifier notifier,
  }) {
    final isCompleted = set.isCompleted;

    return Container(
      color: isCompleted
          ? AppColors.steel.withValues(alpha: 0.15)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // 1. SET Index badge
          SizedBox(
            width: 38,
            child: InkWell(
              onTap: () => _showSetOptionsSheet(context, setIndex, notifier),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.steel,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  set.isWarmup ? 'W' : '${set.setNumber}',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. PREVIOUS Ghost Performance (Tap to Autofill)
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                if (set.previousWeightKg != null && set.previousReps != null) {
                  try {
                    HapticFeedback.selectionClick();
                  } catch (_) {}
                  notifier.updateSetValues(
                    exerciseId: exercise.exerciseId,
                    setIndex: setIndex,
                    weightKg: set.previousWeightKg,
                    reps: set.previousReps,
                    rir: set.previousRir,
                  );
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  set.previousWeightKg != null
                      ? '${set.previousWeightKg!.toInt()} kg × ${set.previousReps}'
                      : '—',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.5,
                    color: AppColors.platinum,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 3. KG (Weight) Input
          Expanded(
            flex: 3,
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.pureWhite.withValues(alpha: 0.5)
                      : AppColors.steel,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        set.weightKg >= 10 && set.weightKg % 1 == 0
                            ? '${set.weightKg.toInt()}'
                            : set.weightKg.toStringAsFixed(1),
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniStepper(
                        icon: Icons.keyboard_arrow_up,
                        onTap: () => notifier.updateSetValues(
                          exerciseId: exercise.exerciseId,
                          setIndex: setIndex,
                          weightKg: set.weightKg + 2.5,
                        ),
                      ),
                      _buildMiniStepper(
                        icon: Icons.keyboard_arrow_down,
                        onTap: () => notifier.updateSetValues(
                          exerciseId: exercise.exerciseId,
                          setIndex: setIndex,
                          weightKg: (set.weightKg - 2.5).clamp(0.0, 999.0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 4. REPS Input
          Expanded(
            flex: 2,
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.pureWhite.withValues(alpha: 0.5)
                      : AppColors.steel,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        '${set.reps}',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniStepper(
                        icon: Icons.keyboard_arrow_up,
                        onTap: () => notifier.updateSetValues(
                          exerciseId: exercise.exerciseId,
                          setIndex: setIndex,
                          reps: set.reps + 1,
                        ),
                      ),
                      _buildMiniStepper(
                        icon: Icons.keyboard_arrow_down,
                        onTap: () => notifier.updateSetValues(
                          exerciseId: exercise.exerciseId,
                          setIndex: setIndex,
                          reps: (set.reps - 1).clamp(0, 999),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 5. EFFORT (RIR & RPE Pill)
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (ctx) => EffortPickerModal(
                    initialRir: set.rir,
                    initialRpe: set.rpe,
                    onSaved: (newRir, newRpe) {
                      notifier.updateSetValues(
                        exerciseId: exercise.exerciseId,
                        setIndex: setIndex,
                        rir: newRir,
                        rpe: newRpe,
                      );
                    },
                  ),
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.steel,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${set.rir.toInt()} RIR (${set.rpe.toInt()})',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 6. LOG Checkmark Button (Min 44×44 pt touch target per Apple HIG)
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: () {
                try {
                  HapticFeedback.mediumImpact();
                } catch (_) {}
                notifier.logSet(
                  exerciseId: exercise.exerciseId,
                  setIndex: setIndex,
                );
              },
              icon: AnimatedScale(
                scale: isCompleted ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                  color: isCompleted ? AppColors.primary : AppColors.platinum,
                  size: 24,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              tooltip: isCompleted ? 'Mark incomplete' : 'Log set',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStepper({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 18,
        height: 18,
        child: Icon(icon, size: 14, color: AppColors.platinum),
      ),
    );
  }

  void _showSetOptionsSheet(
    BuildContext context,
    int setIndex,
    ActiveSessionNotifier notifier,
  ) {
    final set = exercise.sets[setIndex];
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.speed, color: Color(0xFF00E5FF)),
                  title: Text(
                    'Start Tempo Pacer for Set ${set.setNumber}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Hands-free sine wave • ${set.reps} reps',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 11.5,
                      color: AppColors.platinum,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    TempoPacerOverlay.show(
                      context,
                      exerciseName: exercise.name,
                      exerciseId: exercise.exerciseId,
                      setIndex: setIndex,
                      targetReps: set.reps,
                      weightKg: set.weightKg,
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    set.isWarmup ? Icons.fitness_center : Icons.whatshot,
                    color: AppColors.pureWhite,
                  ),
                  title: Text(
                    set.isWarmup ? 'Convert to Working Set' : 'Convert to Warm-up Set',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.pureWhite),
                  ),
                  onTap: () {
                    notifier.updateSetValues(
                      exerciseId: exercise.exerciseId,
                      setIndex: setIndex,
                      isWarmup: !set.isWarmup,
                    );
                    Navigator.of(ctx).pop();
                  },
                ),
                if (exercise.sets.length > 1)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                    title: Text(
                      'Delete Set ${set.setNumber}',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
                    ),
                    onTap: () {
                      notifier.removeSet(exercise.exerciseId, setIndex);
                      Navigator.of(ctx).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
