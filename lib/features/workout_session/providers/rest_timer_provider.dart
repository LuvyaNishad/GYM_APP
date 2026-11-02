import 'dart:async';
import 'package:flutter/material.dart';
import '../../../state/app_providers.dart';
import '../services/native_rest_service.dart';
import '../services/workout_cue_service.dart';
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
  String? _workoutId;
  String? _timerId;
  Future<void> _nativeWrites = Future.value();
  NativeRestService get _native => ref.read(nativeRestServiceProvider);
  void _nativeTask(Future<void> Function() task) {
    if (!_native.supported) return;
    _nativeWrites = _nativeWrites.then((_) => task()).catchError((Object e) {
      if (ref.mounted) {
        state = state.copyWith(
          alertError: 'Background rest alerts unavailable: $e',
        );
      }
    });
  }

  void _scheduleNative() {
    if (!_native.supported || !state.isRunning || state.targetEndTime == null) {
      return;
    }
    final profile = ref.read(userProfileProvider);
    final id = _timerId;
    final snapshot = <String, dynamic>{
      'timerId': id,
      'workoutId': _workoutId ?? id,
      'deadline': state.targetEndTime!.millisecondsSinceEpoch,
      'total': state.totalDurationSeconds,
      'exerciseName': state.exerciseName ?? 'Exercise',
      'exerciseId': state.exerciseId ?? '',
      'setNumber': state.setNumber ?? 1,
      'totalSets': state.totalSets,
      'isWarmup': state.isWarmup,
      'sound': profile?.audioCuesEnabled ?? true,
      'vibrate': profile?.hapticFeedbackEnabled ?? true,
    };
    _nativeTask(() async {
      await ref.read(activeSessionProvider.notifier).flushPendingChanges();
      if (_timerId != id || !state.isRunning) return;
      await _native.schedule(snapshot);
      if (ref.mounted) state = state.copyWith(clearAlertError: true);
    });
  }

  void _syncNative() {
    final requestedId = _timerId;
    _nativeTask(() async {
      final data = await _native.read();
      if (!ref.mounted || requestedId != _timerId) return;
      if (data == null) {
        await _liveActivity.cleanupStaleActivities(null);
        if (_timerId != null && state.isRunning) {
          _ticker?.cancel();
          state = state.copyWith(
            remainingSeconds: 0,
            isRunning: false,
            clearTargetEndTime: true,
          );
        }
        return;
      }
      final session = ref.read(activeSessionProvider);
      if (!session.isActive ||
          data['workoutId'] != session.workoutId ||
          session.nextPendingSet() == null) {
        await _native.cancel();
        await _liveActivity.cleanupStaleActivities(null);
        return;
      }
      _workoutId = session.workoutId;
      _timerId = data['timerId'] as String;
      final deadline = DateTime.fromMillisecondsSinceEpoch(
        (data['deadline'] as num).toInt(),
      );
      final running = data['phase'] == 'running';
      state = RestTimerState(
        autoStart: state.autoStart,
        totalDurationSeconds: (data['total'] as num).toInt(),
        remainingSeconds: running ? _computeRemainingSeconds(deadline) : 0,
        isRunning: running,
        targetEndTime: running ? deadline : null,
        exerciseName: data['exerciseName'] as String?,
        exerciseId: data['exerciseId'] as String?,
        setNumber: (data['setNumber'] as num?)?.toInt(),
        totalSets: (data['totalSets'] as num?)?.toInt() ?? 0,
        isWarmup: data['isWarmup'] as bool? ?? false,
      );
      await _liveActivity.cleanupStaleActivities(
        running ? session.workoutId : null,
      );
      if (running && _refreshTarget()) {
        _startLiveActivity();
        _resyncDart();
        _startTicker();
      }
    });
  }

  double _targetWeightKg = 0;
  int _targetReps = 0;
  String _plateBreakdown = '';

  WorkoutNotificationService get _notifications =>
      ref.read(workoutNotificationServiceProvider);
  LiveActivityService get _liveActivity =>
      ref.read(liveActivityServiceProvider);

  @override
  RestTimerState build() {
    ref.keepAlive();
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

    _native.onChanged = _syncNative;
    Future.microtask(() {
      if (ref.mounted && _timerId == null) _syncNative();
    });
    ref.listen(userProfileProvider, (_, __) {
      if (state.isRunning) _scheduleNative();
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

  /// Starts rest for the upcoming set, never the set that was just completed.
  void startTimer({
    required int durationSeconds,
    String? exerciseName,
    int? setNumber,
    int? totalSets,
    double? targetWeightKg,
    int? targetReps,
    String? plateBreakdown,
    WorkoutSetTarget? nextSet,
    String? sourceExerciseId,
  }) {
    _ticker?.cancel();
    _timerId = DateTime.now().microsecondsSinceEpoch.toString();
    if (durationSeconds <= 0) {
      skip();
      return;
    }
    final session = ref.read(activeSessionProvider);
    _workoutId = session.isActive ? session.workoutId : null;
    final next =
        nextSet ??
        session.nextPendingSet(preferredExerciseId: session.expandedExerciseId);
    if (session.isActive && next == null) {
      skip();
      return;
    }
    _targetWeightKg = next?.set.weightKg ?? targetWeightKg ?? 0;
    _targetReps = next?.set.reps ?? targetReps ?? 0;
    _plateBreakdown = plateBreakdown ?? '';
    final targetEndTime = DateTime.now().add(
      Duration(seconds: durationSeconds),
    );

    state = RestTimerState(
      autoStart: state.autoStart,
      totalDurationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      isRunning: true,
      exerciseName: next?.exercise.name ?? exerciseName,
      setNumber: next?.set.setNumber ?? setNumber,
      totalSets: next?.exercise.sets.length ?? totalSets ?? setNumber ?? 0,
      isWarmup: next?.set.isWarmup ?? false,
      exerciseId: next?.exercise.exerciseId,
      sourceExerciseId: sourceExerciseId,
      targetEndTime: targetEndTime,
    );

    // Launch Android Foreground Persistent Notification with targetEndTime
    _notifications.cancelRestCompletedNotification();
    _notifications.cancelActiveWorkoutNotification();
    _showCountdown();

    _startLiveActivity();
    _startTicker();
  }

  void _startLiveActivity() {
    if (state.setNumber == null) return;
    _liveActivity.configureIdentity(
      _workoutId ?? _timerId,
      state.targetEndTime,
      ref.read(userProfileProvider)?.weightUnit ?? 'kg',
    );
    _liveActivity.startLiveActivity(
      workoutTitle: "TODAY'S WORKOUT",
      exerciseName: state.exerciseName ?? 'Exercise',
      setNumber: state.setNumber!,
      totalSets: state.totalSets,
      remainingSeconds: state.remainingSeconds,
      totalDurationSeconds: state.totalDurationSeconds,
      targetWeightKg: _targetWeightKg,
      targetReps: _targetReps,
      plateBreakdown: _plateBreakdown,
      isResting: true,
    );
  }

  void _showCountdown() {
    _scheduleNative();
    _liveActivity.configureIdentity(
      _workoutId ?? _timerId,
      state.targetEndTime,
      ref.read(userProfileProvider)?.weightUnit ?? 'kg',
    );
    if (_native.supported) return;
    _notifications.showRestTimerNotification(
      exerciseName: state.exerciseName,
      setNumber: state.setNumber,
      isWarmup: state.isWarmup,
      remainingSeconds: state.remainingSeconds,
      totalDurationSeconds: state.totalDurationSeconds,
      targetEndTime: state.targetEndTime,
    );
  }

  // Revalidate after edits/removals and before delivering a completion alert.
  void refreshForSession() {
    if (state.isRunning) _refreshTarget();
  }

  bool _refreshTarget() {
    if (_workoutId == null) return true;
    final session = ref.read(activeSessionProvider);
    final next = session.nextPendingSet(preferredExerciseId: state.exerciseId);
    if (session.workoutId != _workoutId || next == null) {
      skip();
      return false;
    }
    final changed =
        state.exerciseId != next.exercise.exerciseId ||
        state.exerciseName != next.exercise.name ||
        state.setNumber != next.set.setNumber ||
        state.isWarmup != next.set.isWarmup ||
        state.totalSets != next.exercise.sets.length;
    if (changed) {
      state = state.copyWith(
        exerciseId: next.exercise.exerciseId,
        exerciseName: next.exercise.name,
        setNumber: next.set.setNumber,
        totalSets: next.exercise.sets.length,
        isWarmup: next.set.isWarmup,
      );
    }
    _targetWeightKg = next.set.weightKg;
    _targetReps = next.set.reps;
    if (changed && state.isRunning) _showCountdown();
    return true;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!state.isRunning || !_refreshTarget()) return;

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
      if (state.setNumber != null) {
        _liveActivity.updateLiveActivity(
          remainingSeconds: remaining,
          totalDurationSeconds: state.totalDurationSeconds,
          exerciseName: state.exerciseName ?? 'Exercise',
          setNumber: state.setNumber ?? 1,
          totalSets: state.totalSets,
          targetWeightKg: _targetWeightKg,
          targetReps: _targetReps,
          plateBreakdown: _plateBreakdown,
          isResting: true,
        );
      }
    } else {
      _completeRest();
    }
  }

  /// Internal handler when countdown hits or passes zero.
  void _completeRest() {
    if (!state.isRunning || !_refreshTarget()) return;
    _ticker?.cancel();
    state = state.copyWith(
      remainingSeconds: 0,
      isRunning: false,
      clearTargetEndTime: true,
    );

    _notifications.cancelRestNotification();
    if (!_native.supported) {
      _notifications.showRestCompletedNotification(
        exerciseName: state.exerciseName,
        nextSetNumber: state.setNumber,
        isWarmup: state.isWarmup,
      );
    }

    _liveActivity.stopLiveActivity();

    final id = _timerId;
    if (_native.supported && id != null) {
      _nativeTask(() async {
        final claimed = await _native.complete(
          id,
          background: _notifications.isAppInBackground,
        );
        if (claimed && !_notifications.isAppInBackground) {
          await playWorkoutCue(ref, WorkoutCue.complete);
        } else if (!claimed) {
          _syncNative();
        }
      });
    } else {
      playWorkoutCue(ref, WorkoutCue.complete);
    }
  }

  /// Synchronizes remaining seconds with the actual real-world wall clock.
  /// Called immediately when the application resumes from background.
  void resyncWithWallClock() {
    if (_native.supported) {
      _syncNative();
      return;
    }
    _resyncDart();
  }

  void _resyncDart() {
    if (!_refreshTarget()) return;
    if (state.isRunning && state.targetEndTime != null) {
      final remaining = _computeRemainingSeconds(state.targetEndTime!);
      if (remaining <= 0) {
        _completeRest();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
        if (!_native.supported) _showCountdown();
      }
    }
  }

  /// Pauses the current countdown and freezes remaining seconds.
  void pause() {
    final id = _timerId;
    _nativeTask(() => _native.cancel(id));
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
    _liveActivity.stopLiveActivity();
  }

  /// Resumes countdown from remaining seconds using a new target end timestamp.
  void resume() {
    if (!_refreshTarget()) return;
    if (state.remainingSeconds > 0) {
      final targetEndTime = DateTime.now().add(
        Duration(seconds: state.remainingSeconds),
      );
      state = state.copyWith(isRunning: true, targetEndTime: targetEndTime);
      _showCountdown();
      _startLiveActivity();
      _startTicker();
    }
  }

  /// Adds or subtracts seconds to the current rest interval with wall-clock adjustment.
  void addSeconds(int seconds) {
    if ((!state.isRunning && state.remainingSeconds == 0) ||
        !_refreshTarget()) {
      return;
    }
    if (state.isRunning && state.targetEndTime != null) {
      final newTarget = state.targetEndTime!.add(Duration(seconds: seconds));
      final remaining = _computeRemainingSeconds(newTarget);
      if (remaining <= 0) {
        skip();
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
      _showCountdown();
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
    final id = _timerId;
    _timerId = null;
    _nativeTask(() => _native.cancel(id));
    _ticker?.cancel();
    state = state.copyWith(
      remainingSeconds: 0,
      isRunning: false,
      clearTargetEndTime: true,
    );
    _notifications.cancelRestNotification();
    _notifications.cancelRestCompletedNotification();
    _liveActivity.stopLiveActivity();
  }

  Future<void> flushNativeChanges() async {
    Future<void> previous;
    do {
      previous = _nativeWrites;
      await previous;
    } while (previous != _nativeWrites);
  }

  void retryAlerts() {
    if (state.isRunning) _scheduleNative();
  }

  /// Toggles whether completing a set automatically begins the rest timer.
  void toggleAutoStart() {
    state = state.copyWith(autoStart: !state.autoStart);
  }
}

final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(
  RestTimerNotifier.new,
);
