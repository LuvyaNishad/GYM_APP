import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/exercise_library_item.dart';
import '../providers/exercise_library_provider.dart';

/// Retractable bottom-up sheet with notch affordance for viewing exercise details,
/// step-by-step instructions, coaching cues, and equipment alternatives.
class ExerciseDetailSheet extends ConsumerStatefulWidget {
  const ExerciseDetailSheet({
    super.key,
    required this.initialExercise,
    required this.onAddToWorkout,
  });

  final ExerciseLibraryItem initialExercise;
  final ValueChanged<ExerciseLibraryItem> onAddToWorkout;

  @override
  ConsumerState<ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends ConsumerState<ExerciseDetailSheet> {
  late ExerciseLibraryItem _currentExercise;

  @override
  void initState() {
    super.initState();
    _currentExercise = widget.initialExercise;
  }

  void _switchToExercise(ExerciseLibraryItem alt) {
    setState(() {
      _currentExercise = alt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(exerciseLibraryProvider.notifier);
    final alternatives = notifier.getAlternatives(_currentExercise.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.38,
      maxChildSize: 0.94,
      snap: true,
      snapSizes: const [0.58, 0.94],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.onyx.withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: AppColors.steel,
                  width: 1.0,
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // ── Top Notch / Grabber Handle ─────────────────────────
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.steel,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Exercise Header ────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentExercise.name,
                              style: AppTypography.headlineMedium.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: AppColors.pureWhite,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _buildBadge(_currentExercise.category.toUpperCase(), AppColors.pureWhite, true),
                                _buildBadge(_currentExercise.movementPatternDisplay.toUpperCase(), AppColors.platinum, false),
                                _buildBadge(_currentExercise.exerciseType.toUpperCase(), AppColors.platinum, false),
                                _buildBadge(_currentExercise.difficultyDisplay.toUpperCase(), AppColors.platinum, false),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppColors.platinum),
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Quick Summary Chips ────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          title: 'PRIMARY MUSCLE',
                          content: _currentExercise.primaryMusclesDisplay,
                          highlightColor: AppColors.pureWhite,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInfoCard(
                          title: 'EQUIPMENT',
                          content: _currentExercise.equipmentDisplay,
                          highlightColor: AppColors.platinum,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Secondary Stabilizers Card ─────────────────────────
                  if (_currentExercise.secondaryMuscles.isNotEmpty)
                    _buildInfoCard(
                      title: 'SECONDARY & STABILIZERS',
                      content: _currentExercise.secondaryMusclesDisplay,
                      highlightColor: AppColors.platinum,
                    ),

                  const SizedBox(height: 16),

                  // ── Primary Action Button [ADD TO WORKOUT] ──────────────
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onAddToWorkout(_currentExercise);
                    },
                    icon: const Icon(Icons.add_rounded, size: 20, color: AppColors.onyx),
                    label: Text(
                      'ADD TO WORKOUT',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.onyx,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.pureWhite,
                      foregroundColor: AppColors.onyx,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.steel, height: 1),
                  const SizedBox(height: 16),

                  // ── Personal Performance / History Snapshot ────────────
                  _buildPersonalRecordBanner(),

                  const SizedBox(height: 18),

                  // ── Step-by-Step Instructions ──────────────────────────
                  _buildSectionTitle('HOW TO PERFORM'),
                  const SizedBox(height: 8),
                  ..._currentExercise.instructions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 10, top: 1),
                            decoration: BoxDecoration(
                              color: AppColors.steel,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.steel,
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${entry.key + 1}',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 13.0,
                                height: 1.4,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // ── Coaching Cues & Safety Notes ───────────────────────
                  if (_currentExercise.coachingNotes.isNotEmpty) ...[
                    _buildSectionTitle('COACHING & SAFETY CUES'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.steel,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 18,
                            color: AppColors.platinum,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentExercise.coachingNotes,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 12.5,
                                height: 1.4,
                                color: AppColors.platinum,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Smart Alternatives ("Equipment Occupied? Try These") ─
                  if (alternatives.isNotEmpty) ...[
                    _buildSectionTitle('EQUIPMENT OCCUPIED? TRY THESE SWAPS'),
                    const SizedBox(height: 8),
                    ...alternatives.map((alt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => _switchToExercise(alt),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.charcoal,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.steel,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 18,
                                  color: AppColors.pureWhite,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alt.name,
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.pureWhite,
                                        ),
                                      ),
                                      Text(
                                        '${alt.primaryEquipment.toUpperCase()} · ${alt.primaryMusclesDisplay}',
                                        style: AppTypography.monoSmall.copyWith(
                                          fontSize: 11.0,
                                          color: AppColors.platinum,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.platinum,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.labelSmall.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: AppColors.platinum,
      ),
    );
  }

  Widget _buildBadge(String label, Color color, bool isFilled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFilled ? AppColors.steel : AppColors.onyx,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.steel,
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.monoSmall.copyWith(
          fontSize: 11.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: isFilled ? AppColors.pureWhite : AppColors.platinum,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required Color highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.steel,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.monoSmall.copyWith(
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: AppColors.platinum,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: highlightColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalRecordBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.steel,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.steel,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              size: 20,
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERSONAL BEST RECORD',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.platinum,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '85.0 kg × 8 reps  ·  Est. 1RM: 105.4 kg',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
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
