/// GitHub-style gym activity contribution heatmap chart for LEON.
///
/// Displays a horizontally scrollable 7-row matrix representing days of the
/// week (Sunday to Saturday) across past weeks/months. Completed workout days
/// are highlighted in tactical green (#00E676), today is highlighted in
/// golden yellow (#FFB300), and rest days are dark tactical slate tiles.
///
/// Follows Apple HIG standards:
/// - Typography floor: >= 11.0 pt on all month, weekday, and stat labels
/// - WCAG AA contrast threshold: >= 4.5:1 on all secondary texts
/// - Touch targets with accessible hit testing and fluid momentum scrolling
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Horizontally scrollable gym activity contribution graph.
class GymContributionChart extends StatefulWidget {
  const GymContributionChart({
    super.key,
    required this.loggedWorkoutDates,
    this.selectedDate,
    this.onDateSelected,
    this.weeksCount = 26,
  });

  /// Set of dates on which a gym session was completed.
  final Set<DateTime> loggedWorkoutDates;

  /// Currently selected date.
  final DateTime? selectedDate;

  /// Callback when a day cell is tapped.
  final ValueChanged<DateTime>? onDateSelected;

  /// Total number of weeks to display in the chart (default 26 = ~6 months).
  final int weeksCount;

  @override
  State<GymContributionChart> createState() => _GymContributionChartState();
}

class _GymContributionChartState extends State<GymContributionChart> {
  late final ScrollController _scrollController;
  DateTime? _inspectedDate;

  static const Color _greenAccent = Color(0xFF00E676);
  static const Color _amberAccent = Color(0xFFFFB300);
  static const Color _emptyCellBg = Color(0xFF222836);
  static const Color _emptyCellBorder = Color(0xFF2C3446);
  static const double _cellSize = 13.0;
  static const double _cellGap = 3.5;

  @override
  void initState() {
    super.initState();
    _inspectedDate = widget.selectedDate ?? DateTime.now();
    _scrollController = ScrollController();

    // Auto-scroll to current week on initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Sunday-based start of current week
    final currentWeekStart = today.subtract(Duration(days: now.weekday % 7));

    // Build the grid columns (each column is a week from Sunday to Saturday)
    final weeks = List.generate(widget.weeksCount, (index) {
      final weekOffset = widget.weeksCount - 1 - index;
      final weekStart = currentWeekStart.subtract(Duration(days: weekOffset * 7));
      return List.generate(7, (dayIndex) {
        return weekStart.add(Duration(days: dayIndex));
      });
    });

    // Total logged workouts count within the visible range
    final totalLoggedCount = widget.loggedWorkoutDates.where((d) {
      final earliest = weeks.first.first;
      return !d.isBefore(earliest) && !d.isAfter(today);
    }).length;

    final inspected = _inspectedDate ?? today;
    final isInspectedToday = _isSameDay(inspected, today);
    final isInspectedLogged = widget.loggedWorkoutDates.any((d) => _isSameDay(d, inspected));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Bar: Title & Session Counter Badge ─────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ACTIVITY TELEMETRY',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFF94A3B8), // Apple HIG contrast compliant (> 5:1)
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _greenAccent.withValues(alpha: 0.14),
                border: Border.all(
                  color: _greenAccent.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Text(
                '$totalLoggedCount SESSIONS LOGGED',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: _greenAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Main Graph Container: Day Labels + Horizontal Scroll Grid ─────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Axis: Day Labels (Mon, Wed, Fri) aligned to 7-row grid
            Padding(
              padding: const EdgeInsets.only(top: 20, right: 6),
              child: SizedBox(
                width: 26,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: _cellSize + _cellGap), // Sun (empty)
                    SizedBox(
                      height: _cellSize + _cellGap,
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mon',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: _cellSize + _cellGap), // Tue (empty)
                    SizedBox(
                      height: _cellSize + _cellGap,
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Wed',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: _cellSize + _cellGap), // Thu (empty)
                    SizedBox(
                      height: _cellSize + _cellGap,
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Fri',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: _cellSize), // Sat (empty)
                  ],
                ),
              ),
            ),

            // Horizontally Scrollable Heatmap Weeks Matrix
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month labels row along the top
                    Row(
                      children: [
                        for (int w = 0; w < weeks.length; w++)
                          _buildMonthHeader(w, weeks),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 7 rows of week cells
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final week in weeks)
                          Padding(
                            padding: const EdgeInsets.only(right: _cellGap),
                            child: Column(
                              children: [
                                for (final date in week)
                                  _buildDayCell(date: date, today: today),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Bottom Inspection HUD & Legend Row ────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Selected Day Inspection Readout
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isInspectedToday
                          ? _amberAccent
                          : (isInspectedLogged
                              ? _greenAccent
                              : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isInspectedToday
                          ? 'Today (${_monthAbbr(inspected.month)} ${inspected.day}) · Active Session Ready'
                          : (isInspectedLogged
                              ? '${_monthAbbr(inspected.month)} ${inspected.day} · Gym Session Completed'
                              : '${_monthAbbr(inspected.month)} ${inspected.day} · Rest & Recovery Day'),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE2E8F0),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Legend indicators
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem('Rest', _emptyCellBg),
                const SizedBox(width: 8),
                _buildLegendItem('Gym', _greenAccent),
                const SizedBox(width: 8),
                _buildLegendItem('Today', _amberAccent),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthHeader(int weekIndex, List<List<DateTime>> weeks) {
    final firstDayOfWeek = weeks[weekIndex].first;
    final isFirstWeekOfMonth = firstDayOfWeek.day <= 7 || weekIndex == 0;

    return SizedBox(
      width: _cellSize + _cellGap,
      height: 16,
      child: isFirstWeekOfMonth
          ? OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: 40,
              child: Text(
                _monthAbbr(firstDayOfWeek.month),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                  height: 1.0,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required DateTime today,
  }) {
    final isToday = _isSameDay(date, today);
    final isFuture = date.isAfter(today);
    final isLogged = widget.loggedWorkoutDates.any((d) => _isSameDay(d, date));
    final isSelected = _inspectedDate != null && _isSameDay(date, _inspectedDate!);

    Color bgColor;
    Border? border;

    if (isFuture) {
      bgColor = Colors.white.withValues(alpha: 0.04);
      border = Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1.0);
    } else if (isToday) {
      bgColor = _amberAccent;
      if (isSelected) {
        border = Border.all(color: Colors.white, width: 1.5);
      }
    } else if (isLogged) {
      bgColor = _greenAccent;
      if (isSelected) {
        border = Border.all(color: Colors.white, width: 1.5);
      }
    } else {
      bgColor = _emptyCellBg;
      border = Border.all(
        color: isSelected ? Colors.white.withValues(alpha: 0.8) : _emptyCellBorder,
        width: isSelected ? 1.5 : 1.0,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: _cellGap),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _inspectedDate = date);
          widget.onDateSelected?.call(date);
        },
        child: Container(
          width: _cellSize,
          height: _cellSize,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3.0),
            border: border,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0),
            border: color == _emptyCellBg
                ? Border.all(color: _emptyCellBorder, width: 0.8)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.0,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
