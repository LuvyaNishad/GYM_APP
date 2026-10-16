/// Workout Detail Sheet for the LEON Dashboard.
///
/// Modal bottom sheet presenting in-depth workout overview and rotation telemetry:
/// - Planned exercises count, duration, hypertrophy focus, and Target RPE
/// - Interactive Split Day Switcher chips to rotate through all days in the split
/// - Real-time exercise sequence preview for the selected workout
/// - Direct "START WORKOUT" initiation pre-loading exact movements
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../workout_builder/models/split_model.dart';
import '../../workout_builder/widgets/create_routine_sheet.dart';
import '../providers/workout_rotation_provider.dart';

/// Displays the detailed Workout Overview modal bottom sheet.
void showWorkoutDetailSheet(
  BuildContext context, {
  SplitWorkoutDay? initialDay,
}) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _WorkoutDetailContent(),
  );
}

class _WorkoutDetailContent extends ConsumerWidget {
  const _WorkoutDetailContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rotation = ref.watch(workoutRotationProvider);
    final selectedDay = rotation.selectedDay;
    final split = rotation.split;

    final title = '${selectedDay.name.toUpperCase()}${selectedDay.subtitle.isNotEmpty ? ' ● ${selectedDay.subtitle.toUpperCase()}' : ''}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141722),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 36,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Grab Handle ─────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Top Header: Status Badge + Close Button ─────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: rotation.isCompletedToday
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.steel.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: rotation.isCompletedToday
                            ? AppColors.success.withValues(alpha: 0.6)
                            : AppColors.steel,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rotation.isCompletedToday
                                ? AppColors.success
                                : AppColors.pureWhite,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rotation.isCompletedToday
                              ? 'COMPLETED TODAY'
                              : "TODAY'S WORKOUT",
                          style: AppTypography.labelSmall.copyWith(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11.0,
                            color: rotation.isCompletedToday
                                ? AppColors.success
                                : AppColors.pureWhite,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.platinum,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Interactive Split Rotation Switcher ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ROTATION DAYS ● ${split.shortName}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (rotation.isManuallyOverridden)
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(workoutRotationProvider.notifier)
                            .resetToRecommended();
                      },
                      child: const Text(
                        'Reset Auto',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: split.workouts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final day = split.workouts[index];
                    final isSelected = day.id == selectedDay.id;
                    final isRecommended = index == rotation.recommendedIndex;

                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(workoutRotationProvider.notifier)
                            .selectDayByIndex(index);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.pureWhite
                              : AppColors.charcoal,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.pureWhite
                                : (isRecommended
                                    ? AppColors.primary.withValues(alpha: 0.6)
                                    : AppColors.steel.withValues(alpha: 0.5)),
                            width: isSelected || isRecommended ? 1.2 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isRecommended && !isSelected) ...[
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              day.name,
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.onyx
                                    : (isRecommended
                                        ? AppColors.primary
                                        : AppColors.platinum),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ── Workout Title & Subtitle ──────────────────────────────────
              Text(
                title,
                style: AppTypography.headlineMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.pureWhite,
                ),
              ),
              const SizedBox(height: 4),

              // Auto-Rotation Rationale
              Text(
                rotation.rotationReason,
                style: const TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 12),

              // ── Muscle Badges ─────────────────────────────────────────────
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final muscle in selectedDay.targetMuscles)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.steel.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.steel, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.platinum,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            muscle.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.platinum,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 18),

              // ── 4 Metrics Grid ───────────────────────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: _MetricTile(
                      label: 'TARGET RPE',
                      value: '8.5',
                      subtext: 'Rate of Exertion',
                      icon: Icons.speed_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      label: 'EXERCISES',
                      value: '${selectedDay.exercises.length}',
                      subtext: 'Planned movements',
                      icon: Icons.fitness_center_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'DURATION',
                      value: '~${selectedDay.estimatedDurationMinutes} MIN',
                      subtext: 'Est. workout time',
                      icon: Icons.timer_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: _MetricTile(
                      label: 'TRAINING FOCUS',
                      value: 'HYPERTROPHY',
                      subtext: 'Volume & muscle',
                      icon: Icons.bolt_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Exercise Roster Preview Header ────────────────────────────
              Text(
                'PLANNED EXERCISE SEQUENCE (${selectedDay.exercises.length} MOVEMENTS)',
                style: AppTypography.labelSmall.copyWith(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.0,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              // Dynamic Exercise List
              for (int i = 0; i < selectedDay.exercises.length; i++) ...[
                _ExercisePreviewRow(
                  index: '${i + 1}'.padLeft(2, '0'),
                  name: selectedDay.exercises[i].exerciseName,
                  details:
                      '${selectedDay.exercises[i].targetSets} Sets • ${selectedDay.exercises[i].repRange} Reps • ${selectedDay.exercises[i].targetWeightKg.toInt()} kg target',
                ),
                if (i < selectedDay.exercises.length - 1)
                  const SizedBox(height: 6),
              ],

              const SizedBox(height: 20),

              // ── Action Buttons Row: START WORKOUT / LOGS & EDIT ROUTINE ──
              if (rotation.isCompletedToday) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                          context.go(AppConstants.routeAnalytics);
                        },
                        icon: const Icon(Icons.history_rounded, size: 16, color: AppColors.pureWhite),
                        label: Text(
                          'VIEW WORKOUT LOG',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.pureWhite,
                          side: const BorderSide(color: AppColors.steel),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          Navigator.of(context).pop();
                          ref.read(workoutRotationProvider.notifier).startWorkout(context);
                        },
                        icon: const Icon(Icons.play_arrow_rounded, color: AppColors.onyx, size: 20),
                        label: Text(
                          'EXTRA WORKOUT',
                          style: AppTypography.titleLarge.copyWith(
                            fontFamily: AppTypography.fontDisplay,
                            fontSize: 12.0,
                            color: AppColors.onyx,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pureWhite,
                          foregroundColor: AppColors.onyx,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          Navigator.of(context).pop();
                          ref.read(workoutRotationProvider.notifier).startWorkout(context);
                        },
                        icon: const Icon(Icons.play_arrow_rounded, color: AppColors.onyx, size: 22),
                        label: Text(
                          'START WORKOUT',
                          style: AppTypography.titleLarge.copyWith(
                            fontFamily: AppTypography.fontDisplay,
                            fontSize: 12.5,
                            color: AppColors.onyx,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pureWhite,
                          foregroundColor: AppColors.onyx,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                          showCreateRoutineSheet(context, initialSplit: split);
                        },
                        icon: const Icon(Icons.tune_rounded, size: 16, color: AppColors.pureWhite),
                        label: Text(
                          'EDIT ROUTINE',
                          style: AppTypography.monoSmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.pureWhite,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.pureWhite,
                          side: const BorderSide(color: AppColors.steel),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtext;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.steel.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.platinum),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11.0,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 15.0,
              fontWeight: FontWeight.w800,
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 11.0,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePreviewRow extends StatelessWidget {
  const _ExercisePreviewRow({
    required this.index,
    required this.name,
    required this.details,
  });

  final String index;
  final String name;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.charcoal.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.steel.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(
            index,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                  ),
                ),
                Text(
                  details,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11.0,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
