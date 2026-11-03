import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/liquid_glass_date_picker.dart';
import '../../../shared/widgets/sync_status_indicator.dart';

enum DayStatus { workedOut, missed, rest, future }

/// Compact week header for the LEON Dashboard.
///
/// Features:
/// - Clean corner-to-corner greeting & branding header.
/// - Integrated Sync Status and Date Picker actions (account icon removed; accessible via bottom nav pill).
/// - Permanent, high-contrast 7-day capsule strip with instant date selection.
/// - Amber highlight for active day selection (Apple HIG 2-accent system).
/// - Apple HIG compliant typography (>= 11.0 pt floor) and high contrast ratios.
class RetractableCalendarHeader extends StatefulWidget {
  const RetractableCalendarHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.initialExpanded = true,
    this.selectedDate,
    this.onDateSelected,
    this.loggedWorkoutDates = const {},
    this.scheduledWorkoutDates = const {},
    this.pausedWorkoutDates = const {},
  });

  final String userName;
  final String? avatarUrl;
  final bool initialExpanded;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final Set<DateTime> loggedWorkoutDates;
  final Set<DateTime> scheduledWorkoutDates;
  final Set<DateTime> pausedWorkoutDates;

  @override
  State<RetractableCalendarHeader> createState() =>
      _RetractableCalendarHeaderState();
}

class _RetractableCalendarHeaderState extends State<RetractableCalendarHeader> {
  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedDate ?? DateTime.now();
    final today = DateUtils.dateOnly(DateTime.now());
    final isSelectedToday = DateUtils.isSameDay(selected, today);

    final monday = DateUtils.dateOnly(
      selected,
    ).subtract(Duration(days: selected.weekday - 1));
    final local = MaterialLocalizations.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AEON',
          style: AppTypography.monoSmall.copyWith(
            color: AppColors.platinum,
            letterSpacing: 2.5,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Hi, ${widget.userName}',
          softWrap: true,
          style: AppTypography.headlineLarge.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SyncStatusIndicator(),
        if (!isSelectedToday) ...[
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => widget.onDateSelected?.call(today),
            child: Container(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Text(
                'TODAY',
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Choose date',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () async {
            final date = await showLiquidGlassDatePicker(
              context: context,
              initialDate: selected,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              loggedWorkoutDates: widget.loggedWorkoutDates,
            );
            if (date != null) widget.onDateSelected?.call(date);
          },
          icon: const Icon(
            Icons.calendar_month_outlined,
            size: 20,
            color: AppColors.platinum,
          ),
        ),
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.onyx,
        border: Border(
          bottom: BorderSide(color: Color(0x1AFFFFFF), width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: Branding, Greeting, Sync & Date Actions ───────────
              if (largeText) ...[
                greeting,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: actions),
              ] else
                Row(
                  children: [
                    Expanded(child: greeting),
                    actions,
                  ],
                ),
              const SizedBox(height: 12),

              // ── 7-Day Capsule Strip (Permanently Visible) ───────────────────
              Row(
                children: List.generate(7, (i) {
                  final day = monday.add(Duration(days: i));
                  final active = DateUtils.isSameDay(day, selected);
                  final done = widget.loggedWorkoutDates.any(
                    (d) => DateUtils.isSameDay(d, day),
                  );
                  final isDayToday = DateUtils.isSameDay(day, today);
                  final isPast = day.isBefore(today);
                  final scheduled = widget.scheduledWorkoutDates.any(
                    (date) => DateUtils.isSameDay(date, day),
                  );
                  final paused = widget.pausedWorkoutDates.any(
                    (date) => DateUtils.isSameDay(date, day),
                  );
                  final isMissed = isPast && scheduled && !done && !paused;

                  // Color discipline:
                  // - Green: Day workout was completed (gym hit)
                  // - Red: A scheduled workout was missed on a past day
                  // - Yellow (Amber): Selected day if not already green/red
                  // - Charcoal: Unselected future or uncompleted today
                  final Color capsuleColor = done
                      ? AppColors.gymGreen
                      : isMissed
                      ? AppColors.gymRed
                      : active
                      ? AppColors.warning
                      : AppColors.charcoal;

                  final Color headerTextColor = (done || (active && !isMissed))
                      ? AppColors.onyx.withValues(alpha: 0.85)
                      : isMissed
                      ? AppColors.pureWhite.withValues(alpha: 0.90)
                      : AppColors.platinum;

                  final Color numberTextColor = (done || (active && !isMissed))
                      ? AppColors.onyx
                      : isMissed
                      ? AppColors.pureWhite
                      : AppColors.pureWhite;

                  final Border border = active
                      ? Border.all(color: AppColors.warning, width: 2.0)
                      : Border.all(
                          color: isDayToday
                              ? AppColors.primary.withValues(alpha: 0.6)
                              : const Color(0x1AFFFFFF),
                          width: isDayToday ? 1.0 : 0.8,
                        );

                  final List<BoxShadow>? shadows = active
                      ? [
                          BoxShadow(
                            color: AppColors.warning.withValues(alpha: 0.45),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null;

                  return Expanded(
                    child: Semantics(
                      label:
                          '${local.formatFullDate(day)}${done
                              ? ', workout completed'
                              : isMissed
                              ? ', workout missed'
                              : paused
                              ? ', training paused'
                              : scheduled
                              ? ', workout scheduled'
                              : ', no workout scheduled'}',
                      selected: active,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => widget.onDateSelected?.call(day),
                        child: Container(
                          key: ValueKey(
                            'activity-day-${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: capsuleColor,
                            borderRadius: BorderRadius.circular(10),
                            border: border,
                            boxShadow: shadows,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                style: AppTypography.bodySmall.copyWith(
                                  color: headerTextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${day.day}',
                                style: AppTypography.monoSmall.copyWith(
                                  color: numberTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (widget.pausedWorkoutDates.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                SizedBox(
                                  height: 11,
                                  child: paused && !done
                                      ? Icon(
                                          Icons.pause_rounded,
                                          size: 11,
                                          color: numberTextColor,
                                        )
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
