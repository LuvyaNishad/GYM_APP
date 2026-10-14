/// Daily Workout / Start Workout Bento Card for the LEON Dashboard.
///
/// Features:
/// - Smart Workout Auto-Rotation based on completed workout history
/// - Dynamic workout title, muscle tags, and context rationale
/// - "COMPLETED TODAY" status if a session was already logged today
/// - 1-Tap "ROTATE" cycle button to quickly flip through split days
/// - Immediate high-contrast "START WORKOUT" action button
/// - Tapping card body opens in-depth Workout Detail Sheet with full exercise roster
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/split_model.dart';
import '../../workout_session/providers/active_session_provider.dart';
import '../providers/workout_rotation_provider.dart';
import 'workout_detail_sheet.dart';

/// Full-width Bento card for today's auto-rotated workout and launching the session.
class DailyWorkoutBentoCard extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<DailyWorkoutBentoCard> createState() =>
      _DailyWorkoutBentoCardState();
}

class _DailyWorkoutBentoCardState extends ConsumerState<DailyWorkoutBentoCard> {
  static const Color _cardBg = AppColors.charcoal;
  bool _isPressed = false;

  void _openDetails() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      showWorkoutDetailSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeSessionProvider);
    final rotation = ref.watch(workoutRotationProvider);
    final day = rotation.selectedDay;
    final isSessionActive = activeSession.isActive;

    final workoutTitle = isSessionActive
        ? activeSession.splitName.toUpperCase()
        : day.name.toUpperCase();
    final targetMuscles = day.targetMuscles.isNotEmpty
        ? day.targetMuscles
        : widget.muscleGroups;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSessionActive
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.steel.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _openDetails,
          splashColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header: Active Status + Rotation Position + Cycle Button ─
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSessionActive
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : (rotation.isCompletedToday
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : AppColors.steel.withValues(alpha: 0.6)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSessionActive
                                  ? AppColors.primary.withValues(alpha: 0.6)
                                  : (rotation.isCompletedToday
                                      ? AppColors.success.withValues(alpha: 0.6)
                                      : AppColors.steel),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSessionActive
                                      ? AppColors.primary
                                      : (rotation.isCompletedToday
                                          ? AppColors.success
                                          : AppColors.pureWhite),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isSessionActive
                                    ? 'IN PROGRESS • ${activeSession.formattedElapsed}'
                                    : (rotation.isCompletedToday
                                        ? 'COMPLETED TODAY'
                                        : "TODAY'S WORKOUT"),
                                style: AppTypography.labelSmall.copyWith(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11.0,
                                  color: isSessionActive
                                      ? AppColors.primary
                                      : (rotation.isCompletedToday
                                          ? AppColors.success
                                          : AppColors.pureWhite),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Day Index Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isSessionActive
                                ? '${activeSession.completedSetCount}/${activeSession.totalSetCount} SETS'
                                : 'DAY ${rotation.dayIndex + 1}/${rotation.totalDays}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Quick Rotate Day Action + Details Chevron
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(workoutRotationProvider.notifier)
                                .cycleNextDay();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'SWAP',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Workout Name ────────────────────────────────────────────
                Text(
                  workoutTitle,
                  style: AppTypography.headlineMedium.copyWith(
                    fontSize: 15,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pureWhite,
                  ),
                ),

                const SizedBox(height: 8),

                // ── Targeted Muscles Badges ─────────────────────────────────
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final muscle in targetMuscles)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.steel.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.steel,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 3.5,
                              height: 3.5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.platinum,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              muscle.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.0,
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

                const SizedBox(height: 10),

                // ── Start Workout Action Button ─────────────────────────────
                GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) => setState(() => _isPressed = false),
                  onTapCancel: () => setState(() => _isPressed = false),
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    if (isSessionActive) {
                      context.push(AppConstants.routeWorkoutSession);
                      return;
                    }
                    if (widget.onStartWorkout != null) {
                      widget.onStartWorkout!();
                    } else {
                      ref
                          .read(workoutRotationProvider.notifier)
                          .startWorkout(context);
                    }
                  },
                  child: AnimatedScale(
                    scale: _isPressed ? 0.97 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSessionActive
                            ? AppColors.primary
                            : AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSessionActive
                                ? Icons.play_arrow_rounded
                                : Icons.play_arrow_rounded,
                            color: AppColors.onyx,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSessionActive
                                ? 'RESUME WORKOUT'
                                : (rotation.isCompletedToday
                                    ? 'START EXTRA WORKOUT'
                                    : 'START WORKOUT'),
                            style: AppTypography.titleLarge.copyWith(
                              fontFamily: AppTypography.fontDisplay,
                              fontSize: 12.5,
                              color: AppColors.onyx,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
