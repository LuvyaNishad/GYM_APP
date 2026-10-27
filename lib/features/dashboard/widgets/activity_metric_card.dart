import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';

class ActivityMetricCard extends StatelessWidget {
  const ActivityMetricCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.caption,
    required this.onTap,
    this.progress,
  });
  final String title, value, caption;
  final IconData icon;
  final VoidCallback onTap;
  final double? progress;
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    border: true,
    blur: false,
    padding: const EdgeInsets.all(13),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 102),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.platinum),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.platinum,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.monoMedium.copyWith(
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.platinum,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          if (progress != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 3,
                color: AppColors.platinum,
                backgroundColor: AppColors.steel,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    ),
  );
}
