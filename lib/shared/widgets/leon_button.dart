import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/raised_button_surface.dart';
import 'immediate_press_feedback.dart';

/// AEON primary button.
///
/// Primary buttons are opaque; cards use glass. Theme accent, a pill shape,
/// and the shared shallow bevel with a close contact shadow.
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
    final scheme = Theme.of(context).colorScheme;
    final Color accent = isDestructive ? scheme.error : scheme.primary;
    final bool enabled = !isLoading && onPressed != null;
    final BorderRadius radius = BorderRadius.circular(height / 2);

    final Color bgColor = isOutlined
        ? Colors.white.withValues(alpha: 0.05)
        : accent;
    final Color fgColor = isOutlined
        ? scheme.onSurface
        : isDestructive
        ? scheme.onError
        : scheme.onPrimary;
    final Color contentColor = enabled ? fgColor : AppColors.textMuted;
    final Color iconColor = enabled
        ? (isOutlined ? accent : fgColor)
        : AppColors.textMuted;
    final labelWidget = Text(
      label.toUpperCase(),
      textAlign: TextAlign.center,
      softWrap: true,
      style: AppTypography.button.copyWith(
        color: contentColor,
        letterSpacing: 1.5,
        fontSize: 13,
      ),
    );
    final iconSlot = SizedBox(
      width: 18,
      height: 18,
      child: isLoading
          ? CircularProgressIndicator(strokeWidth: 2, color: contentColor)
          : icon != null
          ? Icon(icon, size: 18, color: iconColor)
          : null,
    );

    return SizedBox(
      width: width,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Semantics(
          liveRegion: isLoading,
          value: isLoading ? 'In progress' : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: isOutlined
                  ? Border.all(
                      color: accent.withValues(alpha: 0.40),
                      width: 1.5,
                    )
                  : null,
              boxShadow: enabled && !isOutlined
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ImmediatePressFeedback(
              enabled: enabled,
              builder: (context, statesController) => ElevatedButton(
                statesController: statesController,
                onPressed: enabled
                    ? () {
                        HapticFeedback.lightImpact();
                        onPressed!();
                      }
                    : null,
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: bgColor,
                      foregroundColor: fgColor,
                      disabledBackgroundColor: AppColors.surfaceVariant,
                      disabledForegroundColor: AppColors.textMuted,
                      elevation: 0,
                      minimumSize: Size(0, height),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: radius),
                    ).copyWith(
                      animationDuration: Duration.zero,
                      elevation: const WidgetStatePropertyAll(0),
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.disabled)) {
                          return AppColors.surfaceVariant;
                        }
                        return isOutlined &&
                                states.contains(WidgetState.pressed)
                            ? Color.alphaBlend(
                                accent.withValues(alpha: .12),
                                bgColor,
                              )
                            : bgColor;
                      }),
                      backgroundBuilder: isOutlined
                          ? plainButtonBackground
                          : raisedButtonBackground,
                    ),
                child: icon != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          iconSlot,
                          const SizedBox(width: 8),
                          Flexible(child: labelWidget),
                        ],
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: labelWidget,
                          ),
                          if (isLoading) Positioned(left: 0, child: iconSlot),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
