import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/local_date_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../history/providers/history_provider.dart';
import '../../workout_builder/models/training_schedule.dart';
import '../../workout_builder/models/workout_sequence.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../../workout_session/providers/active_session_provider.dart';
import '../providers/workout_rotation_provider.dart';

void showTrainingPauseSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  isDismissible: false,
  enableDrag: false,
  backgroundColor: Colors.transparent,
  builder: (_) => const _TrainingPauseSheet(),
);

class _TrainingPauseSheet extends ConsumerStatefulWidget {
  const _TrainingPauseSheet();

  @override
  ConsumerState<_TrainingPauseSheet> createState() =>
      _TrainingPauseSheetState();
}

class _TrainingPauseSheetState extends ConsumerState<_TrainingPauseSheet> {
  bool _busy = false;

  Future<void> _save(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ref.read(selectedCalendarDateProvider.notifier).clear();
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your schedule. Please try again.'),
        ),
      );
    }
  }

  Future<void> _chooseReturnDate() async {
    final today = ref.read(localDateProvider);
    final earliest = DateTime(today.year, today.month, today.day + 1);
    final scheduled = trainingResumeDate(
      ref.read(splitsProvider).schedules,
      today,
    );
    final chosen = await showDatePicker(
      context: context,
      helpText: 'Choose your return date',
      initialDate: scheduled ?? earliest,
      firstDate: earliest,
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (!mounted || chosen == null) return;
    await _save(
      () => ref.read(splitsProvider.notifier).pauseTraining(resumeOn: chosen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(localDateProvider);
    final splits = ref.watch(splitsProvider);
    final rotation = ref.watch(workoutRotationProvider);
    final paused = rotation.isTrainingPaused;
    final resumeOn = trainingResumeDate(splits.schedules, today);
    final active = ref.watch(
      activeSessionProvider.select((session) => session.isActive),
    );
    final latest = latestCompletedSplitDay(
      splits.activeSplit,
      ref.watch(historyWorkoutsProvider),
      today,
    );
    final local = MaterialLocalizations.of(context);
    final workouts = splits.activeSplit.workouts;
    final returnIndex = latest == null
        ? 0
        : nextWorkoutDayIndex(splits.activeSplit, latest, today);
    final returnPattern = TrainingSchedule.fromSplit(splits.activeSplit, today);
    String previewName(int offset) {
      final date = DateTime(today.year, today.month, today.day + offset);
      final explicitRecovery = workouts.any((day) => day.isRestDay);
      if (!explicitRecovery && !returnPattern.isTrainingDay(date)) {
        return 'Rest day';
      }
      var steps = explicitRecovery
          ? offset
          : returnPattern.trainingDaysBetween(today, date);
      if (steps > 0 &&
          latest != null &&
          workoutDateDifference(today, latest.workout.date) == 0) {
        steps--;
      }
      return workouts[(returnIndex + steps) % workouts.length].name;
    }

    final notifier = ref.read(splitsProvider.notifier);

    return AppSheet(
      title: paused ? 'Training paused' : 'Pause training',
      busy: _busy,
      children: [
        Text(
          paused
              ? resumeOn == null
                    ? 'Your plan is paused until you choose to resume.'
                    : 'Training resumes on ${local.formatFullDate(resumeOn)}. You can extend your break or resume earlier.'
              : 'Take the time you need. Paused dates will not count as missed workouts, and your completed sessions stay saved.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        if (latest != null) ...[
          Text(
            'Last workout: ${workouts[latest.index].name} · ${local.formatMediumDate(latest.workout.date)}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (paused && workouts.isNotEmpty) ...[
          GlassCard(
            blur: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'IF YOU RESUME TODAY',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                for (var offset = 0; offset < 4; offset++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 88,
                          child: Text(
                            offset == 0
                                ? 'Today'
                                : local.formatShortDate(
                                    DateTime(
                                      today.year,
                                      today.month,
                                      today.day + offset,
                                    ),
                                  ),
                            style: AppTypography.monoSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            previewName(offset),
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your last logged workout determines what comes next. Days off count toward recovery; unfinished workouts stay in order.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (active) ...[
          Text(
            'Finish or discard your current workout before pausing training.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.warning),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: _busy || active
              ? null
              : () => _save(
                  paused ? notifier.resumeTraining : notifier.pauseTraining,
                ),
          icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
          label: Text(
            _busy
                ? 'SAVING…'
                : paused
                ? 'RESUME TRAINING'
                : 'PAUSE UNTIL I RESUME',
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy || active ? null : _chooseReturnDate,
          icon: const Icon(Icons.calendar_month_rounded),
          label: Text(paused ? 'CHANGE RETURN DATE' : 'CHOOSE A RETURN DATE'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        if (paused && resumeOn != null)
          TextButton(
            onPressed: _busy || active
                ? null
                : () => _save(notifier.pauseTraining),
            child: const Text('PAUSE UNTIL I RESUME'),
          ),
      ],
    );
  }
}
