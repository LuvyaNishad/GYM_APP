/// LEON Tactical Command Center — Dashboard Screen.
///
/// Features:
/// - Retractable interactive calendar header (Hello [Name], PFP, week calendar strip)
/// - Footsteps Bento Card: 8,420 steps, +6.12 km, 12-hour activity bar chart with peak tooltip
/// - Calories & Hydration Bento Grid: 2-column split with radial donut chart and fluid wave curve
/// - Daily Workout Bento Card: Info of the day, targeted muscle groups, and prominent start button
/// - Tactical Module Quick Access: Builder, Database, Telemetry, and Vitals
/// - Optimized scroll clearance for the floating glass navigation pill
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../state/app_providers.dart';
import '../models/daily_telemetry_model.dart';
import '../widgets/calories_bento_card.dart';
import '../widgets/daily_workout_bento_card.dart';
import '../widgets/retractable_calendar_header.dart';
import '../widgets/steps_bento_card.dart';
import '../widgets/water_bento_card.dart';

/// Main Dashboard Screen powered by Riverpod and modular glass bento grids.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final activeSplit = ref.watch(activeSplitProvider);
    final telemetry = ref.watch(dailyTelemetryProvider);

    final operativeName = (userProfile?.displayName.isNotEmpty ?? false)
        ? userProfile!.displayName
        : 'Leon';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Main Content Padding ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                AppShell.reservedBottomSpace + 28,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── 1. Retractable Calendar Header ────────────────────────
                  RetractableCalendarHeader(
                    userName: operativeName,
                    avatarUrl: userProfile?.avatarUrl,
                    initialExpanded: true,
                  ),
                  const SizedBox(height: 16),

                  // ── 2. Footsteps Tracker Bento Card ───────────────────────
                  StepsBentoCard(
                    telemetry: telemetry,
                  ),
                  const SizedBox(height: 16),

                  // ── 3. Split Bento Grid: Calories & Water ─────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CaloriesBentoCard(
                          telemetry: telemetry,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: WaterBentoCard(
                          telemetry: telemetry,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── 4. Daily Workout / Start Workout Bento Card ───────────
                  DailyWorkoutBentoCard(
                    activeSplit: activeSplit,
                    muscleGroups: const ['CHEST', 'DELTOIDS', 'TRICEPS'],
                    exerciseCount: 5,
                    estimatedMinutes: 48,
                    targetRpe: '8.5',
                  ),
                  const SizedBox(height: 24),

                  // ── 5. Tactical Module Shortcuts ──────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TACTICAL MODULES',
                        style: AppTypography.labelSmall.copyWith(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _TacticalModuleTile(
                          icon: Icons.tune_rounded,
                          title: 'BUILDER',
                          subtitle: 'Attache Case',
                          accentColor: AppColors.primary,
                          onTap: () =>
                              context.go(AppConstants.routeWorkoutBuilder),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TacticalModuleTile(
                          icon: Icons.local_fire_department_rounded,
                          title: 'DATABASE',
                          subtitle: 'Movement Index',
                          accentColor: AppColors.secondary,
                          onTap: () =>
                              context.go(AppConstants.routeExerciseLibrary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TacticalModuleTile(
                          icon: Icons.insights_rounded,
                          title: 'TELEMETRY',
                          subtitle: 'Progress Log',
                          accentColor: AppColors.purple,
                          onTap: () => context.go(AppConstants.routeAnalytics),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TacticalModuleTile(
                          icon: Icons.monitor_heart_outlined,
                          title: 'VITALS',
                          subtitle: 'Health Sync',
                          accentColor: AppColors.success,
                          onTap: () =>
                              context.push(AppConstants.routeHealthTracking),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tactical Glass Module Tile for the dashboard grid.
class _TacticalModuleTile extends StatelessWidget {
  const _TacticalModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: accentColor.withValues(alpha: 0.1),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                color: AppColors.textMuted,
                size: 15,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
