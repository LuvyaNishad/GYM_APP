import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/muscle_radar_data.dart';
import '../theme/app_colors.dart';

@immutable
class SpiderChartSeries {
  SpiderChartSeries({
    required List<double> values,
    this.color = AppColors.pureWhite,
    this.filled = true,
  }) : assert(values.length == muscleRadarCategories.length),
       values = List.unmodifiable(
         values.map((value) => value.isFinite ? value.clamp(0.0, 1.0) : 0.0),
       );
  final List<double> values;
  final Color color;
  final bool filled;
}

/// Six filled sectors. Area, rather than radius, is proportional to workload.
class MuscleSpiderChart extends StatefulWidget {
  const MuscleSpiderChart({
    super.key,
    required this.series,
    this.captions,
    this.highlightedCategories = const {},
    this.height = 282,
    this.duration = const Duration(milliseconds: 850),
    this.paintKey,
    this.semanticLabel = 'Muscle workload',
    this.detailBuilder,
  });
  final List<SpiderChartSeries> series;
  final Map<String, String>? captions;
  final Set<String> highlightedCategories;
  final double height;
  final Duration duration;
  final Key? paintKey;
  final String semanticLabel;
  final Widget Function(BuildContext context, String category)? detailBuilder;
  @override
  State<MuscleSpiderChart> createState() => _MuscleSpiderChartState();
}

