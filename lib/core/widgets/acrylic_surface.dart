import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable physical acrylic container surface.
///
/// Combines hardware-accelerated frosted transmission blur, internal bulk
/// absorption tinting, and directional specular edge highlights matching
/// the Noguchi / Cyber-Slate design language.
class AcrylicSurface extends StatelessWidget {
  const AcrylicSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 22.0,
    this.blurSigma = 20.0,
    this.acrylicTint,
    this.borderWidth = 1.2,
    this.showSpecularBevel = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final Color? acrylicTint;
  final double borderWidth;
  final bool showSpecularBevel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final tint = acrylicTint ?? AppColors.charcoal.withValues(alpha: 0.65);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          // Soft ambient contact shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          // Subtle platinum rim dispersion hint
          BoxShadow(
            color: AppColors.platinum.withValues(alpha: 0.04),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: radius,
              border: Border.all(
                color: showSpecularBevel
                    ? AppColors.platinum.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.10),
                width: borderWidth,
              ),
              gradient: showSpecularBevel
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.16), // Specular key light
                        AppColors.charcoal.withValues(alpha: 0.05),
                        AppColors.platinum.withValues(alpha: 0.06), // Secondary rim
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
