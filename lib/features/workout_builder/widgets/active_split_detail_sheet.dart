import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/splits_provider.dart';
import 'create_routine_sheet.dart';
import 'muscle_balance_card.dart';
import 'split_day_workout_card.dart';
import 'switch_split_bottom_sheet.dart';

/// Opens the in-depth Active Training Split & Muscle Balance modal sheet.
void showActiveSplitDetailSheet(BuildContext context) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const ActiveSplitDetailSheet(),
  );
}

/// Modal bottom sheet presenting in-depth stats, muscle radar chart,
/// and day-by-day workout rotation for the user's currently active split.
///
/// Complies with:
/// - Apple HIG: All font sizes >= 11.0 pt, min 4.5:1 WCAG AA contrast.
/// - 2-Accent system: Electric Cyan primary CTA, Slate/Silver neutral chrome.
/// - Standard gym terminology: no pseudo-military or sci-fi words.
class ActiveSplitDetailSheet extends ConsumerWidget {
  const ActiveSplitDetailSheet({super.key});

  void _showSwitchSplitModal(BuildContext context, WidgetRef ref) {
    final state = ref.read(splitsProvider);
    final notifier = ref.read(splitsProvider.notifier);

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SwitchSplitBottomSheet(
        splits: state.splits,
        activeSplitId: state.activeSplitId,
        onSplitSelected: (newId) => notifier.switchActiveSplit(newId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(splitsProvider);
    final notifier = ref.read(splitsProvider.notifier);
    final split = state.activeSplit;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF141722),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 36,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Grab Handle ─────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.steel,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Scrollable Body ─────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Active Program Pill & Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ACTIVE TRAINING PROGRAM',
                                style: AppTypography.monoSmall.copyWith(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.charcoal,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.steel),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Row 2: Split Name
                    Text(
                      split.name,
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: AppColors.pureWhite,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Row 3: Metric Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildMetricChip('${split.daysPerWeek} DAYS/WEEK'),
                        _buildMetricChip('${split.totalWorkouts} WORKOUTS'),
                        _buildMetricChip('${split.totalWeeklySets} TOTAL SETS'),
                        _buildMetricChip(split.isCustom ? 'CUSTOM ROUTINE' : 'PRESET SPLIT'),
                      ],
                    ),

                    if (split.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        split.description,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.5,
                          color: AppColors.platinum,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Row 4: Quick Action Buttons (Switch Split & Customize)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showSwitchSplitModal(context, ref),
                            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                            label: Text(
                              'SWITCH SPLIT',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.pureWhite,
                              side: const BorderSide(color: AppColors.steel),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              showCreateRoutineSheet(context, initialSplit: split);
                            },
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: Text(
                              'CUSTOMIZE',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.pureWhite,
                              side: const BorderSide(color: AppColors.steel),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),
                    const Divider(color: AppColors.steel, height: 1),
                    const SizedBox(height: 20),

                    // ── Section 1: Muscle Balance Radar ─────────────────────
                    MuscleBalanceCard(
                      plannedVolume: split.plannedMuscleSets,
                      loggedVolume: state.loggedVolume,
                      onAutoTuneMuscle: (muscle) {
                        notifier.autoFixLaggingMuscle(muscle);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.charcoal,
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Balanced $muscle deficit: Added volume sets to active rotation.',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 12.0,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: AppColors.steel, height: 1),
                    const SizedBox(height: 20),

                    // ── Section 2: Day-by-Day Workout Rotation ──────────────
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.pureWhite),
                        const SizedBox(width: 8),
                        Text(
                          'DAY-BY-DAY ROTATION',
                          style: AppTypography.headlineSmall.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${split.workouts.length} DAYS',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.platinum,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Workout Days
                    for (int i = 0; i < split.workouts.length; i++)
                      SplitDayWorkoutCard(
                        day: split.workouts[i],
                        dayIndex: i,
                        onStartWorkout: () {
                          Navigator.of(context).pop();
                          notifier.startWorkoutFromDay(context, split.workouts[i]);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.monoSmall.copyWith(
          fontSize: 11.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.platinum,
        ),
      ),
    );
  }
}
