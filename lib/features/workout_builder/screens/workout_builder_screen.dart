import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/leon_button.dart';

/// The Workout Builder screen — "The Attache Case."
///
/// Users drag exercises into a grid layout to plan their workout.
/// Full implementation pending; scaffold is in place.
class WorkoutBuilderScreen extends StatelessWidget {
  const WorkoutBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('WORKOUT BUILDER', style: AppTypography.headlineMedium),
        backgroundColor: AppColors.background,
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('THE ATTACHÉ CASE', style: AppTypography.labelSmall),
            const SizedBox(height: 8),
            Text('Build your workout', style: AppTypography.headlineLarge),
            const SizedBox(height: 20),

            // Placeholder grid
            Expanded(
              child: GlassCard(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        size: 48,
                        color: AppColors.primaryDim,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Exercise grid — coming soon',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            LeonButton(
              label: 'Start Workout',
              icon: Icons.play_arrow,
              onPressed: () {},
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
