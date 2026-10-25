/// Daily Workout / Start Workout Bento Card for the LEON Dashboard.
///
/// Features:
/// - Clear hierarchy: Dominant workout title (20-22sp bold) + high-contrast 52dp CTA
/// - Simplified top status row: "TODAY" / "DAY 1 OF 4" with subtle secondary controls
/// - Refined muscle-group chips in responsive wrapping layout
/// - Adapts dynamically to calendar date selection (Planned, In Progress, Completed, Rest Day)
/// - Preserves 100% of existing workout rotation, active timers, swap, and detail sheet logic
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/split_model.dart';
import '../../history/providers/history_provider.dart';
import '../../workout_session/providers/active_session_provider.dart';
import '../providers/workout_rotation_provider.dart';
import 'workout_detail_sheet.dart';

/// Full-width Bento card for daily workout overview and starting/resuming sessions.
class DailyWorkoutBentoCard extends ConsumerWidget {
  const DailyWorkoutBentoCard({
    super.key,
    this.activeSplit,
    this.muscleGroups = const ['CHEST', 'DELTOIDS', 'TRICEPS'],
    this.exerciseCount = 5,
    this.estimatedMinutes = 48,
    this.targetRpe = '8.5',
    this.onStartWorkout,
    this.onTap,
  });

  /// Optional fallback split model.
  final SplitModel? activeSplit;

  /// Optional fallback muscle groups.
  final List<String> muscleGroups;

  /// Optional fallback exercise count.
  final int exerciseCount;

  /// Optional fallback estimated minutes.
  final int estimatedMinutes;

  /// Optional fallback target RPE.
  final String targetRpe;

  /// Callback when the start workout button is triggered.
  final VoidCallback? onStartWorkout;

  /// Optional tap callback for inspecting workout details.
  final VoidCallback? onTap;

  static const Color _cardBg = AppColors.cardBackground;

  static String _shortMuscleName(String muscle) {
    final upper = muscle.toUpperCase();
    switch (upper) {
      case 'DELTOIDS':
      case 'SHOULDERS':
        return 'DELTS';
      case 'TRICEPS':
        return 'TRIS';
      case 'BICEPS':
        return 'BIS';
      case 'QUADRICEPS':
        return 'QUADS';
      case 'HAMSTRINGS':
        return 'HAMS';
      case 'ABDOMINALS':
        return 'ABS';
      default:
        return upper;
    }
  }

