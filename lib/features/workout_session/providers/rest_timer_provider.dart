import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/active_session_state.dart';
import '../services/live_activity_service.dart';
import '../services/notification_service.dart';
import 'active_session_provider.dart';

/// Provider managing the inter-set rest countdown timer with
/// wall-clock timestamp synchronization, Android Persistent Notifications,
/// and iOS Dynamic Island Live Activities.
class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _ticker;
  AppLifecycleListener? _lifecycleListener;

  WorkoutNotificationService get _notifications =>
      ref.read(workoutNotificationServiceProvider);
  LiveActivityService get _liveActivity =>
      ref.read(liveActivityServiceProvider);

  @override
  RestTimerState build() {
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        resyncWithWallClock();
        ref.read(activeSessionProvider.notifier).resyncWithWallClock();
      },
    );

    ref.onDispose(() {
      _ticker?.cancel();
      _lifecycleListener?.dispose();
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

  /// Calculates ceil remaining seconds from a target DateTime to avoid millisecond truncation jitter.
  int _computeRemainingSeconds(DateTime target) {
    final diffMs = target.difference(DateTime.now()).inMilliseconds;
    if (diffMs <= 0) return 0;
    return (diffMs + 999) ~/ 1000;
  }

  /// Starts or resets the rest countdown with the given duration using wall-clock target timestamp.
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
    final targetEndTime =
        DateTime.now().add(Duration(seconds: durationSeconds));

    state = state.copyWith(
      totalDurationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      isRunning: true,
      exerciseName: exerciseName,
      setNumber: setNumber,
      targetEndTime: targetEndTime,
    );

    // Launch Android Foreground Persistent Notification with targetEndTime
    _notifications.showRestTimerNotification(
      exerciseName: exerciseName ?? 'Exercise',
      setNumber: setNumber ?? 1,
      remainingSeconds: durationSeconds,
      totalDurationSeconds: durationSeconds,
      targetEndTime: targetEndTime,
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
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!state.isRunning) return;

    if (state.targetEndTime == null) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _completeRest();
      }
      return;
    }

    final remaining = _computeRemainingSeconds(state.targetEndTime!);

    if (remaining > 0) {
      state = state.copyWith(remainingSeconds: remaining);

      // Periodically update Live Activity
      _liveActivity.updateLiveActivity(
        remainingSeconds: remaining,
        totalDurationSeconds: state.totalDurationSeconds,
        exerciseName: state.exerciseName ?? 'Exercise',
        setNumber: state.setNumber ?? 1,
        totalSets: 4,
        isResting: true,
      );
    } else {
      _completeRest();
    }
  }

  /// Internal handler when countdown hits or passes zero.
  void _completeRest() {
    _ticker?.cancel();
    state = state.copyWith(
      remainingSeconds: 0,
      isRunning: false,
      clearTargetEndTime: true,
    );

    _notifications.cancelRestNotification();
    _notifications.showRestCompletedNotification(
      exerciseName: state.exerciseName ?? 'Exercise',
      nextSetNumber: (state.setNumber ?? 1) + 1,
    );

    _liveActivity.stopLiveActivity();

    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// Synchronizes remaining seconds with the actual real-world wall clock.
  /// Called immediately when the application resumes from background.
  void resyncWithWallClock() {
    if (state.isRunning && state.targetEndTime != null) {
      final remaining = _computeRemainingSeconds(state.targetEndTime!);
      if (remaining <= 0) {
        _completeRest();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
        _notifications.showRestTimerNotification(
          exerciseName: state.exerciseName ?? 'Exercise',
          setNumber: state.setNumber ?? 1,
          remainingSeconds: remaining,
          totalDurationSeconds: state.totalDurationSeconds,
          targetEndTime: state.targetEndTime,
        );
      }
    }
  }

  /// Pauses the current countdown and freezes remaining seconds.
  void pause() {
    _ticker?.cancel();
    int currentRemaining = state.remainingSeconds;
    if (state.targetEndTime != null) {
      currentRemaining = _computeRemainingSeconds(state.targetEndTime!);
    }
    state = state.copyWith(
      remainingSeconds: currentRemaining,
      isRunning: false,
      clearTargetEndTime: true,
    );
    _notifications.cancelRestNotification();
  }

  /// Resumes countdown from remaining seconds using a new target end timestamp.
  void resume() {
    if (state.remainingSeconds > 0) {
      final targetEndTime =
          DateTime.now().add(Duration(seconds: state.remainingSeconds));
      state = state.copyWith(
        isRunning: true,
        targetEndTime: targetEndTime,
      );
      _notifications.showRestTimerNotification(
        exerciseName: state.exerciseName ?? 'Exercise',
        setNumber: state.setNumber ?? 1,
        remainingSeconds: state.remainingSeconds,
        totalDurationSeconds: state.totalDurationSeconds,
        targetEndTime: targetEndTime,
      );
      _startTicker();
    }
  }

  /// Adds or subtracts seconds to the current rest interval with wall-clock adjustment.
  void addSeconds(int seconds) {
    if (state.isRunning && state.targetEndTime != null) {
      final newTarget = state.targetEndTime!.add(Duration(seconds: seconds));
      final remaining = _computeRemainingSeconds(newTarget);
      if (remaining <= 0) {
        _completeRest();
        return;
      }
      final newTotal = state.totalDurationSeconds < remaining
          ? remaining
          : state.totalDurationSeconds;
      state = state.copyWith(
        targetEndTime: newTarget,
        remainingSeconds: remaining,
        totalDurationSeconds: newTotal,
      );
      _notifications.showRestTimerNotification(
        exerciseName: state.exerciseName ?? 'Exercise',
        setNumber: state.setNumber ?? 1,
        remainingSeconds: remaining,
        totalDurationSeconds: newTotal,
        targetEndTime: newTarget,
      );
    } else {
      final newSeconds = (state.remainingSeconds + seconds).clamp(0, 9999);
      final newTotal = state.totalDurationSeconds < newSeconds
          ? newSeconds
          : state.totalDurationSeconds;
      state = state.copyWith(
        remainingSeconds: newSeconds,
        totalDurationSeconds: newTotal,
      );
    }

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
    addSeconds(-10);
  }

  /// Skips the rest timer immediately (dismisses / finishes).
  void skip() {
    _ticker?.cancel();
    state = state.copyWith(
      remainingSeconds: 0,
      isRunning: false,
      clearTargetEndTime: true,
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
