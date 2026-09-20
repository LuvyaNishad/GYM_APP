import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// LEON primary button.
///
/// Per the Liquid Glass Tactical spec, primary buttons are **opaque** — only
/// cards are glass. Solid cyan on near-black text, fully pill-shaped, with a
/// centred radial glow (`0 0 20px rgba(0,229,255,0.2)`) rather than a dropped
/// shadow: the button reads as emitting light, not casting it.
class LeonButton extends StatelessWidget {
  const LeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDestructive = false,
    this.width,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDestructive;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Color accent = isDestructive ? AppColors.danger : AppColors.primary;
    final bool enabled = !isLoading && onPressed != null;
    final BorderRadius radius = BorderRadius.circular(height / 2);

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: enabled
              ? [
                  // No offset — a centred glow, not a shadow.
                  BoxShadow(
                    color: accent.withValues(alpha: 0.20),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: AppColors.background,
            disabledBackgroundColor: accent.withValues(alpha: 0.30),
            disabledForegroundColor: AppColors.background,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.background,
                  ),
                )
              : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
          label: Text(
            label.toUpperCase(),
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.background,
              letterSpacing: 1.8,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
