import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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

  void _openCreateRoutineDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CreateRoutineSheet(),
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
        onPressed: _openCreateRoutineDialog,
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
              onPressed: _openCreateRoutineDialog,
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
                child: Row(
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
                    const Spacer(),
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
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Modal Sheet for creating a custom training split template with Reorderable exercise list.
class _CreateRoutineSheet extends ConsumerStatefulWidget {
  const _CreateRoutineSheet();

  @override
  ConsumerState<_CreateRoutineSheet> createState() => _CreateRoutineSheetState();
}

class _CreateRoutineSheetState extends ConsumerState<_CreateRoutineSheet> {
  final _nameController = TextEditingController(text: 'My Custom Split');
  int _daysPerWeek = 4;
  late List<SplitWorkoutDay> _workouts;

  @override
  void initState() {
    super.initState();
    _workouts = _generateDefaultDays(_daysPerWeek);
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

  void _saveRoutine() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final newSplit = TrainingSplitModel(
      id: 'custom_split_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      shortName: name.length > 5 ? name.substring(0, 5).toUpperCase() : name.toUpperCase(),
      daysPerWeek: _daysPerWeek,
      description: 'Custom user routine with $_daysPerWeek training days per week.',
      isCustom: true,
      workouts: _workouts,
      plannedMuscleSets: const {
        'Chest': 12,
        'Back': 12,
        'Shoulders': 10,
        'Quads': 10,
        'Hamstrings': 10,
        'Arms': 10,
      },
    );

    ref.read(splitsProvider.notifier).saveCustomSplit(newSplit);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                'CREATE CUSTOM ROUTINE',
                style: AppTypography.headlineMedium.copyWith(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pureWhite,
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
                            _workouts = _generateDefaultDays(days);
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

              // Reorderable Workout Days list
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
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.onyx,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.steel.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            day.name,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${day.exercises.length} Exercises',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              color: AppColors.platinum,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Exercise list within day
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
                            ListTile(
                              key: ValueKey('${day.id}_${day.exercises[eIdx].exerciseId}_$eIdx'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.drag_indicator_rounded,
                                  size: 18, color: AppColors.platinum),
                              title: Text(
                                day.exercises[eIdx].exerciseName,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.pureWhite),
                              ),
                              trailing: Text(
                                '${day.exercises[eIdx].targetSets} × ${day.exercises[eIdx].repRange}',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11.0,
                                  color: AppColors.platinum,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Save button
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
        );
      },
    );
  }
}
