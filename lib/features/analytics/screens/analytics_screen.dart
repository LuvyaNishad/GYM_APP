import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Analytics & progress charts screen.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('ANALYTICS', style: AppTypography.headlineMedium),
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.show_chart, size: 48, color: AppColors.primaryDim),
                const SizedBox(height: 16),
                Text(
                  '1RM trends · Volume · PRs',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'fl_chart — pending data',
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
