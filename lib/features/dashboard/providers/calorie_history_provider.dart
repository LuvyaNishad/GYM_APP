import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'habit_log_provider.dart';

/// A daily active-calorie series. An absent entry is not a measured zero.
@immutable
class CalorieHistory {
  CalorieHistory({required this.start, required List<int?> values})
    : values = List.unmodifiable(values);

  factory CalorieHistory.fromLog(HabitLog log, DateTime now, int days) {
    final start = DateTime(now.year, now.month, now.day - days + 1);
    return CalorieHistory(
      start: start,
      values: List.generate(days, (index) {
        final day = DateTime(start.year, start.month, start.day + index);
        final calories = log.days[habitDateKey(day)]?.calories;
        return calories != null && calories > 0 ? calories : null;
      }),
    );
  }

  final DateTime start;
  final List<int?> values;
  DateTime dateAt(int index) =>
      DateTime(start.year, start.month, start.day + index);
  bool get hasData => values.any((value) => value != null);
  int get peak =>
      values.fold(0, (peak, value) => (value ?? 0) > peak ? value! : peak);

  @override
  bool operator ==(Object other) =>
      other is CalorieHistory &&
      start == other.start &&
      listEquals(values, other.values);
  @override
  int get hashCode => Object.hash(start, Object.hashAll(values));
}

/// Created only by the opened Calories sheet, and released when it closes.
/// Water, sleep, steps and goal edits do not rebuild the calorie series.
final calorieHistoryProvider = Provider.autoDispose.family<CalorieHistory, int>(
  (ref, days) {
    final now = DateTime.now();
    final midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      ref.invalidateSelf,
    );
    ref.onDispose(midnight.cancel);
    return ref.watch(
      habitLogProvider.select((log) => CalorieHistory.fromLog(log, now, days)),
    );
  },
);
