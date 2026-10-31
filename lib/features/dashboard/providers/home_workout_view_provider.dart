import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/workout_model.dart';
import '../../../core/providers/local_date_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../workout_builder/models/split_model.dart';
import '../../workout_builder/models/training_schedule.dart';
import '../../workout_builder/providers/splits_provider.dart';
import 'workout_rotation_provider.dart';

const scheduledRestDay = SplitWorkoutDay(
  id: 'scheduled_rest',
  name: 'Rest day',
  targetMuscles: [],
  isRestDay: true,
);

/// One source of truth for the date card, its preview and its start action.
class HomeWorkoutView {
  const HomeWorkoutView({
    required this.date,
    required this.day,
    required this.logged,
    required this.isToday,
    required this.isPast,
    this.isPaused = false,
  });
  final DateTime date;
  final SplitWorkoutDay? day;
  final List<WorkoutModel> logged;
  final bool isToday;
  final bool isPast;
  final bool isPaused;
}

final homeWorkoutViewProvider = Provider<HomeWorkoutView>((ref) {
  final now = ref.watch(localDateProvider);
  final date = DateUtils.dateOnly(
    ref.watch(selectedCalendarDateProvider) ?? now,
  );
  final rotation = ref.watch(workoutRotationProvider);
  final history = ref.watch(historyWorkoutsProvider);
  final schedules = ref.watch(splitsProvider).schedules;
  final paused = trainingScheduleForDate(schedules, date)?.isPaused == true;
  final logged = history
      .where((w) => DateUtils.isSameDay(w.date, date))
      .toList();
  final isPast = date.isBefore(now);
  final pastDay = isPast && logged.isEmpty
      ? loggedScheduleDay(
          split: rotation.split,
          schedules: schedules,
          history: history,
          date: date,
        )
      : null;
  final weeklyRest =
      !isPast &&
      schedules.isNotEmpty &&
      !rotation.split.workouts.any((day) => day.isRestDay) &&
      !isScheduledTrainingDay(schedules, date) &&
      !(date == now && rotation.isManuallyOverridden);
  final planned = paused
      ? null
      : weeklyRest
      ? scheduledRestDay
      : isPast
      ? (pastDay?.isRestDay == true ? pastDay : null)
      : rotation.dayForDate(date, now);
  return HomeWorkoutView(
    date: date,
    day: planned,
    logged: logged,
    isToday: date == now,
    isPast: isPast,
    isPaused: paused,
  );
});
