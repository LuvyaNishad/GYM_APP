import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/split_model.dart';

/// Card displaying a single workout day inside an expanded split.
class SplitDayWorkoutCard extends StatefulWidget {
  const SplitDayWorkoutCard({
    super.key,
    required this.day,
    required this.dayIndex,
    required this.onStartWorkout,
  });

  final SplitWorkoutDay day;
  final int dayIndex;
  final VoidCallback onStartWorkout;

  @override
  State<SplitDayWorkoutCard> createState() => _SplitDayWorkoutCardState();
}

class _SplitDayWorkoutCardState extends State<SplitDayWorkoutCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.day.isRestDay) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.onyx,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.steel.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bedtime_outlined, size: 18, color: AppColors.platinum),
            const SizedBox(width: 10),
            Text(
              'DAY ${widget.dayIndex + 1}: REST & RECOVERY',
              style: AppTypography.monoSmall.copyWith(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: AppColors.platinum,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(
              'Growth phase',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11.5,
                color: AppColors.platinum.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.onyx,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.steel, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Header Row (Clickable to toggle exercise preview)
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Day Number Badge
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.charcoal,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.steel),
                        ),
                        child: Text(
                          '${widget.dayIndex + 1}',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Day Name & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.day.name.toUpperCase(),
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.pureWhite,
                              ),
                            ),
                            if (widget.day.subtitle.isNotEmpty)
                              Text(
                                widget.day.subtitle,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11.5,
                                  color: AppColors.platinum,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Duration & Set count meta
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '~${widget.day.estimatedDurationMinutes} MIN',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                          ),
                          Text(
                            '${widget.day.totalSets} SETS',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              color: AppColors.platinum,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: AppColors.platinum,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Target Muscle Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final muscle in widget.day.targetMuscles)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.charcoal,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.steel),
                          ),
                          child: Text(
                            muscle.toUpperCase(),
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Exercise List
          if (_isExpanded && widget.day.exercises.isNotEmpty) ...[
            const Divider(color: AppColors.steel, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLANNED EXERCISES (${widget.day.exercises.length})',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.platinum,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < widget.day.exercises.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${i + 1}.',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.5,
                              color: AppColors.platinum,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.day.exercises[i].exerciseName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                          Text(
                            '${widget.day.exercises[i].targetSets} × ${widget.day.exercises[i].repRange}',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.platinum,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Bottom Action: START WORKOUT BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  widget.onStartWorkout();
                },
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                  color: AppColors.onyx,
                ),
                label: Text(
                  'START WORKOUT',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppColors.onyx,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pureWhite,
                  foregroundColor: AppColors.onyx,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
