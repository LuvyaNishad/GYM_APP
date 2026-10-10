import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
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
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Compact Header (Always visible) ────────────────────────────────
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Split Number Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.onyx,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.steel),
                        ),
                        child: Text(
                          '${splitIndex + 1}',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Title
                      Expanded(
                        child: Text(
                          split.name,
                          style: AppTypography.titleLarge.copyWith(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pureWhite,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Status Badge
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                style: AppTypography.monoSmall.copyWith(
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.onyx,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.steel),
                          ),
                          child: Text(
                            split.isCustom ? 'CUSTOM' : 'PRESET',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),

                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 22,
                          color: AppColors.platinum,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Metadata Row
                  Row(
                    children: [
                      Text(
                        '${split.daysPerWeek} DAYS/WK',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: AppColors.steel)),
                      const SizedBox(width: 8),
                      Text(
                        '${split.totalWorkouts} WORKOUTS',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 11.5,
                          color: AppColors.platinum,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: AppColors.steel)),
                      const SizedBox(width: 8),
                      Text(
                        '${split.totalWeeklySets} WEEKLY SETS',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 11.5,
                          color: AppColors.platinum,
                        ),
                      ),
                    ],
                  ),
                ],
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

                  // "Set as Active Program" action if currently inactive
                  if (!isActive) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onSetActive,
                        icon: const Icon(Icons.check, size: 16, color: AppColors.onyx),
                        label: Text(
                          'SET AS ACTIVE TRAINING PROGRAM',
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
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
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
                      const Icon(Icons.calendar_month, size: 18, color: AppColors.pureWhite),
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
                      onStartWorkout: () => onStartDayWorkout(split.workouts[i]),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
