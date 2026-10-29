import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../models/workout_model.dart';
import 'split_model.dart';

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
  }) : startedOn = scheduleDate(startedOn),
       trainingDays = List.unmodifiable(trainingDays);

  factory TrainingSchedule.fromSplit(
    TrainingSplitModel split,
    DateTime startedOn, {
    int startIndex = 0,
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
    );
  }

  final String splitId;
  final DateTime startedOn;
  final List<bool> trainingDays;
  final int startIndex;

  bool isTrainingDay(DateTime date) {
    final day = scheduleDate(date);
    if (day.isBefore(startedOn) || trainingDays.isEmpty) return false;
    final offset = DateTime.utc(day.year, day.month, day.day)
        .difference(
          DateTime.utc(startedOn.year, startedOn.month, startedOn.day),
        )
        .inDays;
    return trainingDays[(startIndex + offset) % trainingDays.length];
  }

  Map<String, Object> toJson() => {
    'splitId': splitId,
    'startedOn': startedOn.toIso8601String(),
    'trainingDays': trainingDays,
    'startIndex': startIndex,
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
    final name = first?.name
        .toLowerCase()
        .split(RegExp(r'\s*[●•]|\s*//\s*'))
        .last
        .trim();
    final index = split.workouts.indexWhere(
      (day) =>
          day.name.toLowerCase().trim() == name || day.id.toLowerCase() == name,
    );
    return TrainingSchedule.fromSplit(
      split,
      first?.date ?? today,
      startIndex: index < 0 ? 0 : index,
    );
  }
}

bool isScheduledTrainingDay(List<TrainingSchedule> schedules, DateTime date) {
  final day = scheduleDate(date);
  for (final schedule in schedules.reversed) {
    if (!schedule.startedOn.isAfter(day)) return schedule.isTrainingDay(day);
  }
  return false;
}

List<TrainingSchedule> startTrainingSchedule(
  List<TrainingSchedule> schedules,
  TrainingSplitModel split,
  DateTime date,
) => [
  ...schedules.where(
    (schedule) => schedule.startedOn.isBefore(scheduleDate(date)),
  ),
  TrainingSchedule.fromSplit(split, date),
];
