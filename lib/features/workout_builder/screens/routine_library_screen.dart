import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../workout_session/widgets/exercise_picker_modal.dart';
import '../models/split_model.dart';
import '../providers/splits_provider.dart';

/// Full-featured Routine Library & Template Builder Screen.
///
/// Complies with:
/// - Apple HIG: All font sizes >= 11.0 pt, min 4.5:1 WCAG AA contrast.
/// - 2-Accent system: Electric Cyan primary CTA, Slate/Silver neutral chrome.
/// - Standard gym terminology: no pseudo-military or sci-fi words.
class RoutineLibraryScreen extends ConsumerStatefulWidget {
  const RoutineLibraryScreen({super.key});

  @override
  ConsumerState<RoutineLibraryScreen> createState() => _RoutineLibraryScreenState();
}

class _RoutineLibraryScreenState extends ConsumerState<RoutineLibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openRoutineEditor({TrainingSplitModel? splitToEdit}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateRoutineSheet(initialSplit: splitToEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(splitsProvider);
    final notifier = ref.read(splitsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.pureWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ROUTINE LIBRARY',
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.pureWhite,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelColor: AppColors.pureWhite,
          unselectedLabelColor: AppColors.platinum,
          labelStyle: AppTypography.labelSmall.copyWith(
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
          unselectedLabelStyle: AppTypography.labelSmall.copyWith(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          tabs: [
            Tab(text: 'PRESET SPLITS (${state.presetSplits.length})'),
            Tab(text: 'MY ROUTINES (${state.customSplits.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRoutineEditor(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onyx,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'NEW ROUTINE',
          style: AppTypography.labelSmall.copyWith(
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.onyx,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: Preset Splits ──────────────────────────────────────────
          _buildSplitList(
            splits: state.presetSplits,
            activeSplitId: state.activeSplitId,
            notifier: notifier,
            isCustomTab: false,
          ),

          // ── TAB 2: Custom Routines ────────────────────────────────────────
          state.customSplits.isEmpty
              ? _buildEmptyCustomState()
              : _buildSplitList(
                  splits: state.customSplits,
                  activeSplitId: state.activeSplitId,
                  notifier: notifier,
                  isCustomTab: true,
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyCustomState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.steel),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Custom Routines Yet',
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a tailored workout routine or duplicate any preset split to modify its exercises and days.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12.5,
                color: AppColors.platinum,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openRoutineEditor(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'CREATE CUSTOM ROUTINE',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.onyx,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pureWhite,
                foregroundColor: AppColors.onyx,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitList({
    required List<TrainingSplitModel> splits,
    required String activeSplitId,
    required SplitsNotifier notifier,
    required bool isCustomTab,
  }) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: splits.length,
      itemBuilder: (context, index) {
        final split = splits[index];
        final isActive = split.id == activeSplitId;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.steel.withValues(alpha: 0.6),
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isActive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${split.daysPerWeek} DAYS / WK',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${split.totalWeeklySets} TOTAL SETS',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      split.name,
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      split.description,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12.5,
                        color: AppColors.platinum,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.steel),

              // ── Days preview ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORKOUT DAYS',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.platinum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...split.workouts.map((w) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: w.isRestDay ? AppColors.platinum : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                w.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              w.isRestDay ? 'Rest' : '${w.exercises.length} ex · ${w.totalSets} sets',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.0,
                                color: AppColors.platinum,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.steel),

              // ── Bottom Action Row ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    if (!isActive)
                      FilledButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          notifier.switchActiveSplit(split.id);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.pureWhite,
                          foregroundColor: AppColors.onyx,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'SET AS ACTIVE',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.onyx,
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!isCustomTab) ...[
                          // Customize button for presets (clones and opens editor immediately)
                          TextButton.icon(
                            onPressed: () async {
                              HapticFeedback.selectionClick();
                              final cloned = await notifier.duplicateSplit(split.id);
                              if (context.mounted) {
                                _openRoutineEditor(splitToEdit: cloned);
                              }
                            },
                            icon: const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
                            label: Text(
                              'CUSTOMIZE',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                        if (isCustomTab) ...[
                          // Edit button for custom routines
                          TextButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _openRoutineEditor(splitToEdit: split);
                            },
                            icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                            label: Text(
                              'EDIT',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                        // Duplicate button
                        TextButton.icon(
                          onPressed: () async {
                            HapticFeedback.selectionClick();
                            final cloned = await notifier.duplicateSplit(split.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.charcoal,
                                  content: Text(
                                    'Created duplicate: ${cloned.name}',
                                    style: const TextStyle(fontSize: 12.0, color: AppColors.pureWhite),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.platinum),
                          label: Text(
                            'DUPLICATE',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.platinum,
                            ),
                          ),
                        ),
                        if (isCustomTab) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Delete Routine',
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.warning),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.charcoal,
                                  title: Text(
                                    'Delete Routine?',
                                    style: AppTypography.headlineMedium.copyWith(
                                      fontSize: 16.0,
                                      color: AppColors.pureWhite,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete "${split.name}"? This cannot be undone.',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 12.5,
                                      color: AppColors.platinum,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('CANCEL', style: TextStyle(color: AppColors.platinum)),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        notifier.deleteCustomSplit(split.id);
                                      },
                                      style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
                                      child: const Text('DELETE', style: TextStyle(color: AppColors.onyx)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
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

/// Modal Sheet for creating or editing a custom training split template with interactive exercise management.
class _CreateRoutineSheet extends ConsumerStatefulWidget {
  const _CreateRoutineSheet({this.initialSplit});

  final TrainingSplitModel? initialSplit;

  @override
  ConsumerState<_CreateRoutineSheet> createState() => _CreateRoutineSheetState();
}

class _CreateRoutineSheetState extends ConsumerState<_CreateRoutineSheet> {
  late final TextEditingController _nameController;
  late int _daysPerWeek;
  late List<SplitWorkoutDay> _workouts;

  @override
  void initState() {
    super.initState();
    final init = widget.initialSplit;
    if (init != null) {
      _nameController = TextEditingController(text: init.name);
      _daysPerWeek = init.daysPerWeek;
      _workouts = init.workouts.map((w) {
        return w.copyWith(
          exercises: w.exercises.map((e) => e.copyWith()).toList(),
        );
      }).toList();
    } else {
      _nameController = TextEditingController(text: 'My Custom Split');
      _daysPerWeek = 4;
      _workouts = _generateDefaultDays(_daysPerWeek);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<SplitWorkoutDay> _generateDefaultDays(int days) {
    final list = <SplitWorkoutDay>[];
    for (int i = 1; i <= days; i++) {
      list.add(
        SplitWorkoutDay(
          id: 'day_$i',
          name: 'Workout Day $i',
          subtitle: 'Target Muscles',
          targetMuscles: ['Chest', 'Back'],
          exercises: [
            const PlannedExercise(
              exerciseId: 'barbell-bench-press',
              exerciseName: 'Barbell Bench Press',
              muscleGroup: 'Chest',
              targetSets: 3,
              repRange: '8–12',
            ),
            const PlannedExercise(
              exerciseId: 'barbell-bent-over-row',
              exerciseName: 'Barbell Bent-Over Row',
              muscleGroup: 'Back',
              targetSets: 3,
              repRange: '8–12',
            ),
          ],
        ),
      );
    }
    return list;
  }

  void _addExerciseToDay(int dayIdx) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExercisePickerModal(
        onExerciseSelected: (selected) {
          setState(() {
            final day = _workouts[dayIdx];
            final currentExercises = List<PlannedExercise>.from(day.exercises);
            final cleanId = 'ex_${selected.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
            currentExercises.add(
              PlannedExercise(
                exerciseId: cleanId,
                exerciseName: selected.name,
                muscleGroup: selected.muscleGroup,
                equipment: selected.equipment,
                targetSets: 3,
                repRange: '8–12',
                targetWeightKg: selected.sets.isNotEmpty ? selected.sets.first.weightKg : 50.0,
                restSeconds: selected.restDurationSeconds,
              ),
            );
            _workouts[dayIdx] = day.copyWith(exercises: currentExercises);
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
      for (final ex in w.exercises) {
        final m = ex.muscleGroup;
        if (muscleSets.containsKey(m)) {
          muscleSets[m] = (muscleSets[m] ?? 0) + ex.targetSets;
        } else {
          muscleSets[m] = ex.targetSets;
        }
      }
    }

    final isNew = widget.initialSplit == null;
    final id = widget.initialSplit?.id ?? 'custom_split_${DateTime.now().millisecondsSinceEpoch}';

    final updatedSplit = TrainingSplitModel(
      id: id,
      name: name,
      shortName: name.length > 5 ? name.substring(0, 5).toUpperCase() : name.toUpperCase(),
      daysPerWeek: _workouts.where((w) => !w.isRestDay).length,
      description: widget.initialSplit?.description ??
          'Custom routine with ${_workouts.where((w) => !w.isRestDay).length} training days per week.',
      isCustom: true,
      workouts: _workouts,
      plannedMuscleSets: muscleSets,
    );

    await ref.read(splitsProvider.notifier).saveCustomSplit(updatedSplit);

    final currentActiveId = ref.read(splitsProvider).activeSplitId;
    if (currentActiveId == id || isNew) {
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
            'Saved "$name" and set as your active split!',
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
                            child: Text(
                              day.name,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pureWhite,
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
                          onReorderItem: (oldIndex, newIndex) {
                            setState(() {
                              final currentExercises = List<PlannedExercise>.from(day.exercises);
                              final item = currentExercises.removeAt(oldIndex);
                              currentExercises.insert(newIndex, item);
                              _workouts[idx] = day.copyWith(exercises: currentExercises);
                            });
                          },
                          children: [
                            for (int eIdx = 0; eIdx < day.exercises.length; eIdx++)
                              Container(
                                key: ValueKey('${day.id}_${day.exercises[eIdx].exerciseId}_$eIdx'),
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.charcoal,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.steel.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.drag_indicator_rounded,
                                      size: 18,
                                      color: AppColors.platinum,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            day.exercises[eIdx].exerciseName,
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
                                            '${day.exercises[eIdx].muscleGroup} · ${day.exercises[eIdx].equipment}',
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
                                        if (day.exercises[eIdx].targetSets > 1) {
                                          setState(() {
                                            final currentExercises = List<PlannedExercise>.from(day.exercises);
                                            currentExercises[eIdx] = currentExercises[eIdx].copyWith(
                                              targetSets: currentExercises[eIdx].targetSets - 1,
                                            );
                                            _workouts[idx] = day.copyWith(exercises: currentExercises);
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
                                      '${day.exercises[eIdx].targetSets}s',
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
                                        if (day.exercises[eIdx].targetSets < 10) {
                                          setState(() {
                                            final currentExercises = List<PlannedExercise>.from(day.exercises);
                                            currentExercises[eIdx] = currentExercises[eIdx].copyWith(
                                              targetSets: currentExercises[eIdx].targetSets + 1,
                                            );
                                            _workouts[idx] = day.copyWith(exercises: currentExercises);
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
                                        final curr = day.exercises[eIdx].repRange;
                                        final nextIdx = (ranges.indexOf(curr) + 1) % ranges.length;
                                        setState(() {
                                          final currentExercises = List<PlannedExercise>.from(day.exercises);
                                          currentExercises[eIdx] =
                                              currentExercises[eIdx].copyWith(repRange: ranges[nextIdx]);
                                          _workouts[idx] = day.copyWith(exercises: currentExercises);
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
                                          day.exercises[eIdx].repRange,
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
                                          final currentExercises = List<PlannedExercise>.from(day.exercises);
                                          currentExercises.removeAt(eIdx);
                                          _workouts[idx] = day.copyWith(exercises: currentExercises);
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
                      SplitWorkoutDay(
                        id: 'day_${DateTime.now().millisecondsSinceEpoch}',
                        name: 'Workout Day $nextNum',
                        subtitle: 'Target Muscles',
                        targetMuscles: ['Chest', 'Arms'],
                        exercises: const [],
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.charcoal,
            border: Border(top: BorderSide(color: AppColors.steel)),
          ),
          child: FilledButton(
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
        ),
      ],
    ),
  );
},
    );
  }
}
