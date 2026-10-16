import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../exercise_library/providers/exercise_library_provider.dart';
import '../models/active_session_state.dart';

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
}

const List<ExerciseTemplate> kExerciseCatalog = [
  // Chest
  ExerciseTemplate(name: 'Barbell Bench Press', muscleGroup: 'Chest', equipment: 'barbell', defaultRestSeconds: 180),
  ExerciseTemplate(name: 'Incline Dumbbell Press', muscleGroup: 'Chest', equipment: 'dumbbell', defaultRestSeconds: 120),
  ExerciseTemplate(name: 'Machine Chest Press', muscleGroup: 'Chest', equipment: 'machine', defaultRestSeconds: 120),
  ExerciseTemplate(name: 'Machine Chest Fly', muscleGroup: 'Chest', equipment: 'machine', defaultRestSeconds: 60),
  ExerciseTemplate(name: 'Dips (Chest Focus)', muscleGroup: 'Chest', equipment: 'bodyweight', defaultRestSeconds: 120),
  ExerciseTemplate(name: 'Cable Chest Fly', muscleGroup: 'Chest', equipment: 'cable', defaultRestSeconds: 60),
  ExerciseTemplate(name: 'Push-Ups', muscleGroup: 'Chest', equipment: 'bodyweight', defaultRestSeconds: 60),
  // Back
  ExerciseTemplate(name: 'Barbell Deadlift', muscleGroup: 'Back', equipment: 'barbell', defaultRestSeconds: 180),
  ExerciseTemplate(name: 'Barbell Bent-Over Row', muscleGroup: 'Back', equipment: 'barbell', defaultRestSeconds: 120),
  ExerciseTemplate(name: 'Pull-Ups', muscleGroup: 'Back', equipment: 'bodyweight', defaultRestSeconds: 120),
  ExerciseTemplate(name: 'Lat Pulldown', muscleGroup: 'Back', equipment: 'cable', defaultRestSeconds: 120),
  ExerciseTemplate(name: 'Seated Cable Row', muscleGroup: 'Back', equipment: 'cable', defaultRestSeconds: 120),
  ExerciseTemplate(name: 'Single-Arm Dumbbell Row', muscleGroup: 'Back', equipment: 'dumbbell', defaultRestSeconds: 90),
  // Shoulders
  ExerciseTemplate(name: 'Standing Overhead Press', muscleGroup: 'Shoulders', equipment: 'barbell', defaultRestSeconds: 180),
  ExerciseTemplate(name: 'Machine Shoulder Press', muscleGroup: 'Shoulders', equipment: 'machine', defaultRestSeconds: 120),
  ExerciseTemplate(name: 'Dumbbell Shoulder Press', muscleGroup: 'Shoulders', equipment: 'dumbbell', defaultRestSeconds: 120),
  ExerciseTemplate(name: 'Machine Rear Delt Fly', muscleGroup: 'Shoulders', equipment: 'machine', defaultRestSeconds: 60),
  ExerciseTemplate(name: 'Cable Lateral Raise', muscleGroup: 'Shoulders', equipment: 'cable', defaultRestSeconds: 60),
  ExerciseTemplate(name: 'Dumbbell Lateral Raise', muscleGroup: 'Shoulders', equipment: 'dumbbell', defaultRestSeconds: 60),
  ExerciseTemplate(name: 'Face Pull', muscleGroup: 'Shoulders', equipment: 'cable', defaultRestSeconds: 60),
  // Arms
  ExerciseTemplate(name: 'Barbell Bicep Curl', muscleGroup: 'Arms', equipment: 'barbell', defaultRestSeconds: 90),
  ExerciseTemplate(name: 'Incline Dumbbell Curl', muscleGroup: 'Arms', equipment: 'dumbbell', defaultRestSeconds: 90),
  ExerciseTemplate(name: 'Tricep Rope Pushdown', muscleGroup: 'Arms', equipment: 'cable', defaultRestSeconds: 60),
  ExerciseTemplate(name: 'Skull Crushers', muscleGroup: 'Arms', equipment: 'barbell', defaultRestSeconds: 90),
  ExerciseTemplate(name: 'Hammer Curl', muscleGroup: 'Arms', equipment: 'dumbbell', defaultRestSeconds: 90),
  // Legs
  ExerciseTemplate(name: 'Barbell Back Squat', muscleGroup: 'Legs', equipment: 'barbell', defaultRestSeconds: 180),
  ExerciseTemplate(name: 'Romanian Deadlift (RDL)', muscleGroup: 'Legs', equipment: 'barbell', defaultRestSeconds: 120),
  ExerciseTemplate(name: 'Leg Press', muscleGroup: 'Legs', equipment: 'machine', defaultRestSeconds: 120),
  ExerciseTemplate(name: 'Walking Lunges', muscleGroup: 'Legs', equipment: 'dumbbell', defaultRestSeconds: 120),
  ExerciseTemplate(name: 'Leg Extension', muscleGroup: 'Legs', equipment: 'machine', defaultRestSeconds: 60),
  ExerciseTemplate(name: 'Lying Hamstring Curl', muscleGroup: 'Legs', equipment: 'machine', defaultRestSeconds: 60),
  ExerciseTemplate(name: 'Standing Calf Raise', muscleGroup: 'Legs', equipment: 'machine', defaultRestSeconds: 60),
  // Core
  ExerciseTemplate(name: 'Hanging Leg Raise', muscleGroup: 'Core', equipment: 'bodyweight', defaultRestSeconds: 60),
  ExerciseTemplate(name: 'Cable Woodchopper', muscleGroup: 'Core', equipment: 'cable', defaultRestSeconds: 60),
  ExerciseTemplate(name: 'Ab Wheel Rollout', muscleGroup: 'Core', equipment: 'bodyweight', defaultRestSeconds: 60),
];

