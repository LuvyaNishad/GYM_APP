import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../history/providers/training_coverage_provider.dart';

class TrainingRecommendationCard extends ConsumerWidget {
  const TrainingRecommendationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = ref.watch(homeTrainingRecommendationProvider);
    if (recommendation == null) return const SizedBox.shrink();
    return GlassCard(
      sharedBackdrop: true,
      repaintBoundary: true,
      blur: true,
      padding: const EdgeInsets.all(12),
      onTap: () => context.push(AppConstants.routeRoutineLibrary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TRAINING RECOMMENDATION',
            style: AppTypography.headlineSmall.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            recommendation.exercise.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineSmall.copyWith(
              fontSize: 14,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${recommendation.muscle.name} · ${recommendation.exercise.sets} planned sets · View routine ›',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              height: 1.3,
              color: AppColors.platinum,
            ),
          ),
        ],
      ),
    );
  }
}
