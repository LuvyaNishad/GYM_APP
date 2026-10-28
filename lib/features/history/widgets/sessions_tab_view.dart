import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../dashboard/providers/workout_rotation_provider.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../../workout_session/providers/active_session_provider.dart';
import '../providers/history_provider.dart';
import 'workout_history_card.dart';

class SessionsTabView extends ConsumerStatefulWidget {
  const SessionsTabView({super.key});

  @override
  ConsumerState<SessionsTabView> createState() => _SessionsTabViewState();
}

class _SessionsTabViewState extends ConsumerState<SessionsTabView> {
  String _selectedFilter = 'All';

  void _clearFilters() {
    setState(() => _selectedFilter = 'All');
    ref.read(selectedCalendarDateProvider.notifier).clear();
  }

  void _startWorkout() {
    if (ref.read(activeSessionProvider).isActive) {
      context.push(AppConstants.routeWorkoutSession);
      return;
    }
    final day = ref.read(workoutRotationProvider).selectedDay;
    final splits = ref.read(splitsProvider.notifier);
    if (day.isRestDay) {
      splits.startEmptyWorkout(context);
    } else {
      splits.startWorkoutFromDay(context, day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workouts = ref.watch(historyWorkoutsProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final hasActiveSession = ref.watch(
      activeSessionProvider.select((session) => session.isActive),
    );
    final dateLabel = selectedDate == null
        ? null
        : MaterialLocalizations.of(context).formatMediumDate(selectedDate);
    final filteredWorkouts = workouts.where((workout) {
      if (selectedDate != null &&
          !DateUtils.isSameDay(workout.date, selectedDate)) {
        return false;
      }
      return _selectedFilter == 'All' ||
          workout.name.toLowerCase().contains(
            _selectedFilter == 'Legs' ? 'leg' : _selectedFilter.toLowerCase(),
          );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedDate != null)
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(dateLabel!, style: AppTypography.dataLabel)),
              TextButton(
                onPressed: () =>
                    ref.read(selectedCalendarDateProvider.notifier).clear(),
                child: const Text('Clear date'),
              ),
            ],
          ),
        if (workouts.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in ['All', 'Push', 'Pull', 'Legs'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (_) =>
                          setState(() => _selectedFilter = filter),
                      selectedColor: AppColors.primary.withValues(alpha: 0.16),
                      checkmarkColor: AppColors.primary,
                      side: BorderSide.none,
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color: _selectedFilter == filter
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (filteredWorkouts.isEmpty)
          GlassCard(
            border: false,
            blur: true,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 28,
                    color: AppColors.platinum,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  workouts.isEmpty
                      ? 'Your training starts here'
                      : 'No matching workouts',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  workouts.isEmpty
                      ? 'Complete your first workout to see your sessions, strength progress and muscle balance here.'
                      : selectedDate != null
                      ? 'No ${_selectedFilter == 'All' ? '' : '${_selectedFilter.toLowerCase()} '}workouts logged on $dateLabel.'
                      : 'No ${_selectedFilter.toLowerCase()} workouts in your history yet.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (workouts.isEmpty) ...[
                  FilledButton.icon(
                    onPressed: _startWorkout,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      hasActiveSession ? 'Resume workout' : 'Start workout',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () =>
                        context.go(AppConstants.routeWorkoutBuilder),
                    child: const Text('Browse training splits'),
                  ),
                ] else
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('Show all workouts'),
                  ),
              ],
            ),
          )
        else
          for (final workout in filteredWorkouts)
            WorkoutHistoryCard(key: ValueKey(workout.id), workout: workout),
      ],
    );
  }
}
