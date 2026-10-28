import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Lightweight specular light-catch painter that produces a beveled acrylic /
/// cut-glass outline streak along the top and left perimeter with 0 FPS overhead.
class AcrylicStreakPainter extends CustomPainter {
  const AcrylicStreakPainter({
    required this.radius,
    this.strokeWidth = 1.0,
    this.specularColor,
    this.ambientColor,
    this.innerSheen = true,
  });

  final double radius;
  final double strokeWidth;
  final Color? specularColor;
  final Color? ambientColor;
  final bool innerSheen;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final spec = specularColor ?? Colors.white.withValues(alpha: 0.55);
    final amb = ambientColor ?? AppColors.subtleBorder.withValues(alpha: 0.25);

    // 1. Primary outer beveled rim with directional light-catch
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          spec,
          spec.withValues(alpha: (spec.a * 0.55).clamp(0.0, 1.0)),
          amb.withValues(alpha: (amb.a * 0.30).clamp(0.0, 1.0)),
          amb,
        ],
        stops: const [0.0, 0.28, 0.72, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect.deflate(strokeWidth / 2), borderPaint);

    // 2. Inner specular prism streak (liquid glass bevel highlight)
    if (innerSheen && strokeWidth > 0) {
      final innerRRect = rrect.deflate(strokeWidth + 0.8);
      final innerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.75],
        ).createShader(rect);

      canvas.drawRRect(innerRRect, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AcrylicStreakPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.specularColor != specularColor ||
      oldDelegate.ambientColor != ambientColor ||
      oldDelegate.innerSheen != innerSheen;
}

/// Frosted glass surface with an acrylic specular outline streak.
///
/// Cards in scrolling collections should set [sharedBackdrop] and live under a
/// [BackdropGroup]. Flutter can then reuse one blur input for every visible
/// card instead of issuing one expensive off-screen blur pass per item.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.sigmaBlur = 10,
    this.blur = false,
    this.sharedBackdrop = false,
    this.repaintBoundary = false,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.border = true,
    this.borderWidth = 1,
    this.glowColor,
    this.boxShadow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double sigmaBlur;
  final bool blur;
  final bool sharedBackdrop;
  final bool repaintBoundary;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final bool border;
  final double borderWidth;
  final Color? glowColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    final content = CustomPaint(
      foregroundPainter: border
          ? AcrylicStreakPainter(
              radius: borderRadius,
              strokeWidth: borderWidth,
              specularColor: borderColor != null
                  ? borderColor!.withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.40),
              ambientColor: borderColor != null
                  ? borderColor!.withValues(alpha: 0.25)
                  : AppColors.subtleBorder.withValues(alpha: 0.35),
            )
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient:
                  gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor?.withValues(
                            alpha: (backgroundColor!.a * 1.15).clamp(0.0, 1.0),
                          ) ??
                          AppColors.cardBackground.withValues(alpha: 0.78),
                      backgroundColor?.withValues(
                            alpha: (backgroundColor!.a * 0.85).clamp(0.0, 1.0),
                          ) ??
                          AppColors.cardBackground.withValues(alpha: 0.68),
                    ],
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow:
            boxShadow ??
            [
              // Soft ambient drop shadow for depth
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
              if (glowColor != null)
                BoxShadow(color: glowColor!, blurRadius: 22, spreadRadius: -1),
            ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: blur && sigmaBlur > 0
            ? sharedBackdrop
                  ? BackdropFilter.grouped(
                      filter: ImageFilter.blur(
                        sigmaX: sigmaBlur,
                        sigmaY: sigmaBlur,
                      ),
                      child: content,
                    )
                  : BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: sigmaBlur,
                        sigmaY: sigmaBlur,
                      ),
                      child: content,
                    )
            : content,
      ),
    );

    return repaintBoundary ? RepaintBoundary(child: card) : card;
  }
}
