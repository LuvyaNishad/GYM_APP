/// Historical Workout Log Editor Sheet for LEON.
/// Allows correcting past workout session data (sets, reps, weights, warmup flags, and deletion).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/workout_model.dart';
import '../providers/history_provider.dart';

class EditWorkoutSheet extends ConsumerStatefulWidget {
  const EditWorkoutSheet({
    super.key,
    required this.workout,
  });

  final WorkoutModel workout;

  static Future<void> show(BuildContext context, WorkoutModel workout) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
  })  : weightController = TextEditingController(
          text: weight % 1 == 0 ? weight.toInt().toString() : weight.toString(),
        ),
        repsController = TextEditingController(text: reps.toString());

  final TextEditingController weightController;
  final TextEditingController repsController;
  bool isWarmup;
  bool isPr;

  void dispose() {
    weightController.dispose();
    repsController.dispose();
  }
}

class _EditableExercise {
  _EditableExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.sets,
  });

  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final List<_EditableSet> sets;
}

class _EditWorkoutSheetState extends ConsumerState<EditWorkoutSheet> {
  late final TextEditingController _nameController;
  final List<_EditableExercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout.name);
    for (final ex in widget.workout.exercises) {
      final editableSets = ex.sets
          .map(
            (s) => _EditableSet(
              weight: s.weightKg,
              reps: s.reps,
              isWarmup: s.isWarmup,
              isPr: s.isPr,
            ),
          )
          .toList();
      _exercises.add(
        _EditableExercise(
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
          muscleGroup: ex.muscleGroup,
          sets: editableSets,
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

  void _saveChanges() {
    HapticFeedback.mediumImpact();
    final updatedExercises = <WorkoutExercise>[];

    for (final ex in _exercises) {
      final updatedSets = <WorkoutSet>[];
      for (final s in ex.sets) {
        final w = double.tryParse(s.weightController.text) ?? 0.0;
        final r = int.tryParse(s.repsController.text) ?? 0;
        if (r > 0) {
          updatedSets.add(
            WorkoutSet(
              weightKg: w,
              reps: r,
              isWarmup: s.isWarmup,
              isPr: s.isPr,
            ),
          );
        }
      }
      if (updatedSets.isNotEmpty) {
        updatedExercises.add(
          WorkoutExercise(
            exerciseId: ex.exerciseId,
            exerciseName: ex.exerciseName,
            muscleGroup: ex.muscleGroup,
            sets: updatedSets,
          ),
        );
      }
    }

    var totalVolume = 0.0;
    for (final ex in updatedExercises) {
      for (final s in ex.sets) {
        if (!s.isWarmup) {
          totalVolume += s.weightKg * s.reps;
        }
      }
    }

    final updatedWorkout = widget.workout.copyWith(
      name: _nameController.text.trim().isEmpty
          ? widget.workout.name
          : _nameController.text.trim(),
      exercises: updatedExercises,
      totalVolumeKg: totalVolume,
    );

    ref.read(historyWorkoutsProvider.notifier).updateWorkout(updatedWorkout);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Workout log updated successfully.',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 12.0,
            color: AppColors.pureWhite,
          ),
        ),
        backgroundColor: AppColors.charcoal,
        duration: Duration(seconds: 2),
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
            fontFamily: 'JetBrains Mono',
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
                fontFamily: 'JetBrains Mono',
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
                fontFamily: 'JetBrains Mono',
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(historyWorkoutsProvider.notifier).deleteWorkout(widget.workout.id);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Workout removed from history.',
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 12.0,
              color: AppColors.pureWhite,
            ),
          ),
          backgroundColor: AppColors.charcoal,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.onyx,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.steel, width: 1.0),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.steel.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF00E5FF),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EDIT WORKOUT LOG',
                    style: AppTypography.headlineSmall.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Workout Name Input
          TextField(
            controller: _nameController,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: AppColors.pureWhite,
            ),
            decoration: InputDecoration(
              labelText: 'WORKOUT NAME',
              labelStyle: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11.0,
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
              filled: true,
              fillColor: AppColors.charcoal,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.steel),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.steel.withValues(alpha: 0.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00E5FF)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Exercises List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.steel.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ex.muscleGroup.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Set column headers
                      Row(
                        children: const [
                          SizedBox(
                            width: 32,
                            child: Text(
                              'SET',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'KG',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
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
                                fontFamily: 'JetBrains Mono',
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
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.platinum,
                                  ),
                                ),
                              ),
                              // Weight field
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: ex.sets[sIdx].weightController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 12.0,
                                      color: AppColors.pureWhite,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      filled: true,
                                      fillColor: AppColors.onyx,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                            color: AppColors.steel.withValues(alpha: 0.5)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Reps field
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: ex.sets[sIdx].repsController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 12.0,
                                      color: AppColors.pureWhite,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      filled: true,
                                      fillColor: AppColors.onyx,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                            color: AppColors.steel.withValues(alpha: 0.5)),
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
                                    ex.sets[sIdx].isWarmup = !ex.sets[sIdx].isWarmup;
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

                      // Add set button
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              final lastWeight = ex.sets.isNotEmpty
                                  ? double.tryParse(ex.sets.last.weightController.text) ?? 60.0
                                  : 60.0;
                              final lastReps = ex.sets.isNotEmpty
                                  ? int.tryParse(ex.sets.last.repsController.text) ?? 10
                                  : 10;
                              ex.sets.add(
                                _EditableSet(
                                  weight: lastWeight,
                                  reps: lastReps,
                                  isWarmup: false,
                                  isPr: false,
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.add, size: 14, color: Color(0xFF00E5FF)),
                          label: const Text(
                            'ADD SET',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00E5FF),
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
          ),

          const SizedBox(height: 12),

          // Action buttons: Delete vs Save
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'DELETE',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: AppColors.onyx,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
