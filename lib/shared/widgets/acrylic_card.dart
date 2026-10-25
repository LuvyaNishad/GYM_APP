import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// A sleek, high-performance acrylic card widget for LEON's Bento Grid
/// and Workout Sections.
///
/// Features:
/// - Slight frosted acrylic blur (`sigma: 10.0`), distinctly lighter and more
///   grounded than the high-intensity floating navbar pill (`sigma: 18.0`, alpha: 0.40)
/// - Translucent dark slate-charcoal body (~74% opacity) allowing the atmospheric
///   ambient glow to gently diffuse through without degrading text contrast
/// - Hairline specular border stroke (`0xFF373942` at 75% opacity or custom accent)
/// - Subtle elevation drop shadow for separation from OLED black background
/// - Optional interactive tap handling with light haptic feedback and splash
class AcrylicCard extends StatelessWidget {
  const AcrylicCard({
    super.key,
    required this.child,
    this.borderRadius = 22.0,
    this.padding,
    this.margin,
    this.borderWidth = 1.0,
    this.borderColor,
    this.backgroundColor,
    this.blurSigma = 10.0,
    this.boxShadow,
    this.glowColor,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  /// The child content placed inside the acrylic card.
  final Widget child;

  /// Corner radius in dp (defaults to 22.0 for standard bento cards).
  final double borderRadius;

  /// Internal padding for the card contents.
  final EdgeInsetsGeometry? padding;

  /// External margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Border hairline stroke width.
  final double borderWidth;

  /// Custom border stroke color (defaults to subtle steel border at 75% opacity).
  final Color? borderColor;

  /// Custom base background color. If null, a default 74% opacity slate gradient is applied.
  final Color? backgroundColor;

  /// Frosted glass blur strength (defaults to 10.0 for slight acrylic effect).
  final double blurSigma;

  /// Custom drop shadows.
  final List<BoxShadow>? boxShadow;

  /// Optional ambient glow accent color (e.g. cyan when workout active).
  final Color? glowColor;

  /// Optional card tap callback.
  final VoidCallback? onTap;

  /// Clip behavior for the card corners.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    final effectiveBorderColor =
        borderColor ?? AppColors.subtleBorder.withValues(alpha: 0.75);

    final effectiveShadows = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.16),
              blurRadius: 18,
              spreadRadius: -1,
              offset: const Offset(0, 2),
            ),
        ];

    // Card decoration: translucent acrylic gradient allowing background glow to diffuse through
    final decoration = BoxDecoration(
      borderRadius: radius,
      border: Border.all(
        color: effectiveBorderColor,
        width: borderWidth,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          backgroundColor?.withValues(alpha: 0.80) ??
              const Color(0xFF222634).withValues(alpha: 0.76),
          backgroundColor?.withValues(alpha: 0.70) ??
              const Color(0xFF141722).withValues(alpha: 0.72),
        ],
      ),
    );

    Widget innerContent = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    // If interactive, wrap with transparent Material & InkWell with ripple
    if (onTap != null) {
      innerContent = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap!();
          },
          borderRadius: radius,
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: innerContent,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: decoration,
            child: innerContent,
          ),
        ),
      ),
    );
  }
}
