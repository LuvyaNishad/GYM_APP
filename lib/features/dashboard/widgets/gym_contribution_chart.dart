import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Completed workout days, displayed as a GitHub-style weekly grid.
class GymContributionChart extends StatefulWidget {
  const GymContributionChart({
    super.key,
    required this.loggedWorkoutDates,
    this.today,
    this.selectedDate,
    this.onDateSelected,
    this.weeksCount = 52,
  }) : assert(weeksCount > 0);

  final Set<DateTime> loggedWorkoutDates;
  final DateTime? today;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final int weeksCount;

  @override
  State<GymContributionChart> createState() => _GymContributionChartState();
}

class _GymContributionChartState extends State<GymContributionChart> {
  final _scrollController = ScrollController();
  static const _cellSize = 13.0;
  static const _gap = 3.5;
  static const _stride = _cellSize + _gap;

  DateTime _day(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final today = _day(widget.today ?? DateTime.now());
    final currentSunday = DateTime(
      today.year,
      today.month,
      today.day - today.weekday % 7,
    );
    final firstDay = DateTime(
      currentSunday.year,
      currentSunday.month,
      currentSunday.day - (widget.weeksCount - 1) * 7,
    );
    final logged = widget.loggedWorkoutDates
        .map(_day)
        .where((day) => !day.isBefore(firstDay) && !day.isAfter(today))
        .toSet();
    final weeks = List.generate(
      widget.weeksCount,
      (week) => List.generate(
        7,
        (day) => DateTime(
          firstDay.year,
          firstDay.month,
          firstDay.day + week * 7 + day,
        ),
      ),
    );
    final textScaler = MediaQuery.textScalerOf(context);
    final rowHeight = math.max(_stride, textScaler.scale(11) + _gap);
    final monthHeight = textScaler.scale(11) + 6;
    final caption = AppTypography.bodySmall.copyWith(
      fontSize: 11,
      color: AppColors.textSecondary,
    );
    final localizations = MaterialLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'WORKOUT ACTIVITY',
            style: AppTypography.headlineSmall.copyWith(
              fontSize: 12,
              letterSpacing: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${logged.length} gym ${logged.length == 1 ? 'day' : 'days'} in the last ${widget.weeksCount} weeks',
          style: AppTypography.monoSmall.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: textScaler.scale(26) + 6,
              child: Column(
                children: [
                  SizedBox(height: monthHeight + _gap),
                  for (var day = 0; day < 7; day++)
                    SizedBox(
                      height: rowHeight,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: day == 1 || day == 3 || day == 5
                            ? Text(
                                ['', 'Mon', '', 'Wed', '', 'Fri', ''][day],
                                style: caption,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const PageStorageKey('gym-attendance-grid'),
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (var week = 0; week < weeks.length; week++)
                          SizedBox(
                            width: _stride,
                            height: monthHeight,
                            child: weeks[week].first.day <= 7
                                ? OverflowBox(
                                    alignment: Alignment.centerLeft,
                                    minWidth: 0,
                                    maxWidth: 64,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        [
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
                                        ][weeks[week].first.month - 1],
                                        style: caption,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        SizedBox(width: textScaler.scale(22)),
                      ],
                    ),
                    const SizedBox(height: _gap),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: widget.onDateSelected == null
                          ? null
                          : (details) {
                              final week = (details.localPosition.dx / _stride)
                                  .floor();
                              final day = (details.localPosition.dy / rowHeight)
                                  .floor();
                              if (week >= 0 &&
                                  week < weeks.length &&
                                  day >= 0 &&
                                  day < 7) {
                                final date = weeks[week][day];
                                if (!date.isAfter(today)) {
                                  widget.onDateSelected!(date);
                                }
                              }
                            },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final week in weeks)
                            Column(
                              children: [
                                for (final date in week)
                                  SizedBox(
                                    width: _stride,
                                    height: rowHeight,
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Semantics(
                                        label:
                                            '${localizations.formatFullDate(date)}: ${date.isAfter(today)
                                                ? 'Future date'
                                                : logged.contains(date)
                                                ? 'Workout logged'
                                                : 'No workout logged'}',
                                        child: Container(
                                          key: ValueKey(
                                            'gym-day-${date.toIso8601String()}',
                                          ),
                                          width: _cellSize,
                                          height: _cellSize,
                                          decoration: BoxDecoration(
                                            color: logged.contains(date)
                                                ? AppColors.primary
                                                : AppColors.surfaceSecondary,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                            border: Border.all(
                                              color:
                                                  widget.selectedDate != null &&
                                                      _day(
                                                            widget
                                                                .selectedDate!,
                                                          ) ==
                                                          date
                                                  ? AppColors.textPrimary
                                                  : AppColors.subtleBorder,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _legend('No workout', AppColors.surfaceSecondary, caption),
            _legend('Gym day', AppColors.primary, caption),
          ],
        ),
      ],
    );
  }

  Widget _legend(String label, Color color, TextStyle style) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.subtleBorder),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: style),
    ],
  );
}
