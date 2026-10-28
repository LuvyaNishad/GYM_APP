import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/liquid_glass_date_picker.dart';
import '../../../shared/widgets/sync_status_indicator.dart';

enum DayStatus { workedOut, missed, rest, future }

/// Unified Tactical Week Header for the LEON Dashboard.
///
/// Features:
/// - Clean corner-to-corner greeting & branding header.
/// - Integrated Sync Status and Date Picker actions (account icon removed; accessible via bottom nav pill).
/// - Permanent, high-contrast 7-day capsule strip with instant date selection.
/// - Weekly consistency progress indicator (e.g. `THIS WEEK · 3 OF 4 DAYS`).
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
    this.completedSessions,
    this.targetSessions,
  });

  final String userName;
  final String? avatarUrl;
  final bool initialExpanded;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final Set<DateTime> loggedWorkoutDates;
  final int? completedSessions;
  final int? targetSessions;

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

    // Compute weekly completed sessions if not explicitly supplied
    int completed = widget.completedSessions ?? 0;
    if (widget.completedSessions == null) {
      for (int i = 0; i < 7; i++) {
        final d = monday.add(Duration(days: i));
        if (widget.loggedWorkoutDates.any(
          (logged) => DateUtils.isSameDay(logged, d),
        )) {
          completed++;
        }
      }
    }
    final target = widget.targetSessions ?? 4;

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: Branding, Greeting, Sync & Date Actions ───────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineLarge.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SyncStatusIndicator(),
                  if (!isSelectedToday) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => widget.onDateSelected?.call(today),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
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
                    constraints: const BoxConstraints(),
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
              ),
              const SizedBox(height: 12),

              // ── Sub-row: Weekly Consistency Target & Formatted Date ────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'THIS WEEK · $completed OF $target DAYS',
                      maxLines: 2,
                      style: AppTypography.monoSmall.copyWith(
                        color: AppColors.platinum,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      local.formatMediumDate(selected),
                      maxLines: 2,
                      textAlign: TextAlign.end,
                      style: AppTypography.monoSmall.copyWith(
                        color: isSelectedToday
                            ? AppColors.primary
                            : AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

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
                  final isMissed = isPast && !done;

                  // Color discipline:
                  // - Green: Day workout was completed (gym hit)
                  // - Red: Past day with no workout (gym missed)
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
                          '${local.formatFullDate(day)}${done ? ', workout completed' : (isMissed ? ', workout missed' : '')}',
                      selected: active,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => widget.onDateSelected?.call(day),
                        child: Container(
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
