import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/active_session_state.dart';

/// Provider managing the inter-set rest countdown timer.
class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _ticker;

  @override
  RestTimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const RestTimerState();
  }

  /// Starts or resets the rest countdown with the given duration.
  void startTimer({
    required int durationSeconds,
    String? exerciseName,
    int? setNumber,
  }) {
    _ticker?.cancel();
    state = state.copyWith(
      totalDurationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      isRunning: true,
      exerciseName: exerciseName,
      setNumber: setNumber,
    );

    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        // Timer reached zero
        _ticker?.cancel();
        state = state.copyWith(remainingSeconds: 0, isRunning: false);
        // Haptic notification when rest interval ends
        try {
          HapticFeedback.heavyImpact();
        } catch (_) {}
      }
    });
  }

  /// Pauses the current countdown.
  void pause() {
    _ticker?.cancel();
    state = state.copyWith(isRunning: false);
  }

  /// Resumes countdown if time remains.
  void resume() {
    if (state.remainingSeconds > 0) {
      state = state.copyWith(isRunning: true);
      _startTicker();
    }
  }

  /// Adds 10 seconds to the current rest interval.
  void addTenSeconds() {
    final newSeconds = state.remainingSeconds + 10;
    final newTotal = state.totalDurationSeconds < newSeconds
        ? newSeconds
        : state.totalDurationSeconds;
    state = state.copyWith(
      remainingSeconds: newSeconds,
      totalDurationSeconds: newTotal,
    );
    if (!state.isRunning && state.remainingSeconds > 0) {
      resume();
    }
  }

  /// Subtracts 10 seconds from the remaining rest interval (floor at 0).
  void subtractTenSeconds() {
    final newSeconds = (state.remainingSeconds - 10).clamp(0, 9999);
    state = state.copyWith(remainingSeconds: newSeconds);
    if (newSeconds == 0) {
      skip();
    }
  }

  /// Skips the rest timer immediately (dismisses / finishes).
  void skip() {
    _ticker?.cancel();
    state = state.copyWith(
      remainingSeconds: 0,
      isRunning: false,
    );
  }

  /// Toggles whether completing a set automatically begins the rest timer.
  void toggleAutoStart() {
    state = state.copyWith(autoStart: !state.autoStart);
  }
}

final restTimerProvider =
    NotifierProvider<RestTimerNotifier, RestTimerState>(RestTimerNotifier.new);
