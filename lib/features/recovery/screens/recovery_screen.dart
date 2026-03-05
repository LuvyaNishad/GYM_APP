import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Recovery & sleep tracking screen.
class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('RECOVERY', style: AppTypography.headlineMedium),
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bedtime_outlined,
                  size: 48,
                  color: AppColors.primaryDim,
                ),
                const SizedBox(height: 16),
                Text(
                  'Recovery metrics — pending',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text('Sleep · HRV · Soreness', style: AppTypography.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
