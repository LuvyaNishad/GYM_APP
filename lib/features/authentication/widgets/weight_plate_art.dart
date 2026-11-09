import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A code-rendered still life: three machined plates suspended above slate.
/// Only this paint layer ticks; forms and text remain outside its repaint scope.
class WeightPlateArt extends StatefulWidget {
  const WeightPlateArt({super.key});

  @override
  State<WeightPlateArt> createState() => _WeightPlateArtState();
}

class _WeightPlateArtState extends State<WeightPlateArt>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    final animate =
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context);
    if (animate && !_motion.isAnimating) _motion.repeat();
    if (!animate) _motion.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _PlatePainter(_motion),
        size: Size.infinite,
        isComplex: true,
        willChange: _motion.isAnimating,
      ),
    ),
  );
}

class _PlatePainter extends CustomPainter {
  _PlatePainter(this.motion) : super(repaint: motion);
  final Animation<double> motion;

  Path _ring(double radius, double hole) => Path()
    ..fillType = PathFillType.evenOdd
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: radius))
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: hole));

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 400, size.height / 310);
    canvas.save();
    canvas.translate(
      (size.width - 400 * scale) / 2,
      (size.height - 310 * scale) / 2,
    );
    canvas.scale(scale);
    final phase = motion.value * math.pi * 2;
    final drift = math.sin(phase);

    canvas.drawOval(
      const Rect.fromLTWH(66, 255, 282, 35),
      Paint()
        ..color = const Color(0xAA000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawCircle(
      const Offset(212, 143),
      146,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x1434D6EA), Color(0x0034D6EA)],
        ).createShader(const Rect.fromLTWH(66, -3, 292, 292)),
    );

    _plate(
      canvas,
      const Offset(143, 81) + Offset(0, drift * 3),
      76,
      18,
      -.43 + drift * .025,
      .56,
      .7,
      phase,
    );
    _plate(
      canvas,
      const Offset(185, 135) + Offset(0, -drift * 3),
      95,
      22,
      -.43 + drift * .018,
      .58,
      .86,
      phase + .35,
    );
    _plate(
      canvas,
      const Offset(226, 195) + Offset(0, drift * 4),
      119,
      27,
      -.43 + drift * .014,
      .59,
      1,
      phase + .7,
    );

    // A single reflected edge ties the composition to the active UI accent.
    canvas.drawArc(
      const Rect.fromLTWH(121, 252, 184, 26),
      .15,
      2.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..shader = const LinearGradient(
          colors: [Color(0x0000E5FF), Color(0xAA00E5FF), Color(0x0000E5FF)],
        ).createShader(const Rect.fromLTWH(121, 252, 184, 26)),
    );
    canvas.restore();
  }

  void _plate(
    Canvas canvas,
    Offset center,
    double radius,
    double depth,
    double angle,
    double perspective,
    double light,
    double phase,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(1, perspective);
    final bounds = Rect.fromCircle(center: Offset.zero, radius: radius);
    final hole = radius * .205;
    final ring = _ring(radius, hole);
    final sidePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF454E5D),
          Color(0xFF111721),
          Color(0xFF7E8796),
          Color(0xFF202833),
          Color(0xFF10161F),
        ],
        stops: [0, .32, .55, .77, 1],
      ).createShader(bounds);

    // Stacked annular slices make an actual open bore, including the sidewall.
    for (var z = depth.toInt(); z > 0; z--) {
      canvas.save();
      canvas.translate(0, z.toDouble());
      canvas.drawPath(ring, sidePaint);
      canvas.restore();
    }
    canvas.drawPath(
      ring,
      Paint()
        ..shader = SweepGradient(
          transform: GradientRotation(.35 + math.sin(phase) * .12),
          colors: [
            Color.lerp(
              const Color(0xFF343E4B),
              const Color(0xFF65717F),
              light,
            )!,
            const Color(0xFFD9DFE6),
            const Color(0xFF798593),
            const Color(0xFF273340),
            const Color(0xFFBFC9D5),
            const Color(0xFFF0F3F6),
            const Color(0xFF535E6C),
            Color.lerp(
              const Color(0xFF343E4B),
              const Color(0xFF65717F),
              light,
            )!,
          ],
          stops: const [0, .14, .24, .43, .59, .68, .83, 1],
        ).createShader(bounds),
    );

    // Fine concentric machining catches light without raster textures.
    canvas.save();
    canvas.clipPath(ring);
    for (double r = hole + 2; r < radius; r += 1.9) {
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .45
          ..color = Color.fromRGBO(237, 242, 248, r.toInt().isEven ? .11 : .04),
      );
    }
    canvas.restore();
    for (final r in [radius - 1, radius - 5, radius * .79, hole + 5]) {
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r == radius - 1 ? 1.4 : .9
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xEFFFFFFF), Color(0x00293647), Color(0x80313E50)],
          ).createShader(bounds),
      );
    }
    canvas.drawCircle(
      Offset.zero,
      hole + 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFF151F2B),
    );
    // A wider recessed hub and three inset grips give the objects the
    // construction of weight plates rather than thin decorative discs.
    canvas.drawCircle(
      Offset.zero,
      hole + 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF283544), Color(0xFFCBD4DF)],
        ).createShader(bounds),
    );
    for (final angle in [0.0, math.pi * 2 / 3, math.pi * 4 / 3]) {
      canvas.save();
      canvas.rotate(angle);
      final slot = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(radius * .66, 0),
          width: radius * .095,
          height: radius * .30,
        ),
        Radius.circular(radius * .045),
      );
      canvas.drawRRect(
        slot.shift(const Offset(1, 1.5)),
        Paint()..color = const Color(0x88FFFFFF),
      );
      canvas.drawRRect(
        slot,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF17232E), Color(0xFF596777)],
          ).createShader(slot.outerRect),
      );
      canvas.restore();
    }
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius - 2),
      .07,
      1.1,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x8000E5FF),
    );
    if (light == 1) {
      final label = TextPainter(
        text: const TextSpan(
          text: 'A E O N',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Color(0xFF293443),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(-label.width / 2, -radius * .90));
      final mark = Paint()
        ..color = const Color(0xFF465361)
        ..strokeWidth = 2;
      for (int i = -1; i <= 1; i++) {
        canvas.drawLine(
          Offset(i * 6, radius * .55),
          Offset(i * 6, radius * .65),
          mark,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlatePainter oldDelegate) =>
      oldDelegate.motion != motion;
}
