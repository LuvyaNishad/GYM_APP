/// Minimal, high-performance Monthly & Collapsible Calendar for LEON History.
///
/// Features:
/// - Protruding bottom notch tab with grab handle pill (RE4 / HUD aesthetic)
/// - Collapsible between 1-Week view (when collapsed) and Full Month view (when expanded)
/// - Direct drag & tap notch interaction with smooth spring animation
/// - Visual color-coded day highlighting:
///   * 🟢 Solid Green: Worked out sessions
///   * ⚪ Solid White: Current day (Today)
///   * 🔴 Soft Red: Missed scheduled sessions
///   * ⚫ Slate Dark: Rest / recovery days
///   * 🟢 Dimmed Green: Previous/adjacent month completed sessions
///   * 🔵 Cyan Ring: Selected date filter
/// - Month & year quick-jump navigation (Days, Months, and Years picker grids)
/// - Selected date filter state integration
/// - Apple HIG compliant typography (>= 11.0 pt) and WCAG AA contrast (>= 4.5:1)
library;

import 'package:flutter/material.dart';
import 'package:leon/core/theme/app_typography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/notched_header_painter.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/history_provider.dart';

enum _CalendarNavView { days, months, years }

enum DayStatus { workedOut, missed, rest, future }

class LeonMonthlyCalendar extends ConsumerStatefulWidget {
  const LeonMonthlyCalendar({
    super.key,
    this.initialMonth,
    this.initialCollapsed = true,
    this.onDateSelected,
  });

  final DateTime? initialMonth;
  final bool initialCollapsed;
  final ValueChanged<DateTime>? onDateSelected;

  @override
  ConsumerState<LeonMonthlyCalendar> createState() =>
      _LeonMonthlyCalendarState();
}

