import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';

/// Interactive glass bottom sheet allowing athletes to change their active training goal
/// (Build Muscle, Strength, Lose Fat, Athletic) from anywhere in the app.
void showGoalSelectorSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF161A23),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final currentGoal = ref.watch(trainingGoalProvider);
      final goals = [
        {
          'title': 'BUILD MUSCLE',
          'desc': 'Hypertrophy & volume accumulation (8-12 reps, 120s rest)',
          'icon': Icons.fitness_center_rounded,
        },
        {
          'title': 'STRENGTH',
          'desc': 'Maximal power & compound PRs (3-6 reps, 180s rest)',
          'icon': Icons.bolt_rounded,
        },
        {
          'title': 'LOSE FAT',
          'desc': 'High density & metabolic caloric deficit (10-15 reps, 60s rest)',
          'icon': Icons.local_fire_department_rounded,
        },
        {
          'title': 'ATHLETIC',
          'desc': 'Conditioning, speed, and movement symmetry (6-10 reps, 90s rest)',
          'icon': Icons.speed_rounded,
        },
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'CHANGE TRAINING GOAL',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your dashboard targets and workout defaults will update instantly.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.0,
                ),
              ),
              const SizedBox(height: 14),
              ...goals.map((item) {
                final isSelected = currentGoal == item['title'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      try {
                        HapticFeedback.selectionClick();
                      } catch (_) {}
                      ref
                          .read(onboardingProvider.notifier)
                          .updatePrimaryGoal(item['title'] as String);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['desc'] as String,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
