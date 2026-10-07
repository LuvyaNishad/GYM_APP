import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Standard tactical top bar for LEON onboarding steps.
class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    super.key,
    required this.stepLabel,
    required this.progress,
    required this.onBack,
    this.onSkip,
  });

  final String stepLabel;
  final double progress;
  final VoidCallback onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Navigation & Step Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Circular Glass Back Button
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
                ),
              ),

              // Step indicator
              if (stepLabel.isNotEmpty)
                Text(
                  stepLabel,
                  style: AppTypography.labelSmall.copyWith(
                    fontFamily: 'JetBrainsMono',
                    color: AppColors.textSecondary,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                const SizedBox(width: 40),

              // Optional Skip button
              if (onSkip != null)
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: Text(
                    'SKIP',
                    style: AppTypography.labelSmall.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Glowing Cyan Progress Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2537),
              borderRadius: BorderRadius.circular(1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.primary,
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
