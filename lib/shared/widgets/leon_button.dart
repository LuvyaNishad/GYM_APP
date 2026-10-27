import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.isOutlined = false,
    this.width,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDestructive;
  final bool isOutlined;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Color accent = isDestructive ? AppColors.danger : AppColors.primary;
    final bool enabled = !isLoading && onPressed != null;
    final BorderRadius radius = BorderRadius.circular(height / 2);

    final Color bgColor = isOutlined
        ? Colors.white.withValues(alpha: 0.05)
        : accent;
    final Color fgColor = isOutlined
        ? AppColors.textPrimary
        : AppColors.background;
    final Color contentColor = enabled ? fgColor : AppColors.textMuted;
    final Color iconColor = enabled
        ? (isOutlined ? accent : AppColors.background)
        : AppColors.textMuted;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: isOutlined
              ? Border.all(color: accent.withValues(alpha: 0.40), width: 1.5)
              : null,
          boxShadow: enabled && !isOutlined
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
          onPressed: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            disabledBackgroundColor: AppColors.surfaceVariant,
            disabledForegroundColor: AppColors.textMuted,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          icon: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: contentColor,
                  ),
                )
              : (icon != null
                    ? Icon(icon, size: 18, color: iconColor)
                    : const SizedBox.shrink()),
          label: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.button.copyWith(
              color: contentColor,
              letterSpacing: 1.5,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
