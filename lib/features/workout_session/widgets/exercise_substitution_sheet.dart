import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/active_session_state.dart';
import '../providers/active_session_provider.dart';
import 'exercise_picker_modal.dart';

/// Bottom sheet allowing the user to 1-tap substitute an exercise with an alternative
/// targeting the same muscle group when gym equipment is busy or occupied.
/// Completed sets already logged remain completely preserved.
class ExerciseSubstitutionSheet extends ConsumerStatefulWidget {
  const ExerciseSubstitutionSheet({
    super.key,
    required this.currentExercise,
  });

  final ActiveExerciseState currentExercise;

  @override
  ConsumerState<ExerciseSubstitutionSheet> createState() =>
      _ExerciseSubstitutionSheetState();
}

class _ExerciseSubstitutionSheetState
    extends ConsumerState<ExerciseSubstitutionSheet> {
  String _selectedEquipment = 'ALL';
  String _searchQuery = '';

  static const List<String> _equipmentFilters = [
    'ALL',
    'DUMBBELL',
    'BARBELL',
    'CABLE',
    'MACHINE',
    'BODYWEIGHT',
  ];

  @override
  Widget build(BuildContext context) {
    final currentMuscle = widget.currentExercise.muscleGroup.toLowerCase();

    bool isMatchingMuscle(String catalogMuscle, String current) {
      if (catalogMuscle == current) return true;
      if (catalogMuscle == 'legs' &&
          (current.contains('leg') ||
              current.contains('quad') ||
              current.contains('hamstring') ||
              current.contains('cal') ||
              current.contains('glute'))) {
        return true;
      }
      if (catalogMuscle == 'arms' &&
          (current.contains('arm') ||
              current.contains('bicep') ||
              current.contains('tricep') ||
              current.contains('forearm'))) {
        return true;
      }
      if (catalogMuscle == 'back' &&
          (current.contains('back') ||
              current.contains('lat') ||
              current.contains('trap'))) {
        return true;
      }
      if (catalogMuscle == 'chest' &&
          (current.contains('chest') || current.contains('pec'))) {
        return true;
      }
      if (catalogMuscle == 'shoulders' &&
          (current.contains('shoulder') || current.contains('delt'))) {
        return true;
      }
      if (catalogMuscle == 'core' &&
          (current.contains('core') || current.contains('ab'))) {
        return true;
      }
      return current.contains(catalogMuscle) || catalogMuscle.contains(current);
    }

    // Query alternatives matching the same muscle group
    final matchingTemplates = kExerciseCatalog.where((tpl) {
      final sameMuscle = isMatchingMuscle(
        tpl.muscleGroup.toLowerCase(),
        currentMuscle,
      );
      final isDifferentExercise =
          tpl.name.toLowerCase() != widget.currentExercise.name.toLowerCase();

      final matchesEquipment = _selectedEquipment == 'ALL' ||
          tpl.equipment.toUpperCase() == _selectedEquipment;

      final matchesSearch = _searchQuery.isEmpty ||
          tpl.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tpl.equipment.toLowerCase().contains(_searchQuery.toLowerCase());

      return sameMuscle && isDifferentExercise && matchesEquipment && matchesSearch;
    }).toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.steel.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
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
              const SizedBox(height: 14),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUBSTITUTE EXERCISE',
                        style: AppTypography.titleLarge.copyWith(
                          fontFamily: AppTypography.fontDisplay,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pureWhite,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Current: ${widget.currentExercise.name}',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.0,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.platinum),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Bar
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  color: AppColors.pureWhite,
                ),
                decoration: InputDecoration(
                  hintText: 'Search matching alternatives...',
                  hintStyle: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    color: AppColors.platinum,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.platinum,
                    size: 18,
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
                    borderSide: const BorderSide(color: AppColors.steel),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Equipment Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _equipmentFilters.map((eq) {
                    final isSelected = _selectedEquipment == eq;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        label: Text(
                          eq,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.onyx : AppColors.platinum,
                          ),
                        ),
                        backgroundColor: AppColors.charcoal,
                        selectedColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.steel,
                            width: 1,
                          ),
                        ),
                        onSelected: (_) => setState(() => _selectedEquipment = eq),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Alternatives List
              Expanded(
                child: matchingTemplates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.fitness_center_outlined,
                              size: 36,
                              color: AppColors.platinum,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No matching alternatives found',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 13,
                                color: AppColors.platinum,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: matchingTemplates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final alt = matchingTemplates[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.charcoal,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.steel.withValues(alpha: 0.6),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alt.name,
                                        style: AppTypography.bodySmall.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.pureWhite,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              alt.equipment.toUpperCase(),
                                              style: const TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                                fontSize: 11.0,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.platinum,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Rest: ${alt.defaultRestSeconds}s',
                                            style: const TextStyle(
                                              fontFamily: 'JetBrains Mono',
                                              fontSize: 11.0,
                                              color: AppColors.platinum,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Swap Action Button
                                ElevatedButton(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    final notifier =
                                        ref.read(activeSessionProvider.notifier);
                                    notifier.substituteExercise(
                                      oldExerciseId: widget.currentExercise.exerciseId,
                                      newExerciseId:
                                          'sub_${alt.name.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
                                      newName: alt.name,
                                      newMuscleGroup: alt.muscleGroup,
                                      newEquipment: alt.equipment,
                                      newRestSeconds: alt.defaultRestSeconds,
                                    );

                                    Navigator.of(context).pop();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.charcoal,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: const BorderSide(
                                            color: AppColors.primary,
                                            width: 1,
                                          ),
                                        ),
                                        content: Text(
                                          'Substituted with ${alt.name} (logged sets preserved)',
                                          style: AppTypography.bodySmall.copyWith(
                                            fontSize: 12.5,
                                            color: AppColors.pureWhite,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onyx,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: Text(
                                    'SWAP',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.onyx,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper method to present the ExerciseSubstitutionSheet.
void showExerciseSubstitutionSheet({
  required BuildContext context,
  required ActiveExerciseState currentExercise,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => ExerciseSubstitutionSheet(
      currentExercise: currentExercise,
    ),
  );
}
