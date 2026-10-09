/// LEON Tactical Command Center — Dashboard Screen.
///
/// Features:
/// - Clean, minimal, non-glassmorphic solid tactical calendar header
/// - Compact footsteps bento card (8,420 steps, distance, clean activity bars)
/// - Compact 2-column bento grid for calories & water intake + sleep
/// - Compact daily workout card with prominent commence operation button
/// - Zero scroll: entire daily overview & start button fits cleanly on initial view
/// - Clean dark Cyber-Slate palette without sloppy blur glows
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../state/app_providers.dart';
import '../models/daily_telemetry_model.dart';
import '../widgets/calories_bento_card.dart';
import '../widgets/daily_workout_bento_card.dart';
import '../widgets/retractable_calendar_header.dart';
import '../widgets/sleep_bento_card.dart';
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. End-to-End Retractable Tactical Calendar Header ─────────
          // Corner-to-corner full bleed, completely covers top of screen
          SliverToBoxAdapter(
            child: RetractableCalendarHeader(
              userName: operativeName,
              avatarUrl: userProfile?.avatarUrl,
              initialExpanded: true,
            ),
          ),

          // ── 2. Bento Grid Telemetry & Operational Modules ───────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              AppShell.reservedBottomSpace + 16,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Compact Footsteps Tracker Bento Card ───────────────────
                StepsBentoCard(
                  telemetry: telemetry,
                ),
                const SizedBox(height: 10),

                // ── Split Bento Grid: Calories (Left) & Hydration/Sleep (Right) ─
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: CaloriesBentoCard(
                          telemetry: telemetry,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: WaterBentoCard(
                                telemetry: telemetry,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: SleepBentoCard(
                                telemetry: telemetry,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Compact Daily Workout / Start Workout Bento Card ───────
                DailyWorkoutBentoCard(
                  activeSplit: activeSplit,
                  muscleGroups: const ['CHEST', 'DELTOIDS', 'TRICEPS'],
                  exerciseCount: 5,
                  estimatedMinutes: 48,
                  targetRpe: '8.5',
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
