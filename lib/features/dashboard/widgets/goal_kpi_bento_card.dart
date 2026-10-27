import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/user_model.dart';
import '../../../state/app_providers.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/widgets/goal_selector_sheet.dart';

/// Full-width Bento card rendering live progress metrics and coaching cues
/// specifically tailored to the user's active training goal (Bulk, Cut, Strength, Muscle).
class GoalKpiBentoCard extends ConsumerWidget {
  const GoalKpiBentoCard({super.key});

  static const Color _cardBg = AppColors.charcoal;

  void _showGoalSelectorSheet(BuildContext context, WidgetRef ref) {
    showGoalSelectorSheet(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalConfig = ref.watch(trainingGoalConfigProvider);
    final user = ref.watch(userProfileProvider);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Goal Badge + Title + Edit Goal Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: goalConfig.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: goalConfig.accentColor.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'GOAL: ${goalConfig.displayName}',
                          style: AppTypography.monoSmall.copyWith(
                            color: goalConfig.accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          goalConfig.primaryMetricLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showGoalSelectorSheet(context, ref),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CHANGE',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_right_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Main Goal Metric Content
            _buildGoalContent(goalConfig, user),

            const SizedBox(height: 10),

            // Chips Row: Rep Targets + Rest Intervals
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.repeat_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Target: ${goalConfig.targetRepRange}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Rest: ${goalConfig.defaultRestSeconds}s',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalContent(TrainingGoalConfig config, UserModel? user) {
    switch (config.type) {
      case TrainingGoalType.loseFat:
        final currentWeight = user?.currentWeight ?? 78.0;
        final targetWeight = user?.targetWeight ?? 74.0;
        final unit = user?.weightUnit ?? 'kg';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WEIGHT DEFICIT PACE',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$currentWeight → $targetWeight $unit',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.secondary,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.65,
                backgroundColor: Color(0xFF1E2537),
                color: AppColors.secondary,
                minHeight: 6,
              ),
            ),
          ],
        );

      case TrainingGoalType.strength:
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BENCH PRESS 1RM',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '102.5 KG',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontFamily: AppTypography.fontMono,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 32, color: AppColors.steel),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SQUAT 1RM',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '140.0 KG',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontFamily: AppTypography.fontMono,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case TrainingGoalType.athletic:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SYMMETRY & DENSITY',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '94% BALANCED',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.94,
                backgroundColor: Color(0xFF1E2537),
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
          ],
        );

      case TrainingGoalType.buildMuscle:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WEEKLY DIRECT SETS',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '14 / 16 SETS (88%)',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.88,
                backgroundColor: Color(0xFF1E2537),
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
          ],
        );
    }
  }
}
