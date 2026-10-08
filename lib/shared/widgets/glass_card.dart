import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A premium glassmorphism card widget — the foundational surface of LEON's
/// Liquid Glass Tactical system.
///
/// Features:
/// - 24px hardware-accelerated frosted backdrop blur
/// - Multi-tone specular border gradient with top-left catch-light
/// - Cylindrical lens surface glare (convex curvature reflection)
/// - Subtle elevation drop shadow for separation from OLED black
/// - Optional glow accent for interactive or highlighted status
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 22,
    this.sigmaBlur = 24.0,
    this.backgroundColor,
    this.borderColor,
    this.border = true,
    this.borderWidth = 1.0,
    this.glowColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double sigmaBlur;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool border;
  final double borderWidth;
  final Color? glowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          // Soft ambient drop shadow for elevation
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.16),
              blurRadius: 24,
              spreadRadius: -2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaBlur, sigmaY: sigmaBlur),
          child: CustomPaint(
            foregroundPainter: border
                ? _GlassCardBorderPainter(
                    radius: borderRadius,
                    strokeWidth: borderWidth,
                    borderColor: borderColor,
                  )
                : null,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundColor ?? const Color(0x1E222C3D),
                    const Color(0x14121622),
                    const Color(0x1E0A0D14),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: card,
        ),
      );
    }

    return card;
  }
}

class _GlassCardBorderPainter extends CustomPainter {
  const _GlassCardBorderPainter({
    required this.radius,
    required this.strokeWidth,
    this.borderColor,
  });

  final double radius;
  final double strokeWidth;
  final Color? borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Specular top-down lens reflection
    final sheenPath = Path()
      ..moveTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.45,
        0,
        size.height * 0.35,
      )
      ..close();

    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.07),
          Colors.white.withValues(alpha: 0.02),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect);

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawPath(sheenPath, sheenPaint);
    canvas.restore();

    // Multi-tone edge border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          borderColor ?? Colors.white.withValues(alpha: 0.42),
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.06),
          borderColor ?? Colors.white.withValues(alpha: 0.28),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect.deflate(strokeWidth / 2), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _GlassCardBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderColor != borderColor;
  }
}
