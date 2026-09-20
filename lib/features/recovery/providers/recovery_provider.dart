import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recovery_factor.dart';

/// Recovery score, composed from a pluggable list of [RecoveryFactor]s.
///
/// The screen renders whatever factors are in the list. Adding a signal later
/// (e.g. `CyclePhaseFactor`, wearable HRV) means one new factor class and one
/// entry in [build] — the score engine in [RecoveryScore] never changes.
class RecoveryNotifier extends Notifier<RecoveryScore> {
  @override
  RecoveryScore build() {
    ref.keepAlive();
    // Demo factors until the workout-history aggregation feeds real numbers.
    // See DESIGN.md § 12 (screen 25) for the inputs this will read.
    return const RecoveryScore(
      factors: [
        RestDaysFactor(1),
        VolumeLoadFactor(recentVolumeKg: 11800, baselineVolumeKg: 10000),
      ],
    );
  }

  /// Replace the factor set (called when real inputs change).
  void setFactors(List<RecoveryFactor> factors) {
    state = RecoveryScore(factors: factors);
  }
}

final recoveryProvider =
    NotifierProvider<RecoveryNotifier, RecoveryScore>(RecoveryNotifier.new);

/// Convenience: the 0–100 score for widgets that only need the number.
final recoveryScoreProvider =
    Provider<int>((ref) => ref.watch(recoveryProvider).value);
