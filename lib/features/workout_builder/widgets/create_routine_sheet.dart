import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../workout_session/widgets/exercise_picker_modal.dart';
import '../models/split_model.dart';
import '../providers/splits_provider.dart';

/// Convenience helper to open the routine builder/editor modal sheet.
void showCreateRoutineSheet(BuildContext context, {TrainingSplitModel? initialSplit}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CreateRoutineSheet(initialSplit: initialSplit),
  );
}

/// Draft models for routine customization to maintain stable keys and direct item mutation during reordering.
class _ExerciseDraft {
  _ExerciseDraft({
    required this.uid,
    required this.exercise,
  });

  final String uid;
  PlannedExercise exercise;
}

class _DayDraft {
  _DayDraft({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.targetMuscles,
    required this.exercises,
    this.isRestDay = false,
  });

  final String id;
  String name;
  String subtitle;
  List<String> targetMuscles;
  final List<_ExerciseDraft> exercises;
  bool isRestDay;

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.exercise.targetSets);
}

/// Modal Sheet for creating or editing a custom training split template with interactive exercise management.
class CreateRoutineSheet extends ConsumerStatefulWidget {
  const CreateRoutineSheet({super.key, this.initialSplit});

  final TrainingSplitModel? initialSplit;

  @override
  ConsumerState<CreateRoutineSheet> createState() => _CreateRoutineSheetState();
}

class _CreateRoutineSheetState extends ConsumerState<CreateRoutineSheet> {
  late final TextEditingController _nameController;
  late int _daysPerWeek;
  late List<_DayDraft> _workouts;
  late bool _setAsActive;
  int _draftCounter = 0;

