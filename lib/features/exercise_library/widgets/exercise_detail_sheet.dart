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
                color: const Color(0xFF0F1219).withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
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
                        color: const Color(0xFF475569),
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
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _buildBadge(_currentExercise.category.toUpperCase(), AppColors.primary, true),
                                _buildBadge(_currentExercise.movementPatternDisplay.toUpperCase(), const Color(0xFFCBD5E1), false),
                                _buildBadge(_currentExercise.exerciseType.toUpperCase(), const Color(0xFF94A3B8), false),
                                _buildBadge(_currentExercise.difficultyDisplay.toUpperCase(), AppColors.amber, false),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
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
                          highlightColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInfoCard(
                          title: 'EQUIPMENT',
                          content: _currentExercise.equipmentDisplay,
                          highlightColor: const Color(0xFFCBD5E1),
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
                      highlightColor: const Color(0xFF94A3B8),
                    ),

                  const SizedBox(height: 16),

                  // ── Primary Action Button [ADD TO WORKOUT] ──────────────
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onAddToWorkout(_currentExercise);
                    },
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'ADD TO WORKOUT',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Colors.black,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFF1E293B), height: 1),
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
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${entry.key + 1}',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 13.0,
                                height: 1.4,
                                color: const Color(0xFFE2E8F0),
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
                        color: const Color(0xFF141722),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 18,
                            color: AppColors.amber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentExercise.coachingNotes,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 12.5,
                                height: 1.4,
                                color: const Color(0xFFCBD5E1),
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
                              color: const Color(0xFF161A23),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 18,
                                  color: AppColors.primary,
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
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '${alt.primaryEquipment.toUpperCase()} · ${alt.primaryMusclesDisplay}',
                                        style: AppTypography.monoSmall.copyWith(
                                          fontSize: 11.0,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
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
        color: const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, bool isFilled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFilled ? color.withValues(alpha: 0.15) : const Color(0xFF1E2433),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.monoSmall.copyWith(
          fontSize: 11.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
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
        color: const Color(0xFF141722),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
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
              color: const Color(0xFF94A3B8),
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
        color: const Color(0xFF161A23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.20),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              size: 20,
              color: AppColors.primary,
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
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '85.0 kg × 8 reps  ·  Est. 1RM: 105.4 kg',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
