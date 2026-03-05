import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A glassmorphism card widget consistent with LEON's "Cyber-Slate" aesthetic.
///
/// Wraps [child] with a frosted-glass effect using [BackdropFilter].
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.sigmaBlur = 10.0,
    this.backgroundColor = AppColors.glassWhite,
    this.borderColor = AppColors.glassBorder,
    this.border = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double sigmaBlur;
  final Color backgroundColor;
  final Color borderColor;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaBlur, sigmaY: sigmaBlur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ? Border.all(color: borderColor, width: 0.8) : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
