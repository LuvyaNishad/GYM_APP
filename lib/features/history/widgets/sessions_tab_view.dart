/// Sessions Tab View for LEON History:
/// Minimal, uncluttered chronological workout log feed with split filter & calendar date sync.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/history_provider.dart';
import 'workout_history_card.dart';

class SessionsTabView extends ConsumerStatefulWidget {
  const SessionsTabView({super.key});

  @override
  ConsumerState<SessionsTabView> createState() => _SessionsTabViewState();
}

class _SessionsTabViewState extends ConsumerState<SessionsTabView> {
  String _selectedFilter = 'ALL';

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final workouts = ref.watch(historyWorkoutsProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);

    final filteredWorkouts = workouts.where((w) {
      if (selectedDate != null) {
        final matchesDate = w.date.year == selectedDate.year &&
            w.date.month == selectedDate.month &&
            w.date.day == selectedDate.day;
        if (!matchesDate) return false;
      }

      if (_selectedFilter == 'ALL') return true;
      if (_selectedFilter == 'PUSH') return w.name.toUpperCase().contains('PUSH');
      if (_selectedFilter == 'PULL') return w.name.toUpperCase().contains('PULL');
      if (_selectedFilter == 'LEGS') return w.name.toUpperCase().contains('LEG');
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Selected Date Filter Active Notice (if any) ─────────────────────
        if (selectedDate != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'FILTER: ${_formatDate(selectedDate).toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    ref.read(selectedCalendarDateProvider.notifier).clear();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.steel.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'CLEAR',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Split Filter Pills ─────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final filter in ['ALL', 'PUSH', 'PULL', 'LEGS']) ...[
                GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedFilter == filter
                          ? AppColors.pureWhite
                          : AppColors.charcoal,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedFilter == filter
                            ? AppColors.pureWhite
                            : AppColors.steel.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _selectedFilter == filter
                            ? AppColors.onyx
                            : AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Chronological Workout Log Cards ────────────────────────────────
        if (filteredWorkouts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 32,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    selectedDate != null
                        ? 'No workouts logged on ${_formatDate(selectedDate)}.'
                        : 'No workouts found for $_selectedFilter.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (selectedDate != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        ref.read(selectedCalendarDateProvider.notifier).clear();
                      },
                      child: const Text(
                        'Show All Workouts',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          for (final workout in filteredWorkouts)
            WorkoutHistoryCard(workout: workout),
      ],
    );
  }
}
