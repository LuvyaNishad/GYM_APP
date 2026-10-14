/// Expandable workout session history card for LEON.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/workout_model.dart';
import 'edit_workout_sheet.dart';

class WorkoutHistoryCard extends StatefulWidget {
  const WorkoutHistoryCard({
    super.key,
    required this.workout,
    this.initiallyExpanded = false,
  });

  final WorkoutModel workout;
  final bool initiallyExpanded;

  @override
  State<WorkoutHistoryCard> createState() => _WorkoutHistoryCardState();
}

class _WorkoutHistoryCardState extends State<WorkoutHistoryCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  String _formatDate(DateTime dt) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    return '${mins}M';
  }

  String _formatTonnage(double volume) {
    final intVol = volume.toInt();
    if (intVol >= 1000) {
      final k = (intVol / 1000).toStringAsFixed(1);
      return '$k' 'K KG';
    }
    return '$intVol KG';
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;
    final prCount = w.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.sets.where((s) => s.isPr).length,
    );
    final totalSets = w.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.sets.where((s) => !s.isWarmup).length,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isExpanded = !_isExpanded);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date and Stats Row ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date badge
                    Text(
                      _formatDate(w.date),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),

                    // PR Highlight or Duration tag
                    Row(
                      children: [
                        if (prCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00E676),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🏆 ', style: TextStyle(fontSize: 11)),
                                Text(
                                  '$prCount PR${prCount > 1 ? 'S' : ''}',
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF00E676),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.steel.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDuration(w.durationSeconds),
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
                  ],
                ),

                const SizedBox(height: 8),

                // ── Workout Title ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        w.name.toUpperCase(),
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pureWhite,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Sub-metrics Pill Row ────────────────────────────────────────
                Row(
                  children: [
                    _buildSubTag('${w.exercises.length} EXERCISES'),
                    const SizedBox(width: 6),
                    _buildSubTag('$totalSets SETS'),
                    const SizedBox(width: 6),
                    _buildSubTag(_formatTonnage(w.totalVolumeKg ?? 0)),
                  ],
                ),

                // ── Expandable Exercise Set Breakdown ─────────────────────────
                if (_isExpanded) ...[
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.steel, height: 1),
                  const SizedBox(height: 12),
                  for (final ex in w.exercises)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ex.exerciseName,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                              Text(
                                ex.muscleGroup.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (int i = 0; i < ex.sets.length; i++)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ex.sets[i].isPr
                                        ? const Color(0xFF00E676).withValues(alpha: 0.15)
                                        : AppColors.steel.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(6),
                                    border: ex.sets[i].isPr
                                        ? Border.all(
                                            color: const Color(0xFF00E676),
                                            width: 0.8,
                                          )
                                        : null,
                                  ),
                                  child: Text(
                                    '${ex.sets[i].weightKg}kg × ${ex.sets[i].reps}',
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w600,
                                      color: ex.sets[i].isPr
                                          ? const Color(0xFF00E676)
                                          : AppColors.platinum,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Action Row: EDIT WORKOUT
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        EditWorkoutSheet.show(context, widget.workout);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: Color(0xFF00E5FF),
                      ),
                      label: const Text(
                        'EDIT WORKOUT',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00E5FF),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.steel.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          color: AppColors.platinum,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
