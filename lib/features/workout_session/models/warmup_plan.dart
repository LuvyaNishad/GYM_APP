class WarmupStep {
  const WarmupStep(this.weightKg, this.reps, this.percentage);
  final double weightKg;
  final int reps, percentage;
}

/// Shared by the session's warmup insertion and the plate calculator preview.
List<WarmupStep> buildWarmupPlan(
  double workingWeight, {
  double minimumWeight = 0,
  double increment = 2.5,
}) {
  if (!workingWeight.isFinite || workingWeight < 0) workingWeight = 0;
  if (!minimumWeight.isFinite || minimumWeight < 0) minimumWeight = 0;
  if (!increment.isFinite || increment <= 0) increment = 2.5;
  final minimum = minimumWeight.clamp(0.0, workingWeight.clamp(0.0, 1500.0));
  return [
    for (final tier in [(40, 10), (60, 6), (80, 3)])
      WarmupStep(
        (((workingWeight * tier.$1 / 100 / increment).round() * increment)
                .toDouble())
            .clamp(minimum, workingWeight.clamp(0.0, 1500.0)),
        tier.$2,
        tier.$1,
      ),
  ];
}
