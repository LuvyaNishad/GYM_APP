import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import 'bento_edge_glow.dart';

class ActivityMetricCard extends StatelessWidget {
  const ActivityMetricCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.caption,
    required this.onTap,
    this.progress,
    this.glowPlacement = BentoGlowPlacement.nearLeft,
  });
  final String title, value, caption;
  final IconData icon;
  final VoidCallback onTap;
  final double? progress;
  final BentoGlowPlacement glowPlacement;
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    border: true,
    blur: true,
    sharedBackdrop: true,
    repaintBoundary: true,
    surfacePainter: BentoEdgeGlowPainter(
      placement: glowPlacement,
      color: Theme.of(context).colorScheme.primary,
    ),
    padding: const EdgeInsets.all(12),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 80),
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
          const SizedBox(height: 8),
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
