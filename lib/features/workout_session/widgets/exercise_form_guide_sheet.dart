import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../exercise_library/models/exercise_library_item.dart';
import '../../exercise_library/providers/exercise_library_provider.dart';
import '../models/active_session_state.dart';

/// Non-disruptive, interactive bottom sheet providing instant access to:
/// - Exercise Form Guide & Step-by-Step execution cues
/// - All-time Personal Records & Estimated 1RM
/// - Target muscle groups & equipment setup
/// - Option to deep-dive into full exercise analytics without losing active workout state
class ExerciseFormGuideSheet extends StatelessWidget {
  const ExerciseFormGuideSheet({
    super.key,
    required this.exercise,
    this.libraryItem,
  });

  final ActiveExerciseState exercise;
  final ExerciseLibraryItem? libraryItem;

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required ActiveExerciseState exercise,
  }) async {
    final catalog = ref.read(exerciseLibraryProvider).allExercises;
    ExerciseLibraryItem? matched;
    try {
      matched = catalog.firstWhere(
        (e) =>
            e.id == exercise.exerciseId ||
            e.name.trim().toLowerCase() == exercise.name.trim().toLowerCase(),
      );
    } catch (_) {
      matched = null;
    }

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ExerciseFormGuideSheet(
        exercise: exercise,
        libraryItem: matched,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final item = libraryItem;

    // Calculate Estimated 1RM from top logged set or previous ghost data
    ActiveSetState? bestSet = exercise.topCompletedSet;
    if (bestSet == null && exercise.sets.isNotEmpty) {
      // Find highest previous ghost set
      final ghostSets = exercise.sets
          .where((s) => (s.previousWeightKg ?? 0) > 0)
          .toList();
      if (ghostSets.isNotEmpty) {
        ghostSets.sort((a, b) =>
            (b.previousWeightKg ?? 0).compareTo(a.previousWeightKg ?? 0));
        bestSet = ghostSets.first;
      } else {
        bestSet = exercise.sets.first;
      }
    }

    final bestWeight = bestSet?.isCompleted == true
        ? bestSet!.weightKg
        : (bestSet?.previousWeightKg ?? bestSet?.weightKg ?? 0.0);
    final bestReps = bestSet?.isCompleted == true
        ? bestSet!.reps
        : (bestSet?.previousReps ?? bestSet?.reps ?? 1);

    // E1RM Formula (Epley): Weight × (1 + Reps / 30)
    final estimated1RM = bestWeight > 0
        ? (bestWeight * (1.0 + (bestReps / 30.0))).roundToDouble()
        : 0.0;

    final instructions = item?.instructions ??
        [
          'Position equipment securely and maintain optimal posture.',
          'Brace core and engage target muscle groups throughout the movement.',
          'Execute with controlled eccentric tempo and explosive concentric drive.',
          'Maintain constant tension and avoid using excessive momentum.',
        ];

    final coachingNotes = item?.coachingNotes ??
        'Keep shoulder blades packed, maintain a neutral spine, and control every repetition.';

    final primaryMuscles = item?.primaryMuscles.isNotEmpty == true
        ? item!.primaryMuscles
        : [exercise.muscleGroup];

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.onyx,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.steel, width: 1.5),
          left: BorderSide(color: AppColors.steel, width: 1.0),
          right: BorderSide(color: AppColors.steel, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.steel,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name.toUpperCase(),
                          style: AppTypography.headlineSmall.copyWith(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pureWhite,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildTagPill(
                              label: exercise.muscleGroup.toUpperCase(),
                              isPrimary: true,
                            ),
                            _buildTagPill(
                              label: exercise.equipment.toUpperCase(),
                              isPrimary: false,
                            ),
                            if (item != null && item.exerciseType.isNotEmpty)
                              _buildTagPill(
                                label: item.exerciseType.toUpperCase(),
                                isPrimary: false,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.platinum, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close Guide',
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.steel),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // PR & 1RM Highlight Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.steel),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.steel.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.emoji_events_outlined,
                              color: AppColors.pureWhite,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ESTIMATED 1RM',
                                  style: AppTypography.monoSmall.copyWith(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.platinum,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  estimated1RM > 0
                                      ? '${estimated1RM.toInt()} kg'
                                      : 'No Logged Load',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'BEST SET',
                                style: AppTypography.monoSmall.copyWith(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.platinum,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                bestWeight > 0
                                    ? '${bestWeight.toInt()}kg × $bestReps'
                                    : '—',
                                style: AppTypography.monoSmall.copyWith(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Coaching Cues Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.steel,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 16,
                                color: AppColors.pureWhite,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'KEY COACHING CUES',
                                style: AppTypography.headlineSmall.copyWith(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.pureWhite,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            coachingNotes,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12.5,
                              height: 1.45,
                              color: AppColors.platinum,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Target Anatomy
                    Text(
                      'TARGET ANATOMY',
                      style: AppTypography.headlineSmall.copyWith(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: primaryMuscles.map((muscle) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.charcoal,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.steel),
                          ),
                          child: Text(
                            muscle.toUpperCase(),
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Step-by-Step Execution Guide
                    Text(
                      'STEP-BY-STEP EXECUTION',
                      style: AppTypography.headlineSmall.copyWith(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),

                    for (int i = 0; i < instructions.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                color: AppColors.charcoal,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.steel),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: AppTypography.monoSmall.copyWith(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                instructions[i],
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
                  ],
                ),
              ),
            ),

            // Bottom Actions (Back to workout & optional full deep-dive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  if (item != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push(
                            AppConstants.routeExerciseDetail,
                            extra: item,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.steel),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 44),
                        ),
                        child: Text(
                          'FULL DETAILS',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pureWhite,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.pureWhite,
                        foregroundColor: AppColors.onyx,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(
                        'BACK TO WORKOUT',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onyx,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagPill({
    required String label,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.pureWhite.withValues(alpha: 0.12)
            : AppColors.charcoal,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPrimary ? AppColors.pureWhite : AppColors.steel,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.monoSmall.copyWith(
          fontSize: 11.0,
          fontWeight: FontWeight.w700,
          color: isPrimary ? AppColors.pureWhite : AppColors.platinum,
        ),
      ),
    );
  }
}
