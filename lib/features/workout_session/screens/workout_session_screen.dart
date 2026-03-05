import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Active Workout Session screen — "Active Mode."
///
/// Distraction-free OLED black background.
/// Set logging, auto-rest timer, RPE sliders — pending implementation.
class WorkoutSessionScreen extends StatelessWidget {
  const WorkoutSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // OLED black for Active Mode
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('ACTIVE MODE', style: AppTypography.headlineMedium),
        leading: BackButton(color: AppColors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined, color: AppColors.primary),
            onPressed: () {},
            tooltip: 'Rest Timer',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: AppColors.primaryDim,
                ),
                const SizedBox(height: 16),
                Text(
                  'Set logger · rest timer · RPE slider',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('Coming soon', style: AppTypography.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
