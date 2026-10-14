import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../workout_session/providers/active_session_provider.dart';
import '../models/exercise_library_item.dart';

/// Modal dialog allowing the user to configure and add an exercise to a specific
/// training day or directly into the currently active workout session.
class AddToRoutineDialog extends ConsumerStatefulWidget {
  const AddToRoutineDialog({
    super.key,
    required this.exercise,
  });

  final ExerciseLibraryItem exercise;

  @override
  ConsumerState<AddToRoutineDialog> createState() => _AddToRoutineDialogState();
}

class _AddToRoutineDialogState extends ConsumerState<AddToRoutineDialog> {
  String _selectedDestination = 'Active Workout';
  int _targetSets = 3;
  String _targetRepRange = '8-12 reps';
  late int _restSeconds;
  final double _defaultWeight = 60.0;

  static const List<String> _destinations = [
    'Active Workout',
    'Push Day ● Workout A',
    'Pull Day ● Workout B',
    'Leg Day ● Workout C',
  ];

  static const List<String> _repRanges = [
    '5-8 reps',
    '8-12 reps',
    '12-15 reps',
    '15-20 reps',
  ];

  static const List<int> _restOptions = [60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    _restSeconds = widget.exercise.defaultRestSeconds;
  }

  void _onConfirm() {
    final activeSession = ref.read(activeSessionProvider);
    final activeNotifier = ref.read(activeSessionProvider.notifier);

    int defaultReps = 10;
    if (_targetRepRange.startsWith('5-8')) defaultReps = 6;
    if (_targetRepRange.startsWith('8-12')) defaultReps = 10;
    if (_targetRepRange.startsWith('12-15')) defaultReps = 12;
    if (_targetRepRange.startsWith('15-20')) defaultReps = 15;

    if (_selectedDestination == 'Active Workout') {
      if (!activeSession.isActive) {
        // Start workout if not started
        activeNotifier.startSession(splitName: 'CUSTOM WORKOUT');
      }

      final activeExercise = widget.exercise.toActiveExercise(
        targetSets: _targetSets,
        defaultWeightKg: _defaultWeight,
        defaultReps: defaultReps,
        customRestSeconds: _restSeconds,
      );

      activeNotifier.addExercise(activeExercise);
    }

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
          'Added ${widget.exercise.name} ($_targetSets sets) to $_selectedDestination',
          style: AppTypography.bodySmall.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.pureWhite,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.onyx.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.steel,
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Title Header ───────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ADD TO ROUTINE',
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: AppColors.platinum,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.exercise.name,
                              style: AppTypography.headlineMedium.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.pureWhite,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppColors.platinum),
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      ),
                    ],
                  ),

                  const Divider(color: AppColors.steel, height: 24),

                  // ── Destination Split Selector ─────────────────────────
                  _buildSectionLabel('SELECT DESTINATION'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.charcoal,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.steel,
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDestination,
                        isExpanded: true,
                        dropdownColor: AppColors.charcoal,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.platinum),
                        items: _destinations.map((dest) {
                          return DropdownMenuItem<String>(
                            value: dest,
                            child: Text(
                              dest,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDestination = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Target Sets Stepper ─────────────────────────────────
                  _buildSectionLabel('TARGET SETS'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStepperButton(
                        icon: Icons.remove_rounded,
                        onTap: () {
                          if (_targetSets > 1) setState(() => _targetSets--);
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '$_targetSets SETS',
                            style: AppTypography.monoMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ),
                      ),
                      _buildStepperButton(
                        icon: Icons.add_rounded,
                        onTap: () {
                          if (_targetSets < 10) setState(() => _targetSets++);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Target Rep Range Chips ─────────────────────────────
                  _buildSectionLabel('TARGET REP RANGE'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _repRanges.map((range) {
                      final isSelected = _targetRepRange == range;
                      return InkWell(
                        onTap: () => setState(() => _targetRepRange = range),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.pureWhite
                                : AppColors.charcoal,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.pureWhite : AppColors.steel,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            range,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 12.0,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.onyx : AppColors.platinum,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // ── Rest Timer Selector ────────────────────────────────
                  _buildSectionLabel('REST TIMER INTERVAL'),
                  const SizedBox(height: 8),
                  Row(
                    children: _restOptions.map((secs) {
                      final isSelected = _restSeconds == secs;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () => setState(() => _restSeconds = secs),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.pureWhite
                                    : AppColors.charcoal,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.pureWhite : AppColors.steel,
                                  width: 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${secs}s',
                                  style: AppTypography.monoSmall.copyWith(
                                    fontSize: 12.0,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.onyx : AppColors.platinum,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 22),

                  // ── Confirm / Action Button ────────────────────────────
                  FilledButton(
                    onPressed: _onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.pureWhite,
                      foregroundColor: AppColors.onyx,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'CONFIRM & ADD',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppColors.onyx,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTypography.labelSmall.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.platinum,
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.steel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.steel,
              width: 1.0,
            ),
          ),
          child: Icon(icon, size: 20, color: AppColors.pureWhite),
        ),
      ),
    );
  }
}
