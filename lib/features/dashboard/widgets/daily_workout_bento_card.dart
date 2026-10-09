/// Daily Workout / Start Workout Bento Card for the LEON Dashboard.
///
/// Features:
/// - Operation/Protocol briefing banner with active status indicator
/// - Daily targeted muscle groups display with tactical glass tags
/// - Workout session telemetry preview (exercise count, estimated time, target RPE)
/// - Prominent glass "COMMENCE OPERATION" initiation action button
/// - Cyber-Slate glassmorphic design language
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/split_model.dart';
import '../../../shared/widgets/liquid_glass.dart';

/// Full-width Bento card for reviewing today's workout protocol and launching the session.
class DailyWorkoutBentoCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final splitTitle =
        activeSplit?.name.toUpperCase() ?? 'TACTICAL PUSH // PROTOCOL A';

    return LiquidGlassContainer(
      borderRadius: 22,
      blurSigma: 24,
      glowColor: AppColors.primary.withValues(alpha: 0.16),
      padding: const EdgeInsets.all(20),
      borderWidth: 1.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Active Status + Target RPE ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE PROTOCOL',
                      style: AppTypography.labelSmall.copyWith(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                'TARGET RPE $targetRpe',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Protocol Name ─────────────────────────────────────────────────
          Text(
            splitTitle,
            style: AppTypography.headlineMedium.copyWith(
              fontSize: 18,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 14),

          // ── Targeted Muscles Heading & Badges ─────────────────────────────
          Row(
            children: [
              Text(
                'TARGETED MUSCLES',
                style: AppTypography.labelSmall.copyWith(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final muscle in muscleGroups)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      width: 1,
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
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        muscle.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Session Metrics Strip ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SessionMetricItem(
                  icon: Icons.fitness_center_rounded,
                  label: '$exerciseCount EXERCISES',
                ),
                Container(
                  width: 1,
                  height: 14,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                _SessionMetricItem(
                  icon: Icons.timer_outlined,
                  label: '~$estimatedMinutes MIN',
                ),
                Container(
                  width: 1,
                  height: 14,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                const _SessionMetricItem(
                  icon: Icons.bolt_rounded,
                  label: 'HYPERTROPHY',
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Commence Operation Action Button ──────────────────────────────
          LiquidGlassButton(
            height: 50,
            accentColor: AppColors.primary,
            onPressed: () {
              HapticFeedback.heavyImpact();
              if (onStartWorkout != null) {
                onStartWorkout!();
              } else {
                context.push(AppConstants.routeWorkoutSession);
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'COMMENCE OPERATION',
                  style: AppTypography.titleLarge.copyWith(
                    fontFamily: 'Outfit',
                    fontSize: 13.5,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
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
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}
