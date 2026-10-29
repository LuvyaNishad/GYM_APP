import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../history/providers/training_coverage_provider.dart';

class TrainingRecommendationCard extends ConsumerWidget {
  const TrainingRecommendationCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = ref.watch(homeTrainingRecommendationProvider);
    if (recommendation == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GlassCard(
        blur: true,
        padding: const EdgeInsets.all(16),
        onTap: () => context.push(AppConstants.routeRoutineLibrary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✨ RECOMMENDED FOR YOUR NEXT WORKOUT',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${recommendation.day.name} · ${recommendation.muscle.name}',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Prioritize ${recommendation.exercise.name} within your planned ${recommendation.exercise.sets} sets.',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Below your target on ${MaterialLocalizations.of(context).formatShortDate(recommendation.previous.workout.date)} · View routine ›',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
