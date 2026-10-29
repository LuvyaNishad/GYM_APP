import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/daily_steps_platform.dart';
import '../../../services/pedometer_service.dart';
import '../models/daily_telemetry_model.dart';
import 'habit_log_provider.dart';

typedef StepHistoryRange = ({int days, int page});

@immutable
class StepHistory {
  StepHistory({
    required this.start,
    required List<int?> values,
    required this.page,
    required this.lastPage,
  }) : values = List.unmodifiable(values);

  factory StepHistory.fromTotals({
    required int steps,
    required Map<String, int> history,
    required DateTime now,
    required StepHistoryRange range,
    required bool unavailable,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    var first = today;
    if (range.days == 0) {
      for (final key in history.keys) {
        if (!DailyStepsSnapshot.validDate(key)) continue;
        final date = DateTime.parse(key);
        if (date.isBefore(first)) first = date;
      }
    }
    // All history stays available in 30-day windows, with at most 30 painted bars.
    final lastPage = range.days == 0 ? _dayDifference(today, first) ~/ 30 : 0;
    final page = range.page.clamp(0, lastPage);
    final end = DateTime(today.year, today.month, today.day - page * 30);
    var start = DateTime(
      end.year,
      end.month,
      end.day - (range.days == 0 ? 30 : range.days) + 1,
    );
    if (range.days == 0 && start.isBefore(first)) start = first;
    final count = _dayDifference(end, start) + 1;
    return StepHistory(
      start: start,
      page: page,
      lastPage: lastPage,
      values: List.generate(count, (i) {
        final date = DateTime(start.year, start.month, start.day + i);
        return date == today
            ? (unavailable ? null : steps)
            : history[habitDateKey(date)];
      }),
    );
  }

  final DateTime start;
  final List<int?> values;
  final int page, lastPage;
  DateTime dateAt(int index) =>
      DateTime(start.year, start.month, start.day + index);
  bool get hasData => values.any((value) => value != null);

  @override
  bool operator ==(Object other) =>
      other is StepHistory &&
      start == other.start &&
      page == other.page &&
      lastPage == other.lastPage &&
      listEquals(values, other.values);
  @override
  int get hashCode =>
      Object.hash(start, page, lastPage, Object.hashAll(values));
}

int _dayDifference(DateTime later, DateTime earlier) => DateTime.utc(
  later.year,
  later.month,
  later.day,
).difference(DateTime.utc(earlier.year, earlier.month, earlier.day)).inDays;

/// The chart's history and rollover timer exist only while Steps is opened.
final stepHistoryProvider = Provider.autoDispose
    .family<StepHistory, StepHistoryRange>((ref, range) {
      final now = DateTime.now();
      final timer = Timer(
        DateTime(now.year, now.month, now.day + 1).difference(now),
        ref.invalidateSelf,
      );
      ref.onDispose(timer.cancel);
      final totals = ref.watch(
        dailyTelemetryProvider.select(
          (data) => (steps: data.steps, history: data.historicalDays),
        ),
      );
      final status = ref.watch(stepTrackingStatusProvider);
      final hasSavedToday = ref.watch(
        stepSyncInfoProvider.select(
          (sync) =>
              sync.updatedAt != null &&
              habitDateKey(sync.updatedAt!.toLocal()) == habitDateKey(now),
        ),
      );
      final unavailable =
          status == StepTrackingStatus.permissionDenied ||
          status == StepTrackingStatus.sensorUnavailable ||
          (status == StepTrackingStatus.syncFailed && !hasSavedToday);
      return StepHistory.fromTotals(
        steps: totals.steps,
        history: totals.history,
        now: now,
        range: range,
        unavailable: unavailable,
      );
    });