class _LeonMonthlyCalendarState extends ConsumerState<LeonMonthlyCalendar>
    with SingleTickerProviderStateMixin {
  late DateTime _displayedMonth;
  late DateTime _focusedDate;
  _CalendarNavView _navView = _CalendarNavView.days;
  late int _yearAnchor;
  late final AnimationController _collapseController;

  static const double _tabHeight = 18.0;

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
    'Su',
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = widget.initialMonth ?? DateTime(now.year, now.month, 1);
    _focusedDate = DateTime(now.year, now.month, now.day);
    _yearAnchor = _displayedMonth.year;

    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: widget.initialCollapsed ? 0.0 : 1.0,
    );
  }

  @override
  void dispose() {
    _collapseController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DayStatus _getDayStatus(
    DateTime date,
    Set<DateTime> loggedDates,
    DateTime today,
  ) {
    final d = DateTime(date.year, date.month, date.day);

    // Any logged workout day is green
    final hasWorkout = loggedDates.any(
      (w) => w.year == d.year && w.month == d.month && w.day == d.day,
    );
    if (hasWorkout) {
      return DayStatus.workedOut;
    }

    // Future dates or today (if unworked, not yet missed)
    if (d.isAfter(today) || d.isAtSameMomentAs(today)) {
      return DayStatus.future;
    }

    // Past date:
    // Sunday (weekday 7) and Wednesday (weekday 3) are designated rest days
    if (d.weekday == DateTime.sunday || d.weekday == DateTime.wednesday) {
      return DayStatus.rest;
    }

    // Other scheduled training days (Mon, Tue, Thu, Fri, Sat) without workout = Missed
    return DayStatus.missed;
  }

  List<DateTime> _buildMonthGrid(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstOfMonth.weekday % 7; // Sunday = 0
    final gridStart = firstOfMonth.subtract(Duration(days: firstWeekday));

    // 42 cells (6 rows x 7 cols) for smooth uniform calendar grid
    return List.generate(42, (i) => gridStart.add(Duration(days: i)));
  }

  void _goToMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
        1,
      );
      _yearAnchor = _displayedMonth.year;
    });
  }

  void _toggleCollapse() {
    HapticFeedback.lightImpact();
    if (_collapseController.value > 0.5) {
      _collapseController.animateTo(0.0, curve: Curves.easeOutCubic);
    } else {
      _collapseController.animateTo(1.0, curve: Curves.easeOutCubic);
    }
  }

  void _onPrevPressed() {
    if (_navView == _CalendarNavView.years) {
      setState(() => _yearAnchor -= 12);
    } else if (_collapseController.value < 0.5) {
      // 1-Week view: shift focused week back by 7 days
      setState(() {
        _focusedDate = _focusedDate.subtract(const Duration(days: 7));
        if (_focusedDate.month != _displayedMonth.month ||
            _focusedDate.year != _displayedMonth.year) {
          _displayedMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
          _yearAnchor = _displayedMonth.year;
        }
      });
      ref.read(selectedCalendarDateProvider.notifier).select(_focusedDate);
      widget.onDateSelected?.call(_focusedDate);
    } else {
      _goToMonth(-1);
    }
  }

  void _onNextPressed() {
    if (_navView == _CalendarNavView.years) {
      setState(() => _yearAnchor += 12);
    } else if (_collapseController.value < 0.5) {
      // 1-Week view: shift focused week forward by 7 days
      setState(() {
        _focusedDate = _focusedDate.add(const Duration(days: 7));
        if (_focusedDate.month != _displayedMonth.month ||
            _focusedDate.year != _displayedMonth.year) {
          _displayedMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
          _yearAnchor = _displayedMonth.year;
        }
      });
      ref.read(selectedCalendarDateProvider.notifier).select(_focusedDate);
      widget.onDateSelected?.call(_focusedDate);
    } else {
      _goToMonth(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedDates = ref.watch(loggedWorkoutDatesProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnimatedBuilder(
      animation: _collapseController,
      builder: (context, _) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) {
            _collapseController.value += details.primaryDelta! / 180.0;
          },
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0.0;
            if (velocity > 300) {
              _collapseController.animateTo(1.0, curve: Curves.easeOutCubic);
            } else if (velocity < -300) {
              _collapseController.animateTo(0.0, curve: Curves.easeOutCubic);
            } else {
              if (_collapseController.value > 0.5) {
                _collapseController.animateTo(1.0, curve: Curves.easeOutCubic);
              } else {
                _collapseController.animateTo(0.0, curve: Curves.easeOutCubic);
              }
            }
          },
          child: CustomPaint(
            painter: NotchedHeaderPainter(
              backgroundColor: AppColors.charcoal,
              borderColor: AppColors.steel.withValues(alpha: 0.5),
              handleColor: AppColors.platinum.withValues(alpha: 0.5),
              bottomRadius: 24.0,
              tabHeight: _tabHeight,
              tabWidth: 76.0,
            ),
            child: Stack(
              children: [
                // ── Main Content Area ─────────────────────────────────────
                Padding(
                  padding: EdgeInsets.only(
                    top: topPadding + 8,
                    left: 16,
                    right: 16,
                    bottom: 10 + _tabHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: Prev, Month | Year Quick Nav, Next
                      _buildHeader(),

                      const SizedBox(height: 8),

                      // Animated Switcher: Days Grid vs Months vs Years
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: switch (_navView) {
                          _CalendarNavView.days => _buildDaysView(
                            loggedDates: loggedDates,
                            selectedDate: selectedDate,
                            today: today,
                          ),
                          _CalendarNavView.months => _buildMonthsView(),
                          _CalendarNavView.years => _buildYearsView(),
                        },
                      ),

                      // Minimal Legend (Smoothly slides/fades out when collapsed)
                      if (_navView == _CalendarNavView.days)
                        ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: _collapseController.value,
                            child: Opacity(
                              opacity: _collapseController.value.clamp(
                                0.0,
                                1.0,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _buildMinimalLegend(),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Dedicated Notch Click & Tap Affordance ────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: _tabHeight + 20,
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleCollapse,
                      child: Container(
                        width: 120,
                        height: _tabHeight + 20,
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final monthName = _monthNames[_displayedMonth.month - 1];

    return Row(
      children: [
        // Previous Button
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.pureWhite,
            size: 20,
          ),
          onPressed: _onPrevPressed,
        ),

        // Quick Nav: Month | Year
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _navView = (_navView == _CalendarNavView.months)
                          ? _CalendarNavView.days
                          : _CalendarNavView.months;
                    });
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _navView == _CalendarNavView.months
                          ? AppColors.amber.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      monthName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: _navView == _CalendarNavView.months
                            ? AppColors.amber
                            : AppColors.pureWhite,
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                '|',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              SizedBox(
                width: 72,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _navView = (_navView == _CalendarNavView.years)
                          ? _CalendarNavView.days
                          : _CalendarNavView.years;
                      _yearAnchor = _displayedMonth.year;
                    });
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _navView == _CalendarNavView.years
                          ? AppColors.amber.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_displayedMonth.year}',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: AppTypography.fontMono,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _navView == _CalendarNavView.years
                            ? AppColors.amber
                            : AppColors.pureWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Next Button
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.pureWhite,
            size: 20,
          ),
          onPressed: _onNextPressed,
        ),
      ],
    );
  }

  Widget _buildDaysView({
    required Set<DateTime> loggedDates,
    required DateTime? selectedDate,
    required DateTime today,
  }) {
    final grid = _buildMonthGrid(_displayedMonth);
    final activeDate = selectedDate ?? _focusedDate;

    // Locate which row (0..5) contains the currently active/focused date
    int activeRow = 0;
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 7; c++) {
        final d = grid[r * 7 + c];
        if (_isSameDay(d, activeDate)) {
          activeRow = r;
          break;
        }
      }
    }

    return Column(
      key: const ValueKey('days_view'),
      children: [
        // Weekday header row (always visible)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: _weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontMono,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        // 6-week day grid with collapse animation
        for (int row = 0; row < 6; row++)
          if (row == activeRow)
            // Active week row: always visible in both 1-week and full month modes
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: _buildGridRow(
                row: row,
                grid: grid,
                loggedDates: loggedDates,
                selectedDate: selectedDate,
                today: today,
              ),
            )
          else
            // Inactive week rows: collapse smoothly when _collapseController approaches 0.0
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _collapseController.value,
                child: Opacity(
                  opacity: _collapseController.value.clamp(0.0, 1.0),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 2.0 * _collapseController.value,
                    ),
                    child: _buildGridRow(
                      row: row,
                      grid: grid,
                      loggedDates: loggedDates,
                      selectedDate: selectedDate,
                      today: today,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildGridRow({
    required int row,
    required List<DateTime> grid,
    required Set<DateTime> loggedDates,
    required DateTime? selectedDate,
    required DateTime today,
  }) {
    return Row(
      children: List.generate(7, (col) {
        final date = grid[row * 7 + col];
        final isCurrentMonth = date.month == _displayedMonth.month;
        final isToday = _isSameDay(date, today);
        final isSelected = _isSameDay(date, selectedDate);
        final status = _getDayStatus(date, loggedDates, today);

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _focusedDate = date;
              });
              ref.read(selectedCalendarDateProvider.notifier).select(date);
              widget.onDateSelected?.call(date);
            },
            child: SizedBox(
              height: 36,
              child: _buildDayCell(
                date: date,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isSelected: isSelected,
                status: status,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required bool isCurrentMonth,
    required bool isToday,
    required bool isSelected,
    required DayStatus status,
  }) {
    Color? circleBg;
    Border? circleBorder;
    Color textColor;
    FontWeight fontWeight = FontWeight.w600;

    if (isToday) {
      // Current day with a solid neutral badge
      circleBg = AppColors.pureWhite;
      textColor = AppColors.onyx;
      fontWeight = FontWeight.w800;
    } else if (status == DayStatus.workedOut) {
      if (isCurrentMonth) {
        // Current month completed day: solid silver
        circleBg = AppColors.platinum;
        textColor = AppColors.onyx;
        fontWeight = FontWeight.w800;
      } else {
        // Adjacent-month completed day: neutral tint and readable date
        circleBg = AppColors.platinum.withValues(alpha: 0.18);
        circleBorder = Border.all(
          color: AppColors.platinum.withValues(alpha: 0.35),
          width: 0.8,
        );
        textColor = AppColors.textMuted;
        fontWeight = FontWeight.w600;
      }
    } else if (status == DayStatus.missed) {
      if (isCurrentMonth) {
        // Missed day in current month: amber warning
        circleBg = AppColors.warning.withValues(alpha: 0.16);
        circleBorder = Border.all(
          color: AppColors.warning.withValues(alpha: 0.45),
          width: 0.8,
        );
        textColor = AppColors.warning;
        fontWeight = FontWeight.w700;
      } else {
        // Adjacent-month missed day: warning tint and readable date
        circleBg = AppColors.warning.withValues(alpha: 0.08);
        textColor = AppColors.textMuted;
      }
    } else if (status == DayStatus.rest) {
      if (isCurrentMonth) {
        // Rest day in current month: subtle dark grey circle
        circleBg = AppColors.onyx.withValues(alpha: 0.65);
        circleBorder = Border.all(
          color: AppColors.steel.withValues(alpha: 0.35),
          width: 0.8,
        );
        textColor = AppColors.textSecondary;
      } else {
        textColor = AppColors.textMuted;
      }
    } else {
      // Future / upcoming day
      if (isCurrentMonth) {
        textColor = AppColors.textPrimary;
      } else {
        textColor = AppColors.textMuted;
      }
    }

    return Center(
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.amber.withValues(alpha: 0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.amber, width: 1.6)
              : null,
        ),
        child: Container(
          width: 27,
          height: 27,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: circleBg,
            shape: BoxShape.circle,
            border: circleBorder,
          ),
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 11.5,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthsView() {
    return GridView.builder(
      key: const ValueKey('months_view'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final isSelected = _displayedMonth.month == index + 1;
        final name = _monthNames[index].substring(0, 3).toUpperCase();

        return GestureDetector(
          onTap: () {
            setState(() {
              _displayedMonth = DateTime(_displayedMonth.year, index + 1, 1);
              _navView = _CalendarNavView.days;
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.amber
                  : AppColors.steel.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.amber
                    : AppColors.steel.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Text(
              name,
              style: TextStyle(
                fontFamily: AppTypography.fontMono,
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.onyx : AppColors.pureWhite,
                letterSpacing: 0.6,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearsView() {
    final startYear = _yearAnchor - 5;

    return Column(
      key: const ValueKey('years_view'),
      children: [
        // Range label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '$startYear – ${startYear + 11}',
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final year = startYear + index;
            final isSelected = _displayedMonth.year == year;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _displayedMonth = DateTime(year, _displayedMonth.month, 1);
                  _navView = _CalendarNavView.days;
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.amber
                      : AppColors.steel.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.amber
                        : AppColors.steel.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.onyx : AppColors.pureWhite,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMinimalLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.onyx.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.steel.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          _buildLegendItem(color: AppColors.platinum, label: 'WORKOUT'),
          _buildLegendItem(color: AppColors.pureWhite, label: 'TODAY'),
          _buildLegendItem(color: AppColors.warning, label: 'MISSED'),
          _buildLegendItem(color: const Color(0xFF64748B), label: 'REST'),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontMono,
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
