/// Reusable minimal Donut Progress Ring with percentage in center for LEON Bento Cards.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Clean circular progress donut ring displaying the completion percentage in its center.
class BentoDonutProgress extends StatelessWidget {
  const BentoDonutProgress({
    super.key,
    required this.progress,
    required this.percentage,
    this.size = 52.0,
    this.strokeWidth = 4.5,
    this.progressColor = AppColors.pureWhite,
  });

  /// Normalized completion progress between 0.0 and 1.0.
  final double progress;

  /// Percentage value displayed inside the ring (e.g. 84).
  final int percentage;

  /// Diameter of the circle widget.
  final double size;

  /// Stroke width of the ring.
  final double strokeWidth;

  /// Active arc color.
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutRingPainter(
              progress: progress,
              trackColor: AppColors.steel.withValues(alpha: 0.35),
              progressColor: progressColor,
              strokeWidth: strokeWidth,
            ),
          ),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.pureWhite,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutRingPainter extends CustomPainter {
  const _DonutRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweepAngle = (2 * math.pi) * progress.clamp(0.0, 1.0);
    const startAngle = -math.pi / 2;

    final progressRect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(progressRect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
