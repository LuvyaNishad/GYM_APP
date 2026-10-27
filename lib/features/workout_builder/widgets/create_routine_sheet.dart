import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../workout_session/widgets/exercise_picker_modal.dart';
import '../models/split_model.dart';
import '../providers/routine_draft_provider.dart';
import '../providers/splits_provider.dart';

void showCreateRoutineSheet(
  BuildContext context, {
  TrainingSplitModel? initialSplit,
  String? initialDayId,
}) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => CreateRoutineSheet(
        initialSplit: initialSplit,
        initialDayId: initialDayId,
      ),
    ),
  );
}

class CreateRoutineSheet extends ConsumerStatefulWidget {
  const CreateRoutineSheet({super.key, this.initialSplit, this.initialDayId});
  final TrainingSplitModel? initialSplit;
  final String? initialDayId;
  @override
  ConsumerState<CreateRoutineSheet> createState() => _CreateRoutineSheetState();
}

class _CreateRoutineSheetState extends ConsumerState<CreateRoutineSheet> {
  late final _provider =
      NotifierProvider.autoDispose<RoutineDraftNotifier, TrainingSplitModel>(
        () => RoutineDraftNotifier(widget.initialSplit),
      );
  late final TextEditingController _name;
  String? _expanded, _error;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final draft = ref.read(_provider);
    _name = TextEditingController(text: draft.name);
    _expanded = widget.initialDayId ?? draft.workouts.first.id;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give your routine a name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final split = ref.read(_provider.notifier).snapshot();
    if (split.workouts.every((d) => d.isRestDay)) {
      setState(() {
        _saving = false;
        _error = 'Include at least one training day.';
      });
      return;
    }
    try {
      await ref.read(splitsProvider.notifier).saveCustomSplit(split);
      if (!mounted) return;
      final notifier = ref.read(splitsProvider.notifier);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Saved ${split.name}'),
          action: SnackBarAction(
            label: 'Make active',
            onPressed: () => notifier.switchActiveSplit(split.id),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Your draft is still here. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Cancel editing',
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(
            widget.initialSplit == null ? 'CREATE ROUTINE' : 'EDIT ROUTINE',
            style: AppTypography.headlineSmall,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            TextField(
              controller: _name,
              enabled: !_saving,
              onChanged: notifier.rename,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Routine name'),
            ),
            const SizedBox(height: 12),
            Text('Weekly training target', style: AppTypography.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Choose your training frequency. Follow the days below in order, on the days that work for you.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var count = 1; count <= 7; count++)
                  ChoiceChip(
                    label: Text('$count day${count == 1 ? '' : 's'}'),
                    selected: draft.daysPerWeek == count,
                    onSelected: _saving
                        ? null
                        : (_) => notifier.setWeeklyDays(count),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < draft.workouts.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _day(draft.workouts[i], i, notifier),
              ),
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () {
                      notifier.addDay();
                      setState(
                        () => _expanded = ref.read(_provider).workouts.last.id,
                      );
                    },
              icon: const Icon(Icons.add_rounded),
              label: const Text('ADD WORKOUT DAY'),
            ),
            const SizedBox(height: 12),
            Text(
              'New days start empty. To start with exercises, customize a template from the Routine Library.',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(_saving ? 'SAVING…' : 'SAVE ROUTINE'),
                ),
                const SizedBox(height: 6),
                Text(
                  'Saved to your library. Make it active when you are ready.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _day(SplitWorkoutDay day, int index, RoutineDraftNotifier notifier) {
    final expanded = _expanded == day.id;
    final muscleTotals = <String, int>{};
    for (final ex in day.exercises) {
      muscleTotals[ex.muscleGroup] =
          (muscleTotals[ex.muscleGroup] ?? 0) + ex.targetSets;
    }
    final highVolume = muscleTotals.entries
        .where((e) => e.value > 8)
        .map((e) => '${e.value} ${e.key.toLowerCase()} sets')
        .join(', ');
    return GlassCard(
      border: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = expanded ? null : day.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day.name, style: AppTypography.headlineSmall),
                        const SizedBox(height: 6),
                        Text(
                          day.isRestDay
                              ? 'Recovery day'
                              : '${day.exercises.length} exercises · ${day.totalSets} sets · ~${day.estimatedDurationMinutes} min',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('name_${day.id}'),
              initialValue: day.name,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Day name'),
              onChanged: (name) => notifier.updateDay(day.copyWith(name: name)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recovery day'),
              value: day.isRestDay,
              onChanged: _saving
                  ? null
                  : (value) =>
                        notifier.updateDay(day.copyWith(isRestDay: value)),
            ),
            if (!day.isRestDay) ...[
              if (highVolume.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '$highVolume in one session. Review overlap and recovery when adding more.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              if (day.exercises.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Add exercises to build this workout.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: day.exercises.length,
                onReorderItem: (oldIndex, newIndex) {
                  final list = [...day.exercises];
                  list.insert(newIndex, list.removeAt(oldIndex));
                  notifier.setExercises(day.id, list);
                },
                itemBuilder: (_, i) {
                  final ex = day.exercises[i];
                  return ListTile(
                    key: ValueKey('${day.id}_$i'),
                    contentPadding: EdgeInsets.zero,
                    leading: ReorderableDragStartListener(
                      index: i,
                      child: const SizedBox(
                        width: 32,
                        height: 48,
                        child: Icon(Icons.drag_indicator_rounded, size: 20),
                      ),
                    ),
                    title: Text(
                      ex.exerciseName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.pureWhite,
                      ),
                    ),
                    subtitle: Text(
                      '${ex.targetSets} sets × ${ex.repRange} reps · ${ex.restSeconds}s rest',
                    ),
                    trailing: const Icon(Icons.edit_outlined, size: 19),
                    onTap: _saving
                        ? null
                        : () async {
                            final edited =
                                await showModalBottomSheet<PlannedExercise>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _ExerciseEditor(
                                    exercise: ex,
                                    onRemove: () {
                                      final list = [...day.exercises]
                                        ..removeAt(i);
                                      notifier.setExercises(day.id, list);
                                    },
                                  ),
                                );
                            if (edited != null) {
                              final list = [
                                ...ref
                                    .read(_provider)
                                    .workouts
                                    .firstWhere((d) => d.id == day.id)
                                    .exercises,
                              ];
                              list[i] = edited;
                              notifier.setExercises(day.id, list);
                            }
                          },
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ExercisePickerModal(
                          multiSelect: true,
                          onExerciseSelected: (selected) {
                            final current = ref
                                .read(_provider)
                                .workouts
                                .firstWhere((d) => d.id == day.id);
                            notifier.setExercises(day.id, [
                              ...current.exercises,
                              PlannedExercise(
                                exerciseId: selected.exerciseId,
                                exerciseName: selected.name,
                                muscleGroup: selected.muscleGroup,
                                equipment: selected.equipment,
                                targetWeightKg: 0,
                                restSeconds: selected.restDurationSeconds,
                                isUnilateral: selected.isUnilateral,
                              ),
                            ]);
                          },
                        ),
                      ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('ADD EXERCISES'),
              ),
            ],
            if (ref.read(_provider).workouts.length > 1)
              TextButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final yes = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove this day?'),
                            content: const Text(
                              'This removes the day from this draft. Save the routine to keep the change.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                        if (yes == true) notifier.removeDay(day.id);
                      },
                child: const Text('Remove day'),
              ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseEditor extends StatefulWidget {
  const _ExerciseEditor({required this.exercise, required this.onRemove});
  final PlannedExercise exercise;
  final VoidCallback onRemove;
  @override
  State<_ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<_ExerciseEditor> {
  final _form = GlobalKey<FormState>();
  late int _sets = widget.exercise.targetSets;
  late final _reps = TextEditingController(text: widget.exercise.repRange);
  late final _weight = TextEditingController(
    text: widget.exercise.targetWeightKg.toString(),
  );
  late final _rest = TextEditingController(
    text: widget.exercise.restSeconds.toString(),
  );
  late double _rir = widget.exercise.targetRir;
  late bool _unilateral = widget.exercise.isUnilateral;
  @override
  void dispose() {
    _reps.dispose();
    _weight.dispose();
    _rest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppSheet(
    title: widget.exercise.exerciseName,
    children: [
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Working sets', style: AppTypography.bodyMedium),
                ),
                IconButton(
                  tooltip: 'Fewer sets',
                  onPressed: _sets > 1 ? () => setState(() => _sets--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_sets', style: AppTypography.monoMedium),
                IconButton(
                  tooltip: 'More sets',
                  onPressed: _sets < 20 ? () => setState(() => _sets++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reps,
              decoration: const InputDecoration(
                labelText: 'Reps or rep range',
                helperText: 'Examples: 5, 6–8, 10–15',
              ),
              validator: (value) {
                final match = RegExp(
                  r'^(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?$',
                ).firstMatch(value?.trim() ?? '');
                if (match == null) return 'Enter reps or a range such as 8–12.';
                final lo = int.parse(match[1]!);
                final hi = int.parse(match[2] ?? match[1]!);
                return lo < 1 || hi < lo || hi > 100
                    ? 'Use an ordered range from 1 to 100 reps.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Starting weight (kg)',
                helperText: '0 for bodyweight or to choose during the session',
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                return n == null || !n.isFinite || n < 0 || n > 1500
                    ? 'Enter 0–1500 kg.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rest,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rest between sets (seconds)',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 0 || n > 900
                    ? 'Enter 0–900 seconds.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Target effort: ${_rir.toStringAsFixed(1)} reps in reserve',
              style: AppTypography.bodyMedium,
            ),
            Slider(
              value: _rir,
              min: 0,
              max: 5,
              divisions: 10,
              label: _rir.toStringAsFixed(1),
              onChanged: (v) => setState(() => _rir = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Log left and right separately'),
              value: _unilateral,
              onChanged: (v) => setState(() => _unilateral = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  widget.exercise.copyWith(
                    targetSets: _sets,
                    repRange: _reps.text.trim().replaceAll('-', '–'),
                    targetWeightKg: double.parse(_weight.text),
                    restSeconds: int.parse(_rest.text),
                    targetRir: _rir,
                    isUnilateral: _unilateral,
                  ),
                );
              },
              child: const Text('APPLY CHANGES'),
            ),
            TextButton(
              onPressed: () {
                widget.onRemove();
                Navigator.pop(context);
              },
              child: const Text('Remove exercise'),
            ),
          ],
        ),
      ),
    ],
  );
}
