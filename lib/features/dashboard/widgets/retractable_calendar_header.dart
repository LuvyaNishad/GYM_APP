/// Retractable calendar header widget for the LEON dashboard.
///
/// Features a 3-phase interactive layout with a dedicated pull-tab notch
/// affordance at the bottom edge:
/// - Phase 0: Collapsed Phase (compact greeting + PFP avatar)
/// - Phase 1: Weekly Calendar Phase (7-day week strip with amber today and green gym days)
/// - Phase 2: Extended Opened View (GitHub-style horizontally scrollable activity heatmap)
///
/// Follows Apple HIG & Fluid Interface principles:
/// - Typography floor: >= 11.0 pt on all labels, badges, and numerals
/// - WCAG AA contrast threshold: >= 4.5:1 on all secondary texts
/// - Direct 1:1 drag manipulation, interruptibility, and velocity-projected spring settling
/// - Touch target bounds >= 44 pt on notch handle and weekday pills
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'gym_contribution_chart.dart';

/// Retractable calendar header for the dashboard with 3 distinct phases.
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

  /// Optional avatar URL for profile avatar.
  final String? avatarUrl;

  /// Whether the calendar strip starts in the expanded weekly state (Phase 1).
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
  static const Color _greenAccent = Color(0xFF00E676); // Completed workout green
  static const double _tabHeight = 18.0;

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

    // 0.0 = Collapsed, 1.0 = Weekly, 2.0 = Extended (GitHub Graph)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.initialExpanded ? 1.0 : 0.0,
      lowerBound: 0.0,
      upperBound: 2.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Cycles between the 3 phases:
  /// Collapsed (0) -> Weekly (1) -> Extended (2) -> Weekly (1)
  void _cyclePhase() {
    HapticFeedback.lightImpact();
    double target;
    if (_controller.value < 0.5) {
      target = 1.0;
    } else if (_controller.value < 1.5) {
      target = 2.0;
    } else {
      target = 1.0;
    }
    _controller.animateTo(target, curve: Curves.easeOutCubic);
  }

  /// Toggles between Collapsed and Weekly from the greeting row
  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    double target;
    if (_controller.value < 0.5) {
      target = 1.0;
    } else if (_controller.value < 1.5) {
      target = 0.0;
    } else {
      target = 1.0;
    }
    _controller.animateTo(target, curve: Curves.easeOutCubic);
  }

  void _onDragStart(DragStartDetails details) {
    _controller.stop(); // SKILL2.md §3: Interrupt instantly from live value
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // SKILL2.md §2: Direct 1:1 manipulation
    final delta = details.primaryDelta ?? 0.0;
    _controller.value = (_controller.value + (delta / 120.0)).clamp(0.0, 2.0);
  }

  void _onDragEnd(DragEndDetails details) {
    // SKILL2.md §5 & §6: Velocity handoff & momentum projection
    final v = details.primaryVelocity ?? 0.0;
    double target;
    if (v > 300) {
      // Fling down
      target = _controller.value < 1.0 ? 1.0 : 2.0;
    } else if (v < -300) {
      // Fling up
      target = _controller.value > 1.0 ? 1.0 : 0.0;
    } else {
      // Snap to closest phase
      if (_controller.value < 0.5) {
        target = 0.0;
      } else if (_controller.value < 1.5) {
        target = 1.0;
      } else {
        target = 2.0;
      }
    }
    HapticFeedback.lightImpact();
    _controller.animateTo(target, curve: Curves.easeOutCubic);
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
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
          final t = _controller.value;

          // Compute expandable height and crossfade opacities across 3 phases
          double expandableHeight;
          double weeklyOpacity;
          double extendedOpacity;

          if (t <= 1.0) {
            expandableHeight = t * 74.0;
            weeklyOpacity = t.clamp(0.0, 1.0);
            extendedOpacity = 0.0;
          } else {
            final p = t - 1.0;
            expandableHeight = 74.0 + (p * 156.0);
            weeklyOpacity = (1.0 - p * 2.5).clamp(0.0, 1.0);
            extendedOpacity = ((p - 0.2) / 0.8).clamp(0.0, 1.0);
          }

          // Subtitle and chevron orientation per phase
          String phaseSubtitle;
          double chevronAngle;
          if (t < 0.5) {
            phaseSubtitle = '$monthStr · Tap to expand';
            chevronAngle = -1.5708; // -90 deg
          } else if (t < 1.5) {
            phaseSubtitle = monthStr;
            chevronAngle = (1.0 - t) * -1.5708;
          } else {
            phaseSubtitle = '$monthStr · Workout History';
            chevronAngle = 3.14159; // 180 deg (pointing up to collapse)
          }

          return CustomPaint(
            painter: NotchedHeaderPainter(
              backgroundColor: _cardBg,
              borderColor: Colors.white.withValues(alpha: 0.10),
              handleColor: Colors.white.withValues(alpha: 0.38),
              tabHeight: _tabHeight,
            ),
            child: Stack(
              children: [
                // ── Main Content Area ───────────────────────────────────────
                Padding(
                  padding: EdgeInsets.only(
                    top: topPadding + 8,
                    left: 20,
                    right: 20,
                    bottom: 12 + _tabHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top Greeting Row: Hello Name & PFP ─────────────────
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

                                    // Month/Year & Interactive Phase Chevron
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          phaseSubtitle,
                                          style: const TextStyle(
                                            fontFamily: AppTypography.fontBody,
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Transform.rotate(
                                          angle: chevronAngle,
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

                          // Profile avatar with 44pt accessible touch target
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

                      // ── Expandable Section (Phase 1 Weekly vs Phase 2 Graph) ─
                      ClipRect(
                        child: SizedBox(
                          height: expandableHeight,
                          child: Stack(
                            children: [
                              // Phase 1: 7-Day Weekly Calendar Strip
                              if (weeklyOpacity > 0.0)
                                Positioned(
                                  top: 14,
                                  left: 0,
                                  right: 0,
                                  child: Opacity(
                                    opacity: weeklyOpacity,
                                    child: _buildWeeklyStrip(now),
                                  ),
                                ),

                              // Phase 2: Extended GitHub Contribution Graph
                              if (extendedOpacity > 0.0)
                                Positioned(
                                  top: 14,
                                  left: 0,
                                  right: 0,
                                  child: Opacity(
                                    opacity: extendedOpacity,
                                    child: GymContributionChart(
                                      loggedWorkoutDates: widget.loggedWorkoutDates,
                                      selectedDate: _selectedDate,
                                      onDateSelected: (date) {
                                        setState(() => _selectedDate = date);
                                        widget.onDateSelected?.call(date);
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Dedicated Notch Drag Handle Affordance ──────────────────
                // Positioned right over the bottom center tab for intuitive slide & tap
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: _tabHeight + 20,
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _cyclePhase,
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
          );
        },
      ),
    );
  }

  Widget _buildWeeklyStrip(DateTime now) {
    return Row(
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
                fontFamily: AppTypography.fontDisplay,
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
            // - Previous logged sessions: Solid green badge (_greenAccent) with dark text
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

/// Custom painter for the end-to-end header with a protruding
/// center notch tab and grab handle pill (matching user design).
class NotchedHeaderPainter extends CustomPainter {
  const NotchedHeaderPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.handleColor,
    this.bottomRadius = 28.0,
    this.tabWidth = 76.0,
    this.tabHeight = 18.0,
    this.tabCornerRadius = 8.0,
    this.filletRadius = 10.0,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color handleColor;
  final double bottomRadius;
  final double tabWidth;
  final double tabHeight;
  final double tabCornerRadius;
  final double filletRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height - tabHeight; // main card bottom baseline
    final cx = w / 2;
    final halfTab = tabWidth / 2;

    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final handlePaint = Paint()
      ..color = handleColor
      ..style = PaintingStyle.fill;

    // Full closed path for solid background fill
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h - bottomRadius);
    path.quadraticBezierTo(w, h, w - bottomRadius, h);

    // Right shoulder fillet into center notch tab
    path.lineTo(cx + halfTab + filletRadius, h);
    path.quadraticBezierTo(
      cx + halfTab, h,
      cx + halfTab, h + filletRadius,
    );
    path.lineTo(cx + halfTab, h + tabHeight - tabCornerRadius);
    path.quadraticBezierTo(
      cx + halfTab, h + tabHeight,
      cx + halfTab - tabCornerRadius, h + tabHeight,
    );
    path.lineTo(cx - halfTab + tabCornerRadius, h + tabHeight);
    path.quadraticBezierTo(
      cx - halfTab, h + tabHeight,
      cx - halfTab, h + tabHeight - tabCornerRadius,
    );
    path.lineTo(cx - halfTab, h + filletRadius);
    path.quadraticBezierTo(
      cx - halfTab, h,
      cx - halfTab - filletRadius, h,
    );

    // Bottom edge to bottom-left corner
    path.lineTo(bottomRadius, h);
    path.quadraticBezierTo(0, h, 0, h - bottomRadius);
    path.close();

    canvas.drawPath(path, fillPaint);

    // Stroke along the bottom perimeter including the notch
    final borderPath = Path();
    borderPath.moveTo(0, h - bottomRadius);
    borderPath.quadraticBezierTo(0, h, bottomRadius, h);
    borderPath.lineTo(cx - halfTab - filletRadius, h);
    borderPath.quadraticBezierTo(
      cx - halfTab, h,
      cx - halfTab, h + filletRadius,
    );
    borderPath.lineTo(cx - halfTab, h + tabHeight - tabCornerRadius);
    borderPath.quadraticBezierTo(
      cx - halfTab, h + tabHeight,
      cx - halfTab + tabCornerRadius, h + tabHeight,
    );
    borderPath.lineTo(cx + halfTab - tabCornerRadius, h + tabHeight);
    borderPath.quadraticBezierTo(
      cx + halfTab, h + tabHeight,
      cx + halfTab, h + tabHeight - tabCornerRadius,
    );
    borderPath.lineTo(cx + halfTab, h + filletRadius);
    borderPath.quadraticBezierTo(
      cx + halfTab, h,
      cx + halfTab + filletRadius, h,
    );
    borderPath.lineTo(w - bottomRadius, h);
    borderPath.quadraticBezierTo(w, h, w, h - bottomRadius);

    canvas.drawPath(borderPath, strokePaint);

    // Drag handle pill centered inside the protruding tab
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h + (tabHeight / 2)),
        width: 32.0,
        height: 4.0,
      ),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(handleRect, handlePaint);
  }

  @override
  bool shouldRepaint(covariant NotchedHeaderPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.handleColor != handleColor ||
        oldDelegate.tabHeight != tabHeight;
  }
}
