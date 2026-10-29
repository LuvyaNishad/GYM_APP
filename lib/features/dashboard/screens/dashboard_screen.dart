/// LEON Dashboard Screen.
///
/// Features:
/// - Clean, minimal, solid retractable calendar header with unified date selection
/// - Compact footsteps bento card (active, 0 steps, unavailable handling)
/// - Compact 2-column bento grid for active calories burn & water intake + sleep
/// - Compact daily workout card with prominent 52dp start workout button
/// - Scrollable daily overview with adaptive recommendations below the grid
/// - Clean dark Cyber-Slate palette without sloppy blur glows
/// - Granular Riverpod rebuild scoping: bento cards watch their own projections via [select]
library;

import 'package:flutter/material.dart';
import '../widgets/training_recommendation_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../state/app_providers.dart';
import '../../history/providers/history_provider.dart';
import '../../../services/pedometer_service.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/calories_bento_card.dart';
import '../widgets/daily_workout_bento_card.dart';
import '../widgets/retractable_calendar_header.dart';
import '../widgets/sleep_bento_card.dart';
import '../widgets/steps_bento_card.dart';
import '../widgets/water_bento_card.dart';

/// Main Dashboard Screen powered by Riverpod and modular minimal bento grids.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Start periodic daily step imports without rebuilding the whole dashboard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(pedometerServiceProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final loggedWorkoutDates = ref.watch(loggedWorkoutDatesProvider);
    final scheduledWorkoutDates = ref.watch(scheduledWorkoutDatesProvider);
    final selectedCalendarDate = ref.watch(selectedCalendarDateProvider);
    final weeklyConsistency = ref.watch(weeklyConsistencyProvider);

    final userName = (userProfile?.displayName.isNotEmpty ?? false)
        ? userProfile!.displayName
        : 'Leon';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. End-to-End Unified Tactical Week Header ───────────────────
          // Corner-to-corner full bleed, integrates consistency tracker & day picker
          SliverToBoxAdapter(
            child: RetractableCalendarHeader(
              userName: userName,
              avatarUrl: userProfile?.avatarUrl,
              selectedDate: selectedCalendarDate,
              onDateSelected: (date) {
                ref.read(selectedCalendarDateProvider.notifier).select(date);
              },
              loggedWorkoutDates: loggedWorkoutDates,
              scheduledWorkoutDates: scheduledWorkoutDates,
              completedSessions: weeklyConsistency.completedThisWeek,
              targetSessions: weeklyConsistency.plannedThisWeek,
            ),
          ),

          // ── 2. Bento Grid Workout & Activity Cards ──────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              AppShell.bottomPadding(context, extra: 24),
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── 1. Compact Daily Workout / Start Workout Bento Card ───────
                const DailyWorkoutBentoCard(),
                const SizedBox(height: 14),

                // ── 2. Today's Activity Section Header ────────────────────────
                Text(
                  "TODAY'S ACTIVITY",
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.platinum,
                    letterSpacing: 1.5,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),

                // ── 3. 4 Equal Square Bento Cards (2x2 Grid) ──────────────────
                // Each bento card granularly watches only its own metrics via .select(...)
                const Row(
                  children: [
                    Expanded(child: StepsBentoCard()),
                    SizedBox(width: 10),
                    Expanded(child: CaloriesBentoCard()),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(child: WaterBentoCard()),
                    SizedBox(width: 10),
                    Expanded(child: SleepBentoCard()),
                  ],
                ),
                const TrainingRecommendationCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
