import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/exercise_library_item.dart';
import '../providers/exercise_library_provider.dart';
import '../widgets/exercise_filter_bar.dart';
import '../widgets/exercise_library_card.dart';
import '../widgets/exercise_detail_sheet.dart';
import '../widgets/add_to_routine_dialog.dart';
import 'custom_exercise_creator_screen.dart';

/// Screen 1: The primary Exercise Library directory, featuring live fuzzy search,
/// cinema-style horizontal filter pills, retractable detail sheets, and quick-add actions.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetailSheet(ExerciseLibraryItem exercise) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseDetailSheet(
        initialExercise: exercise,
        onAddToWorkout: (selected) {
          _openAddToRoutine(selected);
        },
      ),
    );
  }

  void _openAddToRoutine(ExerciseLibraryItem exercise) {
    showDialog<void>(
      context: context,
      builder: (_) => AddToRoutineDialog(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseLibraryProvider);
    final notifier = ref.read(exerciseLibraryProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.onyx,
      appBar: AppBar(
        backgroundColor: AppColors.onyx,
        elevation: 0,
        centerTitle: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.pureWhite),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'EXERCISE LIBRARY',
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.pureWhite,
          ),
        ),
        actions: [
          // ── Create Custom Exercise Button ─────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CustomExerciseCreatorScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.pureWhite),
              label: Text(
                'CUSTOM',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.pureWhite,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.charcoal,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(
                    color: AppColors.steel,
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Live Search Input Field ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.steel,
                    width: 1.0,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: notifier.setSearchQuery,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.pureWhite, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search 156 exercises, muscles, equipment...',
                    hintStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.platinum, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.platinum, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            // ── Horizontal Filter Bar (Master button + Divider + Quick Chips) ─
            const ExerciseFilterBar(),

            const SizedBox(height: 8),

            // ── Results Counter & Active Filters Clear Banner ───────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.filteredExercises.length} EXERCISES FOUND',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.platinum,
                    ),
                  ),
                  if (state.filter.hasActiveFilters)
                    InkWell(
                      onTap: () {
                        _searchController.clear();
                        notifier.clearAll();
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'CLEAR ALL',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Exercise List or Empty State ─────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pureWhite),
                    )
                  : state.filteredExercises.isEmpty
                      ? _buildEmptyState(notifier)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(0, 6, 0, 120),
                          itemCount: state.filteredExercises.length,
                          itemBuilder: (context, index) {
                            final exercise = state.filteredExercises[index];
                            return ExerciseLibraryCard(
                              exercise: exercise,
                              onTap: () => _openDetailSheet(exercise),
                              onQuickAdd: () => _openAddToRoutine(exercise),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ExerciseLibraryNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.steel,
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppColors.platinum,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises found',
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your search query or removing filter constraints.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12.5,
                color: AppColors.platinum,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                _searchController.clear();
                notifier.clearAll();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.pureWhite,
                foregroundColor: AppColors.onyx,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'RESET ALL FILTERS',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.onyx,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
