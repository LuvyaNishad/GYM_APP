import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../exercise_library/models/exercise_library_item.dart';
import '../../exercise_library/providers/exercise_library_provider.dart';
import '../models/active_session_state.dart';
import '../providers/active_session_provider.dart';
import 'exercise_picker_modal.dart';

int substitutionScore(
  ExerciseLibraryItem current,
  ExerciseLibraryItem candidate,
) {
  var score = 0;
  if (current.movementPattern != 'general' &&
      current.movementPattern == candidate.movementPattern) {
    score += 10;
  }
  if (current.primaryMuscles.any(candidate.primaryMuscles.contains)) score += 5;
  if (current.category.toLowerCase() == candidate.category.toLowerCase()) {
    score += 3;
  }
  if (current.primaryEquipment == candidate.primaryEquipment) score += 2;
  if (current.exerciseType == candidate.exerciseType) score++;
  return score;
}

void showExerciseSubstitutionSheet({
  required BuildContext context,
  required ActiveExerciseState currentExercise,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => ExerciseSubstitutionSheet(currentExercise: currentExercise),
);

class ExerciseSubstitutionSheet extends ConsumerStatefulWidget {
  const ExerciseSubstitutionSheet({super.key, required this.currentExercise});
  final ActiveExerciseState currentExercise;
  @override
  ConsumerState<ExerciseSubstitutionSheet> createState() =>
      _ExerciseSubstitutionSheetState();
}

class _ExerciseSubstitutionSheetState
    extends ConsumerState<ExerciseSubstitutionSheet> {
  String _equipment = 'All';
  @override
  Widget build(BuildContext context) {
    final ex = widget.currentExercise;
    final all = ref.watch(exerciseLibraryProvider).allExercises;
    final current =
        all
            .where(
              (e) =>
                  e.id == ex.exerciseId ||
                  e.name.toLowerCase() == ex.name.toLowerCase(),
            )
            .firstOrNull ??
        ExerciseLibraryItem(
          id: ex.exerciseId,
          name: ex.name,
          category: ex.muscleGroup,
          description: '',
          primaryEquipment: ex.equipment,
        );
    final matches =
        all
            .where(
              (e) =>
                  e.name != current.name &&
                  (_equipment == 'All' || e.primaryEquipment == _equipment) &&
                  (e.category == current.category ||
                      (current.movementPattern != 'general' &&
                          current.movementPattern == e.movementPattern)),
            )
            .toList()
          ..sort(
            (a, b) => substitutionScore(
              current,
              b,
            ).compareTo(substitutionScore(current, a)),
          );
    return AppSheet(
      title: 'Replace exercise',
      children: [
        Text(ex.name, style: AppTypography.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Completed sets stay under the original exercise. Remaining work starts with the replacement’s previous values when available.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _equipment,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Available equipment'),
          items: [
            'All',
            ...all.map((e) => e.primaryEquipment).toSet().toList()..sort(),
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _equipment = v ?? 'All'),
        ),
        const SizedBox(height: 16),
        Text('RECOMMENDED', style: AppTypography.monoSmall),
        if (matches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No close matches for this filter. Browse the full library.',
            ),
          ),
        for (final item in matches.take(8))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.name),
            subtitle: Text(
              '${item.movementPatternDisplay} · ${item.primaryEquipment}',
            ),
            trailing: const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.platinum,
            ),
            onTap: () {
              ref
                  .read(activeSessionProvider.notifier)
                  .replaceExercise(
                    ex.exerciseId,
                    item.toActiveExercise(defaultWeightKg: 0),
                  );
              Navigator.pop(context);
            },
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ExercisePickerModal(
              onExerciseSelected: (selected) {
                ref
                    .read(activeSessionProvider.notifier)
                    .replaceExercise(ex.exerciseId, selected);
                // The picker closes itself; close this recommendation sheet next.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Navigator.pop(context);
                });
              },
            ),
          ),
          icon: const Icon(Icons.search_rounded),
          label: const Text('BROWSE ALL EXERCISES'),
        ),
      ],
    );
  }
}
