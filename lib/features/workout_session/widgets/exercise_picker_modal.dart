import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../exercise_library/providers/exercise_library_provider.dart';
import '../models/active_session_state.dart';
import '../../exercise_library/models/exercise_library_item.dart';
import '../../history/providers/history_provider.dart';
import '../providers/exercise_favorites_provider.dart';

class ExerciseTemplate {
  const ExerciseTemplate({
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    this.defaultRestSeconds = 90,
  });

  final String name;
  final String muscleGroup;
  final String equipment;
  final int defaultRestSeconds;

  bool get isUnilateral =>
      name.toLowerCase().contains('single-arm') ||
      name.toLowerCase().contains('single arm') ||
      name.toLowerCase().contains('single-leg') ||
      name.toLowerCase().contains('single leg') ||
      name.toLowerCase().contains('one-arm') ||
      name.toLowerCase().contains('one arm') ||
      name.toLowerCase().contains('lateral raise') ||
      name.toLowerCase().contains('split squat') ||
      name.toLowerCase().contains('lunge');
}

const List<ExerciseTemplate> kExerciseCatalog = [
  // Chest
  ExerciseTemplate(
    name: 'Barbell Bench Press',
    muscleGroup: 'Chest',
    equipment: 'barbell',
    defaultRestSeconds: 180,
  ),
  ExerciseTemplate(
    name: 'Incline Dumbbell Press',
    muscleGroup: 'Chest',
    equipment: 'dumbbell',
    defaultRestSeconds: 120,
  ),
  ExerciseTemplate(
    name: 'Machine Chest Press',
    muscleGroup: 'Chest',
    equipment: 'machine',
    defaultRestSeconds: 120,
  ),
  ExerciseTemplate(
    name: 'Machine Chest Fly',
    muscleGroup: 'Chest',
    equipment: 'machine',
    defaultRestSeconds: 60,
  ),
  ExerciseTemplate(
    name: 'Dips (Chest Focus)',
    muscleGroup: 'Chest',
    equipment: 'bodyweight',
    defaultRestSeconds: 120,
  ),
  ExerciseTemplate(
    name: 'Cable Chest Fly',
    muscleGroup: 'Chest',
    equipment: 'cable',
    defaultRestSeconds: 60,
  ),
  ExerciseTemplate(
    name: 'Push-Ups',
    muscleGroup: 'Chest',
    equipment: 'bodyweight',
    defaultRestSeconds: 60,
  ),
  // Back
  ExerciseTemplate(
    name: 'Barbell Deadlift',
    muscleGroup: 'Back',
    equipment: 'barbell',
    defaultRestSeconds: 180,
  ),
  ExerciseTemplate(
    name: 'Barbell Bent-Over Row',
    muscleGroup: 'Back',
    equipment: 'barbell',
    defaultRestSeconds: 120,
  ),
  ExerciseTemplate(
    name: 'Pull-Ups',
    muscleGroup: 'Back',
    equipment: 'bodyweight',
    defaultRestSeconds: 120,
  ),
  ExerciseTemplate(
    name: 'Lat Pulldown',
    muscleGroup: 'Back',
    equipment: 'cable',
    defaultRestSeconds: 120,
  ),
  ExerciseTemplate(
    name: 'Seated Cable Row',
    muscleGroup: 'Back',
    equipment: 'cable',
    defaultRestSeconds: 120,
  ),
  ExerciseTemplate(
    name: 'Single-Arm Dumbbell Row',
    muscleGroup: 'Back',
    equipment: 'dumbbell',
    defaultRestSeconds: 90,
  ),
  // Shoulders
  ExerciseTemplate(
    name: 'Standing Overhead Press',
    muscleGroup: 'Shoulders',
    equipment: 'barbell',
    defaultRestSeconds: 180,
  ),
  ExerciseTemplate(
    name: 'Machine Shoulder Press',
    muscleGroup: 'Shoulders',
    equipment: 'machine',
    defaultRestSeconds: 120,
  ),
  ExerciseTemplate(
    name: 'Dumbbell Shoulder Press',
    muscleGroup: 'Shoulders',
    equipment: 'dumbbell',
    defaultRestSeconds: 120,
  ),
  ExerciseTemplate(
    name: 'Machine Rear Delt Fly',
    muscleGroup: 'Shoulders',
    equipment: 'machine',
    defaultRestSeconds: 60,
  ),
  ExerciseTemplate(
    name: 'Cable Lateral Raise',
    muscleGroup: 'Shoulders',
    equipment: 'cable',
    defaultRestSeconds: 60,
  ),
  ExerciseTemplate(
    name: 'Dumbbell Lateral Raise',
    muscleGroup: 'Shoulders',
    equipment: 'dumbbell',
    defaultRestSeconds: 60,
  ),
  ExerciseTemplate(
    name: 'Face Pull',
    muscleGroup: 'Shoulders',
    equipment: 'cable',
    defaultRestSeconds: 60,
  ),
  // Arms
  ExerciseTemplate(
    name: 'Barbell Bicep Curl',
    muscleGroup: 'Arms',
    equipment: 'barbell',
    defaultRestSeconds: 90,
  ),
  ExerciseTemplate(
    name: 'Incline Dumbbell Curl',
    muscleGroup: 'Arms',
    equipment: 'dumbbell',
    defaultRestSeconds: 90,
  ),
  ExerciseTemplate(
    name: 'Tricep Rope Pushdown',
    muscleGroup: 'Arms',
    equipment: 'cable',
    defaultRestSeconds: 60,
  ),
  ExerciseTemplate(
    name: 'Skull Crushers',
    muscleGroup: 'Arms',
    equipment: 'barbell',
    defaultRestSeconds: 90,
  ),
  ExerciseTemplate(
    name: 'Hammer Curl',
    muscleGroup: 'Arms',
    equipment: 'dumbbell',
    defaultRestSeconds: 90,
  ),
  // Legs
  ExerciseTemplate(
    name: 'Barbell Back Squat',
    muscleGroup: 'Legs',
    equipment: 'barbell',
    defaultRestSeconds: 180,
  ),
  ExerciseTemplate(
    name: 'Romanian Deadlift (RDL)',
    muscleGroup: 'Legs',
    equipment: 'barbell',
    defaultRestSeconds: 120,
  ),
  ExerciseTemplate(
    name: 'Leg Press',
    muscleGroup: 'Legs',
    equipment: 'machine',
    defaultRestSeconds: 120,
  ),
  ExerciseTemplate(
    name: 'Walking Lunges',
    muscleGroup: 'Legs',
    equipment: 'dumbbell',
    defaultRestSeconds: 120,
  ),
  ExerciseTemplate(
    name: 'Leg Extension',
    muscleGroup: 'Legs',
    equipment: 'machine',
    defaultRestSeconds: 60,
  ),
  ExerciseTemplate(
    name: 'Lying Hamstring Curl',
    muscleGroup: 'Legs',
    equipment: 'machine',
    defaultRestSeconds: 60,
  ),
  ExerciseTemplate(
    name: 'Standing Calf Raise',
    muscleGroup: 'Legs',
    equipment: 'machine',
    defaultRestSeconds: 60,
  ),
  // Core
  ExerciseTemplate(
    name: 'Hanging Leg Raise',
    muscleGroup: 'Core',
    equipment: 'bodyweight',
    defaultRestSeconds: 60,
  ),
  ExerciseTemplate(
    name: 'Cable Woodchopper',
    muscleGroup: 'Core',
    equipment: 'cable',
    defaultRestSeconds: 60,
  ),
  ExerciseTemplate(
    name: 'Ab Wheel Rollout',
    muscleGroup: 'Core',
    equipment: 'bodyweight',
    defaultRestSeconds: 60,
  ),
];

