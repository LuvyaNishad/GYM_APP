/// Daily Workout / Start Workout Bento Card for the LEON Dashboard.
///
/// Clean, minimal, low-cognitive-load card:
/// - Today's routine status indicator badge
/// - Daily targeted muscle groups display with tags
/// - Immediate high-contrast "START WORKOUT" action button
/// - Tapping card body or info chevron reveals detailed workout telemetry modal
///   (Target RPE, Planned Exercises, Estimated Duration, Hypertrophy focus)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/split_model.dart';
import 'workout_detail_sheet.dart';

/// Full-width Bento card for today's workout and launching the session.
class DailyWorkoutBentoCard extends StatefulWidget {
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

  /// The active split assigned to the user.
  final SplitModel? activeSplit;

  /// Muscle groups being targeted during today's workout session.
  final List<String> muscleGroups;

  /// Total number of planned exercises for the day.
  final int exerciseCount;

  /// Estimated duration in minutes.
  final int estimatedMinutes;

  /// Target Rate of Perceived Exertion (RPE).
  final String targetRpe;

  /// Callback when the start workout button is triggered.
  final VoidCallback? onStartWorkout;

  /// Optional tap callback for inspecting workout details.
  final VoidCallback? onTap;

  @override
  State<DailyWorkoutBentoCard> createState() => _DailyWorkoutBentoCardState();
}

class _DailyWorkoutBentoCardState extends State<DailyWorkoutBentoCard> {
  static const Color _cardBg = AppColors.charcoal;
  bool _isPressed = false;

  void _openDetails() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      showWorkoutDetailSheet(
        context,
        activeSplit: widget.activeSplit,
        muscleGroups: widget.muscleGroups,
        exerciseCount: widget.exerciseCount,
        estimatedMinutes: widget.estimatedMinutes,
        targetRpe: widget.targetRpe,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final splitTitle =
        widget.activeSplit?.name.toUpperCase() ?? 'PUSH DAY // WORKOUT A';

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.5),
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
                // ── Header: Active Status + Details Chevron ────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.steel.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.steel,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.pureWhite,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "TODAY'S WORKOUT",
                            style: AppTypography.labelSmall.copyWith(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tap chevron for deep workout breakdown
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

                const SizedBox(height: 8),

                // ── Workout Name ────────────────────────────────────────────
                Text(
                  splitTitle,
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
                    for (final muscle in widget.muscleGroups)
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
                    if (widget.onStartWorkout != null) {
                      widget.onStartWorkout!();
                    } else {
                      context.push(AppConstants.routeWorkoutSession);
                    }
                  },
                  child: AnimatedScale(
                    scale: _isPressed ? 0.97 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.onyx,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'START WORKOUT',
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
