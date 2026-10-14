import 'package:flutter/foundation.dart';

/// Pre-configured tempo presets designed for specific lifting adaptations.
enum TempoPreset {
  controlled(
    id: 'controlled',
    name: 'Controlled Hypertrophy',
    shortName: 'Control 3-0-1',
    description: '3s Lower • 1s Drive (Universal standard)',
    eccentricSeconds: 3,
    bottomHoldSeconds: 0,
    concentricSeconds: 1,
    topHoldSeconds: 0,
  ),
  hypertrophy(
    id: 'hypertrophy',
    name: 'Muscle Growth (TUT)',
    shortName: 'Growth 3-1-1',
    description: '3s Lower • 1s Stretch • 1s Push',
    eccentricSeconds: 3,
    bottomHoldSeconds: 1,
    concentricSeconds: 1,
    topHoldSeconds: 0,
  ),
  paused(
    id: 'paused',
    name: 'Pause Reps',
    shortName: 'Pause 3-2-1',
    description: '3s Lower • 2s Bottom Freeze • 1s Push',
    eccentricSeconds: 3,
    bottomHoldSeconds: 2,
    concentricSeconds: 1,
    topHoldSeconds: 0,
  ),
  explosive(
    id: 'explosive',
    name: 'Explosive Power',
    shortName: 'Power 2-0-1',
    description: '2s Lower • Maximum Speed Drive',
    eccentricSeconds: 2,
    bottomHoldSeconds: 0,
    concentricSeconds: 1,
    topHoldSeconds: 0,
  );

  final String id;
  final String name;
  final String shortName;
  final String description;
  final int eccentricSeconds;
  final int bottomHoldSeconds;
  final int concentricSeconds;
  final int topHoldSeconds;

  const TempoPreset({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.eccentricSeconds,
    required this.bottomHoldSeconds,
    required this.concentricSeconds,
    required this.topHoldSeconds,
  });

  int get totalCycleSeconds =>
      eccentricSeconds + bottomHoldSeconds + concentricSeconds + topHoldSeconds;
}

/// The distinct biomechanical movement phases of a single repetition.
enum TempoPhase {
  countdown,   // 5s preparation countdown
  eccentric,   // Lowering / lengthening under tension
  bottomHold,  // Isometric hold / stretch at the bottom
  concentric,  // Explosive drive / lifting up
  topHold,     // Brief contraction / reset
  completed,   // Target reps reached
}

/// Immutable state describing the active hands-free tempo session.
@immutable
class TempoPacerState {
  final bool isActive;
  final bool isPaused;
  final int countdownRemaining; // 5..0
  final int currentRep;          // 1..targetReps
  final int targetReps;          // e.g. 8
  final TempoPhase phase;
  final double phaseProgress;    // 0.0 .. 1.0 within active phase
  final double cycleProgress;    // 0.0 .. 1.0 across full single rep cycle
  final TempoPreset preset;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final String? exerciseName;
  final String? exerciseId;
  final int? setIndex;
  final double? weightKg;

  const TempoPacerState({
    this.isActive = false,
    this.isPaused = false,
    this.countdownRemaining = 5,
    this.currentRep = 1,
    this.targetReps = 8,
    this.phase = TempoPhase.countdown,
    this.phaseProgress = 0.0,
    this.cycleProgress = 0.0,
    this.preset = TempoPreset.controlled,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.exerciseName,
    this.exerciseId,
    this.setIndex,
    this.weightKg,
  });

  TempoPacerState copyWith({
    bool? isActive,
    bool? isPaused,
    int? countdownRemaining,
    int? currentRep,
    int? targetReps,
    TempoPhase? phase,
    double? phaseProgress,
    double? cycleProgress,
    TempoPreset? preset,
    bool? soundEnabled,
    bool? hapticsEnabled,
    String? exerciseName,
    String? exerciseId,
    int? setIndex,
    double? weightKg,
  }) {
    return TempoPacerState(
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      countdownRemaining: countdownRemaining ?? this.countdownRemaining,
      currentRep: currentRep ?? this.currentRep,
      targetReps: targetReps ?? this.targetReps,
      phase: phase ?? this.phase,
      phaseProgress: phaseProgress ?? this.phaseProgress,
      cycleProgress: cycleProgress ?? this.cycleProgress,
      preset: preset ?? this.preset,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseId: exerciseId ?? this.exerciseId,
      setIndex: setIndex ?? this.setIndex,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  /// Whether this movement starts from the bottom (lift/pull first) vs top (descent first).
  bool get isConcentricFirst {
    final n = exerciseName?.toLowerCase() ?? '';
    return n.contains('deadlift') ||
        n.contains('curl') ||
        n.contains('pull') ||
        n.contains('row') ||
        n.contains('chin') ||
        n.contains('raise') ||
        n.contains('clean') ||
        n.contains('snatch');
  }

  /// Live remaining seconds in the current phase for HUD countdown readouts.
  int get phaseSecondsRemaining {
    switch (phase) {
      case TempoPhase.countdown:
        return countdownRemaining;
      case TempoPhase.eccentric:
        final rem = (preset.eccentricSeconds * (1.0 - phaseProgress)).ceil();
        return rem <= 0 ? 1 : rem;
      case TempoPhase.bottomHold:
        final rem = (preset.bottomHoldSeconds * (1.0 - phaseProgress)).ceil();
        return rem <= 0 ? 1 : rem;
      case TempoPhase.concentric:
        final rem = (preset.concentricSeconds * (1.0 - phaseProgress)).ceil();
        return rem <= 0 ? 1 : rem;
      case TempoPhase.topHold:
        final rem = ((preset.topHoldSeconds > 0
                    ? preset.topHoldSeconds
                    : preset.bottomHoldSeconds) *
                (1.0 - phaseProgress))
            .ceil();
        return rem <= 0 ? 1 : rem;
      case TempoPhase.completed:
        return 0;
    }
  }

  /// Label for the current active movement phase with clear biomechanical wording.
  String get phaseLabel {
    switch (phase) {
      case TempoPhase.countdown:
        return 'GET IN POSITION';
      case TempoPhase.eccentric:
        return 'LOWER CONTROLLED • ECCENTRIC';
      case TempoPhase.bottomHold:
        return 'HOLD & STRETCH';
      case TempoPhase.concentric:
        return isConcentricFirst
            ? 'EXPLODE & LIFT • CONCENTRIC'
            : 'EXPLODE & DRIVE • CONCENTRIC';
      case TempoPhase.topHold:
        return 'PEAK CONTRACTION • HOLD';
      case TempoPhase.completed:
        return 'SET COMPLETE';
    }
  }

  /// Coaching instruction subtitle for lifters.
  String get phaseCoachingNote {
    switch (phase) {
      case TempoPhase.countdown:
        return 'Grip bar and brace your core';
      case TempoPhase.eccentric:
        return 'Resist gravity smoothly for ${preset.eccentricSeconds}s (Eccentric)';
      case TempoPhase.bottomHold:
        return 'Freeze motion without bouncing';
      case TempoPhase.concentric:
        return 'Push with maximum intent for ${preset.concentricSeconds}s (Concentric)';
      case TempoPhase.topHold:
        return 'Squeeze peak contraction';
      case TempoPhase.completed:
        return 'Reps finished — auto-logging rest';
    }
  }
}
