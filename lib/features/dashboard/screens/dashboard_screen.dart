/// LEON Dashboard Screen.
///
/// Features:
/// - Clean, minimal, solid retractable calendar header with unified date selection
/// - Compact footsteps bento card (active, 0 steps, unavailable handling)
/// - Compact 2-column bento grid for active calories burn & water intake + sleep
/// - Compact daily workout card with prominent 52dp start workout button
/// - Zero scroll: entire daily overview & start button fits cleanly on initial view
/// - Clean dark Cyber-Slate palette without sloppy blur glows
/// - Granular Riverpod rebuild scoping: bento cards watch their own projections via [select]
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
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
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep hardware pedometer sensor listening in background
    ref.watch(pedometerServiceProvider);

    final userProfile = ref.watch(userProfileProvider);
    final loggedWorkoutDates = ref.watch(loggedWorkoutDatesProvider);
    final selectedCalendarDate = ref.watch(selectedCalendarDateProvider);

    final userName = (userProfile?.displayName.isNotEmpty ?? false)
        ? userProfile!.displayName
        : 'Leon';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. End-to-End Retractable Calendar Header ───────────────────
          // Corner-to-corner full bleed, completely covers top of screen
          SliverToBoxAdapter(
            child: RetractableCalendarHeader(
              userName: userName,
              avatarUrl: userProfile?.avatarUrl,
              initialExpanded: true,
              selectedDate: selectedCalendarDate,
              onDateSelected: (date) {
                ref.read(selectedCalendarDateProvider.notifier).select(date);
              },
              loggedWorkoutDates: loggedWorkoutDates,
            ),
          ),

          // ── 2. Bento Grid Workout & Activity Cards ──────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, AppShell.bottomPadding(context, extra: 24)),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── 1. Compact Daily Workout / Start Workout Bento Card ───────
                const DailyWorkoutBentoCard(),
                const SizedBox(height: 12),

                // ── 2. 4 Equal Square Bento Cards (2x2 Grid) ──────────────────
                // Each bento card granularly watches only its own metrics via .select(...)
                const Row(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.02,
                        child: StepsBentoCard(),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.02,
                        child: CaloriesBentoCard(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.42,
                        child: WaterBentoCard(),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.42,
                        child: SleepBentoCard(),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
