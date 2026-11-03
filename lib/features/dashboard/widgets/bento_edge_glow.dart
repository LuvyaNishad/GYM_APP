import 'package:flutter/material.dart';

/// Card positions relative to the wide Home action button above the grid.
/// Light faces the button's center and weakens on the more distant lower row.
enum BentoGlowPlacement {
  nearLeft(Offset(1.02, -.05), Size(1.40, 1.40), .12, .42),
  nearRight(Offset(-.02, -.05), Size(1.40, 1.40), .12, .42),
  farLeft(Offset(.98, -.10), Size(1.32, 1.25), .10, .30),
  farRight(Offset(.02, -.10), Size(1.32, 1.25), .10, .30);

  const BentoGlowPlacement(
    this.center,
    this.footprint,
    this.intensity,
    this.rimIntensity,
  );

  final Offset center;
  final Size footprint;
  final double intensity;
  final double rimIntensity;
}

/// Two gradient draws, clipped by the existing card: no blur or extra layer.
class BentoEdgeGlowPainter extends CustomPainter {
  const BentoEdgeGlowPainter({
    required this.placement,
    required this.color,
    this.radius = 20,
  });

  final BentoGlowPlacement placement;
  final Color color;
  final double radius;
  static const _unitRect = Rect.fromLTRB(-1, -1, 1, 1);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(
      size.width * placement.center.dx,
      size.height * placement.center.dy,
    );

    // The source sits above the card. A broader shoulder spreads its light
    // over less than half of the surface while retaining the safe peak alpha.
    final wash = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: placement.intensity),
          color.withValues(alpha: placement.intensity * .80),
          color.withValues(alpha: placement.intensity * .24),
          color.withValues(alpha: 0),
        ],
        stops: const [0, .35, .72, 1],
      ).createShader(_unitRect);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(
      size.width * placement.footprint.width / 2,
      size.height * placement.footprint.height / 2,
    );
    canvas.drawCircle(Offset.zero, 1, wash);
    canvas.restore();

    // A local inner rim catches the same light without a full glowing outline.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..shader =
          RadialGradient(
            colors: [
              color.withValues(alpha: placement.rimIntensity),
              color.withValues(alpha: placement.rimIntensity * .42),
              color.withValues(alpha: 0),
            ],
            stops: const [0, .42, 1],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.shortestSide * .90),
          );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(2.2),
        Radius.circular((radius - 2.2).clamp(0, radius)),
      ),
      rim,
    );
  }

  @override
  bool shouldRepaint(covariant BentoEdgeGlowPainter oldDelegate) =>
      placement != oldDelegate.placement ||
      color != oldDelegate.color ||
      radius != oldDelegate.radius;
}
