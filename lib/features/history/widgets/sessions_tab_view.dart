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
          _buildEmptyState(
            selectedDate: selectedDate,
            selectedFilter: _selectedFilter,
            onClearFilter: () {
              ref.read(selectedCalendarDateProvider.notifier).clear();
            },
          )
        else
          for (final workout in filteredWorkouts)
            WorkoutHistoryCard(workout: workout),
      ],
    );
  }

  Widget _buildEmptyState({
    required DateTime? selectedDate,
    required String selectedFilter,
    required VoidCallback onClearFilter,
  }) {
    if (selectedDate == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.fitness_center_rounded,
                size: 34,
                color: AppColors.textSecondary.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 12),
              Text(
                'No workouts found for $selectedFilter.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isRest = selectedDate.weekday == DateTime.sunday ||
        selectedDate.weekday == DateTime.wednesday;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final isFuture = sel.isAfter(today);

    final title = isFuture
        ? 'UPCOMING DATE'
        : isRest
            ? 'SCHEDULED REST DAY'
            : 'MISSED SESSION';
    final subtitle = isFuture
        ? 'No workouts scheduled yet for ${_formatDate(selectedDate)}'
        : isRest
            ? 'Rest & muscle recovery day. No workouts logged.'
            : 'No workout was logged on ${_formatDate(selectedDate)}.';
    final icon = isFuture
        ? Icons.calendar_today_rounded
        : isRest
            ? Icons.pause_circle_outline_rounded
            : Icons.event_busy_rounded;
    final accentColor = isFuture
        ? AppColors.textSecondary
        : isRest
            ? AppColors.textSecondary
            : const Color(0xFFFF5252);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: accentColor,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12.0,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.0,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onClearFilter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: const Text(
                'SHOW ALL WORKOUTS',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00E5FF),
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
