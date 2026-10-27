/// Daily telemetry metrics model for the LEON dashboard bento grid.
///
/// Encapsulates daily health data: steps, hourly activity distribution,
/// calorie burn/consumption, hydration intake, and goal milestones.
library;

import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/hive_service.dart';
import '../providers/habit_log_provider.dart';

/// Daily telemetry data points for the dashboard bento grid.

class DailyTelemetry {
  const DailyTelemetry({
    this.steps = 0,
    this.stepsGoal = 8000,
    this.distanceKm = 0.0,
    this.calories = 0,
    this.caloriesGoal = 3000,
    this.waterMl = 0,
    this.waterGoalMl = 3500,
    this.sleepHours = 0.0,
    this.sleepGoalHours = 8.0,
    this.hourlySteps = const [],
    this.historicalDays = const {},
    this.recordSingleDaySteps = 0,
    this.recordSingleDayKm = 0.0,
    this.recordDate = '--',
  });

  /// Total steps taken today.
  final int steps;

  /// Daily step target.
  final int stepsGoal;

  /// Approximate walking/running distance in kilometers.
  final double distanceKm;

  /// Calories burned / tracked today.
  final int calories;

  /// Daily calorie target.
  final int caloriesGoal;

  /// Water drank today in milliliters.
  final int waterMl;

  /// Daily water target in milliliters.
  final int waterGoalMl;

  /// Sleep logged last night in hours (e.g. 7.5).
  final double sleepHours;

  /// Daily sleep target in hours.
  final double sleepGoalHours;

  /// Hourly steps distribution across active daytime hours (e.g. 08:00 - 20:00).
  final List<int> hourlySteps;

  /// Historical daily step counts from built-in phone tracker.
  final Map<String, int> historicalDays;

  /// All-time single day step record from built-in phone tracker.
  final int recordSingleDaySteps;

  /// All-time single day distance record in km.
  final double recordSingleDayKm;

  /// Date when the record was achieved.
  final String recordDate;

  /// Progress fraction for steps (0.0 to 1.0+).
  double get stepsProgress => (steps / stepsGoal).clamp(0.0, 1.0);

  /// Progress fraction for calories (0.0 to 1.0+).
  double get caloriesProgress => (calories / caloriesGoal).clamp(0.0, 1.0);

  /// Progress fraction for water (0.0 to 1.0+).
  double get waterProgress => (waterMl / waterGoalMl).clamp(0.0, 1.0);

  /// Progress fraction for sleep (0.0 to 1.0+).
  double get sleepProgress => (sleepHours / sleepGoalHours).clamp(0.0, 1.0);

  DailyTelemetry copyWith({
    int? steps,
    int? stepsGoal,
    double? distanceKm,
    int? calories,
    int? caloriesGoal,
    int? waterMl,
    int? waterGoalMl,
    double? sleepHours,
    double? sleepGoalHours,
    List<int>? hourlySteps,
    Map<String, int>? historicalDays,
    int? recordSingleDaySteps,
    double? recordSingleDayKm,
    String? recordDate,
  }) {
    return DailyTelemetry(
      steps: steps ?? this.steps,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      distanceKm: distanceKm ?? this.distanceKm,
      calories: calories ?? this.calories,
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      waterMl: waterMl ?? this.waterMl,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
      hourlySteps: hourlySteps ?? this.hourlySteps,
      historicalDays: historicalDays ?? this.historicalDays,
      recordSingleDaySteps: recordSingleDaySteps ?? this.recordSingleDaySteps,
      recordSingleDayKm: recordSingleDayKm ?? this.recordSingleDayKm,
      recordDate: recordDate ?? this.recordDate,
    );
  }
}

/// Global provider for daily telemetry stats in the dashboard bento grid.
class DailyTelemetryNotifier extends Notifier<DailyTelemetry> {
  @override
  DailyTelemetry build() {
    final hive = ref.watch(hiveServiceProvider);
    final now = DateTime.now();
    final habits = ref.watch(habitLogProvider);
    final today = habits.day(now);
    final rollover = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      ref.invalidateSelf,
    );
    ref.onDispose(rollover.cancel);
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final savedDate = hive.getSetting<String>(AppConstants.settingStepDate);

