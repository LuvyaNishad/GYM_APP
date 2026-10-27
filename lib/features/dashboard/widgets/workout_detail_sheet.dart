import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/workout_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../workout_builder/models/split_model.dart';
import '../../workout_builder/widgets/create_routine_sheet.dart';
import '../../workout_session/providers/active_session_provider.dart';
import '../providers/workout_rotation_provider.dart';

void showWorkoutDetailSheet(
  BuildContext context, {
  SplitWorkoutDay? initialDay,
  DateTime? date,
  List<WorkoutModel> loggedWorkouts = const [],
}) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WorkoutDetailContent(
      initialDay: initialDay,
      date: date,
      logged: loggedWorkouts,
    ),
  );
}

class _WorkoutDetailContent extends ConsumerStatefulWidget {
  const _WorkoutDetailContent({
    this.initialDay,
    this.date,
    required this.logged,
  });
  final SplitWorkoutDay? initialDay;
  final DateTime? date;
  final List<WorkoutModel> logged;
  @override
  ConsumerState<_WorkoutDetailContent> createState() =>
      _WorkoutDetailContentState();
}

class _WorkoutDetailContentState extends ConsumerState<_WorkoutDetailContent> {
  SplitWorkoutDay? _selected;
  @override
  void initState() {
    super.initState();
    _selected = widget.initialDay;
  }

  @override
  Widget build(BuildContext context) {
    final rotation = ref.watch(workoutRotationProvider);
    final day = _selected ?? rotation.selectedDay;
    final past =
        widget.date != null &&
        DateUtils.dateOnly(
          widget.date!,
        ).isBefore(DateUtils.dateOnly(DateTime.now()));
    final active = ref.watch(activeSessionProvider.select((s) => s.isActive));
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.sizeOf(context).height * .88,
        decoration: const BoxDecoration(
          color: AppColors.onyx,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.date == null
                          ? 'WORKOUT PREVIEW'
                          : MaterialLocalizations.of(
                              context,
                            ).formatFullDate(widget.date!),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.platinum,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close preview',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  if (past) ...[
                    Text(
                      widget.logged.isEmpty
                          ? 'No workout logged'
                          : 'Completed workouts',
                      style: AppTypography.headlineSmall.copyWith(
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final workout in widget.logged)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workout.name,
                                style: AppTypography.headlineSmall,
                              ),
                              const SizedBox(height: 12),
                              for (final exercise in workout.exercises)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(exercise.exerciseName),
                                  subtitle: Text(
                                    '${exercise.sets.length} sets · ${exercise.sets.map((s) => '${s.weightKg} kg × ${s.reps}').join(', ')}',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ] else ...[
                    Text(
                      day.name,
                      style: AppTypography.headlineSmall.copyWith(
                        fontSize: 25,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${day.exercises.length} exercises · ${day.totalSets} sets · ~${day.estimatedDurationMinutes} min',
                      style: AppTypography.monoSmall.copyWith(
                        color: AppColors.platinum,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.date == null ||
                        DateUtils.isSameDay(widget.date, DateTime.now()))
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: rotation.split.workouts.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final item = rotation.split.workouts[i];
                            return ChoiceChip(
                              label: Text(item.name),
                              selected: day.id == item.id,
                              onSelected: (_) =>
                                  setState(() => _selected = item),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (day.exercises.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          day.isRestDay
                              ? 'Recovery day. Choose a different day to train.'
                              : 'Add exercises to this day in the routine editor.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.platinum,
                          ),
                        ),
                      ),
                    for (var i = 0; i < day.exercises.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          border: false,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i + 1}'.padLeft(2, '0'),
                                style: AppTypography.monoSmall.copyWith(
                                  color: AppColors.platinum,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      day.exercises[i].exerciseName,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${day.exercises[i].targetSets} sets × ${day.exercises[i].repRange} reps · ${day.exercises[i].restSeconds}s rest',
                                      style: AppTypography.monoSmall.copyWith(
                                        color: AppColors.platinum,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (!past)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => showCreateRoutineSheet(
                        context,
                        initialSplit: rotation.split,
                        initialDayId: day.id,
                      ),
                      child: const Text('EDIT'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: day.isRestDay && !active
                            ? null
                            : () {
                                final router = GoRouter.of(context);
                                ref
                                    .read(activeSessionProvider.notifier)
                                    .startSession(
                                      splitName:
                                          '${rotation.split.shortName} · ${day.name}',
                                      initialExercises: day.exercises
                                          .map((e) => e.toActiveExerciseState())
                                          .toList(),
                                    );
                                Navigator.pop(context);
                                router.push(AppConstants.routeWorkoutSession);
                              },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: Text(
                          active ? 'RESUME WORKOUT' : 'START WORKOUT',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
