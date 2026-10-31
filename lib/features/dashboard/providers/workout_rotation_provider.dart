/// Smart Workout Auto-Rotation Provider for LEON.
///
/// Intelligently resolves today's workout day based on completed workout history:
/// - If the lifter completed Pull Day yesterday, automatically queues Legs Day today.
/// - Preserves any recovery days after the completed workout.
/// - If the lifter already finished a workout today, marks it completed and shows next up.
/// - Allows rapid day swapping if the user wants to rotate or do a different session today.
/// - Pre-loads the exact planned exercises and sets directly into the active workout session.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/local_date_provider.dart';
import '../../../models/workout_model.dart';
import '../../history/providers/history_provider.dart';
import '../../workout_builder/models/split_model.dart';
import '../../workout_builder/models/training_schedule.dart';
import '../../workout_builder/models/workout_sequence.dart';
import '../../workout_builder/providers/splits_provider.dart';
import '../../workout_session/providers/active_session_provider.dart';

/// State of the daily workout rotation and recommendation.
@immutable
class WorkoutRotationState {
  const WorkoutRotationState({
    required this.selectedDay,
    required this.recommendedDay,
    required this.split,
    required this.dayIndex,
    required this.recommendedIndex,
    required this.totalDays,
    this.lastCompletedWorkout,
    this.lastCompletedDate,
    required this.isCompletedToday,
    required this.rotationReason,
    this.isTrainingPaused = false,
    this.resumeOn,
    this.resumeDayIndex = 0,
    this.schedule,
    this.resumeSchedule,
  });

  /// The workout day currently queued for today (can be manually selected or auto-recommended).
  final SplitWorkoutDay selectedDay;

  /// The automatically calculated next day based on workout history.
  final SplitWorkoutDay recommendedDay;

  /// The active training split (e.g. PPL, Upper/Lower).
  final TrainingSplitModel split;

  /// Index of the selected day in [split.workouts] (0-indexed).
  final int dayIndex;

  /// Index of the auto-recommended day in [split.workouts] (0-indexed).
  final int recommendedIndex;

  /// Total workout days in the split.
  final int totalDays;

  /// The most recent completed workout in history, if any.
  final WorkoutModel? lastCompletedWorkout;

  /// When the last workout occurred.
  final DateTime? lastCompletedDate;

  /// Whether a workout was already logged/completed today.
  final bool isCompletedToday;

  /// Human-readable explanation of why this workout is queued.
  final String rotationReason;
  final bool isTrainingPaused;
  final DateTime? resumeOn;
  final int resumeDayIndex;
  final TrainingSchedule? schedule;
  final TrainingSchedule? resumeSchedule;

  /// Whether the user manually chose a different day than what was auto-recommended.
  bool get isManuallyOverridden => dayIndex != recommendedIndex;

  /// Today's completed workout already advanced the queue to tomorrow.
  /// Future previews must not advance it a second time.
  SplitWorkoutDay dayForDate(DateTime date, DateTime today) {
    if (split.workouts.isEmpty) return selectedDay;
    if (isTrainingPaused && resumeOn != null && !date.isBefore(resumeOn!)) {
      final offset =
          !split.workouts.any((day) => day.isRestDay) && resumeSchedule != null
          ? resumeSchedule!.trainingDaysBetween(resumeOn!, date)
          : workoutDateDifference(date, resumeOn!);
      return split.workouts[(resumeDayIndex + offset) % split.workouts.length];
    }
    var offset = workoutDateDifference(date, today);
    if (offset > 0 &&
        !split.workouts.any((day) => day.isRestDay) &&
        schedule != null) {
      offset = schedule!.trainingDaysBetween(today, date);
    }
    if (offset > 0 &&
        !isManuallyOverridden &&
        lastCompletedDate != null &&
        workoutDateDifference(today, lastCompletedDate!) == 0) {
      offset--;
    }
    return split.workouts[(dayIndex + offset) % split.workouts.length];
  }

  WorkoutRotationState copyWith({
    SplitWorkoutDay? selectedDay,
    SplitWorkoutDay? recommendedDay,
    TrainingSplitModel? split,
    int? dayIndex,
    int? recommendedIndex,
    int? totalDays,
    WorkoutModel? lastCompletedWorkout,
    DateTime? lastCompletedDate,
    bool? isCompletedToday,
    String? rotationReason,
  }) {
    return WorkoutRotationState(
      selectedDay: selectedDay ?? this.selectedDay,
      recommendedDay: recommendedDay ?? this.recommendedDay,
      split: split ?? this.split,
      dayIndex: dayIndex ?? this.dayIndex,
      recommendedIndex: recommendedIndex ?? this.recommendedIndex,
      totalDays: totalDays ?? this.totalDays,
      lastCompletedWorkout: lastCompletedWorkout ?? this.lastCompletedWorkout,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      rotationReason: rotationReason ?? this.rotationReason,
      isTrainingPaused: isTrainingPaused,
      resumeOn: resumeOn,
      resumeDayIndex: resumeDayIndex,
      schedule: schedule,
      resumeSchedule: resumeSchedule,
    );
  }
}

class WorkoutRotationNotifier extends Notifier<WorkoutRotationState> {
  int? _manualSelectedIndex;
  String? _lastSplitId;
  WorkoutModel? _lastCompletion;
  DateTime? _lastDate;
  TrainingSchedule? _lastSchedule;

