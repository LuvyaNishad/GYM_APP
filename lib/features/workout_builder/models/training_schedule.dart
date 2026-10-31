import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../models/workout_model.dart';
import 'split_model.dart';
import 'workout_sequence.dart';

DateTime scheduleDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// A dated copy of the plan. Later split switches/edits cannot rewrite past days.
@immutable
class TrainingSchedule {
  TrainingSchedule({
    required this.splitId,
    required DateTime startedOn,
    required List<bool> trainingDays,
    this.startIndex = 0,
    this.isPaused = false,
    DateTime? historyStartedOn,
  }) : startedOn = scheduleDate(startedOn),
       historyStartedOn = scheduleDate(historyStartedOn ?? startedOn),
       trainingDays = List.unmodifiable(trainingDays);

  factory TrainingSchedule.fromSplit(
    TrainingSplitModel split,
    DateTime startedOn, {
    int startIndex = 0,
    bool isPaused = false,
    DateTime? historyStartedOn,
  }) {
    final explicitRecovery = split.workouts.any((day) => day.isRestDay);
    // Workout-only routines use their weekly target; remaining days are rest.
    final days = split.workouts.isEmpty
        ? <bool>[]
        : explicitRecovery
        ? split.workouts.map((day) => !day.isRestDay).toList()
        : List.generate(7, (index) => index < split.daysPerWeek.clamp(1, 7));
    return TrainingSchedule(
      splitId: split.id,
      startedOn: startedOn,
      trainingDays: days,
      startIndex: startIndex,
      isPaused: isPaused,
      historyStartedOn: historyStartedOn,
    );
  }

  final String splitId;
  final DateTime startedOn;
  final List<bool> trainingDays;
  final int startIndex;
  final bool isPaused;

  /// Pausing changes dates, but keeps the last completed day in this plan.
  final DateTime historyStartedOn;

  bool isTrainingDay(DateTime date) {
    final day = scheduleDate(date);
    if (isPaused || day.isBefore(startedOn) || trainingDays.isEmpty) {
      return false;
    }
    final offset = DateTime.utc(day.year, day.month, day.day)
        .difference(
          DateTime.utc(startedOn.year, startedOn.month, startedOn.day),
        )
        .inDays;
    return trainingDays[(startIndex + offset) % trainingDays.length];
  }

  /// Count planned sessions between dates, without advancing over rest days.
  int trainingDaysBetween(DateTime start, DateTime end) {
    if (isPaused || trainingDays.isEmpty) return 0;
    final first = scheduleDate(start).isBefore(startedOn)
        ? startedOn
        : scheduleDate(start);
    final count = workoutDateDifference(end, first);
    if (count <= 0) return 0;
    final offset = workoutDateDifference(first, startedOn);
    final cycles = count ~/ trainingDays.length;
    var total = cycles * trainingDays.where((day) => day).length;
    for (var i = 0; i < count % trainingDays.length; i++) {
      if (trainingDays[(startIndex + offset + i) % trainingDays.length]) {
        total++;
      }
    }
    return total;
  }

  Map<String, Object> toJson() => {
    'splitId': splitId,
    'startedOn': startedOn.toIso8601String(),
    'trainingDays': trainingDays,
    'startIndex': startIndex,
    'isPaused': isPaused,
    'historyStartedOn': historyStartedOn.toIso8601String(),
  };

  static List<TrainingSchedule> decode(String? raw) {
    if (raw == null) return [];
    try {
      final schedules =
          (jsonDecode(raw) as List)
              .map(
                (entry) => TrainingSchedule(
                  splitId: entry['splitId'] as String,
                  startedOn: DateTime.parse(entry['startedOn'] as String),
                  trainingDays: (entry['trainingDays'] as List).cast<bool>(),
                  startIndex: (entry['startIndex'] as num?)?.toInt() ?? 0,
                  isPaused: entry['isPaused'] as bool? ?? false,
                  historyStartedOn: entry['historyStartedOn'] == null
                      ? null
                      : DateTime.parse(entry['historyStartedOn'] as String),
                ),
              )
              .toList()
            ..sort((a, b) => a.startedOn.compareTo(b.startedOn));
      return schedules;
    } catch (_) {
      return [];
    }
  }

  static String encode(List<TrainingSchedule> schedules) =>
      jsonEncode(schedules.map((s) => s.toJson()).toList());

  /// Older installs did not record activation dates. Begin at the first actual
  /// workout, or today if there is no history; never invent earlier missed days.
  static TrainingSchedule fromLegacy(
    TrainingSplitModel split,
    List<WorkoutModel> history,
    DateTime today,
  ) {
    final completed =
        history
            .where((workout) => !scheduleDate(workout.date).isAfter(today))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final first = completed.firstOrNull;
    final index = first == null ? -1 : matchWorkoutDay(split, first);
    return TrainingSchedule.fromSplit(
      split,
      first?.date ?? today,
      startIndex: index < 0 ? 0 : index,
    );
  }
}

/// Resolve a date in the current plan from logs recorded on or before it.
/// Earlier plan snapshots remain untouched after a split switch or rest edit.
SplitWorkoutDay? loggedScheduleDay({
  required TrainingSplitModel split,
  required List<TrainingSchedule> schedules,
  required List<WorkoutModel> history,
  required DateTime date,
}) {
  if (split.workouts.isEmpty || !split.workouts.any((day) => day.isRestDay)) {
    return null;
  }
  final active = trainingScheduleForDate(schedules, date);
  if (active != null && (active.isPaused || active.splitId != split.id)) {
    return null;
  }
  if (active == null && schedules.isNotEmpty) return null;
  final completed = latestCompletedSplitDay(
    split,
    history,
    date,
    since: active?.historyStartedOn,
  );
  if (completed == null) return null;
  final index = workoutDateDifference(date, completed.workout.date) == 0
      ? completed.index
      : nextWorkoutDayIndex(split, completed, date);
  return split.workouts[index];
}

TrainingSchedule? trainingScheduleForDate(
  List<TrainingSchedule> schedules,
  DateTime date,
) {
  final day = scheduleDate(date);
  for (final schedule in schedules.reversed) {
    if (!schedule.startedOn.isAfter(day)) return schedule;
  }
  return null;
}

bool isScheduledTrainingDay(List<TrainingSchedule> schedules, DateTime date) =>
    trainingScheduleForDate(schedules, date)?.isTrainingDay(date) ?? false;

DateTime? trainingResumeDate(List<TrainingSchedule> schedules, DateTime today) {
  if (trainingScheduleForDate(schedules, today)?.isPaused != true) return null;
  return schedules
      .where(
        (schedule) => schedule.startedOn.isAfter(today) && !schedule.isPaused,
      )
      .firstOrNull
      ?.startedOn;
}

List<TrainingSchedule> startTrainingSchedule(
  List<TrainingSchedule> schedules,
  TrainingSplitModel split,
  DateTime date,
) {
  // Switching or editing a routine must not silently end a training break.
  final active = trainingScheduleForDate(schedules, date);
  final paused = active?.isPaused == true;
  final resumeOn = paused ? trainingResumeDate(schedules, date) : null;
  final historyStart = paused && active?.splitId == split.id
      ? active?.historyStartedOn
      : null;
  return [
    ...schedules.where(
      (schedule) => schedule.startedOn.isBefore(scheduleDate(date)),
    ),
    TrainingSchedule.fromSplit(
      split,
      date,
      isPaused: paused,
      historyStartedOn: historyStart,
    ),
    if (resumeOn != null)
      TrainingSchedule.fromSplit(
        split,
        resumeOn,
        historyStartedOn: historyStart ?? date,
      ),
  ];
}
