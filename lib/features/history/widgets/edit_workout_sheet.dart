/// Historical Workout Log Editor Sheet for AEON.
/// Allows correcting past workout session data (sets, reps, weights, warmup flags, and deletion).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/measurement_units.dart';
import '../../../models/workout_model.dart';
import '../providers/history_provider.dart';
import '../../../shared/widgets/persistence_feedback.dart';
import '../../../shared/widgets/app_sheet.dart';

class EditWorkoutSheet extends ConsumerStatefulWidget {
  const EditWorkoutSheet({super.key, required this.workout});

  final WorkoutModel workout;

  static Future<void> show(BuildContext context, WorkoutModel workout) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditWorkoutSheet(workout: workout),
    );
  }

  @override
  ConsumerState<EditWorkoutSheet> createState() => _EditWorkoutSheetState();
}

class _EditableSet {
  _EditableSet({
    required double weight,
    required int reps,
    required this.isWarmup,
    required this.isPr,
    WorkoutSet? source,
    bool unilateral = false,
    MeasurementUnits units = const MeasurementUnits(),
  }) : original = source ?? WorkoutSet(weightKg: weight, reps: reps),
       weightController = TextEditingController(
         text: units.weightInput(weight),
       ),
       repsController = TextEditingController(text: reps.toString()),
       rightWeightController =
           unilateral ||
               source?.weightKgRight != null ||
               source?.repsRight != null
           ? TextEditingController(
               text: units.weightInput(source?.weightKgRight ?? weight),
             )
           : null,
       rightRepsController =
           unilateral ||
               source?.weightKgRight != null ||
               source?.repsRight != null
           ? TextEditingController(text: (source?.repsRight ?? reps).toString())
           : null;

  final WorkoutSet original;
  final TextEditingController? rightWeightController, rightRepsController;
  final TextEditingController weightController;
  final TextEditingController repsController;
  bool isWarmup;
  bool isPr;

  void dispose() {
    weightController.dispose();
    repsController.dispose();
    rightWeightController?.dispose();
    rightRepsController?.dispose();
  }
}

class _EditableExercise {
  _EditableExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.sets,
    required this.original,
  });

  final WorkoutExercise original;
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final List<_EditableSet> sets;
}

class _EditWorkoutSheetState extends ConsumerState<EditWorkoutSheet> {
  late final TextEditingController _nameController;
  final List<_EditableExercise> _exercises = [];
  bool _isSaving = false;
  late final MeasurementUnits _units;