    int todaySteps = 0;
    List<int> hourlySteps = List<int>.filled(24, 0);
    Map<String, int> history = {};

    final historyRaw = hive.getSetting<String>(AppConstants.settingStepHistory);
    if (historyRaw != null && historyRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(historyRaw) as Map<String, dynamic>;
        history = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {}
    }

    int recordSteps =
        hive.getSetting<int>(
          AppConstants.settingStepRecordSteps,
          fallback: 0,
        ) ??
        0;
    String recordDate =
        hive.getSetting<String>(
          AppConstants.settingStepRecordDate,
          fallback: '--',
        ) ??
        '--';

    if (savedDate == todayStr) {
      todaySteps =
          hive.getSetting<int>(
            AppConstants.settingStepTodayCount,
            fallback: 0,
          ) ??
          0;
      final hourlyRaw = hive.getSetting<String>(
        AppConstants.settingStepHourlyDistribution,
      );
      if (hourlyRaw != null && hourlyRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(hourlyRaw) as List<dynamic>;
          hourlySteps = decoded.map((e) => (e as num).toInt()).toList();
          if (hourlySteps.length != 24) {
            hourlySteps = List<int>.filled(24, 0);
          }
        } catch (_) {}
      }
    } else if (savedDate != null) {
      // Midnight rollover if previous day's steps were not archived yet
      final prevSteps =
          hive.getSetting<int>(
            AppConstants.settingStepTodayCount,
            fallback: 0,
          ) ??
          0;
      if (prevSteps > 0) {
        history[savedDate] = prevSteps;
        if (prevSteps > recordSteps) {
          recordSteps = prevSteps;
          try {
            final parts = savedDate.split('-');
            recordDate = '${parts[2]}/${parts[1]}/${parts[0]}';
          } catch (_) {
            recordDate = savedDate;
          }
        }
      }
    }

    final distanceKm = double.parse((todaySteps * 0.000708).toStringAsFixed(2));
    final recordKm = double.parse((recordSteps * 0.000708).toStringAsFixed(2));

    return DailyTelemetry(
      waterMl: today.waterMl,
      waterGoalMl: habits.waterGoalMl,
      sleepHours: today.sleepHours,
      sleepGoalHours: habits.sleepGoalHours,
      calories: today.calories,
      stepsGoal: habits.stepsGoal,
      steps: todaySteps,
      distanceKm: distanceKm,
      hourlySteps: hourlySteps,
      historicalDays: history,
      recordSingleDaySteps: recordSteps,
      recordSingleDayKm: recordKm,
      recordDate: recordDate,
    );
  }

  void updateDailyStepTelemetry({
    required int steps,
    required double distanceKm,
    required List<int> hourlySteps,
    required Map<String, int> historicalDays,
    required int recordSingleDaySteps,
    required double recordSingleDayKm,
    required String recordDate,
  }) {
    state = state.copyWith(
      steps: steps,
      distanceKm: distanceKm,
      hourlySteps: hourlySteps,
      historicalDays: historicalDays,
      recordSingleDaySteps: recordSingleDaySteps,
      recordSingleDayKm: recordSingleDayKm,
      recordDate: recordDate,
    );
  }

  void updateSteps(int steps, double distanceKm) {
    state = state.copyWith(steps: steps, distanceKm: distanceKm);
  }

  Future<void> logWater(int additionalMl) => additionalMl < 0
      ? ref.read(habitLogProvider.notifier).undoWater()
      : ref.read(habitLogProvider.notifier).addWater(additionalMl);

  Future<void> logCalories(int additionalCalories) =>
      ref.read(habitLogProvider.notifier).addCalories(additionalCalories);

  Future<void> updateSleep(double hours) => ref
      .read(habitLogProvider.notifier)
      .saveSleep(date: DateTime.now(), hours: hours);

  Future<void> updateSleepGoal(double goalHours) =>
      ref.read(habitLogProvider.notifier).setGoals(sleepHours: goalHours);

  Future<void> updateStepsGoal(int goalSteps) =>
      ref.read(habitLogProvider.notifier).setGoals(steps: goalSteps);
}

final dailyTelemetryProvider =
    NotifierProvider<DailyTelemetryNotifier, DailyTelemetry>(
      DailyTelemetryNotifier.new,
    );
