import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tempo_pacer_state.dart';
import 'active_session_provider.dart';

class TempoAutoLog extends Notifier<bool> {
  @override
  bool build() => false;
  void setEnabled(bool enabled) => state = enabled;
}

final tempoAutoLogProvider = NotifierProvider<TempoAutoLog, bool>(
  TempoAutoLog.new,
);

final tempoPacerProvider =
    NotifierProvider<TempoPacerNotifier, TempoPacerState>(
      TempoPacerNotifier.new,
    );

class TempoPacerNotifier extends Notifier<TempoPacerState> {
  Timer? _ticker;
  Timer? _completionTimer;
  String? _workoutId;
  Object? _targetSet;
  int _generation = 0;
  int get generation => _generation;
  final Stopwatch _phaseStopwatch = Stopwatch();
  int _lastTickSecond = -1;

  @override
  TempoPacerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _completionTimer?.cancel();
      _phaseStopwatch.stop();
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
    TempoPreset? preset,
    bool skipCountdown = false,
  }) {
    _ticker?.cancel();
    _completionTimer?.cancel();
    _generation++;
    final session = ref.read(activeSessionProvider);
    _workoutId = session.workoutId;
    final exercise = session.exercises
        .where((e) => e.exerciseId == exerciseId)
        .firstOrNull;
    _targetSet =
        exercise != null && setIndex >= 0 && setIndex < exercise.sets.length
        ? exercise.sets[setIndex]
        : null;
    _phaseStopwatch.reset();
    _phaseStopwatch.start();
    _lastTickSecond = -1;

    final resolvedPreset =
        preset ?? TempoPreset.defaultForExercise(exerciseName);

    final startPhase = skipCountdown
        ? (TempoPacerState(exerciseName: exerciseName).isConcentricFirst
              ? TempoPhase.concentric
              : TempoPhase.eccentric)
        : TempoPhase.countdown;

    state = TempoPacerState(
      isActive: true,
      isPaused: false,
      countdownRemaining: skipCountdown ? 0 : 5,
      currentRep: 1,
      targetReps: targetReps,
      phase: startPhase,
      phaseProgress: 0.0,
      cycleProgress: 0.0,
      preset: resolvedPreset,
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
    const tickIntervalMs = 25; // Continuous metronome & phase monitor
    _ticker = Timer.periodic(
      const Duration(milliseconds: tickIntervalMs),
      (_) => _onTick(),
    );
  }

  void _onTick() {
    if (!state.isActive || state.isPaused) return;

    final elapsedMs = _phaseStopwatch.elapsedMilliseconds;

    if (state.phase == TempoPhase.countdown) {
      final remaining = (5 - (elapsedMs / 1000).floor()).clamp(0, 5);

      if (remaining != state.countdownRemaining) {
        state = state.copyWith(
          countdownRemaining: remaining,
          phaseProgress: (elapsedMs / 5000).clamp(0.0, 1.0),
        );
        _playCountdownTick(remaining);
      }

      if (elapsedMs >= 5000) {
        // Countdown finished -> Start Rep 1
        _phaseStopwatch.reset();
        _phaseStopwatch.start();
        _lastTickSecond = -1;
        state = state.copyWith(
          phase: state.isConcentricFirst
              ? TempoPhase.concentric
              : TempoPhase.eccentric,
          countdownRemaining: 0,
          phaseProgress: 0.0,
          cycleProgress: 0.0,
        );
        _playCue(isPhaseStart: true);
      }
      return;
    }

    if (state.phase == TempoPhase.completed) return;

    final phaseDurationMs = _currentPhaseDurationMs();

    if (phaseDurationMs <= 0) {
      _advancePhase();
      return;
    }

    final rawProgress = (elapsedMs / phaseDurationMs).clamp(0.0, 1.0);

    // Audio/Haptic metronome ticks during eccentric descent (1 tick per second)
    if (state.phase == TempoPhase.eccentric) {
      final currentSecond = (elapsedMs / 1000).floor();
      if (currentSecond > _lastTickSecond &&
          currentSecond < state.preset.eccentricSeconds) {
        _lastTickSecond = currentSecond;
        _playMetronomeTick();
      }
    }

    final cycleProg = _calculateCycleProgress(rawProgress);

    state = state.copyWith(
      phaseProgress: rawProgress,
      cycleProgress: cycleProg,
    );

    if (elapsedMs >= phaseDurationMs) {
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
        final holdSec = state.preset.topHoldSeconds > 0
            ? state.preset.topHoldSeconds
            : (state.isConcentricFirst ? state.preset.bottomHoldSeconds : 0);
        return holdSec * 1000;
      case TempoPhase.completed:
        return 0;
    }
  }

  double _calculateCycleProgress(double currentPhaseProgress) {
    final totalSec = state.preset.totalCycleSeconds;
    if (totalSec <= 0) return 0.0;

    double elapsedBefore = 0.0;
    if (state.isConcentricFirst) {
      switch (state.phase) {
        case TempoPhase.concentric:
          elapsedBefore = 0.0;
          break;
        case TempoPhase.topHold:
          elapsedBefore = state.preset.concentricSeconds.toDouble();
          break;
        case TempoPhase.eccentric:
          elapsedBefore =
              (state.preset.concentricSeconds + state.preset.topHoldSeconds)
                  .toDouble();
          break;
        case TempoPhase.bottomHold:
          elapsedBefore =
              (state.preset.concentricSeconds +
                      state.preset.topHoldSeconds +
                      state.preset.eccentricSeconds)
                  .toDouble();
          break;
        default:
          return 0.0;
      }
    } else {
      switch (state.phase) {
        case TempoPhase.eccentric:
          elapsedBefore = 0.0;
          break;
        case TempoPhase.bottomHold:
          elapsedBefore = state.preset.eccentricSeconds.toDouble();
          break;
        case TempoPhase.concentric:
          elapsedBefore =
              (state.preset.eccentricSeconds + state.preset.bottomHoldSeconds)
                  .toDouble();
          break;
        case TempoPhase.topHold:
          elapsedBefore =
              (state.preset.eccentricSeconds +
                      state.preset.bottomHoldSeconds +
                      state.preset.concentricSeconds)
                  .toDouble();
          break;
        default:
          return 0.0;
      }
    }

    final currentPhaseSec = _currentPhaseDurationMs() / 1000.0;
    final currentSec = elapsedBefore + (currentPhaseProgress * currentPhaseSec);
    return (currentSec / totalSec).clamp(0.0, 1.0);
  }

  void _advancePhase() {
    _phaseStopwatch.reset();
    _phaseStopwatch.start();
    _lastTickSecond = -1;

    if (state.isConcentricFirst) {
      switch (state.phase) {
        case TempoPhase.concentric:
          if (state.preset.topHoldSeconds > 0) {
            state = state.copyWith(
              phase: TempoPhase.topHold,
              phaseProgress: 0.0,
            );
            _playTurnaroundSnap();
          } else {
            state = state.copyWith(
              phase: TempoPhase.eccentric,
              phaseProgress: 0.0,
            );
            _playDrivePulse();
          }
          break;

        case TempoPhase.topHold:
          state = state.copyWith(
            phase: TempoPhase.eccentric,
            phaseProgress: 0.0,
          );
          _playDrivePulse();
          break;

        case TempoPhase.eccentric:
          if (state.preset.bottomHoldSeconds > 0) {
            state = state.copyWith(
              phase: TempoPhase.bottomHold,
              phaseProgress: 0.0,
            );
            _playTurnaroundSnap();
          } else {
            _completeCurrentRep();
          }
          break;

        case TempoPhase.bottomHold:
          _completeCurrentRep();
          break;

        default:
          break;
      }
      return;
    }

    switch (state.phase) {
      case TempoPhase.eccentric:
        if (state.preset.bottomHoldSeconds > 0) {
          state = state.copyWith(
            phase: TempoPhase.bottomHold,
            phaseProgress: 0.0,
          );
          _playTurnaroundSnap();
        } else {
          state = state.copyWith(
            phase: TempoPhase.concentric,
            phaseProgress: 0.0,
          );
          _playTurnaroundSnap();
        }
        break;

      case TempoPhase.bottomHold:
        state = state.copyWith(
          phase: TempoPhase.concentric,
          phaseProgress: 0.0,
        );
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
      _phaseStopwatch.reset();
      _phaseStopwatch.start();
      _lastTickSecond = -1;
      state = state.copyWith(
        currentRep: state.currentRep + 1,
        phase: state.isConcentricFirst
            ? TempoPhase.concentric
            : TempoPhase.eccentric,
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
    _phaseStopwatch.stop();
    state = state.copyWith(
      phase: TempoPhase.completed,
      phaseProgress: 1.0,
      cycleProgress: 1.0,
    );
    _playCompletionFanfare();

    // Auto-transition to logging set and rest timer after 1.5 seconds
    final completedGeneration = _generation;
    _completionTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!ref.mounted ||
          completedGeneration != _generation ||
          !state.isActive ||
          state.phase != TempoPhase.completed ||
          !ref.read(tempoAutoLogProvider)) {
        return;
      }
      final exercise = ref
          .read(activeSessionProvider)
          .exercises
          .where((e) => e.exerciseId == state.exerciseId)
          .firstOrNull;
      if (exercise?.isUnilateral == true) return;
      _autoLogAndLaunchRest();
    });
  }

  void _autoLogAndLaunchRest({int? rightReps}) {
    final exId = state.exerciseId;
    final setIdx = state.setIndex;
    final repsCompleted = state.currentRep;
    final session = ref.read(activeSessionProvider);
    final exercise = session.exercises
        .where((e) => e.exerciseId == exId)
        .firstOrNull;
    if (!state.isActive ||
        !session.isActive ||
        session.workoutId != _workoutId ||
        exercise == null ||
        setIdx == null ||
        setIdx < 0 ||
        setIdx >= exercise.sets.length ||
        !identical(exercise.sets[setIdx], _targetSet) ||
        exercise.sets[setIdx].isCompleted) {
      cancel();
      return;
    }
    if (exercise.isUnilateral && rightReps == null) return;

    if (exId != null) {
      // Update reps achieved if lifter changed reps during session
      ref
          .read(activeSessionProvider.notifier)
          .updateSetValues(
            exerciseId: exId,
            setIndex: setIdx,
            reps: repsCompleted,
            repsRight: exercise.isUnilateral ? rightReps : null,
          );

      // Automatically log the set as completed (which auto-starts the rest timer)
      ref
          .read(activeSessionProvider.notifier)
          .logSet(exerciseId: exId, setIndex: setIdx, completed: true);
    }

    state = state.copyWith(isActive: false);
  }

  /// Finishes immediately, logs the reps completed so far, and launches the rest timer.
  void finishEarlyAndRest() {
    _ticker?.cancel();
    _completionTimer?.cancel();
    _phaseStopwatch.stop();
    _autoLogAndLaunchRest();
  }

  void confirmRepsAndRest(int reps, {int? rightReps}) {
    if (reps < 1 ||
        reps > 100 ||
        (rightReps != null && (rightReps < 1 || rightReps > 100))) {
      return;
    }
    state = state.copyWith(currentRep: reps);
    _ticker?.cancel();
    _completionTimer?.cancel();
    _phaseStopwatch.stop();
    _autoLogAndLaunchRest(rightReps: rightReps);
  }

  bool get targetIsUnilateral =>
      ref
          .read(activeSessionProvider)
          .exercises
          .where((e) => e.exerciseId == state.exerciseId)
          .firstOrNull
          ?.isUnilateral ??
      false;

  void beginConfirmation() {
    _completionTimer?.cancel();
    if (!state.isPaused && state.phase != TempoPhase.completed) togglePause();
  }

  void togglePause() {
    if (!state.isActive) return;
    if (state.isPaused) {
      _phaseStopwatch.start();
    } else {
      _phaseStopwatch.stop();
    }
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
    _completionTimer?.cancel();
    _generation++;
    _phaseStopwatch.stop();
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
