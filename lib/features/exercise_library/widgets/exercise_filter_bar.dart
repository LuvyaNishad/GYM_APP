import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/exercise_library_provider.dart';
import 'exercise_filter_modal.dart';

/// Horizontal scrolling filter bar inspired by high-end cinema/booking filters.
/// Features a master '[⊶ Filters ⌄]' trigger pill on the left, a subtle divider '|',
/// and horizontally scrollable quick filter toggle chips.
class ExerciseFilterBar extends ConsumerWidget {
  const ExerciseFilterBar({super.key});

  static const List<String> _quickCategories = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
  ];

  static const List<String> _quickEquipment = [
    'Barbell',
    'Dumbbell',
    'Cable',
    'Machine',
    'Bodyweight',
  ];

  static const List<String> _quickTypes = [
    'Compound',
    'Isolation',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exerciseLibraryProvider);
    final notifier = ref.read(exerciseLibraryProvider.notifier);
    final activeFiltersCount = state.filter.activeFiltersCount;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // ── Master Filter Trigger Button [⊶ Filters ⌄] ──────────────────
          _MasterFilterButton(
            activeCount: activeFiltersCount,
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ExerciseFilterModal(),
              );
            },
          ),

          // ── Vertical Subtle Glass Divider ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Container(
              width: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),

          // ── Category Toggle Chips ──────────────────────────────────────
          ..._quickCategories.map((category) {
            final isSelected = state.filter.selectedCategory.toLowerCase() == category.toLowerCase();
            return _FilterChip(
              label: category,
              isSelected: isSelected,
              onTap: () => notifier.setCategory(category),
            );
          }),

          // ── Equipment Toggle Chips ─────────────────────────────────────
          ..._quickEquipment.map((equipment) {
            final isSelected = state.filter.selectedEquipment.toLowerCase() == equipment.toLowerCase();
            return _FilterChip(
              label: equipment,
              isSelected: isSelected,
              onTap: () => notifier.setEquipment(equipment),
            );
          }),

          // ── Type Toggle Chips ──────────────────────────────────────────
          ..._quickTypes.map((type) {
            final isSelected = state.filter.selectedType.toLowerCase() == type.toLowerCase();
            return _FilterChip(
              label: type,
              isSelected: isSelected,
              onTap: () => notifier.setType(type),
            );
          }),
        ],
      ),
    );
  }
}

class _MasterFilterButton extends StatelessWidget {
  const _MasterFilterButton({
    required this.activeCount,
    required this.onTap,
  });

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasActive = activeCount > 0;

    return Semantics(
      button: true,
      label: 'Open Filters Sheet',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: hasActive
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : const Color(0xFF161A23),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasActive
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.14),
                width: hasActive ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: hasActive ? AppColors.primary : Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  hasActive ? 'Filters ($activeCount)' : 'Filters',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: hasActive ? AppColors.primary : Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: hasActive ? AppColors.primary : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Filter by $label',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : const Color(0xFF161A23),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.12),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 12.0,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.4,
                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
