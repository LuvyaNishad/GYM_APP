/// Smart Workout Auto-Rotation Provider for LEON.
///
/// Intelligently resolves today's workout day based on completed workout history:
/// - If the lifter completed Pull Day yesterday, automatically queues Legs Day today.
/// - If Legs Day was completed, automatically queues Push Day.
/// - If the lifter already finished a workout today, marks it completed and shows next up.
/// - Allows rapid day swapping if the user wants to rotate or do a different session today.
/// - Pre-loads the exact planned exercises and sets directly into the active workout session.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/workout_model.dart';
import '../../history/providers/history_provider.dart';
import '../../workout_builder/models/split_model.dart';
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

  /// Whether the user manually chose a different day than what was auto-recommended.
  bool get isManuallyOverridden => dayIndex != recommendedIndex;

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
    );
  }
}

class WorkoutRotationNotifier extends Notifier<WorkoutRotationState> {
  int? _manualSelectedIndex;

  @override
  WorkoutRotationState build() {
    ref.keepAlive();

    final splitsState = ref.watch(splitsProvider);
    final historyWorkouts = ref.watch(historyWorkoutsProvider);

    final split = splitsState.activeSplit;
    final workouts = split.workouts;

    if (workouts.isEmpty) {
      const fallback = SplitWorkoutDay(
        id: 'fallback_push',
        name: 'Push Day // Workout A',
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
      );
    }

    WorkoutModel? lastW;
    DateTime? lastDate;
    bool isToday = false;
    int matchedIndex = -1;

    if (historyWorkouts.isNotEmpty) {
      lastW = historyWorkouts.first;
      lastDate = lastW.date;
      final now = DateTime.now();
      isToday = (lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day);

      // 1. Direct name / ID match against active split's workouts
      final lastTitle = lastW.name.toLowerCase();
      for (int i = 0; i < workouts.length; i++) {
        final w = workouts[i];
        final wName = w.name.toLowerCase();
        final wId = w.id.toLowerCase();
        if (lastTitle.contains(wId) ||
            lastTitle.contains(wName) ||
            (lastTitle.contains('push') && wName.contains('push')) ||
            (lastTitle.contains('pull') && wName.contains('pull')) ||
            (lastTitle.contains('leg') && wName.contains('leg')) ||
            (lastTitle.contains('upper') && wName.contains('upper')) ||
            (lastTitle.contains('lower') && wName.contains('lower'))) {
          matchedIndex = i;
          break;
        }
      }

      // 2. If no direct title match, infer from dominant muscle group
      if (matchedIndex == -1 && lastW.exercises.isNotEmpty) {
        final muscleCounts = <String, int>{};
        for (final ex in lastW.exercises) {
          final m = ex.muscleGroup.toLowerCase();
          muscleCounts[m] = (muscleCounts[m] ?? 0) + 1;
        }
        String topMuscle = '';
        int maxCount = 0;
        muscleCounts.forEach((k, v) {
          if (v > maxCount) {
            maxCount = v;
            topMuscle = k;
          }
        });

        for (int i = 0; i < workouts.length; i++) {
          final w = workouts[i];
          final targets =
              w.targetMuscles.map((m) => m.toLowerCase()).toList();
          if (targets.any((t) => t.contains(topMuscle) || topMuscle.contains(t))) {
            matchedIndex = i;
            break;
          }
        }
      }
    }

    int recommendedIndex = 0;
    String reason = '';

    if (matchedIndex != -1 && lastW != null) {
      final nextIdx = (matchedIndex + 1) % workouts.length;
      recommendedIndex = nextIdx;
      final lastDayName = workouts[matchedIndex].name;
      final nextDayName = workouts[nextIdx].name;

      if (isToday) {
        reason = 'Completed $lastDayName today • Next up: $nextDayName';
      } else {
        final daysAgo = DateTime.now().difference(lastDate!).inDays;
        if (daysAgo <= 1) {
          reason = 'Following $lastDayName yesterday • $nextDayName is next in rotation';
        } else {
          reason = 'Following $lastDayName ($daysAgo days ago) • Pick up with $nextDayName';
        }
      }
    } else {
      recommendedIndex = 0;
      reason = 'Starting rotation with ${workouts.first.name}';
    }

    final effectiveIndex = (_manualSelectedIndex != null &&
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
    final day = state.selectedDay;
    final activeExercises =
        day.exercises.map((e) => e.toActiveExerciseState()).toList();

    ref.read(activeSessionProvider.notifier).startSession(
          splitName: '${state.split.shortName} // ${day.name.toUpperCase()}',
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
