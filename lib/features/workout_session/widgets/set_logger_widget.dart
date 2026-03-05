import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Set logger widget for the Active Workout Session screen.
///
/// Allows the user to log reps, weight, and RPE for each set.
/// Full implementation pending; scaffold is in place.
class SetLoggerWidget extends StatelessWidget {
  const SetLoggerWidget({
    super.key,
    required this.setNumber,
    this.onLogSet,
  });

  final int setNumber;
  final VoidCallback? onLogSet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Text(
            'SET $setNumber',
            style: AppTypography.monoSmall,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '— reps  —  kg  RPE —',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline,
                color: AppColors.success),
            onPressed: onLogSet,
            tooltip: 'Log set',
          ),
        ],
      ),
    );
  }
}
