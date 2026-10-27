import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'liquid_glass.dart';

/// Opens a high-performance frosted acrylic / liquid glass date picker dialog.
///
/// Features:
/// - 24px backdrop optical blur with specular rim reflections and frosted depth.
/// - Apple HIG compliant typography (>= 11.0 pt minimum) and high contrast ratios.
/// - Strict 2-accent discipline: Amber for selected day, Electric Cyan for today & confirm.
/// - Workout date indicator pips showing logged training history on calendar days.
/// - Month & year navigation controls with instant "TODAY" quick-jump.
Future<DateTime?> showLiquidGlassDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  Set<DateTime> loggedWorkoutDates = const {},
}) {
  return showGeneralDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss calendar',
    barrierColor: Colors.black.withValues(alpha: 0.70),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _LiquidGlassDatePickerDialog(
        initialDate: initialDate,
        firstDate: firstDate ?? DateTime(2020),
        lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
        loggedWorkoutDates: loggedWorkoutDates,
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _LiquidGlassDatePickerDialog extends StatefulWidget {
  const _LiquidGlassDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.loggedWorkoutDates,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Set<DateTime> loggedWorkoutDates;

  @override
  State<_LiquidGlassDatePickerDialog> createState() =>
      _LiquidGlassDatePickerDialogState();
}

class _LiquidGlassDatePickerDialogState
    extends State<_LiquidGlassDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdayLabels = [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate);
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
        1,
      );
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDayOfMonth = _displayedMonth;
    // Monday = 1 in Dart DateTime, convert to 0-indexed (Monday = 0, Sunday = 6)
    final firstWeekday = firstDayOfMonth.weekday - 1;
    final gridStartDate = firstDayOfMonth.subtract(
      Duration(days: firstWeekday),
    );

    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final totalGridCells = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: LiquidGlassContainer(
            borderRadius: 24,
            blurSigma: 24,
            borderWidth: 1.2,
            showGlow: true,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Header: Title, Month/Year & Navigation Arrows ────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CALENDAR',
                            style: AppTypography.monoSmall.copyWith(
                              color: AppColors.platinum,
                              letterSpacing: 2.0,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                            style: AppTypography.headlineMedium.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Previous month',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.platinum,
                        size: 22,
                      ),
                      onPressed: () => _changeMonth(-1),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Next month',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.platinum,
                        size: 22,
                      ),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── 2. Weekday Label Row ────────────────────────────────────
                Row(
                  children: List.generate(7, (i) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          _weekdayLabels[i],
                          style: AppTypography.monoSmall.copyWith(
                            color: AppColors.platinum.withValues(alpha: 0.70),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),

                // ── 3. Days Grid ────────────────────────────────────────────
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalGridCells,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final dayDate = gridStartDate.add(Duration(days: index));
                    final isCurrentMonth =
                        dayDate.month == _displayedMonth.month;
                    final isSelected = _isSameDay(dayDate, _selectedDate);
                    final isToday = _isSameDay(dayDate, today);
                    final hasWorkout = widget.loggedWorkoutDates.any(
                      (w) => _isSameDay(w, dayDate),
                    );

                    if (!isCurrentMonth) {
                      return const SizedBox.shrink();
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedDate = dayDate;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.warning
                              : isToday
                              ? AppColors.charcoal
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.warning
                                : isToday
                                ? AppColors.primary.withValues(alpha: 0.70)
                                : Colors.white.withValues(alpha: 0.08),
                            width: 0.8,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${dayDate.day}',
                              style: AppTypography.monoSmall.copyWith(
                                color: isSelected
                                    ? AppColors.onyx
                                    : isToday
                                    ? AppColors.primary
                                    : AppColors.pureWhite,
                                fontSize: 12,
                                fontWeight: (isSelected || isToday)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            if (hasWorkout)
                              Positioned(
                                bottom: 3,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.onyx
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // ── 4. Action Buttons (Today, Cancel, Confirm) ───────────────
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(48, 36),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedDate = today;
                          _displayedMonth = DateTime(
                            today.year,
                            today.month,
                            1,
                          );
                        });
                      },
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
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(48, 36),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'CANCEL',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.platinum,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: const Size(72, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () =>
                          Navigator.of(context).pop(_selectedDate),
                      child: Text(
                        'CONFIRM',
                        style: AppTypography.monoSmall.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
