import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/glass_card.dart';
import '../widgets/radar_chart_widget.dart';
import '../widgets/recovery_status_widget.dart';

/// LEON Command Center — main dashboard screen.
///
/// Shows the muscle-balance radar chart, recovery status, and quick-action
/// shortcuts. Navigates to [WorkoutBuilderScreen] or [WorkoutSessionScreen].
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                AppConstants.appName,
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 4,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.person_outline,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {},
                tooltip: 'Profile',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Recovery Status
                const RecoveryStatusWidget(),
                const SizedBox(height: 20),

                // Radar Chart Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MUSCLE BALANCE', style: AppTypography.labelSmall),
                      const SizedBox(height: 4),
                      Text('This Week', style: AppTypography.headlineMedium),
                      const SizedBox(height: 16),
                      const SizedBox(height: 240, child: RadarChartWidget()),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Actions
                Text('QUICK ACTIONS', style: AppTypography.labelSmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.add_circle_outline,
                        label: 'New\nWorkout',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.history,
                        label: 'History',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.bar_chart,
                        label: 'Analytics',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact glass quick-action button for the dashboard grid.
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
