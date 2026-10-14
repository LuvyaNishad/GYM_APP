import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tempo_pacer_state.dart';
import 'active_session_provider.dart';

final tempoPacerProvider =
    NotifierProvider<TempoPacerNotifier, TempoPacerState>(
  TempoPacerNotifier.new,
);

class TempoPacerNotifier extends Notifier<TempoPacerState> {
  Timer? _ticker;
  int _phaseElapsedMs = 0;
  int _lastTickSecond = -1;

  @override
  TempoPacerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const TempoPacerState();
  }

  /// Launches a hands-free tempo session with an optional 5s preparation countdown.
  void startSession({
    required String exerciseName,
    required String exerciseId,
    required int setIndex,
    required int targetReps,
    double? weightKg,
    TempoPreset preset = TempoPreset.controlled,
    bool skipCountdown = false,
  }) {
    _ticker?.cancel();
    _phaseElapsedMs = 0;
    _lastTickSecond = -1;

    state = TempoPacerState(
      isActive: true,
      isPaused: false,
      countdownRemaining: skipCountdown ? 0 : 5,
      currentRep: 1,
      targetReps: targetReps,
      phase: skipCountdown ? TempoPhase.eccentric : TempoPhase.countdown,
      phaseProgress: 0.0,
      cycleProgress: 0.0,
      preset: preset,
      soundEnabled: true,
      hapticsEnabled: true,
      exerciseName: exerciseName,
      exerciseId: exerciseId,
      setIndex: setIndex,
      weightKg: weightKg,
    );

    _playCue(isPrep: true);
    _startTicker();
  }

  void _startTicker() {
    const tickIntervalMs = 30; // ~33 FPS continuous sine-wave resolution
    _ticker = Timer.periodic(
      const Duration(milliseconds: tickIntervalMs),
      (_) => _onTick(tickIntervalMs),
    );
  }

  void _onTick(int deltaMs) {
    if (!state.isActive || state.isPaused) return;

    if (state.phase == TempoPhase.countdown) {
      _phaseElapsedMs += deltaMs;
      final remaining = (5 - (_phaseElapsedMs / 1000).floor()).clamp(0, 5);

      if (remaining != state.countdownRemaining) {
        state = state.copyWith(
          countdownRemaining: remaining,
          phaseProgress: (_phaseElapsedMs / 5000).clamp(0.0, 1.0),
        );
        _playCountdownTick(remaining);
      }

      if (_phaseElapsedMs >= 5000) {
        // Countdown finished -> Start Rep 1 Eccentric
        _phaseElapsedMs = 0;
        _lastTickSecond = -1;
        state = state.copyWith(
          phase: TempoPhase.eccentric,
          countdownRemaining: 0,
          phaseProgress: 0.0,
          cycleProgress: 0.0,
        );
        _playCue(isPhaseStart: true);
      }
      return;
    }

    if (state.phase == TempoPhase.completed) return;

    _phaseElapsedMs += deltaMs;
    final phaseDurationMs = _currentPhaseDurationMs();

    if (phaseDurationMs <= 0) {
      _advancePhase();
      return;
    }

    final rawProgress = (_phaseElapsedMs / phaseDurationMs).clamp(0.0, 1.0);

    // Audio/Haptic metronome ticks during eccentric descent (1 tick per second)
    if (state.phase == TempoPhase.eccentric) {
      final currentSecond = (_phaseElapsedMs / 1000).floor();
      if (currentSecond > _lastTickSecond && currentSecond < state.preset.eccentricSeconds) {
        _lastTickSecond = currentSecond;
        _playMetronomeTick();
      }
    }

    final cycleProg = _calculateCycleProgress(rawProgress);

    state = state.copyWith(
      phaseProgress: rawProgress,
      cycleProgress: cycleProg,
    );

    if (_phaseElapsedMs >= phaseDurationMs) {
      _advancePhase();
    }
  }

  int _currentPhaseDurationMs() {
    switch (state.phase) {
      case TempoPhase.countdown:
        return 5000;
      case TempoPhase.eccentric:
        return state.preset.eccentricSeconds * 1000;
      case TempoPhase.bottomHold:
        return state.preset.bottomHoldSeconds * 1000;
      case TempoPhase.concentric:
        return state.preset.concentricSeconds * 1000;
      case TempoPhase.topHold:
        return state.preset.topHoldSeconds * 1000;
      case TempoPhase.completed:
        return 0;
    }
  }

  double _calculateCycleProgress(double currentPhaseProgress) {
    final totalSec = state.preset.totalCycleSeconds;
    if (totalSec <= 0) return 0.0;

    double elapsedBefore = 0.0;
    switch (state.phase) {
      case TempoPhase.eccentric:
        elapsedBefore = 0.0;
        break;
      case TempoPhase.bottomHold:
        elapsedBefore = state.preset.eccentricSeconds.toDouble();
        break;
      case TempoPhase.concentric:
        elapsedBefore = (state.preset.eccentricSeconds +
                state.preset.bottomHoldSeconds)
            .toDouble();
        break;
      case TempoPhase.topHold:
        elapsedBefore = (state.preset.eccentricSeconds +
                state.preset.bottomHoldSeconds +
                state.preset.concentricSeconds)
            .toDouble();
        break;
      default:
        return 0.0;
    }

    final currentPhaseSec = _currentPhaseDurationMs() / 1000.0;
    final currentSec = elapsedBefore + (currentPhaseProgress * currentPhaseSec);
    return (currentSec / totalSec).clamp(0.0, 1.0);
  }

  void _advancePhase() {
    _phaseElapsedMs = 0;
    _lastTickSecond = -1;

    switch (state.phase) {
      case TempoPhase.eccentric:
        if (state.preset.bottomHoldSeconds > 0) {
          state = state.copyWith(phase: TempoPhase.bottomHold, phaseProgress: 0.0);
          _playTurnaroundSnap();
        } else {
          state = state.copyWith(phase: TempoPhase.concentric, phaseProgress: 0.0);
          _playTurnaroundSnap();
        }
        break;

      case TempoPhase.bottomHold:
        state = state.copyWith(phase: TempoPhase.concentric, phaseProgress: 0.0);
        _playDrivePulse();
        break;

      case TempoPhase.concentric:
        if (state.preset.topHoldSeconds > 0) {
          state = state.copyWith(phase: TempoPhase.topHold, phaseProgress: 0.0);
        } else {
          _completeCurrentRep();
        }
        break;

      case TempoPhase.topHold:
        _completeCurrentRep();
        break;

      default:
        break;
    }
  }

  void _completeCurrentRep() {
    if (state.currentRep < state.targetReps) {
      // Advance to next repetition
      state = state.copyWith(
        currentRep: state.currentRep + 1,
        phase: TempoPhase.eccentric,
        phaseProgress: 0.0,
        cycleProgress: 0.0,
      );
      _playNextRepChime();
    } else {
      // Completed full target set!
      _onAllRepsCompleted();
    }
  }

  void _onAllRepsCompleted() {
    _ticker?.cancel();
    state = state.copyWith(
      phase: TempoPhase.completed,
      phaseProgress: 1.0,
      cycleProgress: 1.0,
    );
    _playCompletionFanfare();

    // Auto-transition to logging set and rest timer after 1.5 seconds
    Timer(const Duration(milliseconds: 1500), () {
      if (!state.isActive) return;
      _autoLogAndLaunchRest();
    });
  }

  void _autoLogAndLaunchRest() {
    final exId = state.exerciseId;
    final setIdx = state.setIndex;
    final repsCompleted = state.currentRep;

    if (exId != null && setIdx != null) {
      // Update reps achieved if lifter changed reps during session
      ref.read(activeSessionProvider.notifier).updateSetValues(
            exerciseId: exId,
            setIndex: setIdx,
            reps: repsCompleted,
          );

      // Automatically log the set as completed (which auto-starts the rest timer)
      ref.read(activeSessionProvider.notifier).logSet(
            exerciseId: exId,
            setIndex: setIdx,
            completed: true,
          );
    }

    state = state.copyWith(isActive: false);
  }

  /// Finishes immediately and logs the reps completed so far (for early failure).
  void finishEarlyAndRest() {
    _ticker?.cancel();
    _onAllRepsCompleted();
  }

  void togglePause() {
    if (!state.isActive) return;
    state = state.copyWith(isPaused: !state.isPaused);
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void setPreset(TempoPreset preset) {
    state = state.copyWith(preset: preset);
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void adjustTargetReps(int delta) {
    final newTarget = (state.targetReps + delta).clamp(1, 99);
    state = state.copyWith(targetReps: newTarget);
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void toggleSound() {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void toggleHaptics() {
    state = state.copyWith(hapticsEnabled: !state.hapticsEnabled);
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void cancel() {
    _ticker?.cancel();
    state = state.copyWith(isActive: false);
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  // ── Tactile Haptics & Non-Interfering System Sound Cues ────────────────────

  void _playCountdownTick(int remaining) {
    if (state.hapticsEnabled) {
      try {
        if (remaining == 0) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.selectionClick();
        }
      } catch (_) {}
    }
    if (state.soundEnabled) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  void _playMetronomeTick() {
    if (state.hapticsEnabled) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
    if (state.soundEnabled) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  void _playTurnaroundSnap() {
    if (state.hapticsEnabled) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }
    if (state.soundEnabled) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  void _playDrivePulse() {
    if (state.hapticsEnabled) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
    if (state.soundEnabled) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  void _playNextRepChime() {
    if (state.hapticsEnabled) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }

  void _playCompletionFanfare() {
    if (state.hapticsEnabled) {
      try {
        HapticFeedback.vibrate();
      } catch (_) {}
    }
    if (state.soundEnabled) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  void _playCue({bool isPrep = false, bool isPhaseStart = false}) {
    if (state.hapticsEnabled) {
      try {
        if (isPrep) {
          HapticFeedback.mediumImpact();
        } else if (isPhaseStart) {
          HapticFeedback.heavyImpact();
        }
      } catch (_) {}
    }
  }
}