/// Search once, select several exercises, then add them together.
class ExercisePickerModal extends ConsumerStatefulWidget {
  const ExercisePickerModal({
    super.key,
    required this.onExerciseSelected,
    this.multiSelect = false,
    this.initialCategory,
  });
  final void Function(ActiveExerciseState exercise) onExerciseSelected;
  final bool multiSelect;
  final String? initialCategory;
  @override
  ConsumerState<ExercisePickerModal> createState() =>
      _ExercisePickerModalState();
}

class _ExercisePickerModalState extends ConsumerState<ExercisePickerModal> {
  late String _category = widget.initialCategory ?? 'All';
  String _equipment = 'All', _query = '', _collection = 'All';
  final Map<String, ExerciseLibraryItem> _selected = {};
  @override
  Widget build(BuildContext context) {
    final library = ref.watch(exerciseLibraryProvider);
    final favorites = ref.watch(exerciseFavoritesProvider);
    final recentNames = ref
        .watch(historyWorkoutsProvider)
        .expand((w) => w.exercises)
        .map((e) => e.exerciseName.toLowerCase())
        .toSet()
        .toList();
    final all = library.allExercises.isNotEmpty
        ? library.allExercises
        : kExerciseCatalog
              .map(
                (e) => ExerciseLibraryItem(
                  id: e.name.toLowerCase().replaceAll(' ', '_'),
                  name: e.name,
                  category: e.muscleGroup,
                  description: '',
                  primaryEquipment: e.equipment,
                  defaultRestSeconds: e.defaultRestSeconds,
                ),
              )
              .toList();
    final categories = [
      'All',
      ...all.map((e) => e.category).toSet().toList()..sort(),
    ];
    final equipment = [
      'All',
      ...all.map((e) => e.primaryEquipment).toSet().toList()..sort(),
    ];
    final filtered = all.where((e) {
      final name = e.name.toLowerCase();
      return (_category == 'All' ||
              e.category.toLowerCase() == _category.toLowerCase()) &&
          (_equipment == 'All' || e.primaryEquipment == _equipment) &&
          (name.contains(_query.toLowerCase()) ||
              e.category.toLowerCase().contains(_query.toLowerCase())) &&
          (_collection != 'Favorites' || favorites.contains(name)) &&
          (_collection != 'Recent' || recentNames.contains(name));
    }).toList();
    if (_collection == 'Recent') {
      filtered.sort(
        (a, b) => recentNames
            .indexOf(a.name.toLowerCase())
            .compareTo(recentNames.indexOf(b.name.toLowerCase())),
      );
    }
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.sizeOf(context).height * .9,
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.onyx,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.multiSelect ? 'ADD EXERCISES' : 'CHOOSE EXERCISE',
                    style: AppTypography.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Close picker',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search exercise or muscle',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'All', label: Text('All')),
                ButtonSegment(value: 'Recent', label: Text('Recent')),
                ButtonSegment(value: 'Favorites', label: Text('Favorites')),
              ],
              selected: {_collection},
              onSelectionChanged: (v) => setState(() => _collection = v.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: categories.contains(_category)
                        ? _category
                        : 'All',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Muscle'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (c) => setState(() => _category = c ?? 'All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _equipment,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Equipment'),
                    items: equipment
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (c) => setState(() => _equipment = c ?? 'All'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _collection == 'Favorites'
                            ? 'Star an exercise to keep it here.'
                            : _collection == 'Recent'
                            ? 'Exercises from completed workouts appear here.'
                            : 'No matches. Try another filter.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final item = filtered[i];
                        final chosen = _selected.containsKey(item.id);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: widget.multiSelect
                              ? Checkbox(
                                  value: chosen,
                                  onChanged: (_) => _toggle(item),
                                )
                              : const Icon(Icons.add_circle_outline_rounded),
                          title: Text(
                            item.name,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.pureWhite,
                            ),
                          ),
                          subtitle: Text(
                            '${item.category} · ${item.primaryEquipment}',
                          ),
                          trailing: IconButton(
                            tooltip: favorites.contains(item.name.toLowerCase())
                                ? 'Remove favorite'
                                : 'Favorite exercise',
                            icon: Icon(
                              favorites.contains(item.name.toLowerCase())
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppColors.platinum,
                            ),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(exerciseFavoritesProvider.notifier)
                                    .toggle(item.name.toLowerCase());
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not save favorite. Try again.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          onTap: () {
                            if (widget.multiSelect) {
                              _toggle(item);
                            } else {
                              widget.onExerciseSelected(
                                item.toActiveExercise(defaultWeightKg: 0),
                              );
                              Navigator.pop(context);
                            }
                          },
                        );
                      },
                    ),
            ),
            if (widget.multiSelect)
              FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () {
                        for (final item in _selected.values) {
                          widget.onExerciseSelected(
                            item.toActiveExercise(defaultWeightKg: 0),
                          );
                        }
                        Navigator.pop(context);
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(
                  _selected.isEmpty
                      ? 'SELECT EXERCISES'
                      : 'ADD ${_selected.length} EXERCISE${_selected.length == 1 ? '' : 'S'}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggle(ExerciseLibraryItem item) => setState(() {
    if (_selected.containsKey(item.id)) {
      _selected.remove(item.id);
    } else {
      _selected[item.id] = item;
    }
  });
}
