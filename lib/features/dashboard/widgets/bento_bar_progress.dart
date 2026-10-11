/// Reusable minimal Bar Progress widgets for LEON Bento Cards.
///
/// Designed with Apple HIG contrast and typography standards.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Clean horizontal progress bar for compact wellness cards.
class BentoHorizontalBarProgress extends StatelessWidget {
  const BentoHorizontalBarProgress({
    super.key,
    required this.progress,
    this.barHeight = 5.0,
    this.progressColor = AppColors.pureWhite,
    this.trackColor,
  });

  /// Normalized completion progress between 0.0 and 1.0.
  final double progress;

  /// Thickness of the horizontal progress bar.
  final double barHeight;

  /// Active progress fill color.
  final Color progressColor;

  /// Inactive background track color.
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final effectiveTrackColor =
        trackColor ?? Colors.white.withValues(alpha: 0.12);

    return ClipRRect(
      borderRadius: BorderRadius.circular(barHeight / 2),
      child: Container(
        height: barHeight,
        width: double.infinity,
        color: effectiveTrackColor,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(barHeight / 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clean vertical capsule progress bar with completion percentage displayed above.
class BentoBarProgress extends StatelessWidget {
  const BentoBarProgress({
    super.key,
    required this.progress,
    required this.percentage,
    this.barWidth = 8.0,
    this.barHeight = 42.0,
    this.progressColor = AppColors.pureWhite,
    this.trackColor,
  });

  /// Normalized completion progress between 0.0 and 1.0.
  final double progress;

  /// Percentage value displayed above the bar (e.g. 78).
  final int percentage;

  /// Width of the vertical bar capsule.
  final double barWidth;

  /// Height of the vertical bar capsule.
  final double barHeight;

  /// Active progress fill color.
  final Color progressColor;

  /// Inactive background track color.
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final effectiveTrackColor =
        trackColor ?? Colors.white.withValues(alpha: 0.12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Percentage readout (Apple HIG minimum font floor >= 11.0 pt)
        Text(
          '$percentage%',
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            color: AppColors.pureWhite,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 5),
        // Slim vertical capsule bar
        ClipRRect(
          borderRadius: BorderRadius.circular(barWidth / 2),
          child: Container(
            width: barWidth,
            height: barHeight,
            color: effectiveTrackColor,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(barWidth / 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