class _MuscleSpiderChartState extends State<MuscleSpiderChart>
    with SingleTickerProviderStateMixin {
  late final _reveal = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final AppLifecycleListener _lifecycle;
  bool _started = false, _reduced = false, _foreground = true;
  int? _selected;

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
      _started = true;
      _reduced = reduced;
      _animate();
    }
  }

  @override
  void didUpdateWidget(covariant MuscleSpiderChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reveal.duration = widget.duration;
    if (!_sameSeries(oldWidget.series, widget.series)) {
      _selected = null;
      _animate();
    }
  }

  void _animate() {
    _reveal.value = _reduced ? 1 : 0;
    if (!_reduced && _foreground) _reveal.forward();
  }

  void _select(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selected = index);
  }

  int get _active {
    if (_selected != null) return _selected!;
    final data = widget.series.where((s) => s.filled).lastOrNull;
    if (data == null) return 0;
    var index = 0;
    for (var i = 1; i < data.values.length; i++) {
      if (data.values[i] > data.values[index]) index = i;
    }
    return index;
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(11) / 11;
    final active = _active;
    return Semantics(
      label: widget.semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: widget.height + 40 * (scale - 1).clamp(0, 2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final center = size.center(Offset.zero);
                final labelWidth = math.min(
                  size.width / 2,
                  90.0 * math.max(1.0, scale * .85),
                );
                final radius = math.max(
                  0.0,
                  math.min(
                    (size.width - labelWidth) / 2 - 32,
                    size.height * .32,
                  ),
                );
                final labelHeight = math.max(
                  44.0,
                  (widget.captions == null ? 28 : 42) * scale,
                );
                return Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (event) {
                          final offset = event.localPosition - center;
                          if (offset.distance > radius + 12) return;
                          final angle =
                              (math.atan2(offset.dy, offset.dx) -
                                  MuscleSpiderPainter.startAngle +
                                  math.pi / 6) %
                              (2 * math.pi);
                          _select((angle / (math.pi / 3)).floor() % 6);
                        },
                        child: RepaintBoundary(
                          child: CustomPaint(
                            key: widget.paintKey,
                            painter: MuscleSpiderPainter(
                              reveal: _reveal,
                              center: center,
                              radius: radius,
                              series: widget.series,
                              selectedIndex: active,
                            ),
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < muscleRadarCategories.length; i++)
                      Positioned(
                        left:
                            (center.dx +
                                    MuscleSpiderPainter.directions[i].dx *
                                        (radius + 38) -
                                    labelWidth / 2)
                                .clamp(0, math.max(0, size.width - labelWidth)),
                        top:
                            center.dy +
                            MuscleSpiderPainter.directions[i].dy *
                                (radius + 38) -
                            labelHeight / 2,
                        width: labelWidth,
                        child: Semantics(
                          button: true,
                          selected: active == i,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _select(i),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: labelHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    muscleRadarCategories[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                      color: active == i
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (widget.captions != null)
                                    Text(
                                      widget.captions![muscleRadarCategories[i]] ??
                                          '',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (widget.detailBuilder != null)
            widget.detailBuilder!(context, muscleRadarCategories[active]),
        ],
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

bool _sameSeries(List<SpiderChartSeries> a, List<SpiderChartSeries> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].color != b[i].color ||
        a[i].filled != b[i].filled ||
        !listEquals(a[i].values, b[i].values)) {
      return false;
    }
  }
  return true;
}

class MuscleSpiderPainter extends CustomPainter {
  MuscleSpiderPainter({
    required this.reveal,
    required this.center,
    required this.radius,
    required this.series,
    this.selectedIndex = -1,
  }) : super(repaint: reveal);
  final Animation<double> reveal;
  final Offset center;
  final double radius;
  final List<SpiderChartSeries> series;
  final int selectedIndex;
  static const ringCount = 3;
  static const startAngle = -2 * math.pi / 3;
  static const sectorSweep = math.pi / 3;
  static final directions = List<Offset>.unmodifiable(
    List.generate(6, (i) {
      final angle = startAngle + i * sectorSweep;
      return Offset(math.cos(angle), math.sin(angle));
    }),
  );
  double get growth => Curves.easeOutCubic.transform(reveal.value);
  double sectorRadius(SpiderChartSeries data, int index) =>
      radius * math.sqrt(data.values[index] * growth);
  double sectorArea(SpiderChartSeries data, int index) =>
      .5 * sectorSweep * math.pow(sectorRadius(data, index), 2);
  List<Offset> pointsFor(SpiderChartSeries data) => [
    for (var i = 0; i < 6; i++) center + directions[i] * sectorRadius(data, i),
  ];
  Path sectorPath(SpiderChartSeries data, int index) {
    final r = sectorRadius(data, index);
    if (r <= 0) return Path();
    return Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: r),
        startAngle + index * sectorSweep - sectorSweep / 2,
        sectorSweep,
        false,
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    final guide = Paint()
      ..color = const Color(0xFF465160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    for (var ring = 1; ring <= ringCount; ring++) {
      canvas.drawCircle(center, radius * math.sqrt(ring / ringCount), guide);
    }
    for (var i = 0; i < 6; i++) {
      final angle = startAngle + (i - .5) * sectorSweep;
      canvas.drawLine(
        center,
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        guide,
      );
    }
    for (final data in series.where((s) => s.filled)) {
      for (var i = 0; i < 6; i++) {
        if (data.values[i] <= 0 || growth <= 0) continue;
        final selected = i == selectedIndex;
        final color = selected ? AppColors.primary : data.color;
        final path = sectorPath(data, i);
        canvas.drawPath(
          path,
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    color.withValues(alpha: selected ? .07 : .04),
                    color.withValues(alpha: selected ? .34 : .24),
                  ],
                ).createShader(
                  Rect.fromCircle(
                    center: center,
                    radius: sectorRadius(data, i),
                  ),
                ),
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = selected ? 2 : 1.25,
        );
        canvas.drawCircle(
          center + directions[i] * sectorRadius(data, i),
          selected ? 2.8 : 2,
          Paint()..color = color,
        );
      }
    }
    // Each target is a dashed arc in its own sector, on the same absolute scale.
    for (final data in series.where((s) => !s.filled)) {
      for (var i = 0; i < 6; i++) {
        final r = sectorRadius(data, i);
        if (r <= 0) continue;
        final rect = Rect.fromCircle(center: center, radius: r);
        for (var dash = 0; dash < 6; dash++) {
          canvas.drawArc(
            rect,
            startAngle +
                i * sectorSweep -
                sectorSweep / 2 +
                dash * sectorSweep / 6,
            sectorSweep / 11,
            false,
            Paint()
              ..color = data.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3,
          );
        }
      }
    }
    canvas.drawCircle(center, 2.5, Paint()..color = AppColors.platinum);
  }

  @override
  bool shouldRepaint(covariant MuscleSpiderPainter old) =>
      old.reveal != reveal ||
      old.center != center ||
      old.radius != radius ||
      old.selectedIndex != selectedIndex ||
      !_sameSeries(old.series, series);
}
