/// LEON self-drawing radar chart.
///
/// A hand-written [CustomPainter] — `fl_chart`'s radar isn't flexible enough for
/// the staggered draw-on animation or per-axis colouring this design needs.
/// Works for any axis count ≥ 3, so the dashboard's 3-axis PPL view and the
/// analytics 6-axis breakdown share one widget.
///
/// The draw-on runs in three staggered stages (grid rings → axes → data
/// polygon), and any axis whose value falls below [weakThreshold] of the
/// strongest axis has its label turned red so imbalance reads at a glance.
library;

import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// One spoke of the radar: a label, its value, and the colour it owns.
class RadarAxis {
  const RadarAxis({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class LeonRadarChart extends StatefulWidget {
  const LeonRadarChart({
    super.key,
    required this.axes,
    this.maxValue,
    this.weakThreshold = 0.4,
    this.duration = const Duration(milliseconds: 600),
  });

  /// Radar spokes, drawn clockwise from the top. Needs at least 3.
  final List<RadarAxis> axes;

  /// Value mapped to the outer ring. Defaults to the strongest axis, so the
  /// chart always fills its frame regardless of the units in play.
  final double? maxValue;

  /// An axis below this fraction of the strongest axis is "weak" (label → red).
  final double weakThreshold;

  final Duration duration;

  @override
  State<LeonRadarChart> createState() => _LeonRadarChartState();
}

class _LeonRadarChartState extends State<LeonRadarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void didUpdateWidget(LeonRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Replay the draw-on whenever the data actually changes.
    if (_signature(oldWidget.axes) != _signature(widget.axes)) {
      _controller.forward(from: 0);
    }
  }

  String _signature(List<RadarAxis> axes) =>
      axes.map((a) => '${a.label}:${a.value}').join('|');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _RadarChartPainter(
          axes: widget.axes,
          maxValue: widget.maxValue,
          weakThreshold: widget.weakThreshold,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  _RadarChartPainter({
    required this.axes,
    required this.maxValue,
    required this.weakThreshold,
    required this.progress,
  });

  final List<RadarAxis> axes;
  final double? maxValue;
  final double weakThreshold;
  final double progress;

  static const int _ringCount = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final n = axes.length;
    if (n < 3) return;

    final center = size.center(Offset.zero);
    // Leave room around the ring for the labels.
    final radius = math.min(size.width, size.height) / 2 * 0.72;

    // Staggered timeline, all inside the single 0→1 controller value.
    final ringsT = const Interval(0.0, 0.35, curve: Curves.easeOut)
        .transform(progress);
    final axesT = const Interval(0.25, 0.6, curve: Curves.easeOut)
        .transform(progress);
    final polyT = const Interval(0.55, 1.0, curve: Curves.easeOutCubic)
        .transform(progress);

    final observedMax = axes.fold<double>(0, (m, a) => math.max(m, a.value));
    final scale = maxOr(observedMax);

    _paintRings(canvas, center, radius, n, ringsT);
    _paintAxes(canvas, center, radius, n, axesT);
    _paintPolygon(canvas, center, radius, scale, polyT);
    if (axesT > 0) {
      _paintLabels(canvas, center, radius, n, observedMax, axesT);
    }
  }

  Offset _vertex(Offset center, double radius, int i, int n) {
    final angle = -math.pi / 2 + 2 * math.pi * i / n;
    return center + Offset(math.cos(angle), math.sin(angle)) * radius;
  }

  void _paintRings(
    Canvas canvas,
    Offset center,
    double radius,
    int n,
    double t,
  ) {
    if (t <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.chartGrid;
    for (var r = 1; r <= _ringCount; r++) {
      final ringRadius = radius * (r / _ringCount) * t;
      canvas.drawPath(_polygonPath(center, ringRadius, n), paint);
    }
  }

  void _paintAxes(
    Canvas canvas,
    Offset center,
    double radius,
    int n,
    double t,
  ) {
    if (t <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.chartGrid;
    for (var i = 0; i < n; i++) {
      // Spokes extend one after another for the staggered draw-on.
      final spokeT = (t * n - i).clamp(0.0, 1.0);
      if (spokeT <= 0) continue;
      final tip = _vertex(center, radius * spokeT, i, n);
      canvas.drawLine(center, tip, paint);
    }
  }

  void _paintPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    double scale,
    double t,
  ) {
    if (t <= 0 || scale <= 0) return;
    final n = axes.length;
    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < n; i++) {
      final norm = (axes[i].value / scale).clamp(0.0, 1.0);
      final p = _vertex(center, radius * norm * t, i, n);
      points.add(p);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    // Cyan → transparent gradient fill (reads as a power level).
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.28),
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.primary;
    canvas.drawPath(path, stroke);

    // Vertex dots.
    final dot = Paint()..color = AppColors.primary;
    canvas.drawPoints(PointMode.points, points, dot..strokeWidth = 6);
  }

  void _paintLabels(
    Canvas canvas,
    Offset center,
    double radius,
    int n,
    double observedMax,
    double t,
  ) {
    for (var i = 0; i < n; i++) {
      final axis = axes[i];
      final isWeak =
          observedMax > 0 && axis.value < weakThreshold * observedMax;
      final color = isWeak ? AppColors.danger : axis.color;

      final tp = TextPainter(
        text: TextSpan(
          text: axis.label,
          style: AppTypography.labelSmall.copyWith(
            color: color.withValues(alpha: t),
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final anchor = _vertex(center, radius + 20, i, n);
      tp.paint(
        canvas,
        anchor - Offset(tp.width / 2, tp.height / 2),
      );
    }
  }

  Path _polygonPath(Offset center, double radius, int n) {
    final path = Path();
    for (var i = 0; i < n; i++) {
      final p = _vertex(center, radius, i, n);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_RadarChartPainter old) =>
      old.progress != progress || old.axes != axes;
}

extension on _RadarChartPainter {
  /// Effective scale: caller-supplied [maxValue] if given, else the strongest
  /// axis, else 1 (so an all-zero snapshot collapses to the centre, not NaN).
  double maxOr(double observedMax) {
    final m = maxValue ?? observedMax;
    return m > 0 ? m : 1;
  }
}
