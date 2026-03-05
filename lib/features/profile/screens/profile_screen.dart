import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// User profile screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('PROFILE', style: AppTypography.headlineMedium),
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryDim.withOpacity(0.2),
                  child: Icon(Icons.person, size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text('Operator Profile', style: AppTypography.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Stats · Weight unit · Goals',
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