  @override
  WorkoutRotationState build() {
    ref.keepAlive();

    final splitsState = ref.watch(splitsProvider);
    final historyWorkouts = ref.watch(historyWorkoutsProvider);
    final today = ref.watch(localDateProvider);

    final split = splitsState.activeSplit;
    final schedule = trainingScheduleForDate(splitsState.schedules, today);
    final paused = schedule?.isPaused == true;
    final resumeOn = trainingResumeDate(splitsState.schedules, today);
    if (_lastSplitId != split.id ||
        _lastDate != today ||
        _lastSchedule != schedule) {
      _manualSelectedIndex = null;
      _lastSplitId = split.id;
      _lastDate = today;
      _lastSchedule = schedule;
    }
    final workouts = split.workouts;

    if (workouts.isEmpty) {
      const fallback = SplitWorkoutDay(
        id: 'fallback_push',
        name: 'Push Day ● Workout A',
        subtitle: 'Chest & Shoulders',
        targetMuscles: ['Chest', 'Shoulders', 'Triceps'],
        estimatedDurationMinutes: 48,
      );
      return WorkoutRotationState(
        selectedDay: fallback,
        recommendedDay: fallback,
        split: split,
        dayIndex: 0,
        recommendedIndex: 0,
        totalDays: 1,
        isCompletedToday: false,
        rotationReason: 'Standard routine',
        isTrainingPaused: paused,
        resumeOn: resumeOn,
        schedule: schedule,
        resumeSchedule: resumeOn == null
            ? null
            : trainingScheduleForDate(splitsState.schedules, resumeOn),
      );
    }

    final latest = latestCompletedSplitDay(split, historyWorkouts, today);
    final lastW = latest?.workout;
    final lastDate = lastW?.date;
    final isToday = historyWorkouts.any(
      (workout) => workoutDateDifference(today, workout.date) == 0,
    );

    if (_lastCompletion != lastW) {
      _manualSelectedIndex = null;
      _lastCompletion = lastW;
    }

    int recommendedIndex = 0;
    String reason = '';

    if (latest != null) {
      final nextIdx = nextWorkoutDayIndex(split, latest, today);
      recommendedIndex = nextIdx;
      final lastDayName = workouts[latest.index].name;
      final nextDayName = workouts[nextIdx].name;

      if (workoutDateDifference(today, latest.workout.date) == 0) {
        reason = 'Completed $lastDayName today • Next up: $nextDayName';
      } else {
        final daysAgo = workoutDateDifference(today, latest.workout.date);
        if (daysAgo <= 1) {
          reason =
              'Following $lastDayName yesterday • $nextDayName is next in rotation';
        } else {
          reason =
              'Following $lastDayName ($daysAgo days ago) • Pick up with $nextDayName';
        }
      }
    } else {
      recommendedIndex = 0;
      reason = 'Starting rotation with ${workouts.first.name}';
    }

    final effectiveIndex =
        (_manualSelectedIndex != null &&
            _manualSelectedIndex! >= 0 &&
            _manualSelectedIndex! < workouts.length)
        ? _manualSelectedIndex!
        : recommendedIndex;

    return WorkoutRotationState(
      selectedDay: workouts[effectiveIndex],
      recommendedDay: workouts[recommendedIndex],
      split: split,
      dayIndex: effectiveIndex,
      recommendedIndex: recommendedIndex,
      totalDays: workouts.length,
      lastCompletedWorkout: lastW,
      lastCompletedDate: lastDate,
      isCompletedToday: isToday,
      rotationReason: reason,
      isTrainingPaused: paused,
      resumeOn: resumeOn,
      resumeDayIndex: resumeOn == null || latest == null
          ? 0
          : nextWorkoutDayIndex(split, latest, resumeOn),
      schedule: schedule,
      resumeSchedule: resumeOn == null
          ? null
          : trainingScheduleForDate(splitsState.schedules, resumeOn),
    );
  }

  /// Manually select a specific day from the split to perform today.
  void selectDay(SplitWorkoutDay day) {
    final workouts = state.split.workouts;
    final index = workouts.indexWhere((w) => w.id == day.id);
    if (index != -1) {
      selectDayByIndex(index);
    }
  }

  /// Select a specific day by its 0-based index in the split rotation.
  void selectDayByIndex(int index) {
    if (state.isTrainingPaused) return;
    if (index >= 0 && index < state.split.workouts.length) {
      _manualSelectedIndex = index;
      final selected = state.split.workouts[index];
      state = state.copyWith(
        selectedDay: selected,
        dayIndex: index,
        rotationReason: index == state.recommendedIndex
            ? state.rotationReason
            : 'Manually selected: ${selected.name}',
      );
    }
  }

  /// Cycles to the next day in the split rotation.
  void cycleNextDay() {
    final nextIdx = (state.dayIndex + 1) % state.totalDays;
    selectDayByIndex(nextIdx);
  }

  /// Resets back to the auto-recommended workout day.
  void resetToRecommended() {
    _manualSelectedIndex = null;
    state = state.copyWith(
      selectedDay: state.recommendedDay,
      dayIndex: state.recommendedIndex,
    );
  }

  /// Initiates the active workout session pre-populated with this day's planned exercises.
  void startWorkout(BuildContext context) {
    if (state.isTrainingPaused) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume training from Home before starting a workout.'),
        ),
      );
      return;
    }
    final day = state.selectedDay;
    final activeExercises = day.exercises
        .map((e) => e.toActiveExerciseState())
        .toList();

    ref
        .read(activeSessionProvider.notifier)
        .startSession(
          splitName: '${state.split.shortName} ● ${day.name.toUpperCase()}',
          initialExercises: activeExercises,
        );

    context.push(AppConstants.routeWorkoutSession);
  }
}

/// Global provider for smart workout auto-rotation.
final workoutRotationProvider =
    NotifierProvider<WorkoutRotationNotifier, WorkoutRotationState>(
      WorkoutRotationNotifier.new,
    );
