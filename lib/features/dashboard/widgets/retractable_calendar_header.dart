/// Retractable tactical calendar header widget for the LEON dashboard.
///
/// Features:
/// - Operative greeting ("Hello [Name]!") and circular PFP avatar
/// - Interactive month/year indicator with collapse/expand toggle
/// - 7-day horizontal calendar week strip with date numbers & day letters
/// - Active day highlighted with high-contrast tactical glow badge
/// - Retractable animation: slides up and converges smoothly to just the
///   greeting and PFP at the same position, and expands on tap or pull-down.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/liquid_glass.dart';

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

class _RetractableCalendarHeaderState extends State<RetractableCalendarHeader>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late DateTime _selectedDate;
  late final List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _selectedDate = DateTime.now();

    // Generate current week dates centered on today (Monday - Sunday or current 7 days)
    final now = DateTime.now();
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
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return letters[(weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStr = '${_monthName(now.month)}, ${now.year}';

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100 && _isExpanded) {
            // Swiped up -> collapse
            _toggleExpanded();
          } else if (details.primaryVelocity! > 100 && !_isExpanded) {
            // Swiped down -> expand
            _toggleExpanded();
          }
        }
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: LiquidGlassContainer(
          borderRadius: 22,
          blurSigma: 24,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          borderWidth: 1.0,
          glowColor: AppColors.primary.withValues(alpha: 0.08),
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
                      borderRadius: BorderRadius.circular(12),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: AppTypography.displayMedium.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
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
                          const SizedBox(height: 2),

                          // Month & Year with retractable chevron indicator
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                monthStr,
                                style: AppTypography.labelSmall.copyWith(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: _isExpanded ? 0.0 : -0.25,
                                duration: const Duration(milliseconds: 250),
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
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
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                const SizedBox(height: 12),

                // Weekday chips row (S, M, T, W, T, F, S)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final date in _weekDays)
                      _buildDayItem(
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
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: AppColors.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildDayItem({
    required DateTime date,
    required bool isSelected,
    required bool isToday,
  }) {
    // Selected day gets luminous amber/gold tactical glow (matching reference image)
    const accentColor = Color(0xFFFFB300);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedDate = date);
        widget.onDateSelected?.call(date);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 42,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.03),
          border: isSelected
              ? Border.all(color: accentColor.withValues(alpha: 0.6), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Day letter (S, M, T...)
            Text(
              _weekdayLetter(date.weekday),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),

            // Date number circle
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
