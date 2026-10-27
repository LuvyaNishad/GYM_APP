import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/dashboard_provider.dart';

class WeeklyConsistencyCard extends ConsumerWidget {
  const WeeklyConsistencyCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(weeklyConsistencyProvider);
    return GlassCard(
      border: true,
      blur: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK',
            style: AppTypography.monoSmall.copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '${data.completedThisWeek} of ${data.plannedThisWeek} training days',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final d in data.days)
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        d.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 20,
                        color: AppColors.platinum,
                      ),
                      const SizedBox(height: 7),
                      Text(d.dayLabel, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
