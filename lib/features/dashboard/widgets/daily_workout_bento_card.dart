/// Daily Workout / Start Workout Bento Card for the LEON Dashboard.
///
/// Clean, minimal, non-sloppy design without outer blur glows:
/// - Operation/Protocol briefing banner with active status indicator
/// - Daily targeted muscle groups display with tactical tags
/// - Workout session telemetry preview (exercise count, estimated time, target RPE)
/// - Prominent clean initiation action button
/// - Compact height ensuring full-screen visibility without mandatory scroll
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/split_model.dart';

/// Full-width Bento card for reviewing today's workout protocol and launching the session.
class DailyWorkoutBentoCard extends StatefulWidget {
  const DailyWorkoutBentoCard({
    super.key,
    this.activeSplit,
    this.muscleGroups = const ['CHEST', 'DELTOIDS', 'TRICEPS'],
    this.exerciseCount = 5,
    this.estimatedMinutes = 48,
    this.targetRpe = '8.5',
    this.onStartWorkout,
  });

  /// The active split assigned to the operative.
  final SplitModel? activeSplit;

  /// Muscle groups being targeted during today's protocol.
  final List<String> muscleGroups;

  /// Total number of planned exercises for the day.
  final int exerciseCount;

  /// Estimated duration in minutes.
  final int estimatedMinutes;

  /// Target Rate of Perceived Exertion (RPE).
  final String targetRpe;

  /// Callback when the start workout button is triggered.
  final VoidCallback? onStartWorkout;

  @override
  State<DailyWorkoutBentoCard> createState() => _DailyWorkoutBentoCardState();
}

class _DailyWorkoutBentoCardState extends State<DailyWorkoutBentoCard> {
  static const Color _cardBg = Color(0xFF161A23);
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final splitTitle =
        widget.activeSplit?.name.toUpperCase() ?? 'TACTICAL PUSH // PROTOCOL A';

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: Active Status + Target RPE ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
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
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ACTIVE PROTOCOL',
                      style: AppTypography.labelSmall.copyWith(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.0,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                'TARGET RPE ${widget.targetRpe}',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.0,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Protocol Name ─────────────────────────────────────────────────
          Text(
            splitTitle,
            style: AppTypography.headlineMedium.copyWith(
              fontSize: 15,
              letterSpacing: 0.6, // SKILL2.md §15: Optical tracking for medium headings
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // ── Targeted Muscles Badges ───────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final muscle in widget.muscleGroups)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2432),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
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
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        muscle.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Session Metrics Strip ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF12151E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SessionMetricItem(
                  icon: Icons.fitness_center_rounded,
                  label: '${widget.exerciseCount} EXERCISES',
                ),
                Container(
                  width: 1,
                  height: 11,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                _SessionMetricItem(
                  icon: Icons.timer_outlined,
                  label: '~${widget.estimatedMinutes} MIN',
                ),
                Container(
                  width: 1,
                  height: 11,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                const _SessionMetricItem(
                  icon: Icons.bolt_rounded,
                  label: 'HYPERTROPHY',
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Commence Operation Action Button ──────────────────────────────
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
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'COMMENCE OPERATION',
                      style: AppTypography.titleLarge.copyWith(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 12.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionMetricItem extends StatelessWidget {
  const _SessionMetricItem({
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
          color: AppColors.primary,
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
