import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/entry_widgets.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    super.key,
    required this.stepLabel,
    required this.progress,
    this.onBack,
    this.onSkip,
  });
  final String stepLabel;
  final double progress;
  final VoidCallback? onBack, onSkip;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
            ),
            Expanded(
              child: Text(
                stepLabel,
                textAlign: TextAlign.center,
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            if (onSkip != null)
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: const Size(48, 48),
                ),
                child: const Text('Skip', style: AppTypography.bodyMedium),
              )
            else
              const SizedBox(width: 64),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    child: AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: progress * 4 > i
                            ? EntryStyle.accent
                            : const Color(0xFF3B4655),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
