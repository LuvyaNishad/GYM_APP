import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A glassmorphism card widget, the base surface of LEON's Liquid Glass
/// Tactical system.
///
/// Wraps [child] with a frosted-glass effect using [BackdropFilter]. Defaults
/// come straight from the spec: 24px blur, 24px radius, 24px padding, a 1px
/// 20 %-white border, and a very faint fill. **No inner shadows** — refraction
/// does the depth work, so a shadow only muddies it.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 24,
    this.sigmaBlur = 24.0,
    this.backgroundColor = AppColors.glassWhite,
    this.borderColor = AppColors.glassBorder,
    this.border = true,
    this.borderWidth = 1.0,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double sigmaBlur;
  final Color backgroundColor;
  final Color borderColor;
  final bool border;
  final double borderWidth;

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
            border: border
                ? Border.all(color: borderColor, width: borderWidth)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
