/// Main History & Performance Screen for LEON.
///
/// Features:
/// - Pinned Minimal Monthly Calendar at the very top (full bleed, no notch, matching homepage design)
/// - Lifetime Tonnage progress bar positioned below the calendar
/// - 3-segment switcher:
///   * SESSIONS: Chronological workout feed synced with calendar date filter
///   * OVERLOAD: 1RM progression curve (fl_chart), volume trends, PR trophy wall
///   * RADAR: 6-spoke animated Spider Radar chart, lagging muscle alerts, recovery state
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_shell.dart';
import '../providers/history_provider.dart';
import '../widgets/history_segment_bar.dart';
import '../widgets/leon_monthly_calendar.dart';
import '../widgets/muscle_radar_tab_view.dart';
import '../widgets/overload_tab_view.dart';
import '../widgets/sessions_tab_view.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  String _formatTonnage(double volume) {
    final intVol = volume.toInt();
    if (intVol >= 1000) {
      final k = (intVol / 1000).toStringAsFixed(1);
      return '$k' 'K KG';
    }
    return '$intVol KG';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSegment = ref.watch(historyActiveSegmentProvider);
    final summary = ref.watch(historySummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. Corner-to-Corner Pinned Calendar Header (Starts Collapsed with Notch) ──
          SliverToBoxAdapter(
            child: LeonMonthlyCalendar(
              initialCollapsed: true,
              onDateSelected: (_) {
                if (ref.read(historyActiveSegmentProvider) != 0) {
                  ref.read(historyActiveSegmentProvider.notifier).select(0);
                }
              },
            ),
          ),

          // ── 2. Content Area Below Calendar ────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, AppShell.bottomPadding(context, extra: 24)),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Lifetime Tonnage & Level Progress Bar (Below Calendar) ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.charcoal,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.steel.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('🏋️ ',
                                    style: TextStyle(fontSize: 12)),
                                Text(
                                  '${_formatTonnage(summary.totalTonnageKg)} LIFTED',
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.pureWhite,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'NEXT: ${_formatTonnage(summary.nextLevelTonnageTarget)}',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: summary.levelProgress,
                            minHeight: 4,
                            backgroundColor: AppColors.onyx,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00E676),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── 3-Segment Controller ─────────────────────────────────
                  HistorySegmentBar(
                    selectedIndex: activeSegment,
                    onChanged: (idx) {
                      ref
                          .read(historyActiveSegmentProvider.notifier)
                          .select(idx);
                    },
                  ),

                  const SizedBox(height: 14),

                  // ── Active Segment Content ───────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey<int>(activeSegment),
                      child: switch (activeSegment) {
                        0 => const SessionsTabView(),
                        1 => const OverloadTabView(),
                        2 => const MuscleRadarTabView(),
                        _ => const SessionsTabView(),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
