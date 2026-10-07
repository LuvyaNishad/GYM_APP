import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Animated tactical radar sweep widget used across LEON onboarding & synthesis.
class TacticalRadarWidget extends StatefulWidget {
  const TacticalRadarWidget({
    super.key,
    this.size = 200,
    this.showPolygon = false,
    this.sweepDuration = const Duration(seconds: 3),
  });

  final double size;
  final bool showPolygon;
  final Duration sweepDuration;

  @override
  State<TacticalRadarWidget> createState() => _TacticalRadarWidgetState();
}

class _TacticalRadarWidgetState extends State<TacticalRadarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.sweepDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RadarPainter(
              sweepAngle: _controller.value * 2 * math.pi,
              showPolygon: widget.showPolygon,
              pulseProgress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.sweepAngle,
    required this.showPolygon,
    required this.pulseProgress,
  });

  final double sweepAngle;
  final bool showPolygon;
  final double pulseProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background radial glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);

    // Grid rings
    final ringPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.70, ringPaint);
    canvas.drawCircle(center, radius * 0.40, ringPaint);

    // Pulsing middle ring
    final pulseRadius = radius * (0.4 + 0.3 * pulseProgress);
    final pulsePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: (1.0 - pulseProgress) * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    // Crosshairs
    final crosshairPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crosshairPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crosshairPaint);

    // Radar Sweep beam (sweep sector)
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: FractionalOffset.center,
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          Colors.transparent,
          AppColors.primary.withValues(alpha: 0.25),
        ],
        transform: GradientRotation(sweepAngle - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sweepPaint);

    // Sweep leading edge line
    final lineEndX = center.dx + radius * math.cos(sweepAngle);
    final lineEndY = center.dy + radius * math.sin(sweepAngle);
    final edgePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;
    canvas.drawLine(center, Offset(lineEndX, lineEndY), edgePaint);

    // Data Polygon (for synthesis screen)
    if (showPolygon) {
      final polyPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      final polyStroke = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final polyPath = Path();
      final points = [
        Offset(center.dx, center.dy - radius * 0.7),
        Offset(center.dx + radius * 0.65, center.dy - radius * 0.1),
        Offset(center.dx + radius * 0.35, center.dy + radius * 0.65),
        Offset(center.dx - radius * 0.45, center.dy + radius * 0.45),
        Offset(center.dx - radius * 0.65, center.dy - radius * 0.25),
      ];
      polyPath.addPolygon(points, true);
      canvas.drawPath(polyPath, polyPaint);
      canvas.drawPath(polyPath, polyStroke);

      // Vertex dots
      final dotPaint = Paint()..color = AppColors.primary;
      for (final pt in points) {
        canvas.drawCircle(pt, 3.0, dotPaint);
      }
    }

    // Glowing core indicator
    final coreGlow = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 6, coreGlow);

    final coreDot = Paint()..color = AppColors.primary;
    canvas.drawCircle(center, 4, coreDot);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
