import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/history/models/training_coverage.dart';

/// Mounted only in the Radar tab. Ticks repaint the canvas, not the labels,
/// cards or blur. Geometry is laid out once per size/data change.
class TrainingCoverageRadar extends StatefulWidget {
  const TrainingCoverageRadar({
    super.key,
    required this.muscles,
    this.hasPlan = true,
  });
  final List<MuscleCoverage> muscles;
  final bool hasPlan;
  @override
  State<TrainingCoverageRadar> createState() => _TrainingCoverageRadarState();
}

class _TrainingCoverageRadarState extends State<TrainingCoverageRadar>
    with SingleTickerProviderStateMixin {
  late final _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );
  late final AppLifecycleListener _lifecycle;
  bool _started = false, _reduced = false, _foreground = true;

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _foreground = state == AppLifecycleState.resumed;
        if (!_foreground) {
          _reveal.stop();
        } else if (!_reduced && _reveal.value < 1) {
          _reveal.forward();
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (!_started || reduced != _reduced) {
      _reduced = reduced;
      _started = true;
      _animate();
    }
  }

  @override
  void didUpdateWidget(covariant TrainingCoverageRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasPlan != widget.hasPlan ||
        !listEquals(
          oldWidget.muscles
              .map((m) => '${m.name}:${m.completed}:${m.planned}')
              .toList(),
          widget.muscles
              .map((m) => '${m.name}:${m.completed}:${m.planned}')
              .toList(),
        )) {
      _animate();
    }
  }

  void _animate() {
    _reveal.value = _reduced ? 1 : 0;
    if (!_reduced && _foreground) _reveal.forward();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(11) / 11;
    final count = math.max(6, widget.muscles.length);
    final activeIndices = List<int>.generate(
      widget.muscles.length,
      (i) => (i * count / widget.muscles.length).floor(),
    );
    final peak = widget.muscles.fold<double>(
      0,
      (p, m) => math.max(p, m.completed),
    );
    final values = List<double>.generate(
      count,
      (i) => !activeIndices.contains(i)
          ? 0
          : widget.hasPlan
          ? widget.muscles[activeIndices.indexOf(i)].fraction
          : peak <= 0
          ? 0
          : widget.muscles[activeIndices.indexOf(i)].completed / peak,
    );
    return Semantics(
      label:
          'Muscle coverage. ${widget.muscles.map((m) => '${m.name}: ${m.completed.toStringAsFixed(1)} of ${m.planned.toStringAsFixed(1)} planned sets').join('. ')}',
      child: SizedBox(
        height: 282 + 40 * (scale - 1).clamp(0, 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final center = Offset(size.width / 2, size.height / 2);
            final radius = math.min(
              size.width * .29 / math.max(1, scale * .8),
              size.height * .32,
            );
            final directions = List<Offset>.generate(count, (i) {
              final angle = -math.pi / 2 + i * 2 * math.pi / count;
              return Offset(math.cos(angle), math.sin(angle));
            });
            return Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey('training-coverage-web'),
                      painter: CoverageWebPainter(
                        reveal: _reveal,
                        center: center,
                        radius: radius,
                        directions: directions,
                        values: values,
                        activeIndices: activeIndices,
                        hasPlan: widget.hasPlan,
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < widget.muscles.length; i++)
                  Positioned(
                    left:
                        (center.dx +
                                directions[activeIndices[i]].dx *
                                    (radius + 35) -
                                45)
                            .clamp(0, math.max(0, size.width - 90)),
                    top:
                        center.dy +
                        directions[activeIndices[i]].dy * (radius + 29) -
                        17 * scale,
                    width: 90,
                    child: ExcludeSemantics(
                      child: Text(
                        widget.muscles[i].name,
                        textAlign: directions[activeIndices[i]].dx < -.3
                            ? TextAlign.left
                            : directions[activeIndices[i]].dx > .3
                            ? TextAlign.right
                            : TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _reveal.dispose();
    super.dispose();
  }
}

class CoverageWebPainter extends CustomPainter {
  CoverageWebPainter({
    required this.reveal,
    required this.center,
    required this.radius,
    required this.directions,
    required this.values,
    required this.activeIndices,
    required this.hasPlan,
  }) : super(repaint: reveal);
  final Animation<double> reveal;
  final Offset center;
  final double radius;
  final List<Offset> directions;
  final List<double> values;
  final List<int> activeIndices;
  final bool hasPlan;

  Path _polygon(double fraction, [List<double>? weights]) {
    final path = Path();
    final indices = weights == null
        ? List<int>.generate(directions.length, (i) => i)
        : activeIndices;
    var first = true;
    for (final i in indices) {
      final point =
          center + directions[i] * radius * fraction * (weights?[i] ?? 1);
      if (first) {
        path.moveTo(point.dx, point.dy);
        first = false;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = reveal.value;
    final guide = Paint()
      ..color = const Color(0xFF465160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    // The full faint web remains visible even for one logged muscle.
    for (var ring = 1; ring <= 4; ring++) {
      canvas.drawPath(_polygon(ring / 4), guide);
      final spread = Curves.easeOutCubic.transform(
        ((t - (ring - 1) * .07) / .70).clamp(0, 1),
      );
      canvas.drawPath(
        _polygon(ring / 4 * spread),
        Paint()
          ..color = AppColors.platinum.withValues(alpha: .26 * spread)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
    }
    final spread = Curves.easeOutCubic.transform((t / .65).clamp(0, 1));
    for (final direction in directions) {
      canvas.drawLine(center, center + direction * radius * spread, guide);
    }
    if (hasPlan) {
      canvas.drawPath(
        _polygon(spread),
        Paint()
          ..color = AppColors.platinum
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    final growth = Curves.easeOutBack.transform(((t - .13) / .87).clamp(0, 1));
    final actual = _polygon(growth, values);
    canvas.drawPath(
      actual,
      Paint()..color = AppColors.primary.withValues(alpha: .16),
    );
    canvas.drawPath(
      actual,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2,
    );
    for (var i = 0; i < values.length; i++) {
      if (values[i] > 0) {
        canvas.drawCircle(
          center + directions[i] * radius * growth * values[i],
          3,
          Paint()..color = AppColors.primary,
        );
      }
    }
    canvas.drawCircle(center, 2, Paint()..color = AppColors.platinum);
  }

  @override
  bool shouldRepaint(covariant CoverageWebPainter old) =>
      old.center != center ||
      old.radius != radius ||
      old.hasPlan != hasPlan ||
      !listEquals(old.activeIndices, activeIndices) ||
      !listEquals(old.values, values) ||
      !listEquals(old.directions, directions);
}