  @override
  void initState() {
    super.initState();
    _units = ref.read(measurementUnitsProvider);
    _nameController = TextEditingController(text: widget.workout.name);
    for (final ex in widget.workout.exercises) {
      final editableSets = ex.sets
          .map(
            (s) => _EditableSet(
              weight: s.weightKg,
              reps: s.reps,
              isWarmup: s.isWarmup,
              isPr: s.isPr,
              source: s,
              units: _units,
            ),
          )
          .toList();
      _exercises.add(
        _EditableExercise(
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
          muscleGroup: ex.muscleGroup,
          sets: editableSets,
          original: ex,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final ex in _exercises) {
      for (final s in ex.sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final success = await persistWithFeedback(
      context,
      () async {
        final exercises = <WorkoutExercise>[];
        for (final ex in _exercises) {
          final sets = <WorkoutSet>[];
          for (final set in ex.sets) {
            double weight(TextEditingController controller, double original) {
              if (controller.text == _units.weightInput(original)) {
                return original;
              }
              final value = double.tryParse(controller.text);
              if (value == null || !value.isFinite || value < 0) {
                throw const FormatException();
              }
              return _units.weightToKg(value);
            }

            int reps(TextEditingController controller) {
              final value = int.tryParse(controller.text);
              if (value == null || value <= 0) throw const FormatException();
              return value;
            }

            sets.add(
              set.original.copyWith(
                weightKg: weight(set.weightController, set.original.weightKg),
                reps: reps(set.repsController),
                weightKgRight: set.rightWeightController == null
                    ? null
                    : weight(
                        set.rightWeightController!,
                        set.original.weightKgRight ?? set.original.weightKg,
                      ),
                repsRight: set.rightRepsController == null
                    ? null
                    : reps(set.rightRepsController!),
                isWarmup: set.isWarmup,
              ),
            );
          }
          if (sets.isNotEmpty) exercises.add(ex.original.copyWith(sets: sets));
        }
        if (exercises.isEmpty) throw const FormatException();
        await ref
            .read(historyWorkoutsProvider.notifier)
            .updateWorkout(
              widget.workout.copyWith(
                name: _nameController.text.trim().isEmpty
                    ? widget.workout.name
                    : _nameController.text.trim(),
                exercises: exercises,
              ),
            );
      },
      message:
          'Could not save. Check that weights are valid and reps are positive, then try again.',
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!success) return;
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Workout log updated.'),
        backgroundColor: AppColors.charcoal,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.onyx,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.steel),
        ),
        title: const Text(
          'DELETE WORKOUT LOG',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.danger,
            letterSpacing: 0.8,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this workout from your history? This action cannot be undone.',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: AppTypography.fontBody,
                fontSize: 12.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'DELETE',
              style: TextStyle(
                fontFamily: AppTypography.fontBody,
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || _isSaving) return;
    setState(() => _isSaving = true);
    final success = await persistWithFeedback(
      context,
      () => ref
          .read(historyWorkoutsProvider.notifier)
          .deleteWorkout(widget.workout.id),
      message:
          'Could not delete the workout. Your log is still available. Please try again.',
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!success) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Workout removed from history.'),
        backgroundColor: AppColors.charcoal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(13) > 18;
    return PersistenceForm(
      pending: _isSaving,
      child: AppSheet(
        title: 'EDIT WORKOUT LOG',
        busy: _isSaving,
        children: [
          // Workout Name Input
          TextField(
            controller: _nameController,
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: AppColors.pureWhite,
            ),
            decoration: InputDecoration(
              labelText: 'WORKOUT NAME',
              labelStyle: const TextStyle(
                fontFamily: AppTypography.fontMono,
                fontSize: 11.0,
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
              filled: true,
              fillColor: AppColors.charcoal,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.steel),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.steel.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Exercises List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _exercises.length,
            itemBuilder: (context, exIndex) {
              final ex = _exercises[exIndex];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.steel.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ex.exerciseName,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontBody,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.steel.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ex.muscleGroup.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: AppTypography.fontMono,
                              fontSize: 11.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (!compact) ...[
                      // Set column headers
                      Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              'SET',
                              style: TextStyle(
                                fontFamily: AppTypography.fontBody,
                                fontSize: 11.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _units.weightLabel.toUpperCase(),
                              style: TextStyle(
                                fontFamily: AppTypography.fontBody,
                                fontSize: 11.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'REPS',
                              style: TextStyle(
                                fontFamily: AppTypography.fontBody,
                                fontSize: 11.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(width: 60),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Set rows
                      for (int sIdx = 0; sIdx < ex.sets.length; sIdx++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '${sIdx + 1}',
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontMono,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.platinum,
                                  ),
                                ),
                              ),
                              // Weight field
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: TextField(
                                    controller: ex.sets[sIdx].weightController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontMono,
                                      fontSize: 12.0,
                                      color: AppColors.pureWhite,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                      filled: true,
                                      fillColor: AppColors.onyx,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: AppColors.steel.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Reps field
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: TextField(
                                    controller: ex.sets[sIdx].repsController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontMono,
                                      fontSize: 12.0,
                                      color: AppColors.pureWhite,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                      filled: true,
                                      fillColor: AppColors.onyx,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: AppColors.steel.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Warmup toggle
                              IconButton(
                                icon: Icon(
                                  ex.sets[sIdx].isWarmup
                                      ? Icons.whatshot_rounded
                                      : Icons.whatshot_outlined,
                                  size: 18,
                                  color: ex.sets[sIdx].isWarmup
                                      ? const Color(0xFFFFB300)
                                      : AppColors.textSecondary,
                                ),
                                tooltip: 'Toggle Warmup Set',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  setState(() {
                                    ex.sets[sIdx].isWarmup =
                                        !ex.sets[sIdx].isWarmup;
                                  });
                                },
                              ),
                              // Delete set
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                tooltip: 'Delete Set',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  setState(() {
                                    final removed = ex.sets.removeAt(sIdx);
                                    removed.dispose();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      for (final set in ex.sets.where(
                        (set) => set.rightWeightController != null,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text(
                                  'R${ex.sets.indexOf(set) + 1}',
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontMono,
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: set.rightWeightController,
                                  enabled: !_isSaving,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontMono,
                                    fontSize: 13,
                                    color: AppColors.pureWhite,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Right ${_units.weightLabel}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: set.rightRepsController,
                                  enabled: !_isSaving,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontMono,
                                    fontSize: 13,
                                    color: AppColors.pureWhite,
                                  ),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Right reps',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 60),
                            ],
                          ),
                        ),
                    ],
                    if (compact)
                      for (int index = 0; index < ex.sets.length; index++)
                        _largeSet(ex, index),

                    // Add set button
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            final lastWeight = ex.sets.isNotEmpty
                                ? double.tryParse(
                                        ex.sets.last.weightController.text,
                                      ) ??
                                      60.0
                                : 60.0;
                            final lastReps = ex.sets.isNotEmpty
                                ? int.tryParse(
                                        ex.sets.last.repsController.text,
                                      ) ??
                                      10
                                : 10;
                            ex.sets.add(
                              _EditableSet(
                                weight: _units.weightToKg(lastWeight),
                                units: _units,
                                reps: lastReps,
                                isWarmup: false,
                                isPr: false,
                                unilateral: ex.original.sets.any(
                                  (set) =>
                                      set.weightKgRight != null ||
                                      set.repsRight != null,
                                ),
                              ),
                            );
                          });
                        },
                        icon: const Icon(
                          Icons.add,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'ADD SET',
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          if (_isSaving) const Text('Saving changes…'),
          _actions(compact),
        ],
      ),
    );
  }

  Widget _largeSet(_EditableExercise exercise, int index) {
    final set = exercise.sets[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Set ${index + 1}', style: AppTypography.bodyMedium),
          const SizedBox(height: 8),
          _numberInput('Weight (${_units.weightLabel})', set.weightController),
          const SizedBox(height: 12),
          _numberInput('Reps', set.repsController, decimal: false),
          if (set.rightWeightController != null) ...[
            const SizedBox(height: 12),
            _numberInput(
              'Right weight (${_units.weightLabel})',
              set.rightWeightController!,
            ),
            const SizedBox(height: 12),
            _numberInput(
              'Right reps',
              set.rightRepsController!,
              decimal: false,
            ),
          ],
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Warmup set'),
              value: set.isWarmup,
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => set.isWarmup = value),
            ),
          ),
          TextButton.icon(
            onPressed: _isSaving
                ? null
                : () => setState(() {
                    exercise.sets.removeAt(index).dispose();
                  }),
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: const Text('Remove set'),
          ),
        ],
      ),
    );
  }

  Widget _numberInput(
    String label,
    TextEditingController controller, {
    bool decimal = true,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: AppTypography.bodySmall),
      const SizedBox(height: 6),
      Semantics(
        label: label,
        child: TextField(
          controller: controller,
          enabled: !_isSaving,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          style: AppTypography.monoMedium,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
    ],
  );

  Widget _actions(bool compact) {
    final save = ElevatedButton(
      onPressed: _isSaving ? null : _saveChanges,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text('SAVE CHANGES'),
    );
    final remove = OutlinedButton(
      onPressed: _isSaving ? null : _confirmDelete,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        side: const BorderSide(color: AppColors.danger),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text('DELETE'),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [save, const SizedBox(height: 12), remove],
      );
    }
    return Row(
      children: [
        Expanded(child: remove),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: save),
      ],
    );
  }
}
