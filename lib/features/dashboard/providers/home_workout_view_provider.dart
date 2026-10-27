import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/workout_model.dart';
import '../../../core/providers/local_date_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../workout_builder/models/split_model.dart';
import 'workout_rotation_provider.dart';

/// One source of truth for the date card, its preview and its start action.
class HomeWorkoutView {
  const HomeWorkoutView({
    required this.date,
    required this.day,
    required this.logged,
    required this.isToday,
    required this.isPast,
  });
  final DateTime date;
  final SplitWorkoutDay? day;
  final List<WorkoutModel> logged;
  final bool isToday;
  final bool isPast;
}

final homeWorkoutViewProvider = Provider<HomeWorkoutView>((ref) {
  final now = ref.watch(localDateProvider);
  final date = DateUtils.dateOnly(
    ref.watch(selectedCalendarDateProvider) ?? now,
  );
  final rotation = ref.watch(workoutRotationProvider);
  final logged = ref
      .watch(historyWorkoutsProvider)
      .where((w) => DateUtils.isSameDay(w.date, date))
      .toList();
  final isPast = date.isBefore(now);
  final days = rotation.split.workouts;
  final offset = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  final planned = isPast
      ? null
      : days.isEmpty
      ? rotation.selectedDay
      : days[(rotation.dayIndex + offset) % days.length];
  return HomeWorkoutView(
    date: date,
    day: planned,
    logged: logged,
    isToday: date == now,
    isPast: isPast,
  );
});
