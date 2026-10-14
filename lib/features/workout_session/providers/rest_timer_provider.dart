import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/active_session_state.dart';
import '../services/live_activity_service.dart';
import '../services/notification_service.dart';

/// Provider managing the inter-set rest countdown timer with
/// Android Persistent Notifications & iOS Dynamic Island Live Activities.
class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _ticker;

  WorkoutNotificationService get _notifications =>
      ref.read(workoutNotificationServiceProvider);
  LiveActivityService get _liveActivity =>
      ref.read(liveActivityServiceProvider);

  @override
  RestTimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });

    // Wire up interactive action buttons from Android notification (+30s, Skip Rest)
    _notifications.onActionTapped = (actionId) {
      if (actionId == 'add_30') {
        addSeconds(30);
      } else if (actionId == 'skip_rest') {
        skip();
      }
    };

    return const RestTimerState();
  }

  /// Starts or resets the rest countdown with the given duration.
  void startTimer({
    required int durationSeconds,
    String? exerciseName,
    int? setNumber,
    int? totalSets,
    double? targetWeightKg,
    int? targetReps,
    String? plateBreakdown,
  }) {
    _ticker?.cancel();
    state = state.copyWith(
      totalDurationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      isRunning: true,
      exerciseName: exerciseName,
      setNumber: setNumber,
    );

    // Launch Android Foreground Persistent Notification
    _notifications.showRestTimerNotification(
      exerciseName: exerciseName ?? 'Exercise',
      setNumber: setNumber ?? 1,
      remainingSeconds: durationSeconds,
      totalDurationSeconds: durationSeconds,
    );

    // Launch iOS Live Activity & Dynamic Island
    _liveActivity.startLiveActivity(
      workoutTitle: "TODAY'S WORKOUT",
      exerciseName: exerciseName ?? 'Exercise',
      setNumber: setNumber ?? 1,
      totalSets: totalSets ?? 4,
      remainingSeconds: durationSeconds,
      totalDurationSeconds: durationSeconds,
      targetWeightKg: targetWeightKg ?? 0.0,
      targetReps: targetReps ?? 0,
      plateBreakdown: plateBreakdown ?? '',
      isResting: true,
    );

    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        final newRemaining = state.remainingSeconds - 1;
        state = state.copyWith(remainingSeconds: newRemaining);

        // Update persistent notification & Live Activity
        _notifications.showRestTimerNotification(
          exerciseName: state.exerciseName ?? 'Exercise',
          setNumber: state.setNumber ?? 1,
          remainingSeconds: newRemaining,
          totalDurationSeconds: state.totalDurationSeconds,
        );

        _liveActivity.updateLiveActivity(
          remainingSeconds: newRemaining,
          totalDurationSeconds: state.totalDurationSeconds,
          exerciseName: state.exerciseName ?? 'Exercise',
          setNumber: state.setNumber ?? 1,
          totalSets: 4,
          isResting: true,
        );
      } else {
        // Timer reached zero
        _ticker?.cancel();
        state = state.copyWith(remainingSeconds: 0, isRunning: false);

        // Fire high-priority rest completed alert notification
        _notifications.showRestCompletedNotification(
          exerciseName: state.exerciseName ?? 'Exercise',
          nextSetNumber: (state.setNumber ?? 1) + 1,
        );

        // Dismiss iOS Live Activity
        _liveActivity.stopLiveActivity();

        // Haptic & auditory alert notification when rest interval ends
        try {
          HapticFeedback.heavyImpact();
          SystemSound.play(SystemSoundType.alert);
        } catch (_) {}
      }
    });
  }

  /// Pauses the current countdown.
  void pause() {
    _ticker?.cancel();
    state = state.copyWith(isRunning: false);
    _notifications.cancelRestNotification();
  }

  /// Resumes countdown if time remains.
  void resume() {
    if (state.remainingSeconds > 0) {
      state = state.copyWith(isRunning: true);
      _notifications.showRestTimerNotification(
        exerciseName: state.exerciseName ?? 'Exercise',
        setNumber: state.setNumber ?? 1,
        remainingSeconds: state.remainingSeconds,
        totalDurationSeconds: state.totalDurationSeconds,
      );
      _startTicker();
    }
  }

  /// Adds an arbitrary number of seconds to the current rest interval.
  void addSeconds(int seconds) {
    final newSeconds = state.remainingSeconds + seconds;
    final newTotal = state.totalDurationSeconds < newSeconds
        ? newSeconds
        : state.totalDurationSeconds;
    state = state.copyWith(
      remainingSeconds: newSeconds,
      totalDurationSeconds: newTotal,
    );
    _notifications.showRestTimerNotification(
      exerciseName: state.exerciseName ?? 'Exercise',
      setNumber: state.setNumber ?? 1,
      remainingSeconds: newSeconds,
      totalDurationSeconds: newTotal,
    );
    if (!state.isRunning && state.remainingSeconds > 0) {
      resume();
    }
  }

  /// Adds 10 seconds to the current rest interval.
  void addTenSeconds() {
    addSeconds(10);
  }

  /// Adds 30 seconds to the current rest interval.
  void addThirtySeconds() {
    addSeconds(30);
  }

  /// Subtracts 10 seconds from the remaining rest interval (floor at 0).
  void subtractTenSeconds() {
    final newSeconds = (state.remainingSeconds - 10).clamp(0, 9999);
    state = state.copyWith(remainingSeconds: newSeconds);
    if (newSeconds == 0) {
      skip();
    } else {
      _notifications.showRestTimerNotification(
        exerciseName: state.exerciseName ?? 'Exercise',
        setNumber: state.setNumber ?? 1,
        remainingSeconds: newSeconds,
        totalDurationSeconds: state.totalDurationSeconds,
      );
    }
  }

  /// Skips the rest timer immediately (dismisses / finishes).
  void skip() {
    _ticker?.cancel();
    state = state.copyWith(
      remainingSeconds: 0,
      isRunning: false,
    );
    _notifications.cancelRestNotification();
    _liveActivity.stopLiveActivity();
  }

  /// Toggles whether completing a set automatically begins the rest timer.
  void toggleAutoStart() {
    state = state.copyWith(autoStart: !state.autoStart);
  }
}

final restTimerProvider =
    NotifierProvider<RestTimerNotifier, RestTimerState>(RestTimerNotifier.new);