  void _openDetails(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      showWorkoutDetailSheet(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSessionActive =
        ref.watch(activeSessionProvider.select((s) => s.isActive));
    final activeSplitName = isSessionActive
        ? ref.watch(activeSessionProvider.select((s) => s.splitName))
        : null;
    final rotation = ref.watch(workoutRotationProvider);
    final historyWorkouts = ref.watch(historyWorkoutsProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final isViewingToday = selectedDate == null ||
        (selectedDate.year == now.year &&
            selectedDate.month == now.month &&
            selectedDate.day == now.day);

    // Resolve workout state and contents
    final String statusLabel;
    final String dayIndexLabel;
    final String workoutTitle;
    final List<String> displayMuscles;
    final bool isCompleted;
    final bool isRestDay;

    if (isViewingToday) {
      isCompleted = rotation.isCompletedToday;
      isRestDay = false;
      if (isSessionActive) {
        statusLabel = 'WORKOUT IN PROGRESS';
        final formattedElapsed =
            ref.watch(activeSessionProvider.select((s) => s.formattedElapsed));
        final setsProgress = ref.watch(activeSessionProvider
            .select((s) => '${s.completedSetCount}/${s.totalSetCount} SETS'));
        dayIndexLabel = '$formattedElapsed • $setsProgress';
        workoutTitle = (activeSplitName ?? rotation.selectedDay.name)
            .replaceAll('//', '●')
            .toUpperCase();
        displayMuscles = rotation.selectedDay.targetMuscles.isNotEmpty
            ? rotation.selectedDay.targetMuscles
            : muscleGroups;
      } else if (rotation.isCompletedToday) {
        statusLabel = 'COMPLETED TODAY';
        dayIndexLabel = 'DAY ${rotation.dayIndex + 1} OF ${rotation.totalDays}';
        final rawTitle = rotation.lastCompletedWorkout?.name ?? rotation.selectedDay.name;
        workoutTitle = rawTitle.replaceAll('//', '●').toUpperCase();
        displayMuscles = rotation.selectedDay.targetMuscles.isNotEmpty
            ? rotation.selectedDay.targetMuscles
            : muscleGroups;
      } else {
        statusLabel = 'TODAY';
        dayIndexLabel = 'DAY ${rotation.dayIndex + 1} OF ${rotation.totalDays}';
        workoutTitle = rotation.selectedDay.name.replaceAll('//', '●').toUpperCase();
        displayMuscles = rotation.selectedDay.targetMuscles.isNotEmpty
            ? rotation.selectedDay.targetMuscles
            : muscleGroups;
      }
    } else {
      // Viewing a specific selected calendar date
      final targetDate = selectedDate;
      final workoutsOnDate = historyWorkouts
          .where((w) =>
              w.date.year == targetDate.year &&
              w.date.month == targetDate.month &&
              w.date.day == targetDate.day)
          .toList();

      if (workoutsOnDate.isNotEmpty) {
        final completed = workoutsOnDate.first;
        isCompleted = true;
        isRestDay = false;
        statusLabel = 'COMPLETED';
        dayIndexLabel = '${targetDate.day}/${targetDate.month}';
        workoutTitle = completed.name.replaceAll('//', '●').toUpperCase();
        final muscles = completed.exercises.map((e) => e.muscleGroup).toSet().toList();
        displayMuscles = muscles.isNotEmpty ? muscles : muscleGroups;
      } else if (targetDate.isBefore(todayMidnight)) {
        isCompleted = false;
        isRestDay = true;
        statusLabel = 'REST DAY';
        dayIndexLabel = '${targetDate.day}/${targetDate.month}';
        workoutTitle = 'REST & RECOVERY';
        displayMuscles = const ['RECOVERY', 'MOBILITY', 'HYDRATION'];
      } else {
        isCompleted = false;
        isRestDay = false;
        statusLabel = 'SCHEDULED';
        dayIndexLabel = '${targetDate.day}/${targetDate.month}';
        final splitWorkouts = rotation.split.workouts;
        final weekdayIndex = targetDate.weekday % (splitWorkouts.isNotEmpty ? splitWorkouts.length : 1);
        final planned = splitWorkouts.isNotEmpty ? splitWorkouts[weekdayIndex] : rotation.selectedDay;
        workoutTitle = planned.name.replaceAll('//', '●').toUpperCase();
        displayMuscles = planned.targetMuscles.isNotEmpty ? planned.targetMuscles : muscleGroups;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: _cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isSessionActive
                ? AppColors.activeCyan
                : AppColors.subtleBorder,
            width: isSessionActive ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            HapticFeedback.lightImpact();
            _openDetails(context);
          },
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top Row: Status Badges + Clean Secondary Controls ───────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status Pill & Day Indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSessionActive
                                ? AppColors.activeCyan.withValues(alpha: 0.16)
                                : (isCompleted
                                    ? AppColors.emeraldGreen.withValues(alpha: 0.16)
                                    : AppColors.surfaceSecondary),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSessionActive
                                  ? AppColors.activeCyan.withValues(alpha: 0.6)
                                  : (isCompleted
                                      ? AppColors.emeraldGreen.withValues(alpha: 0.6)
                                      : AppColors.subtleBorder),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5.5,
                                height: 5.5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSessionActive
                                      ? AppColors.activeCyan
                                      : (isCompleted
                                          ? AppColors.emeraldGreen
                                          : AppColors.pureWhite),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusLabel,
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pureWhite,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.subtleBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            dayIndexLabel,
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.platinum,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Secondary Controls: Subtle Swap & Details Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isViewingToday && !isSessionActive)
                          InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(workoutRotationProvider.notifier).cycleNextDay();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.subtleBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 17,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _openDetails(context);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.subtleBorder,
                                width: 0.8,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: AppColors.platinum,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Dominant Workout Name (20-22sp Bold) ─────────────────────
                Text(
                  workoutTitle,
                  style: AppTypography.headlineLarge.copyWith(
                    fontSize: 21,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pureWhite,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                // ── Refined Muscle Group Chips (Responsive Wrap) ─────────────
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final muscle in displayMuscles)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.subtleBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.platinum,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _shortMuscleName(muscle),
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.platinum,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Primary Action Button (52dp, Soft White, Bold) ───────────
                _BentoStartWorkoutButton(
                  isSessionActive: isSessionActive,
                  isCompleted: isCompleted,
                  isRestDay: isRestDay,
                  onStartWorkout: onStartWorkout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BentoStartWorkoutButton extends ConsumerStatefulWidget {
  const _BentoStartWorkoutButton({
    required this.isSessionActive,
    required this.isCompleted,
    required this.isRestDay,
    this.onStartWorkout,
  });

  final bool isSessionActive;
  final bool isCompleted;
  final bool isRestDay;
  final VoidCallback? onStartWorkout;

  @override
  ConsumerState<_BentoStartWorkoutButton> createState() =>
      _BentoStartWorkoutButtonState();
}

class _BentoStartWorkoutButtonState
    extends ConsumerState<_BentoStartWorkoutButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted && !widget.isSessionActive) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go(AppConstants.routeAnalytics);
                },
                icon: const Icon(Icons.history_rounded, size: 18, color: AppColors.pureWhite),
                label: const Text(
                  'VIEW LOGS',
                  style: TextStyle(
                    fontFamily: AppTypography.fontDisplay,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.pureWhite,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.pureWhite,
                  side: const BorderSide(color: AppColors.subtleBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  if (widget.onStartWorkout != null) {
                    widget.onStartWorkout!();
                  } else {
                    ref.read(workoutRotationProvider.notifier).startWorkout(context);
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded, color: AppColors.primaryButtonText, size: 20),
                label: const Text(
                  'EXTRA WORKOUT',
                  style: TextStyle(
                    fontFamily: AppTypography.fontDisplay,
                    fontSize: 12.5,
                    color: AppColors.primaryButtonText,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  foregroundColor: AppColors.primaryButtonText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final String buttonLabel;
    if (widget.isSessionActive) {
      buttonLabel = 'RESUME WORKOUT';
    } else if (widget.isRestDay) {
      buttonLabel = 'START WORKOUT';
    } else {
      buttonLabel = 'START WORKOUT';
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.heavyImpact();
        if (widget.isSessionActive) {
          context.push(AppConstants.routeWorkoutSession);
          return;
        }
        if (widget.onStartWorkout != null) {
          widget.onStartWorkout!();
        } else {
          ref.read(workoutRotationProvider.notifier).startWorkout(context);
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: widget.isSessionActive
                ? AppColors.activeCyan
                : AppColors.primaryButton,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: AppColors.primaryButtonText,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                buttonLabel,
                style: const TextStyle(
                  fontFamily: AppTypography.fontDisplay,
                  fontSize: 13.5,
                  color: AppColors.primaryButtonText,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
