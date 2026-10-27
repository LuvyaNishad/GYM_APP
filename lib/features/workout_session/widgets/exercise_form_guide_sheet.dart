import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../exercise_library/models/exercise_library_item.dart';
import '../../exercise_library/providers/exercise_library_provider.dart';
import '../../exercise_library/screens/exercise_detail_screen.dart';
import '../../history/providers/history_provider.dart';
import '../models/active_session_state.dart';

class ExerciseFormGuideSheet extends ConsumerWidget {
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
    final matched = catalog
        .where(
          (e) =>
              e.id == exercise.exerciseId ||
              e.name.toLowerCase() == exercise.name.toLowerCase(),
        )
        .firstOrNull;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ExerciseFormGuideSheet(exercise: exercise, libraryItem: matched),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = libraryItem;
    final sets = ref
        .watch(historyWorkoutsProvider)
        .expand((w) => w.exercises)
        .where(
          (e) =>
              e.exerciseId == exercise.exerciseId ||
              e.exerciseName.toLowerCase() == exercise.name.toLowerCase(),
        )
        .expand((e) => e.sets)
        .where((s) => !s.isWarmup && s.reps > 0)
        .toList();
    final bestWeight = sets.fold<double>(
      0,
      (max, s) => s.weightKg > max ? s.weightKg : max,
    );
    final e1rm = sets.where((s) => s.reps <= 12).fold<double>(0, (max, s) {
      final estimate = s.weightKg * (1 + s.reps / 30);
      return estimate > max ? estimate : max;
    });
    return AppSheet(
      title: exercise.name,
      children: [
        Text('FORM CUES', style: AppTypography.monoSmall),
        const SizedBox(height: 12),
        if (item == null || item.instructions.isEmpty)
          const Text('Detailed cues are not available for this exercise.')
        else
          for (var i = 0; i < item.instructions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}', style: AppTypography.monoSmall),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.instructions[i],
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        if (item != null && item.coachingNotes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(item.coachingNotes, style: AppTypography.bodyMedium),
          ),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SAVED PERFORMANCE', style: AppTypography.monoSmall),
              const SizedBox(height: 10),
              Text(
                sets.isEmpty
                    ? 'No saved working sets yet.'
                    : 'Heaviest logged: ${bestWeight.toStringAsFixed(1)} kg',
                style: AppTypography.bodyMedium,
              ),
              if (e1rm > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Estimated 1RM: ${e1rm.toStringAsFixed(1)} kg\nEpley estimate from saved sets of 1–12 reps.',
                    style: AppTypography.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (item != null)
          OutlinedButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ExerciseDetailScreen(exercise: item, fromSession: true),
              ),
            ),
            child: const Text('FULL EXERCISE DETAILS'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('RETURN TO WORKOUT'),
        ),
      ],
    );
  }
}
