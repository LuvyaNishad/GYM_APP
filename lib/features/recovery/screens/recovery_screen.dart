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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF00E5FF),
              size: 20,
            ),
            tooltip: 'Recovery Science',
            onPressed: () => _showRecoveryScienceDialog(context),
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
                Text(
                  'Sleep · HRV · Soreness',
                  style: AppTypography.labelSmall.copyWith(fontSize: 11.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecoveryScienceDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.onyx,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.steel),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.favorite_outline_rounded,
              color: Color(0xFF00E5FF),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'RECOVERY READINESS',
              style: AppTypography.headlineSmall.copyWith(
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.pureWhite,
              ),
            ),
          ],
        ),
        content: const Text(
          'Self-reported readiness estimate based on workout frequency, rest intervals, and logged sleep/hydration. Not a medical evaluation.\n\nAlways listen to your body, warm up thoroughly, and adjust training intensity when fatigue accumulates.',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'UNDERSTOOD',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
