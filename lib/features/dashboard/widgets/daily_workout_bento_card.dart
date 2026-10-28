import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/split_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../workout_session/providers/active_session_provider.dart';
import '../providers/home_workout_view_provider.dart';
import '../providers/workout_rotation_provider.dart';
import 'workout_detail_sheet.dart';

class DailyWorkoutBentoCard extends ConsumerWidget {
  const DailyWorkoutBentoCard({
    super.key,
    this.activeSplit,
    this.muscleGroups = const [],
    this.exerciseCount = 0,
    this.estimatedMinutes = 0,
    this.targetRpe = '',
    this.onStartWorkout,
    this.onTap,
    this.useCalendarDate = true,
  });
  final SplitModel? activeSplit;
  final List<String> muscleGroups;
  final int exerciseCount;
  final int estimatedMinutes;
  final String targetRpe;
  final VoidCallback? onStartWorkout;
  final VoidCallback? onTap;
  final bool useCalendarDate;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(homeWorkoutViewProvider);
    final rotation = ref.watch(workoutRotationProvider);
    final active = ref.watch(
      activeSessionProvider.select(
        (s) => (s.isActive, s.splitName, s.completedSetCount, s.totalSetCount),
      ),
    );
    final day = useCalendarDate ? view.day : rotation.selectedDay;
    final showActive = active.$1 && (!useCalendarDate || view.isToday);
    final past = useCalendarDate && view.isPast;
    final title = showActive
        ? active.$2
        : past
        ? (view.logged.isEmpty
              ? 'No workout logged'
              : '${view.logged.length} workout${view.logged.length == 1 ? '' : 's'} logged')
        : day?.name ?? 'Rest day';
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(view.date);
    void details() {
      if (onTap != null) {
        onTap!();
        return;
      }
      showWorkoutDetailSheet(
        context,
        initialDay: day,
        date: useCalendarDate ? view.date : DateTime.now(),
        loggedWorkouts: past ? view.logged : const [],
      );
    }

    void start() {
      if (onStartWorkout != null) {
        onStartWorkout!();
        return;
      }
      if (active.$1) {
        context.push(AppConstants.routeWorkoutSession);
        return;
      }
      if (day == null || day.isRestDay) {
        details();
        return;
      }
      ref
          .read(activeSessionProvider.notifier)
          .startSession(
            splitName: '${rotation.split.shortName} · ${day.name}',
            initialExercises: day.exercises
                .map((e) => e.toActiveExerciseState())
                .toList(),
          );
      context.push(AppConstants.routeWorkoutSession);
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      border: false,
      blur: true,
      onTap: details,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                showActive
                    ? Icons.play_circle_outline_rounded
                    : past
                    ? Icons.history_rounded
                    : Icons.fitness_center_rounded,
                size: 18,
                color: showActive ? AppColors.primary : AppColors.platinum,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  showActive
                      ? 'WORKOUT IN PROGRESS'
                      : (!useCalendarDate || view.isToday)
                      ? 'NEXT WORKOUT'
                      : dateLabel.toUpperCase(),
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.platinum,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.platinum,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTypography.headlineSmall.copyWith(
              fontSize: 22,
              letterSpacing: 1.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            showActive
                ? '${active.$3} of ${active.$4} sets logged'
                : past
                ? (view.logged.isEmpty
                      ? 'No session was recorded for this date.'
                      : view.logged.map((w) => w.name).join(' · '))
                : day == null || day.isRestDay
                ? 'Take time to recover, or choose another workout.'
                : '${day.exercises.length} exercises · ${day.totalSets} sets · ~${day.estimatedDurationMinutes} min',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.platinum),
          ),
          if (!past &&
              !showActive &&
              day != null &&
              day.exercises.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              day.exercises.take(3).map((e) => e.exerciseName).join('  /  '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.platinum,
                height: 1.4,
              ),
            ),
          ],
          if (useCalendarDate && !view.isToday && !past) ...[
            const SizedBox(height: 8),
            Text(
              'Rotation preview · starting logs a workout today.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
            ),
          ],
          const SizedBox(height: 14),
          if (!past)
            FilledButton.icon(
              onPressed: start,
              icon: Icon(
                active.$1
                    ? Icons.play_arrow_rounded
                    : Icons.fitness_center_rounded,
                size: 19,
              ),
              label: Text(
                active.$1
                    ? 'RESUME WORKOUT'
                    : day?.isRestDay == true
                    ? 'VIEW PLAN'
                    : 'START WORKOUT',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            )
          else if (view.logged.isNotEmpty)
            OutlinedButton(
              onPressed: details,
              child: const Text('VIEW WORKOUTS'),
            ),
          if (useCalendarDate &&
              view.isToday &&
              view.logged.isNotEmpty &&
              !showActive)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${view.logged.length} workout${view.logged.length == 1 ? '' : 's'} completed today',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.platinum,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
