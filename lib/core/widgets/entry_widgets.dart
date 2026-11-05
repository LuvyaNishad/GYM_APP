import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The first-use surfaces keep cyan for decisions, silver for decoration.
abstract final class EntryStyle {
  static const accent = Color(0xFF00E5FF);
  static const heading = TextStyle(
    fontFamily: AppTypography.fontDisplay,
    fontSize: 34,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.12,
    color: AppColors.textPrimary,
  );

  static InputDecoration input(
    String label, {
    Widget? suffix,
    String? helper,
  }) => InputDecoration(
    labelText: label,
    helperText: helper,
    helperMaxLines: 3,
    errorMaxLines: 3,
    suffixIcon: suffix,
    labelStyle: AppTypography.bodyMedium,
    floatingLabelStyle: AppTypography.bodyMedium.copyWith(color: accent),
    filled: true,
    fillColor: const Color(0xFF1B222D),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF46515F)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: accent, width: 1.5),
    ),
  );
}

class EntryButton extends StatelessWidget {
  const EntryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool primary, busy;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 56),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      backgroundColor: primary ? EntryStyle.accent : const Color(0xFF202833),
      foregroundColor: primary ? AppColors.onyx : Colors.white,
      disabledBackgroundColor: const Color(0xFF303A45),
      disabledForegroundColor: AppColors.textSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: primary ? EntryStyle.accent : const Color(0xFF4B5665),
        ),
      ),
      textStyle: AppTypography.button,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: 12),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}

class EntryNotice extends StatelessWidget {
  const EntryNotice(this.message, {super.key, this.error = false});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(
          color: error ? AppColors.danger : AppColors.textSecondary,
        ),
      ),
    ),
  );
}