  String _nextDraftUid() => 'draft_ex_${++_draftCounter}_${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    final init = widget.initialSplit;
    if (init != null) {
      _nameController = TextEditingController(
        text: init.isCustom ? init.name : '${init.name} (Custom)',
      );
      _daysPerWeek = init.daysPerWeek;
      _workouts = init.workouts.map((w) {
        return _DayDraft(
          id: w.id,
          name: w.name,
          subtitle: w.subtitle,
          targetMuscles: List<String>.from(w.targetMuscles),
          isRestDay: w.isRestDay,
          exercises: w.exercises.map((e) => _ExerciseDraft(
            uid: _nextDraftUid(),
            exercise: e.copyWith(),
          )).toList(),
        );
      }).toList();
      final activeSplitId = ref.read(splitsProvider).activeSplitId;
      _setAsActive = (activeSplitId == init.id || !init.isCustom);
    } else {
      _nameController = TextEditingController(text: 'My Custom Split');
      _daysPerWeek = 4;
      _workouts = _generateDefaultDays(_daysPerWeek);
      _setAsActive = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<_DayDraft> _generateDefaultDays(int days) {
    final list = <_DayDraft>[];
    for (int i = 1; i <= days; i++) {
      list.add(
        _DayDraft(
          id: 'day_$i',
          name: 'Workout Day $i',
          subtitle: 'Target Muscles',
          targetMuscles: ['Chest', 'Back'],
          exercises: [
            _ExerciseDraft(
              uid: _nextDraftUid(),
              exercise: const PlannedExercise(
                exerciseId: 'barbell-bench-press',
                exerciseName: 'Barbell Bench Press',
                muscleGroup: 'Chest',
                targetSets: 3,
                repRange: '8–12',
              ),
            ),
            _ExerciseDraft(
              uid: _nextDraftUid(),
              exercise: const PlannedExercise(
                exerciseId: 'barbell-bent-over-row',
                exerciseName: 'Barbell Bent-Over Row',
                muscleGroup: 'Back',
                targetSets: 3,
                repRange: '8–12',
              ),
            ),
          ],
        ),
      );
    }
    return list;
  }

  void _showRenameDayDialog(int dayIdx) {
    final day = _workouts[dayIdx];
    final nameController = TextEditingController(text: day.name);
    final subtitleController = TextEditingController(text: day.subtitle);
    bool isRest = day.isRestDay;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.charcoal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.steel, width: 1),
            ),
            title: Text(
              'EDIT WORKOUT DAY',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.pureWhite,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAY NAME',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.platinum,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.pureWhite, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'e.g. Push Day, Heavy Legs',
                      hintStyle: const TextStyle(color: AppColors.steel, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.onyx,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.steel),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Quick suggestion chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'Push Day',
                      'Pull Day',
                      'Leg Day',
                      'Upper Body',
                      'Lower Body',
                      'Full Body',
                    ].map((s) {
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            nameController.text = s;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.steel.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 11.0,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'SUBTITLE / FOCUS',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.platinum,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: subtitleController,
                    style: const TextStyle(color: AppColors.pureWhite, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'e.g. Chest & Triceps',
                      hintStyle: const TextStyle(color: AppColors.steel, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.onyx,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.steel),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Rest day toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mark as Rest Day',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.0,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      Switch.adaptive(
                        value: isRest,
                        activeThumbColor: AppColors.pureWhite,
                        activeTrackColor: AppColors.primary,
                        inactiveThumbColor: AppColors.platinum,
                        inactiveTrackColor: AppColors.onyx,
                        onChanged: (val) {
                          setDialogState(() {
                            isRest = val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(
                  'CANCEL',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.platinum,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () {
                  final trimmedName = nameController.text.trim();
                  final trimmedSub = subtitleController.text.trim();
                  if (trimmedName.isNotEmpty) {
                    setState(() {
                      day.name = trimmedName;
                      day.subtitle = trimmedSub;
                      day.isRestDay = isRest;
                    });
                  }
                  Navigator.of(dialogCtx).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.pureWhite,
                  foregroundColor: AppColors.onyx,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(80, 36),
                ),
                child: Text(
                  'SAVE',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onyx,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addExerciseToDay(int dayIdx) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExercisePickerModal(
        onExerciseSelected: (selected) {
          setState(() {
            final cleanId = 'ex_${selected.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
            _workouts[dayIdx].exercises.add(
              _ExerciseDraft(
                uid: _nextDraftUid(),
                exercise: PlannedExercise(
                  exerciseId: cleanId,
                  exerciseName: selected.name,
                  muscleGroup: selected.muscleGroup,
                  equipment: selected.equipment,
                  targetSets: 3,
                  repRange: '8–12',
                  targetWeightKg: selected.sets.isNotEmpty ? selected.sets.first.weightKg : 50.0,
                  restSeconds: selected.restDurationSeconds,
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Future<void> _saveRoutine() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final muscleSets = <String, int>{
      'Chest': 0,
      'Back': 0,
      'Shoulders': 0,
      'Quads': 0,
      'Hamstrings': 0,
      'Arms': 0,
    };
    for (final w in _workouts) {
      if (w.isRestDay) continue;
      for (final draft in w.exercises) {
        final ex = draft.exercise;
        final m = ex.muscleGroup;
        if (muscleSets.containsKey(m)) {
          muscleSets[m] = (muscleSets[m] ?? 0) + ex.targetSets;
        } else {
          muscleSets[m] = ex.targetSets;
        }
      }
    }

    final isNew = widget.initialSplit == null;
    final isOriginalPreset = widget.initialSplit != null && !widget.initialSplit!.isCustom;
    final id = (isNew || isOriginalPreset)
        ? 'custom_split_${DateTime.now().millisecondsSinceEpoch}'
        : widget.initialSplit!.id;

    final finalWorkouts = _workouts.map((d) {
      return SplitWorkoutDay(
        id: d.id,
        name: d.name,
        subtitle: d.subtitle,
        targetMuscles: d.targetMuscles,
        isRestDay: d.isRestDay,
        exercises: d.exercises.map((e) => e.exercise).toList(),
      );
    }).toList();

    final updatedSplit = TrainingSplitModel(
      id: id,
      name: name,
      shortName: name.length > 5 ? name.substring(0, 5).toUpperCase() : name.toUpperCase(),
      daysPerWeek: finalWorkouts.where((w) => !w.isRestDay).length,
      description: widget.initialSplit?.description ??
          'Custom routine with ${finalWorkouts.where((w) => !w.isRestDay).length} training days per week.',
      isCustom: true,
      workouts: finalWorkouts,
      plannedMuscleSets: muscleSets,
    );

    await ref.read(splitsProvider.notifier).saveCustomSplit(updatedSplit);

    if (_setAsActive) {
      ref.read(splitsProvider.notifier).switchActiveSplit(id);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.steel, width: 1),
          ),
          content: Text(
            _setAsActive
                ? 'Saved "$name" and set as your active split!'
                : 'Saved "$name" to Routine Library.',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.pureWhite,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialSplit != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Grabber
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.steel,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? 'EDIT ROUTINE' : 'CREATE CUSTOM ROUTINE',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customize workout days, add personal exercises, and adjust sets and rep ranges.',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12.0,
                        color: AppColors.platinum,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Routine Name input
                    Text(
                      'ROUTINE NAME',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11.5,
                        color: AppColors.platinum,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.pureWhite, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.steel),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Days per week picker
                    Text(
                      'TRAINING DAYS PER WEEK',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11.5,
                        color: AppColors.platinum,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [3, 4, 5, 6].map((days) {
                        final isSelected = _daysPerWeek == days;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _daysPerWeek = days;
                                  if (!isEditing) {
                                    _workouts = _generateDefaultDays(days);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.steel,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$days DAYS',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? AppColors.onyx : AppColors.pureWhite,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: AppColors.steel),
                    const SizedBox(height: 12),

                    // Workout Days list
                    Text(
                      'WORKOUT DAYS & EXERCISES',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11.5,
                        color: AppColors.platinum,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ..._workouts.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final day = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.onyx,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.steel.withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day Header
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: day.isRestDay ? AppColors.platinum : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _showRenameDayDialog(idx),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  day.name,
                                                  style: AppTypography.bodySmall.copyWith(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.pureWhite,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (day.subtitle.isNotEmpty)
                                                  Text(
                                                    day.subtitle,
                                                    style: const TextStyle(
                                                      fontSize: 11.0,
                                                      color: AppColors.platinum,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                            color: AppColors.platinum,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  day.isRestDay ? 'Rest Day' : '${day.exercises.length} Ex · ${day.totalSets} Sets',
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 11.0,
                                    color: AppColors.platinum,
                                  ),
                                ),
                                if (_workouts.length > 1) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.platinum),
                                    tooltip: 'Remove Day',
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      setState(() {
                                        _workouts.removeAt(idx);
                                      });
                                    },
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Exercises list
                            if (day.exercises.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  day.isRestDay
                                      ? 'Rest and recovery day.'
                                      : 'No exercises added yet. Tap below to add your exercises.',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11.5,
                                    color: AppColors.platinum.withValues(alpha: 0.8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            else
                              ReorderableListView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                buildDefaultDragHandles: false,
                                proxyDecorator: (child, index, animation) {
                                  return Material(
                                    color: Colors.transparent,
                                    elevation: 6,
                                    shadowColor: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                    child: child,
                                  );
                                },
                                onReorderItem: (oldIndex, newIndex) {
                                  setState(() {
                                    final item = day.exercises.removeAt(oldIndex);
                                    day.exercises.insert(newIndex, item);
                                  });
                                },
                                children: [
                                  for (int eIdx = 0; eIdx < day.exercises.length; eIdx++)
                                    Container(
                                      key: ValueKey(day.exercises[eIdx].uid),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.charcoal,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.steel.withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        children: [
                                          ReorderableDragStartListener(
                                            index: eIdx,
                                            child: Container(
                                              padding: const EdgeInsets.fromLTRB(2, 6, 8, 6),
                                              color: Colors.transparent,
                                              child: const Icon(
                                                Icons.drag_indicator_rounded,
                                                size: 20,
                                                color: AppColors.platinum,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  day.exercises[eIdx].exercise.exerciseName,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.pureWhite,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${day.exercises[eIdx].exercise.muscleGroup} · ${day.exercises[eIdx].exercise.equipment}',
                                                  style: const TextStyle(
                                                    fontSize: 11.0,
                                                    color: AppColors.platinum,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Sets Decrement
                                          InkWell(
                                            onTap: () {
                                              if (day.exercises[eIdx].exercise.targetSets > 1) {
                                                setState(() {
                                                  day.exercises[eIdx].exercise = day.exercises[eIdx].exercise.copyWith(
                                                    targetSets: day.exercises[eIdx].exercise.targetSets - 1,
                                                  );
                                                });
                                              }
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(Icons.remove_circle_outline_rounded,
                                                  size: 16, color: AppColors.platinum),
                                            ),
                                          ),
                                          Text(
                                            '${day.exercises[eIdx].exercise.targetSets}s',
                                            style: const TextStyle(
                                              fontFamily: 'JetBrains Mono',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.pureWhite,
                                            ),
                                          ),
                                          // Sets Increment
                                          InkWell(
                                            onTap: () {
                                              if (day.exercises[eIdx].exercise.targetSets < 10) {
                                                setState(() {
                                                  day.exercises[eIdx].exercise = day.exercises[eIdx].exercise.copyWith(
                                                    targetSets: day.exercises[eIdx].exercise.targetSets + 1,
                                                  );
                                                });
                                              }
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(Icons.add_circle_outline_rounded,
                                                  size: 16, color: AppColors.platinum),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Rep range chip (cycles on tap)
                                          InkWell(
                                            onTap: () {
                                              final ranges = ['6–8', '8–12', '10–15', '12–20'];
                                              final curr = day.exercises[eIdx].exercise.repRange;
                                              final nextIdx = (ranges.indexOf(curr) + 1) % ranges.length;
                                              setState(() {
                                                day.exercises[eIdx].exercise =
                                                    day.exercises[eIdx].exercise.copyWith(repRange: ranges[nextIdx]);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.steel.withValues(alpha: 0.6)),
                                              ),
                                              child: Text(
                                                day.exercises[eIdx].exercise.repRange,
                                                style: const TextStyle(
                                                  fontFamily: 'JetBrains Mono',
                                                  fontSize: 11.0,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.platinum,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          // Delete Exercise Button
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded,
                                                size: 16, color: AppColors.warning),
                                            tooltip: 'Remove Exercise',
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              setState(() {
                                                day.exercises.removeAt(eIdx);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),

                            const SizedBox(height: 6),
                            // Add Exercise Button for this Day
                            OutlinedButton.icon(
                              onPressed: () => _addExerciseToDay(idx),
                              icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                              label: Text(
                                'ADD EXERCISE',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppColors.primary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                minimumSize: const Size(double.infinity, 36),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Add Workout Day Button
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          final nextNum = _workouts.length + 1;
                          _workouts.add(
                            _DayDraft(
                              id: 'day_${DateTime.now().millisecondsSinceEpoch}',
                              name: 'Workout Day $nextNum',
                              subtitle: 'Target Muscles',
                              targetMuscles: ['Chest', 'Arms'],
                              exercises: [],
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.platinum),
                      label: Text(
                        'ADD WORKOUT DAY',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.platinum,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.steel),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Sticky bottom action bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                decoration: const BoxDecoration(
                  color: AppColors.charcoal,
                  border: Border(top: BorderSide(color: AppColors.steel)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Set as active routine switch row
                    InkWell(
                      onTap: () {
                        setState(() {
                          _setAsActive = !_setAsActive;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SET AS ACTIVE ROUTINE',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: AppColors.pureWhite,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Apply immediately to Home dashboard',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11.0,
                                      color: AppColors.platinum,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _setAsActive,
                              activeThumbColor: AppColors.pureWhite,
                              activeTrackColor: AppColors.primary,
                              inactiveThumbColor: AppColors.platinum,
                              inactiveTrackColor: AppColors.onyx,
                              onChanged: (val) {
                                setState(() {
                                  _setAsActive = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _saveRoutine,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.pureWhite,
                        foregroundColor: AppColors.onyx,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'SAVE ROUTINE',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.onyx,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
