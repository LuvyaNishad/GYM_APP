/// Weekly Consistency Widget for LEON Dashboard.
///
/// Promotes sustainable training habits through weekly compliance tracking
/// without shame mechanics, guilt prompts, or fragile daily streaks.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/dashboard_provider.dart';

class WeeklyConsistencyCard extends ConsumerWidget {
  const WeeklyConsistencyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consistency = ref.watch(weeklyConsistencyProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Title & Compliance Badge ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF00E5FF),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WEEKLY CONSISTENCY',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pureWhite,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  '${consistency.completedThisWeek}/${consistency.plannedThisWeek} WORKOUTS (${(consistency.complianceRate * 100).toInt()}%)',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00E5FF),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── 7-Day Habit Tracker Row ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in consistency.days) ...[
                Column(
                  children: [
                    Text(
                      day.dayLabel,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: day.isToday
                            ? const Color(0xFFFFB300)
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: day.isCompleted
                            ? const Color(0xFF00E5FF)
                            : (day.isToday
                                ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                                : AppColors.onyx),
                        border: Border.all(
                          color: day.isCompleted
                              ? const Color(0xFF00E5FF)
                              : (day.isToday
                                  ? const Color(0xFFFFB300)
                                  : AppColors.steel.withValues(alpha: 0.4)),
                          width: day.isToday ? 1.5 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: day.isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.onyx,
                              )
                            : (day.isToday
                                ? Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFFFB300),
                                    ),
                                  )
                                : const SizedBox.shrink()),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // ── Rolling 4-Week Compliance Bars ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.onyx,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.steel.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '4-WEEK COMPLIANCE TREND',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (int i = 0; i < consistency.fourWeekHistory.length; i++) ...[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: consistency.fourWeekHistory[i],
                                  minHeight: 6,
                                  backgroundColor:
                                      AppColors.steel.withValues(alpha: 0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    i == consistency.fourWeekHistory.length - 1
                                        ? const Color(0xFF00E5FF)
                                        : AppColors.platinum,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                i == consistency.fourWeekHistory.length - 1
                                    ? 'THIS WK'
                                    : 'W-${3 - i}',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Supportive Neutral Messaging Box ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.spa_outlined,
                size: 15,
                color: Color(0xFF00E5FF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  consistency.supportiveMessage,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontBody,
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
