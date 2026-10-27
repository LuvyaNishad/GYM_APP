import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/split_model.dart';
import 'muscle_balance_card.dart';
import 'split_day_workout_card.dart';

/// Compact bento card that expands to reveal muscle radar balance and daily workouts.
class SplitCompactCard extends StatelessWidget {
  const SplitCompactCard({
    super.key,
    required this.split,
    required this.splitIndex,
    required this.isActive,
    required this.isExpanded,
    required this.loggedVolume,
    required this.onToggleExpand,
    required this.onSetActive,
    required this.onStartDayWorkout,
    this.onAutoTuneMuscle,
    this.onCustomize,
  });

  final TrainingSplitModel split;
  final int splitIndex;
  final bool isActive;
  final bool isExpanded;
  final Map<String, int> loggedVolume;
  final VoidCallback onToggleExpand;
  final VoidCallback onSetActive;
  final void Function(SplitWorkoutDay day) onStartDayWorkout;
  final void Function(String muscle)? onAutoTuneMuscle;
  final VoidCallback? onCustomize;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? AppColors.pureWhite : AppColors.steel,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Compact Header (Always visible) ────────────────────────────────
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onToggleExpand();
              },
              borderRadius: BorderRadius.circular(18),
              splashColor: AppColors.primary.withValues(alpha: 0.12),
              highlightColor: AppColors.primary.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Split Number Badge, Full Title (no truncation), Expand Arrow
                    Row(
                      children: [
                        // Split Number Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.onyx,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.steel.withValues(alpha: 0.8),
                            ),
                          ),
                          child: Text(
                            '0${splitIndex + 1}',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title
                        Expanded(
                          child: Text(
                            split.name,
                            style: AppTypography.titleLarge.copyWith(
                              fontSize: 17.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              color: AppColors.pureWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 10),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.onyx,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.steel.withValues(alpha: 0.6),
                              ),
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Row 2: Status Pill & Metric Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Status Badge
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.onyx,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'CURRENT PROGRAM',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: AppColors.onyx,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.onyx,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.steel.withValues(alpha: 0.8),
                              ),
                            ),
                            child: Text(
                              split.isCustom ? 'CUSTOM' : 'PRESET',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: AppColors.platinum,
                              ),
                            ),
                          ),

                        // Metric Chip 1: Days/Week
                        _buildMetricChip('${split.daysPerWeek} DAYS/WK'),

                        // Metric Chip 2: Workouts
                        _buildMetricChip('${split.totalWorkouts} WORKOUTS'),

                        // Metric Chip 3: Weekly Sets
                        _buildMetricChip('${split.totalWeeklySets} TOTAL SETS'),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Row 3: Description Preview
                    Text(
                      split.description,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12.0,
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Expanded Deep Inspection ───────────────────────────────────────
          if (isExpanded) ...[
            const Divider(color: AppColors.steel, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    split.description,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13.0,
                      color: AppColors.platinum,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Quick actions: Set Active and/or Customize Routine
                  if (!isActive || onCustomize != null) ...[
                    Row(
                      children: [
                        if (!isActive)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onSetActive();
                              },
                              icon: const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.onyx,
                              ),
                              label: Text(
                                onCustomize != null
                                    ? 'SET ACTIVE'
                                    : 'SET AS ACTIVE PROGRAM',
                                style: AppTypography.monoSmall.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: AppColors.onyx,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.pureWhite,
                                foregroundColor: AppColors.onyx,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        if (!isActive && onCustomize != null)
                          const SizedBox(width: 8),
                        if (onCustomize != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onCustomize!();
                              },
                              icon: const Icon(
                                Icons.tune_rounded,
                                size: 15,
                                color: AppColors.pureWhite,
                              ),
                              label: Text(
                                'CUSTOMIZE',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.pureWhite,
                                side: const BorderSide(color: AppColors.steel),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Muscle Balance Radar System
                  MuscleBalanceCard(
                    plannedVolume: split.plannedMuscleSets,
                    loggedVolume: loggedVolume,
                    onAutoTuneMuscle: onAutoTuneMuscle,
                  ),

                  const SizedBox(height: 20),

                  // Day-by-Day Rotation Title
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 18,
                        color: AppColors.pureWhite,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DAY-BY-DAY ROTATION',
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: 14.0,
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
                          color: AppColors.platinum,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Daily Workout Cards List
                  for (int i = 0; i < split.workouts.length; i++)
                    SplitDayWorkoutCard(
                      day: split.workouts[i],
                      dayIndex: i,
                      onStartWorkout: () =>
                          onStartDayWorkout(split.workouts[i]),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.onyx,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.monoSmall.copyWith(
          fontSize: 11.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.platinum,
        ),
      ),
    );
  }
}
