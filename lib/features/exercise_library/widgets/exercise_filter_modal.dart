import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/exercise_library_provider.dart';

/// Comprehensive filter bottom sheet for the Exercise Library.
class ExerciseFilterModal extends ConsumerStatefulWidget {
  const ExerciseFilterModal({super.key});

  @override
  ConsumerState<ExerciseFilterModal> createState() => _ExerciseFilterModalState();
}

class _ExerciseFilterModalState extends ConsumerState<ExerciseFilterModal> {
  late String _tempCategory;
  late String _tempEquipment;
  late String _tempType;
  late String _tempDifficulty;

  static const List<String> _categories = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
    'Full Body',
    'Mobility',
  ];

  static const List<String> _equipment = [
    'All',
    'Barbell',
    'Dumbbell',
    'Cable',
    'Machine',
    'Bodyweight',
    'Band',
    'Kettlebell',
  ];

  static const List<String> _types = [
    'All',
    'Compound',
    'Isolation',
    'Mobility',
  ];

  static const List<String> _difficulties = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    final filter = ref.read(exerciseLibraryProvider).filter;
    _tempCategory = filter.selectedCategory;
    _tempEquipment = filter.selectedEquipment;
    _tempType = filter.selectedType;
    _tempDifficulty = filter.selectedDifficulty;
  }

  void _resetAll() {
    setState(() {
      _tempCategory = 'All';
      _tempEquipment = 'All';
      _tempType = 'All';
      _tempDifficulty = 'All';
    });
  }

  void _apply() {
    final notifier = ref.read(exerciseLibraryProvider.notifier);
    notifier.setCategory(_tempCategory);
    notifier.setEquipment(_tempEquipment);
    notifier.setType(_tempType);
    notifier.setDifficulty(_tempDifficulty);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1219).withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
          ),
          padding: EdgeInsets.only(
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Notch Grabber Handle ──────────────────────────────
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Modal Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FILTER EXERCISES',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetAll,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(60, 36),
                      ),
                      child: Text(
                        'RESET',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF1E293B), height: 20),

              // ── Filter Body ───────────────────────────────────────────
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('TARGET MUSCLE GROUP'),
                      _buildWrapSelector(
                        options: _categories,
                        selected: _tempCategory,
                        onSelected: (val) => setState(() => _tempCategory = val),
                      ),
                      const SizedBox(height: 18),

                      _buildSectionHeader('EQUIPMENT'),
                      _buildWrapSelector(
                        options: _equipment,
                        selected: _tempEquipment,
                        onSelected: (val) => setState(() => _tempEquipment = val),
                      ),
                      const SizedBox(height: 18),

                      _buildSectionHeader('MOVEMENT TYPE'),
                      _buildWrapSelector(
                        options: _types,
                        selected: _tempType,
                        onSelected: (val) => setState(() => _tempType = val),
                      ),
                      const SizedBox(height: 18),

                      _buildSectionHeader('DIFFICULTY'),
                      _buildWrapSelector(
                        options: _difficulties,
                        selected: _tempDifficulty,
                        onSelected: (val) => setState(() => _tempDifficulty = val),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Apply CTA Button ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'APPLY FILTERS',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildWrapSelector({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt.toLowerCase() == selected.toLowerCase();
        return InkWell(
          onTap: () => onSelected(opt),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.20)
                  : const Color(0xFF161A23),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.12),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              opt,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
