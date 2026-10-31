/// Pluggable recovery-scoring model.
///
/// Recovery is a sum of independent factors, each contributing a signed delta
/// to a 100-point baseline. Adding a new signal later (menstrual cycle phase,
/// wearable HRV, sleep debt) means writing one [RecoveryFactor] and dropping it
/// into the list in `recovery_provider.dart` — the engine here never changes.
library;

/// One input to the recovery score.
abstract class RecoveryFactor {
  const RecoveryFactor();

  /// Short label for the UI row (e.g. `'REST DAYS'`).
  String get label;

  /// Signed contribution to the score. Positive = more recovered.
  /// Bounded by the engine, so a factor can't blow past 0–100 on its own.
  double delta();

  /// One-line reason shown under the factor, or null if unremarkable.
  String? get insight => null;
}

/// Days since the last training session. More rest = more recovered.
class RestDaysFactor extends RecoveryFactor {
  const RestDaysFactor(this.daysSinceLastSession);

  final int daysSinceLastSession;

  @override
  String get label => 'REST DAYS';

  @override
  double delta() {
    // 0 days trained-today penalises; 2+ days fully recovered on this axis.
    return switch (daysSinceLastSession) {
      <= 0 => -25,
      1 => -5,
      2 => 5,
      _ => 10,
    };
  }

  @override
  String? get insight => daysSinceLastSession <= 0
      ? 'Trained today — muscles still under load.'
      : null;
}

/// Recent training volume relative to the user's normal weekly load.
/// A big spike over baseline means accumulated fatigue.
class VolumeLoadFactor extends RecoveryFactor {
  const VolumeLoadFactor({
    required this.recentVolumeKg,
    required this.baselineVolumeKg,
  });

  final double recentVolumeKg;
  final double baselineVolumeKg;

  @override
  String get label => 'VOLUME LOAD';

  @override
  double delta() {
    if (baselineVolumeKg <= 0) return 0;
    final ratio = recentVolumeKg / baselineVolumeKg;
    // At/under baseline: neutral. 2x baseline: −30. Clamped between.
    final over = (ratio - 1).clamp(0.0, 1.0);
    return -30 * over;
  }

  @override
  String? get insight {
    if (baselineVolumeKg <= 0) return null;
    return recentVolumeKg > 1.5 * baselineVolumeKg
        ? 'Volume is ${((recentVolumeKg / baselineVolumeKg - 1) * 100).round()}% above your previous average.'
        : null;
  }
}

class ManualRecoveryFactor extends RecoveryFactor {
  const ManualRecoveryFactor(this.label, this.contribution, this.reason);
  @override
  final String label;
  final double contribution;
  final String reason;
  @override
  double delta() => contribution;
  @override
  String get insight => reason;
}

/// Folds a list of [RecoveryFactor]s into a 0–100 score.
class RecoveryScore {
  const RecoveryScore({required this.factors, this.baseline = 100});

  final List<RecoveryFactor> factors;
  final double baseline;

  /// Final score, clamped to 0–100.
  int get value {
    final raw = factors.fold<double>(baseline, (sum, f) => sum + f.delta());
    return raw.clamp(0, 100).round();
  }

  /// True when the score clears the "go train" line.
  bool get isReady => value >= 60;

  /// First non-null factor insight, if any — the one line the UI surfaces.
  String? get topInsight {
    for (final f in factors) {
      final i = f.insight;
      if (i != null) return i;
    }
    return null;
  }
}
