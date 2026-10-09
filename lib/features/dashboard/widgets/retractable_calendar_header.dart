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
  });

  /// User display name (e.g. 'Leon').
  final String userName;

  /// Optional avatar URL for operative PFP.
  final String? avatarUrl;

  /// Whether the calendar strip starts in an expanded state.
  final bool initialExpanded;

  /// Callback when a calendar day is tapped.
  final ValueChanged<DateTime>? onDateSelected;

  @override
  State<RetractableCalendarHeader> createState() =>
      _RetractableCalendarHeaderState();
}

class _RetractableCalendarHeaderState extends State<RetractableCalendarHeader> {
  late bool _isExpanded;
  late DateTime _selectedDate;
  late final List<DateTime> _weekDays;

  // Solid dark background matching reference (clean & minimal, non-glassmorphic)
  static const Color _cardBg = Color(0xFF1E232F);
  static const Color _pillSlotBg = Color(0xFF262C3A);
  static const Color _amberAccent = Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _selectedDate = DateTime.now();

    final now = DateTime.now();
    // Sunday-based 7-day strip matching reference (S, M, T, W, T, F, S)
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    _weekDays = List.generate(
      7,
      (i) => startOfWeek.add(Duration(days: i)),
    );
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
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
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100 && _isExpanded) {
            _toggleExpanded();
          } else if (details.primaryVelocity! > 100 && !_isExpanded) {
            _toggleExpanded();
          }
        }
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: Container(
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
            bottom: _isExpanded ? 18 : 14,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: AppTypography.displayMedium.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFD8DDE8),
                                letterSpacing: 0.2,
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
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: _isExpanded ? 0.0 : -0.25,
                                duration: const Duration(milliseconds: 220),
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

                  // Operative PFP Avatar
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push(AppConstants.routeProfile);
                    },
                    child: Container(
                      width: 42,
                      height: 42,
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

              // ── Retractable Calendar Strip ────────────────────────────────
              if (_isExpanded) ...[
                const SizedBox(height: 14),
                // Weekday pill chips row (S, M, T, W, T, F, S)
                Row(
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
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedDate = date);
        widget.onDateSelected?.call(date);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 42,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _pillSlotBg,
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
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _amberAccent : AppColors.textSecondary,
              ),
            ),

            // Date Number (active day has solid amber badge, no blur glow)
            if (isSelected)
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
            else
              Text(
                '${date.day}',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE2E8F0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
