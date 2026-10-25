import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/acrylic_card.dart';
import '../providers/splits_provider.dart';
import '../widgets/active_split_detail_sheet.dart';
import '../widgets/create_routine_sheet.dart';
import '../widgets/split_compact_card.dart';
import '../widgets/switch_split_bottom_sheet.dart';

/// The Workout & Split Hub Screen — "The Attaché Case."
///
/// Features:
/// - Switchable training splits (PPL, Upper/Lower, Arnold, Bro Split)
/// - Active split spotlight with 1-tap fast program switcher
/// - Compact split list expanding to reveal interactive Muscle Balance Radar
/// - Thriving vs Lacking muscle volume diagnostics
/// - Day-by-day workout launch with direct active session hand-off
/// - 1-tap "Start Freestyle Workout" for unstructured gym sessions
/// - True Noguchi monochrome palette & Apple HIG standards
class WorkoutBuilderScreen extends ConsumerWidget {
  const WorkoutBuilderScreen({super.key});

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
    final activeSplit = state.activeSplit;
    final sortedSplits = [
      activeSplit,
      ...state.splits.where((s) => s.id != activeSplit.id),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'TRAINING SPLITS',
          style: AppTypography.headlineSmall.copyWith(
            fontSize: 16.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.pureWhite,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Routine Library',
            icon: const Icon(Icons.folder_copy_outlined,
                size: 22, color: AppColors.pureWhite),
            onPressed: () => context.push(AppConstants.routeRoutineLibrary),
          ),
          IconButton(
            tooltip: 'Switch Active Split',
            icon: const Icon(Icons.swap_horiz_rounded,
                size: 22, color: AppColors.pureWhite),
            onPressed: () => _showSwitchSplitModal(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // ── Quick Freestyle Gym Session Bar ────────────────────────────────
          AcrylicCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(18),
            borderColor: AppColors.steel.withValues(alpha: 0.70),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.onyx,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.steel),
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    size: 20,
                    color: AppColors.pureWhite,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FREESTYLE WORKOUT',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Start an empty session and log on the fly',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.0,
                          color: AppColors.platinum,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => notifier.startEmptyWorkout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pureWhite,
                    foregroundColor: AppColors.onyx,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'START',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: AppColors.onyx,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Active Program Spotlight Card (Tap to View Stats & Rotation) ─
          AcrylicCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(20),
            borderColor: AppColors.primary.withValues(alpha: 0.45),
            borderWidth: 1.2,
            glowColor: AppColors.primary.withValues(alpha: 0.08),
            onTap: () => showActiveSplitDetailSheet(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ACTIVE TRAINING PROGRAM',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.platinum,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showSwitchSplitModal(context, ref),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.onyx,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.steel),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tune,
                                size: 12, color: AppColors.pureWhite),
                            const SizedBox(width: 4),
                            Text(
                              'SWITCH SPLIT',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  activeSplit.name,
                  style: AppTypography.headlineSmall.copyWith(
                    fontSize: 19.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.pureWhite,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${activeSplit.daysPerWeek} Days/Week · ${activeSplit.totalWorkouts} Workouts · ${activeSplit.totalWeeklySets} Total Weekly Sets',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 12.0,
                    color: AppColors.platinum,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.steel, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.radar, size: 15, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'VIEW RADAR & ROTATION',
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Routine Library & Customizer Banner ────────────────────────────
          AcrylicCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.steel.withValues(alpha: 0.70),
            onTap: () => context.push(AppConstants.routeRoutineLibrary),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CUSTOMIZE ROUTINES & SPLITS',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add your exercises, adjust sets & build your default PPL',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11.5,
                          color: AppColors.platinum,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.platinum),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Section Title ──────────────────────────────────────────────────
          Row(
            children: [
              Text(
                'AVAILABLE SPLITS (${state.splits.length})',
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.platinum,
                ),
              ),
              const Spacer(),
              Text(
                'Tap to expand & inspect',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.0,
                  color: AppColors.platinum.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Compact Expandable Splits List (Active split pinned first) ─────
          for (int i = 0; i < sortedSplits.length; i++) ...[
            SplitCompactCard(
              split: sortedSplits[i],
              splitIndex: i,
              isActive: sortedSplits[i].id == state.activeSplitId,
              isExpanded: sortedSplits[i].id == state.expandedSplitId,
              loggedVolume: state.loggedVolume,
              onToggleExpand: () =>
                  notifier.toggleExpandSplit(sortedSplits[i].id),
              onSetActive: () =>
                  notifier.switchActiveSplit(sortedSplits[i].id),
              onStartDayWorkout: (day) =>
                  notifier.startWorkoutFromDay(context, day),
              onCustomize: () =>
                  showCreateRoutineSheet(context, initialSplit: sortedSplits[i]),
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
          ],
        ],
      ),
    );
  }
}
