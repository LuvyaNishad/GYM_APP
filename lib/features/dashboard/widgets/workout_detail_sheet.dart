/// Workout Detail Sheet for the LEON Dashboard.
///
/// Modal bottom sheet presenting in-depth workout overview and telemetry:
/// - Planned exercises count, duration, hypertrophy focus, and Target RPE
/// - Targeted muscle groups
/// - Planned exercise roster preview
/// - Direct "START WORKOUT" initiation button
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/split_model.dart';

/// Displays the detailed Workout Overview modal bottom sheet.
void showWorkoutDetailSheet(
  BuildContext context, {
  SplitModel? activeSplit,
  List<String> muscleGroups = const ['CHEST', 'DELTOIDS', 'TRICEPS'],
  int exerciseCount = 5,
  int estimatedMinutes = 48,
  String targetRpe = '8.5',
}) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _WorkoutDetailContent(
      activeSplit: activeSplit,
      muscleGroups: muscleGroups,
      exerciseCount: exerciseCount,
      estimatedMinutes: estimatedMinutes,
      targetRpe: targetRpe,
    ),
  );
}

class _WorkoutDetailContent extends StatelessWidget {
  const _WorkoutDetailContent({
    this.activeSplit,
    required this.muscleGroups,
    required this.exerciseCount,
    required this.estimatedMinutes,
    required this.targetRpe,
  });

  final SplitModel? activeSplit;
  final List<String> muscleGroups;
  final int exerciseCount;
  final int estimatedMinutes;
  final String targetRpe;

  @override
  Widget build(BuildContext context) {
    final title = activeSplit?.name.toUpperCase() ?? 'PUSH DAY // WORKOUT A';

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
            // Grab Handle
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

            // Top Header: Badge + Close Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.steel.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.steel, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "TODAY'S WORKOUT",
                        style: AppTypography.labelSmall.copyWith(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11.0,
                          color: AppColors.pureWhite,
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

            const SizedBox(height: 12),

            // Workout Title
            Text(
              title,
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.pureWhite,
              ),
            ),

            const SizedBox(height: 8),

            // Muscle Badges
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final muscle in muscleGroups)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

            // 4 Metrics Grid (Target RPE, Exercises, Duration, Focus)
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'TARGET RPE',
                    value: targetRpe,
                    subtext: 'Rate of Exertion',
                    icon: Icons.speed_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'EXERCISES',
                    value: '$exerciseCount',
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
                    value: '~$estimatedMinutes MIN',
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

            // Exercise Roster Preview Header
            Text(
              'PLANNED EXERCISE SEQUENCE',
              style: AppTypography.labelSmall.copyWith(
                fontFamily: 'JetBrains Mono',
                fontSize: 11.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),

            // Preview List
            _ExercisePreviewRow(
              index: '01',
              name: 'Barbell Bench Press',
              details: '4 Sets • 8–10 Reps • RPE 8.5',
            ),
            const SizedBox(height: 6),
            _ExercisePreviewRow(
              index: '02',
              name: 'Incline Dumbbell Press',
              details: '3 Sets • 10–12 Reps • RPE 8.0',
            ),
            const SizedBox(height: 6),
            _ExercisePreviewRow(
              index: '03',
              name: 'Standing Overhead Press',
              details: '3 Sets • 8–10 Reps • RPE 8.5',
            ),
            const SizedBox(height: 6),
            _ExercisePreviewRow(
              index: '04',
              name: 'Lateral Cable Raises',
              details: '4 Sets • 12–15 Reps • RPE 9.0',
            ),
            const SizedBox(height: 6),
            _ExercisePreviewRow(
              index: '05',
              name: 'Triceps Rope Pushdown',
              details: '4 Sets • 10–12 Reps • RPE 8.5',
            ),

            const SizedBox(height: 20),

            // Start Workout Action Button
            GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                Navigator.of(context).pop();
                context.push(AppConstants.routeWorkoutSession);
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.onyx,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'START WORKOUT',
                      style: AppTypography.titleLarge.copyWith(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 13.0,
                        color: AppColors.onyx,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
