/// Retractable tactical calendar header widget for the LEON dashboard.
///
/// Clean, minimal, non-glassmorphic solid dark card design inspired by
/// tactical HUDs:
/// - Full-bleed end-to-end container (corner to corner, covers top of screen)
/// - Bottom two vertices curved (32px radius), top vertices flush
/// - Operative greeting ("Hello [Name]!") and circular avatar
/// - Interactive month/year indicator with collapse/expand toggle
/// - 7-day horizontal calendar week strip with pill slots (matching reference)
/// - Active day highlighted with solid amber circular badge (no glow)
/// - Smooth collapsible retraction: converges to greeting + avatar
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Retractable calendar header for the dashboard.
class RetractableCalendarHeader extends StatefulWidget {
  const RetractableCalendarHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.initialExpanded = true,
    this.onDateSelected,
    this.loggedWorkoutDates = const <DateTime>{},
  });

  /// User display name (e.g. 'Leon').
  final String userName;

  /// Optional avatar URL for operative PFP.
  final String? avatarUrl;

  /// Whether the calendar strip starts in an expanded state.
  final bool initialExpanded;

  /// Callback when a calendar day is tapped.
  final ValueChanged<DateTime>? onDateSelected;

  /// Dates where gym workout sessions have been logged/completed.
  final Set<DateTime> loggedWorkoutDates;

  @override
  State<RetractableCalendarHeader> createState() =>
      _RetractableCalendarHeaderState();
}

class _RetractableCalendarHeaderState extends State<RetractableCalendarHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late DateTime _selectedDate;
  late final List<DateTime> _weekDays;

  // Solid dark background matching reference (clean & minimal, non-glassmorphic)
  static const Color _cardBg = Color(0xFF1E232F);
  static const Color _pillSlotBg = Color(0xFF262C3A);
  static const Color _amberAccent = Color(0xFFFFB300);
  static const Color _greenAccent = Color(0xFF00E676); // Tactical ECG Green


  // Height of expandable strip in logical pixels
  static const double _stripHeight = 70.0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    final now = DateTime.now();
    // Sunday-based 7-day strip matching reference (S, M, T, W, T, F, S)
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    _weekDays = List.generate(
      7,
      (i) => startOfWeek.add(Duration(days: i)),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: widget.initialExpanded ? 1.0 : 0.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    if (_controller.value >= 0.5) {
      _controller.animateTo(0.0, curve: Curves.easeOutCubic);
    } else {
      _controller.animateTo(1.0, curve: Curves.easeOutCubic);
    }
  }

  void _onDragStart(DragStartDetails details) {
    _controller.stop(); // SKILL2.md §3: Interrupt instantly from live value
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // SKILL2.md §2: Direct 1:1 manipulation
    final delta = details.primaryDelta ?? 0.0;
    _controller.value = (_controller.value + (delta / _stripHeight)).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    // SKILL2.md §5 & §6: Velocity handoff & momentum projection
    final v = details.primaryVelocity ?? 0.0;
    double target;
    if (v.abs() > 300) {
      target = v > 0 ? 1.0 : 0.0;
    } else {
      target = _controller.value >= 0.5 ? 1.0 : 0.0;
    }
    _controller.animateTo(target, curve: Curves.easeOutCubic);
  }

  String _monthName(int month) {
    const months = [
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
      'December'
    ];
    return months[month - 1];
  }

  String _weekdayLetter(int weekday) {
    switch (weekday) {
      case DateTime.sunday:
        return 'S';
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStr = '${_monthName(now.month)}, ${now.year}';
    final topPadding = MediaQuery.paddingOf(context).top;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final animValue = _controller.value;
          final bottomPadding = 14.0 + (animValue * 4.0);

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _cardBg,
              // Bottom two vertices curved (32px), top vertices flush corner-to-corner
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.0,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              top: topPadding + 8,
              left: 20,
              right: 20,
              bottom: bottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Greeting Row: Hello Name & PFP ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _toggleExpanded,
                        borderRadius: BorderRadius.circular(10),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  style: AppTypography.displayMedium.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFFD8DDE8),
                                    // SKILL2.md §15: Negative optical tracking for display size
                                    letterSpacing: -0.4,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Hello '),
                                    TextSpan(
                                      text: '${widget.userName}!',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),

                              // Month & Year with animated chevron
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    monthStr,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Transform.rotate(
                                    angle: (1.0 - animValue) * -1.5708, // -90 degrees when collapsed
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Operative PFP Avatar with 44pt accessible touch target
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push(AppConstants.routeProfile);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: widget.avatarUrl != null
                              ? Image.network(
                                  widget.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildDefaultAvatar(),
                                )
                              : _buildDefaultAvatar(),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Retractable Calendar Strip with Fluid Height & Opacity ───
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: animValue,
                    child: Opacity(
                      opacity: animValue.clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        // Weekday pill chips row (S, M, T, W, T, F, S)
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final date in _weekDays)
                              _buildDayPill(
                                date: date,
                                isSelected: date.year == _selectedDate.year &&
                                    date.month == _selectedDate.month &&
                                    date.day == _selectedDate.day,
                                isToday: date.year == now.year &&
                                    date.month == now.month &&
                                    date.day == now.day,
                                isLogged: widget.loggedWorkoutDates.any(
                                  (d) =>
                                      d.year == date.year &&
                                      d.month == date.month &&
                                      d.day == date.day,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF2C3240),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildDayPill({
    required DateTime date,
    required bool isSelected,
    required bool isToday,
    required bool isLogged,
  }) {
    // Days prior to today where a workout was completed/logged
    final isPreviousSession = isLogged && !isToday;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedDate = date);
        widget.onDateSelected?.call(date);
      },
      child: Container(
        width: 44,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _pillSlotBg,
          border: isSelected
              ? Border.all(
                  color: isToday
                      ? _amberAccent.withValues(alpha: 0.8)
                      : (isPreviousSession
                          ? _greenAccent.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.35)),
                  width: 1.5,
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Weekday letter (Apple HIG floor: 11.0 pt, min 4.5:1 contrast)
            Text(
              _weekdayLetter(date.weekday),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.0,
                fontWeight: (isToday || isPreviousSession || isSelected)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isToday
                    ? _amberAccent
                    : (isPreviousSession
                        ? _greenAccent
                        : (isSelected ? Colors.white : AppColors.textSecondary)),
              ),
            ),

            // Date Number:
            // - Today: Solid golden yellow badge (_amberAccent) with dark text
            // - Previous logged sessions: Solid tactical green badge (_greenAccent) with dark text
            // - Unlogged / Rest days: Crisp mono numeral (#E2E8F0)
            if (isToday)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _amberAccent,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              )
            else if (isPreviousSession)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _greenAccent,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              )
            else
              Text(
                '${date.day}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12.0,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
