/// Daily telemetry metrics model for the LEON dashboard bento grid.
///
/// Encapsulates daily health data: steps, hourly activity distribution,
/// calorie burn/consumption, hydration intake, and goal milestones.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Daily telemetry data points for the dashboard bento grid.

class DailyTelemetry {
  const DailyTelemetry({
    this.steps = 5282,
    this.stepsGoal = 8000,
    this.distanceKm = 3.74,
    this.calories = 2390,
    this.caloriesGoal = 3000,
    this.waterMl = 2750,
    this.waterGoalMl = 3500,
    this.sleepHours = 7.5,
    this.sleepGoalHours = 8.0,
    this.hourlySteps = const [
      80, 190, 420, 680, 1150, 1680, 2450, 3120, 3950, 4480, 4920, 5282
    ],
    this.historicalDays = const {
      '30': 5000,
      '2': 5800,
      '4': 4700,
      '6': 3800,
      '8': 6500,
      '9': 8000,
      '10': 3200,
      '12': 1000,
      '13': 6200,
      '14': 5100,
      '15': 3500,
      'Today': 5282,
    },
    this.recordSingleDaySteps = 17024,
    this.recordSingleDayKm = 11.97,
    this.recordDate = '26/6/2026',
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
    return const DailyTelemetry();
  }

  void updateSteps(int steps, double distanceKm) {
    state = state.copyWith(steps: steps, distanceKm: distanceKm);
  }

  void logWater(int additionalMl) {
    state = state.copyWith(waterMl: state.waterMl + additionalMl);
  }

  void logCalories(int additionalCalories) {
    state = state.copyWith(calories: state.calories + additionalCalories);
  }

  void updateSleep(double hours) {
    state = state.copyWith(sleepHours: hours);
  }

  void updateSleepGoal(double goalHours) {
    state = state.copyWith(sleepGoalHours: goalHours);
  }

  void updateStepsGoal(int goalSteps) {
    state = state.copyWith(stepsGoal: goalSteps);
  }
}

final dailyTelemetryProvider =
    NotifierProvider<DailyTelemetryNotifier, DailyTelemetry>(
  DailyTelemetryNotifier.new,
);

