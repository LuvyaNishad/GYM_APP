import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// 6-Axis Muscle Balance Radar Chart rendered with high-performance CustomPainter.
///
/// Features:
/// - 6 axes: Chest, Back, Shoulders, Quads, Hamstrings, Arms
/// - Concentric geometric polygon grid (Low, Optimal, High)
/// - Dual polygon overlay: Planned Split Volume vs Actual Logged History
/// - High-contrast Apple HIG typography (min 11.5pt labels)
/// - Pure Noguchi monochrome palette
class MuscleRadarChart extends StatefulWidget {
  const MuscleRadarChart({
    super.key,
    required this.plannedVolume,
    required this.loggedVolume,
    this.size = 280,
    this.maxSetsScale = 20.0,
  });

  /// Map of muscle group to planned weekly sets.
  final Map<String, int> plannedVolume;

  /// Map of muscle group to actual logged weekly sets.
  final Map<String, int> loggedVolume;

  /// Diameter of the radar widget.
  final double size;

  /// Maximum scale for normalising weekly sets (e.g. 20 sets = 100%).
  final double maxSetsScale;

  static const List<String> kAxes = [
    'Chest',
    'Back',
    'Shoulders',
    'Quads',
    'Hamstrings',
    'Arms',
  ];

  @override
  State<MuscleRadarChart> createState() => _MuscleRadarChartState();
}

class _MuscleRadarChartState extends State<MuscleRadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(MuscleRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plannedVolume != widget.plannedVolume ||
        oldWidget.loggedVolume != widget.loggedVolume) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _MuscleRadarPainter(
              axes: MuscleRadarChart.kAxes,
              plannedVolume: widget.plannedVolume,
              loggedVolume: widget.loggedVolume,
              maxSetsScale: widget.maxSetsScale,
              progress: _animation.value,
            ),
          );
        },
      ),
    );
  }
}

class _MuscleRadarPainter extends CustomPainter {
  _MuscleRadarPainter({
    required this.axes,
    required this.plannedVolume,
    required this.loggedVolume,
    required this.maxSetsScale,
    required this.progress,
  });

  final List<String> axes;
  final Map<String, int> plannedVolume;
  final Map<String, int> loggedVolume;
  final double maxSetsScale;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Radius allows breathing room for axis labels outside the outer ring
    final maxRadius = (size.width / 2) - 44.0;
    final int count = axes.length;
    final angleStep = (2 * math.pi) / count;

    // Paints
    final gridPaint = Paint()
      ..color = AppColors.steel.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final spokePaint = Paint()
      ..color = AppColors.steel.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final plannedFillPaint = Paint()
      ..color = AppColors.platinum.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final plannedStrokePaint = Paint()
      ..color = AppColors.platinum.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final loggedFillPaint = Paint()
      ..color = AppColors.pureWhite.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;

    final loggedStrokePaint = Paint()
      ..color = AppColors.pureWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final nodePaint = Paint()
      ..color = AppColors.pureWhite
      ..style = PaintingStyle.fill;

    final nodeBorderPaint = Paint()
      ..color = AppColors.onyx
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 1. Draw 3 concentric polygon rings (33%, 66%, 100%)
    const ringFractions = [0.33, 0.66, 1.0];
    for (final fraction in ringFractions) {
      final ringPath = Path();
      for (int i = 0; i < count; i++) {
        final angle = -math.pi / 2 + (i * angleStep);
        final r = maxRadius * fraction;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          ringPath.moveTo(x, y);
        } else {
          ringPath.lineTo(x, y);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, gridPaint);
    }

    // 2. Draw Spokes and Axis Labels
    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final spokeEnd = Offset(
        center.dx + maxRadius * math.cos(angle),
        center.dy + maxRadius * math.sin(angle),
      );
      canvas.drawLine(center, spokeEnd, spokePaint);

      // Label Positioning
      final axisName = axes[i];
      final plannedSets = plannedVolume[axisName] ?? 0;
      final loggedSets = loggedVolume[axisName] ?? 0;

      final labelRadius = maxRadius + 22.0;
      final labelX = center.dx + labelRadius * math.cos(angle);
      final labelY = center.dy + labelRadius * math.sin(angle);

      // Determine label text style (highlight lacking vs optimal)
      const labelColor = AppColors.platinum;

      final span = TextSpan(
        children: [
          TextSpan(
            text: '${axisName.toUpperCase()}\n',
            style: AppTypography.monoSmall.copyWith(
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              color: labelColor,
              letterSpacing: 0.6,
            ),
          ),
          TextSpan(
            text: '$loggedSets/$plannedSets sets',
            style: AppTypography.monoSmall.copyWith(
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              color: AppColors.platinum,
            ),
          ),
        ],
      );

      final tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelOffset = Offset(
        labelX - (tp.width / 2),
        labelY - (tp.height / 2),
      );
      tp.paint(canvas, labelOffset);
    }

    // 3. Draw Planned Volume Polygon (Translucent silver wash)
    final plannedPath = Path();
    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final axisName = axes[i];
      final sets = plannedVolume[axisName] ?? 0;
      final normalized = (sets / maxSetsScale).clamp(0.0, 1.0);
      final r = maxRadius * normalized * progress;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        plannedPath.moveTo(x, y);
      } else {
        plannedPath.lineTo(x, y);
      }
    }
    plannedPath.close();
    canvas.drawPath(plannedPath, plannedFillPaint);
    canvas.drawPath(plannedPath, plannedStrokePaint);

    // 4. Draw Actual Logged Volume Polygon (High contrast white outline + nodes)
    final loggedPath = Path();
    final List<Offset> loggedPoints = [];

    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final axisName = axes[i];
      final sets = loggedVolume[axisName] ?? 0;
      final normalized = (sets / maxSetsScale).clamp(0.0, 1.0);
      final r = maxRadius * normalized * progress;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      final pt = Offset(x, y);

      loggedPoints.add(pt);
      if (i == 0) {
        loggedPath.moveTo(x, y);
      } else {
        loggedPath.lineTo(x, y);
      }
    }
    loggedPath.close();
    canvas.drawPath(loggedPath, loggedFillPaint);
    canvas.drawPath(loggedPath, loggedStrokePaint);

    // 5. Draw node dots on actual logged vertices
    for (final pt in loggedPoints) {
      canvas.drawCircle(pt, 4.0, nodePaint);
      canvas.drawCircle(pt, 4.0, nodeBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MuscleRadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.maxSetsScale != maxSetsScale ||
        !mapEquals(oldDelegate.plannedVolume, plannedVolume) ||
        !mapEquals(oldDelegate.loggedVolume, loggedVolume);
  }
}
