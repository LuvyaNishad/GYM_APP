import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

/// Recovery status ECG-style widget.
///
/// Displays a coloured status indicator (Green = Ready, Red = Rest).
/// Placeholder until the recovery algorithm is wired to real data.
class RecoveryStatusWidget extends StatelessWidget {
  const RecoveryStatusWidget({super.key, this.isReady = true});

  final bool isReady;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isReady ? AppColors.success : AppColors.danger;
    final String statusLabel = isReady ? 'READY TO TRAIN' : 'REST RECOMMENDED';
    final IconData statusIcon = isReady
        ? Icons.favorite
        : Icons.favorite_border;

    return GlassCard(
      child: Row(
        children: [
          // Pulsing status dot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withOpacity(0.15),
                  border: Border.all(
                    color: statusColor.withOpacity(value),
                    width: 2,
                  ),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RECOVERY STATUS', style: AppTypography.labelSmall),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: AppTypography.titleLarge.copyWith(color: statusColor),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