/// Modal sheet to search and pick an exercise to add or replace.
class ExercisePickerModal extends ConsumerStatefulWidget {
  const ExercisePickerModal({
    super.key,
    required this.onExerciseSelected,
  });

  final void Function(ActiveExerciseState exercise) onExerciseSelected;

  @override
  ConsumerState<ExercisePickerModal> createState() => _ExercisePickerModalState();
}

class _ExercisePickerModalState extends ConsumerState<ExercisePickerModal> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  final List<String> _categories = [
    'ALL',
    'CHEST',
    'BACK',
    'SHOULDERS',
    'ARMS',
    'LEGS',
    'CORE',
  ];

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(exerciseLibraryProvider);
    final allLibraryExercises = libraryState.allExercises;

    final List<ExerciseTemplate> catalog = allLibraryExercises.isNotEmpty
        ? allLibraryExercises
            .map((e) => ExerciseTemplate(
                  name: e.name,
                  muscleGroup: e.category,
                  equipment: e.primaryEquipment,
                  defaultRestSeconds: e.defaultRestSeconds,
                ))
            .toList()
        : kExerciseCatalog;

    final filtered = catalog.where((e) {
      final matchesCategory = _selectedCategory == 'ALL' ||
          e.muscleGroup.toUpperCase() == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.muscleGroup.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.onyx,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.steel)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.steel,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXERCISE LIBRARY',
                style: AppTypography.headlineSmall.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.pureWhite,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.platinum, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search exercise or muscle...',
              hintStyle: const TextStyle(color: AppColors.platinum, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.platinum, size: 20),
              filled: true,
              fillColor: AppColors.charcoal,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.steel),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.steel),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.pureWhite),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final cat in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                      labelStyle: AppTypography.monoSmall.copyWith(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: _selectedCategory == cat ? AppColors.onPrimary : AppColors.platinum,
                      ),
                      selectedColor: AppColors.pureWhite,
                      backgroundColor: AppColors.charcoal,
                      side: BorderSide(
                        color: _selectedCategory == cat
                            ? AppColors.pureWhite
                            : AppColors.steel,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Exercise List
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.steel,
              ),
              itemBuilder: (context, index) {
                final template = filtered[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  title: Text(
                    template.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        template.muscleGroup,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 11.0,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· ${template.equipment}',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 11.0,
                          color: AppColors.platinum,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.pureWhite,
                    size: 22,
                  ),
                  onTap: () {
                    final exerciseId =
                        'ex_${DateTime.now().microsecondsSinceEpoch}';
                    final newExercise = ActiveExerciseState(
                      exerciseId: exerciseId,
                      name: template.name,
                      muscleGroup: template.muscleGroup,
                      equipment: template.equipment,
                      restDurationSeconds: template.defaultRestSeconds,
                      sets: [
                        const ActiveSetState(setNumber: 1, weightKg: 20.0, reps: 10),
                        const ActiveSetState(setNumber: 2, weightKg: 20.0, reps: 10),
                        const ActiveSetState(setNumber: 3, weightKg: 20.0, reps: 10),
                      ],
                    );
                    widget.onExerciseSelected(newExercise);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
