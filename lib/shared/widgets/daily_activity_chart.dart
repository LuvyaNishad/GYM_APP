import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// One short reveal, only while its sheet is mounted. Animation ticks repaint
/// this isolated canvas; they never rebuild the sheet, labels or glass blur.
class DailyActivityChart extends StatefulWidget {
  const DailyActivityChart({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.paintKey,
  });
  final List<int?> values;
  final int selected;
  final ValueChanged<int> onSelected;
  final Key paintKey;

  @override
  State<DailyActivityChart> createState() => _DailyActivityChartState();
}

class _DailyActivityChartState extends State<DailyActivityChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );
  late final AppLifecycleListener _lifecycle;
  bool _reduceMotion = false;
  bool _started = false;
  bool _foreground = true;
  bool get _hasData => widget.values.any((value) => (value ?? 0) > 0);

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
        } else if (!_reduceMotion && _hasData && _reveal.value < 1) {
          _reveal.forward();
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!_started || reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      _started = true;
      _animate();
    }
  }

  @override
  void didUpdateWidget(covariant DailyActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.values, widget.values)) _animate();
  }

  void _animate() {
    if (_reduceMotion || !_hasData) {
      _reveal.value = 1;
    } else {
      _reveal.value = 0;
      if (_foreground) _reveal.forward();
    }
  }

  void _select(double x, double width) {
    if (widget.values.isEmpty || width <= 0) return;
    widget.onSelected(
      (x / width * widget.values.length).floor().clamp(
        0,
        widget.values.length - 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) =>
          _select(details.localPosition.dx, constraints.maxWidth),
      onHorizontalDragUpdate: (details) =>
          _select(details.localPosition.dx, constraints.maxWidth),
      child: RepaintBoundary(
        child: CustomPaint(
          key: widget.paintKey,
          size: const Size(double.infinity, 144),
          painter: ActivityBarPainter(
            values: widget.values,
            selected: widget.selected,
            reveal: _reveal,
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _lifecycle.dispose();
    _reveal.dispose();
    super.dispose();
  }
}

class ActivityBarPainter extends CustomPainter {
  ActivityBarPainter({
    required this.values,
    required this.selected,
    required this.reveal,
  }) : super(repaint: reveal);
  final List<int?> values;
  final int selected;
  final Animation<double> reveal;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || values.isEmpty) return;
    final bottom = size.height - 1;
    final guide = Paint()
      ..color = AppColors.steel.withValues(alpha: .5)
      ..strokeWidth = 1;
    for (final fraction in [0.0, .5, 1.0]) {
      final y = bottom - fraction * (size.height - 8);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
    }
    final peak = values.fold<int>(0, (max, value) => math.max(max, value ?? 0));
    final rect = Offset.zero & size;
    // Two shared shaders, no per-bar blur, shadow layers or widget layout.
    final silver = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF1F5F9), Color(0xFF94A3B8)],
      ).createShader(rect);
    final cyan = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB5F7FF), AppColors.primary],
      ).createShader(rect);
    final cap = Paint()..color = Colors.white.withValues(alpha: .45);
    final slot = size.width / values.length;
    final width = math.min(18.0, slot * .55);
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null || value < 0) continue;
      final left = (i + .5) * slot - width / 2;
      if (value == 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, bottom - 2, width, 2),
            const Radius.circular(1),
          ),
          i == selected ? cyan : silver,
        );
        continue;
      }
      final delay = values.length <= 1 ? 0.0 : i / (values.length - 1) * .16;
      final t = ((reveal.value - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t == 0) continue;
      // Headroom preserves the small overshoot without clipping the tall bar.
      final height =
          value /
          peak *
          (size.height - 8) *
          .86 *
          Curves.easeOutBack.transform(t);
      final bar = Rect.fromLTWH(left, bottom - height, width, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, Radius.circular(width / 2)),
        i == selected ? cyan : silver,
      );
      if (height > width) {
        canvas.drawLine(
          Offset(left + width * .3, bar.top + width * .3),
          Offset(left + width * .7, bar.top + width * .3),
          cap..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ActivityBarPainter old) =>
      selected != old.selected ||
      !listEquals(values, old.values) ||
      reveal != old.reveal;
}
