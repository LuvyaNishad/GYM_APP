/// LEON Tactical Command Center — Dashboard Screen.
///
/// Features:
/// - Clean, minimal, non-glassmorphic solid tactical calendar header
/// - Compact footsteps bento card (8,420 steps, distance, clean activity bars)
/// - Compact 2-column bento grid for calories & water intake
/// - Compact daily workout card with prominent commence operation button
/// - Zero mandatory scroll: entire daily overview & start button fits on initial view
/// - Clean dark Cyber-Slate palette without sloppy blur glows
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../state/app_providers.dart';
import '../models/daily_telemetry_model.dart';
import '../widgets/calories_bento_card.dart';
import '../widgets/daily_workout_bento_card.dart';
import '../widgets/retractable_calendar_header.dart';
import '../widgets/steps_bento_card.dart';
import '../widgets/water_bento_card.dart';

/// Main Dashboard Screen powered by Riverpod and modular minimal bento grids.
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
                16,
                6,
                16,
                AppShell.reservedBottomSpace + 20,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── 1. Clean Solid Retractable Calendar Header ────────────
                  RetractableCalendarHeader(
                    userName: operativeName,
                    avatarUrl: userProfile?.avatarUrl,
                    initialExpanded: true,
                  ),
                  const SizedBox(height: 10),

                  // ── 2. Compact Footsteps Tracker Bento Card ───────────────
                  StepsBentoCard(
                    telemetry: telemetry,
                  ),
                  const SizedBox(height: 10),

                  // ── 3. Compact Split Bento Grid: Calories & Water ─────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CaloriesBentoCard(
                          telemetry: telemetry,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: WaterBentoCard(
                          telemetry: telemetry,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── 4. Compact Daily Workout / Start Workout Bento Card ───
                  DailyWorkoutBentoCard(
                    activeSplit: activeSplit,
                    muscleGroups: const ['CHEST', 'DELTOIDS', 'TRICEPS'],
                    exerciseCount: 5,
                    estimatedMinutes: 48,
                    targetRpe: '8.5',
                  ),
                  const SizedBox(height: 20),

                  // ── 5. Secondary Tactical Modules (Scroll to inspect) ─────
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
                          fontSize: 10.5,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

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
                      const SizedBox(width: 10),
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
                  const SizedBox(height: 10),
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
                      const SizedBox(width: 10),
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

/// Tactical Clean Module Tile for secondary access.
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161A23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: accentColor, size: 18),
                    ),
                    const Icon(
                      Icons.arrow_outward_rounded,
                      color: AppColors.textMuted,
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    fontFamily: 'Outfit',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
