import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// LEON Liquid Glass Container & Painter
///
/// Implements 21st.dev-inspired multi-layered optical refraction and liquid
/// glassmorphism for Flutter:
/// - 28px backdrop blur for frosted depth
/// - Specular highlight perimeter rim with light-gathering caustics
/// - Cylindrical lens surface glare (convex curvature reflection)
/// - Multi-layer inner bevel shadow and double-walled refraction micro-rim
/// - Meniscus perimeter contour for contrast against light or dark backdrops
class LiquidGlassContainer extends StatelessWidget {
  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.blurSigma = 26.0,
    this.glassTint,
    this.borderWidth = 1.2,
    this.showGlow = true,
    this.glowColor,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? glassTint;
  final double borderWidth;
  final bool showGlow;
  final Color? glowColor;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = glowColor ?? AppColors.primary.withValues(alpha: 0.12);
    final radius = BorderRadius.circular(borderRadius);

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          // Deep ambient drop shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 26,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          // Soft contact shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          if (showGlow)
            BoxShadow(
              color: effectiveGlowColor,
              blurRadius: 32,
              spreadRadius: -4,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            foregroundPainter: LiquidGlassPainter(
              radius: borderRadius,
              strokeWidth: borderWidth,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    glassTint ?? const Color(0x1810141E),
                    const Color(0x220A0D14),
                    Colors.white.withValues(alpha: 0.08),
                  ],
                  stops: const [0.0, 0.35, 0.75, 1.0],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );

    return content;
  }
}

/// Custom painter that renders multi-layered refractive glass optics
class LiquidGlassPainter extends CustomPainter {
  const LiquidGlassPainter({
    required this.radius,
    this.strokeWidth = 1.2,
    this.specularIntensity = 1.0,
  });

  final double radius;
  final double strokeWidth;
  final double specularIntensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // ── 1. Curved Lens Sheen (Curved glare on upper 42% of glass) ───────────
    final sheenPath = Path()
      ..moveTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, size.height * 0.40)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.56,
        0,
        size.height * 0.40,
      )
      ..close();

    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.18 * specularIntensity),
          Colors.white.withValues(alpha: 0.05 * specularIntensity),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawPath(sheenPath, sheenPaint);

    // ── 2. Inner Bevel Shadow (Simulating inset 3px 3px shadow) ─────────────
    final innerShadowPath = Path()
      ..addRect(rect.inflate(20))
      ..addRRect(rrect.shift(const Offset(0, 2.0)))
      ..fillType = PathFillType.evenOdd;

    final innerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8);
    canvas.drawPath(innerShadowPath, innerShadowPaint);

    // ── 3. Inner Specular Caustic (Simulating inset -3px -3px highlight) ────
    final causticPath = Path()
      ..addRect(rect.inflate(20))
      ..addRRect(rrect.shift(const Offset(0, -1.8)))
      ..fillType = PathFillType.evenOdd;

    final causticPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42 * specularIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
    canvas.drawPath(causticPath, causticPaint);

    // ── 4. Micro-Groove Internal Highlight (Refraction boundary) ────────────
    final microRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.28 * specularIntensity),
          Colors.white.withValues(alpha: 0.04),
          Colors.white.withValues(alpha: 0.22 * specularIntensity),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(2.2), microRimPaint);

    canvas.restore();

    // ── 5. Specular Border Rim (Multi-directional catch-light stroke) ─────────
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.88 * specularIntensity),
          Colors.white.withValues(alpha: 0.24),
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.40),
          Colors.white.withValues(alpha: 0.92 * specularIntensity),
        ],
        stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(strokeWidth / 2), borderPaint);

    // ── 6. Outer Meniscus Rim (Crisp Dark Contour Line) ─────────────────────
    final outerMeniscus = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawRRect(rrect, outerMeniscus);
  }

  @override
  bool shouldRepaint(covariant LiquidGlassPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.specularIntensity != specularIntensity;
  }
}

/// Standalone Liquid Glass Button inspired by 21st.dev LiquidButton
class LiquidGlassButton extends StatefulWidget {
  const LiquidGlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.height = 48,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.borderRadius,
    this.accentColor,
    this.isLoading = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double height;
  final double? width;
  final EdgeInsetsGeometry padding;
  final double? borderRadius;
  final Color? accentColor;
  final bool isLoading;

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final radiusVal = widget.borderRadius ?? (widget.height / 2);
    final accent = widget.accentColor ?? AppColors.primary;
    final enabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
      child: LiquidGlassContainer(
        width: widget.width,
        height: widget.height,
        borderRadius: radiusVal,
        glowColor: accent.withValues(alpha: 0.2),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(radiusVal),
            onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
            onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onPressed!();
                  }
                : null,
            child: Padding(
              padding: widget.padding,
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      )
                    : DefaultTextStyle(
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        child: widget.child,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
