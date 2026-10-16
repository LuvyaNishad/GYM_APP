/// LEON Daily Telemetry Detail Bottom Sheets.
///
/// Provides deep inspection popups for:
/// 1. Step Count (Hourly distribution, peak tooltips, distance)
/// 2. Calories (Active vs resting burn, goal completion)
/// 3. Hydration (Live water logging: +250ml, +500ml, undo)
/// 4. Sleep (Quality rating, sleep stages breakdown, recovery readiness)
///
/// Designed per Apple HIG & Noguchi Minimalist Palette with useRootNavigator.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/daily_telemetry_model.dart';

/// Shows the Step Count details modal sheet.
void showStepsDetailSheet(BuildContext context, DailyTelemetry telemetry) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TelemetrySheetContainer(
      child: _StepsDetailContent(telemetry: telemetry),
    ),
  );
}

/// Shows the Calories details modal sheet.
void showCaloriesDetailSheet(BuildContext context, DailyTelemetry telemetry) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TelemetrySheetContainer(
      child: _CaloriesDetailContent(telemetry: telemetry),
    ),
  );
}

/// Shows the Hydration details modal sheet.
void showHydrationDetailSheet(BuildContext context, DailyTelemetry telemetry) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TelemetrySheetContainer(
      child: const _HydrationDetailContent(),
    ),
  );
}

/// Shows the Sleep details modal sheet.
void showSleepDetailSheet(BuildContext context, DailyTelemetry telemetry) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TelemetrySheetContainer(
      child: _SleepDetailContent(telemetry: telemetry),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BASE SHEET CONTAINER
// ─────────────────────────────────────────────────────────────────────────────

class _TelemetrySheetContainer extends StatelessWidget {
  const _TelemetrySheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF141722),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 36,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab notch
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.steel,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. STEP COUNT DETAIL CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _StepsDetailContent extends ConsumerStatefulWidget {
  const _StepsDetailContent({required this.telemetry});

  final DailyTelemetry telemetry;

  @override
  ConsumerState<_StepsDetailContent> createState() => _StepsDetailContentState();
}

class _StepsDetailContentState extends ConsumerState<_StepsDetailContent> {
  int _selectedTabIndex = 0; // 0: Day, 1: Week, 2: Month

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final liveTelemetry = ref.watch(dailyTelemetryProvider);
    final t = liveTelemetry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.directions_walk_rounded,
                  color: AppColors.pureWhite,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Step tracker',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: AppColors.platinum, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Day / Week / Month Tab Switcher
        Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedTabIndex = i);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == i ? const Color(0xFFE2E8F0) : const Color(0xFF1C2230),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _selectedTabIndex == i ? Colors.white : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        ['Day', 'Week', 'Month'][i],
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          color: _selectedTabIndex == i ? Colors.black : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        // 3. Horizontally Scrollable Step Tracker Card with 3 Metrics (Goal, Step count, Distance)
        _HistoricalStepTrackerCard(
          telemetry: t,
          selectedTab: _selectedTabIndex,
          formatNumber: _formatNumber,
        ),
        const SizedBox(height: 16),

        // 4. Highest Single-Day Record Section
        const Text(
          'Highest single-day record',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF161A23),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.recordDate,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
              Text(
                '${_formatNumber(t.recordSingleDaySteps)} steps',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF34D399),
                ),
              ),
              Text(
                '${t.recordSingleDayKm} Kilometres',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoricalStepTrackerCard extends StatefulWidget {
  const _HistoricalStepTrackerCard({
    required this.telemetry,
    required this.selectedTab,
    required this.formatNumber,
  });

  final DailyTelemetry telemetry;
  final int selectedTab;
  final String Function(int) formatNumber;

  @override
  State<_HistoricalStepTrackerCard> createState() =>
      _HistoricalStepTrackerCardState();
}

class _HistoricalStepTrackerCardState
    extends State<_HistoricalStepTrackerCard> {
  late final ScrollController _scrollController;
  int? _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
    // 30 days history leading up to today
    final List<({String label, String displayLabel, int steps})> dayData = [
      (label: '17', displayLabel: '17', steps: 4800),
      (label: '18', displayLabel: '', steps: 6200),
      (label: '19', displayLabel: '19', steps: 5300),
      (label: '20', displayLabel: '', steps: 7100),
      (label: '21', displayLabel: '21', steps: 4300),
      (label: '22', displayLabel: '', steps: 6700),
      (label: '23', displayLabel: '23', steps: 5900),
      (label: '24', displayLabel: '', steps: 3800),
      (label: '25', displayLabel: '25', steps: 6400),
      (label: '26', displayLabel: '', steps: 7400),
      (label: '27', displayLabel: '27', steps: 5200),
      (label: '28', displayLabel: '', steps: 6900),
      (label: '29', displayLabel: '29', steps: 4600),
      (label: '30', displayLabel: '30', steps: 5000),
      (label: '1', displayLabel: '', steps: 1200),
      (label: '2', displayLabel: '2', steps: 5800),
      (label: '3', displayLabel: '', steps: 4400),
      (label: '4', displayLabel: '4', steps: 4700),
      (label: '5', displayLabel: '', steps: 1100),
      (label: '6', displayLabel: '6', steps: 3800),
      (label: '7', displayLabel: '', steps: 4000),
      (label: '8', displayLabel: '8', steps: 6500),
      (label: '9', displayLabel: '', steps: 8000),
      (label: '10', displayLabel: '10', steps: 3200),
      (label: '11', displayLabel: '', steps: 5100),
      (label: '12', displayLabel: '12', steps: 1000),
      (label: '13', displayLabel: '', steps: 6200),
      (label: '14', displayLabel: '14', steps: 5100),
      (label: '15', displayLabel: '', steps: 3500),
      (label: 'Today', displayLabel: 'Today', steps: widget.telemetry.steps),
    ];

    final List<({String label, String displayLabel, int steps})> weekData = [
      (label: 'M', displayLabel: 'M', steps: 5800),
      (label: 'T', displayLabel: 'T', steps: 4700),
      (label: 'W', displayLabel: 'W', steps: 3800),
      (label: 'T', displayLabel: 'T', steps: 6500),
      (label: 'F', displayLabel: 'F', steps: 8000),
      (label: 'S', displayLabel: 'S', steps: 3200),
      (label: 'Today', displayLabel: 'Today', steps: widget.telemetry.steps),
    ];

    final List<({String label, String displayLabel, int steps})> monthData = [
      (label: 'W1', displayLabel: 'W1', steps: 38200),
      (label: 'W2', displayLabel: 'W2', steps: 41500),
      (label: 'W3', displayLabel: 'W3', steps: 44800),
      (label: 'W4', displayLabel: 'W4', steps: 39242),
    ];

    final currentData = widget.selectedTab == 0
        ? dayData
        : widget.selectedTab == 1
            ? weekData
            : monthData;

    final targetGoal = widget.selectedTab == 2 ? 50000 : widget.telemetry.stepsGoal;
    final activeIndex = _selectedDayIndex != null && _selectedDayIndex! < currentData.length
        ? _selectedDayIndex!
        : (currentData.length - 1);
    final activeItem = currentData[activeIndex];
    final isToday = activeItem.label == 'Today';
    final displayedSteps = activeItem.steps;
    final displayedKm = (displayedSteps * 0.000708).toStringAsFixed(2);
    final displayedGoal = targetGoal;

    const double chartBarAreaHeight = 146.0;
    const double bottomLabelHeight = 24.0;
    const double totalChartHeight = chartBarAreaHeight + bottomLabelHeight;
    const double yAxisWidth = 38.0;

    final ySteps = widget.selectedTab == 0
        ? [8000, 6000, 4000, 2000, 0]
        : [
            targetGoal,
            (targetGoal * 0.75).toInt(),
            (targetGoal * 0.5).toInt(),
            (targetGoal * 0.25).toInt(),
            0
          ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161A23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scrollable Chart with Fixed Y-Axis
          SizedBox(
            height: totalChartHeight,
            child: Row(
              children: [
                // Scrollable bars area
                Expanded(
                  child: Stack(
                    children: [
                      // Horizontal background dashed grid lines
                      Positioned.fill(
                        bottom: bottomLabelHeight,
                        child: CustomPaint(
                          painter: _HorizontalGridPainter(
                            levelsCount: ySteps.length,
                          ),
                        ),
                      ),
                      // Horizontally scrollable day bars
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(width: 4),
                            for (int i = 0; i < currentData.length; i++) ...[
                              _buildBarColumn(
                                index: i,
                                item: currentData[i],
                                isSelected: i == activeIndex,
                                targetGoal: targetGoal,
                                barAreaHeight: chartBarAreaHeight,
                                labelHeight: bottomLabelHeight,
                              ),
                            ],
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Fixed Y-Axis Labels
                SizedBox(
                  width: yAxisWidth,
                  height: totalChartHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: chartBarAreaHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final val in ySteps)
                              Text(
                                '$val',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11.0,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: bottomLabelHeight),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3 Metrics Together: Goal, Step count, Distance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131722),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                // 1. Goal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Goal',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.formatNumber(displayedGoal),
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      const Text(
                        'Steps',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.08),
                ),

                // 2. Step count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        isToday ? 'Step count' : 'Steps (${activeItem.label})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.formatNumber(displayedSteps),
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: activeIndex == currentData.length - 1
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF00E5FF),
                        ),
                      ),
                      const Text(
                        'Steps',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.08),
                ),

                // 3. Distance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Distance',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayedKm,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      const Text(
                        'km',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarColumn({
    required int index,
    required ({String label, String displayLabel, int steps}) item,
    required bool isSelected,
    required int targetGoal,
    required double barAreaHeight,
    required double labelHeight,
  }) {
    final double progress = (item.steps / targetGoal).clamp(0.04, 1.0);
    final double fillHeight = progress * barAreaHeight;
    final bool isToday = item.label == 'Today';
    const double barWidth = 10.0;
    final double slotWidth = isToday ? 38.0 : 26.0;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDayIndex = index);
      },
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: slotWidth,
        height: barAreaHeight + labelHeight,
        child: Column(
          children: [
            // Bar Slot Area
            SizedBox(
              height: barAreaHeight,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Inactive Track
                  Container(
                    width: barWidth,
                    height: barAreaHeight,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFF1E2330),
                      borderRadius: BorderRadius.circular(barWidth / 2),
                    ),
                  ),

                  // Today's dashed goal guideline
                  if (isToday && progress < 1.0)
                    Positioned(
                      top: 0,
                      bottom: fillHeight,
                      child: SizedBox(
                        width: 2,
                        child: CustomPaint(
                          painter: _VerticalDashedLinePainter(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),

                  // Active Filled Bar
                  Container(
                    width: barWidth,
                    height: fillHeight,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(barWidth / 2),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // Date / Day Label
            SizedBox(
              height: labelHeight,
              child: Center(
                child: Text(
                  item.displayLabel,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11.0,
                    color: isSelected
                        ? const Color(0xFF00E5FF)
                        : isToday
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF94A3B8),
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
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

class _HorizontalGridPainter extends CustomPainter {
  const _HorizontalGridPainter({required this.levelsCount});
  final int levelsCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    for (int i = 0; i < levelsCount; i++) {
      final y = (i / (levelsCount - 1)) * size.height;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 3.0, size.width), y),
          paint,
        );
        x += 6.0;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VerticalDashedLinePainter extends CustomPainter {
  const _VerticalDashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    double y = size.height;
    while (y > 0) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, math.max(0, y - 3.0)),
        paint,
      );
      y -= 6.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. CALORIES DETAIL CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _CaloriesDetailContent extends StatelessWidget {
  const _CaloriesDetailContent({required this.telemetry});

  final DailyTelemetry telemetry;

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final progressPct = (t.caloriesProgress * 100).toInt();
    final remaining = math.max(0, t.caloriesGoal - t.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.pureWhite,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Calories',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: AppColors.platinum, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'ACTIVE ENERGY & BASAL METABOLISM',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatNumber(t.calories),
                  style: AppTypography.headlineLarge.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pureWhite,
                  ),
                ),
                Text(
                  'KCAL BURNED',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.platinum,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$remaining kcal remaining to goal',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            // Circular progress mini gauge
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: t.caloriesProgress,
                    backgroundColor: AppColors.steel,
                    color: AppColors.pureWhite,
                    strokeWidth: 7,
                  ),
                  Text(
                    '$progressPct%',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontMono,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Split breakdown
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'ACTIVE BURN',
                value: '1,740 kcal',
                icon: Icons.fitness_center_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'BASAL (BMR)',
                value: '650 kcal',
                icon: Icons.favorite_border_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'DAILY GOAL',
                value: '${_formatNumber(t.caloriesGoal)} kcal',
                icon: Icons.flag_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. HYDRATION DETAIL CONTENT (WITH INTERACTIVE WATER LOGGING)
// ─────────────────────────────────────────────────────────────────────────────

class _HydrationDetailContent extends ConsumerWidget {
  const _HydrationDetailContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dailyTelemetryProvider);
    final progressPct = (t.waterProgress * 100).toInt();
    final liters = (t.waterMl / 1000).toStringAsFixed(2);
    final goalLiters = (t.waterGoalMl / 1000).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.pureWhite,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hydration',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: AppColors.platinum, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'WATER INTAKE & FLUID BALANCE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              liters,
              style: AppTypography.headlineLarge.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'LITERS',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.platinum,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.steel),
              ),
              child: Text(
                '$progressPct% of $goalLiters L goal',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: t.waterProgress,
            backgroundColor: AppColors.steel,
            valueColor: const AlwaysStoppedAnimation(AppColors.pureWhite),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'RAPID WATER LOGGING',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.platinum,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Quick log pill buttons
        Row(
          children: [
            Expanded(
              child: _LogButton(
                title: '+250 ml',
                subtitle: 'Glass',
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(dailyTelemetryProvider.notifier).logWater(250);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LogButton(
                title: '+500 ml',
                subtitle: 'Shaker',
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(dailyTelemetryProvider.notifier).logWater(500);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LogButton(
                title: '-250 ml',
                subtitle: 'Undo',
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(dailyTelemetryProvider.notifier).logWater(-250);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LogButton extends StatelessWidget {
  const _LogButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.steel),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pureWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. SLEEP DETAIL CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _SleepDetailContent extends ConsumerStatefulWidget {
  const _SleepDetailContent({required this.telemetry});

  final DailyTelemetry telemetry;

  @override
  ConsumerState<_SleepDetailContent> createState() => _SleepDetailContentState();
}

class _SleepDetailContentState extends ConsumerState<_SleepDetailContent> {
  late double _sleepHours;
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int _qualityIndex = 3; // 0: Restless, 1: Light, 2: Good, 3: Optimal

  @override
  void initState() {
    super.initState();
    _sleepHours = widget.telemetry.sleepHours;
  }

  void _recalculateFromTimes() {
    final bedMinutes = _bedtime.hour * 60 + _bedtime.minute;
    final wakeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;
    int diffMinutes = wakeMinutes - bedMinutes;
    if (diffMinutes <= 0) {
      diffMinutes += 24 * 60; // crossed midnight
    }
    final rawHours = diffMinutes / 60.0;
    setState(() {
      _sleepHours = double.parse(rawHours.toStringAsFixed(1)).clamp(1.0, 16.0);
    });
  }

  Future<void> _pickBedtime() async {
    HapticFeedback.lightImpact();
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: Color(0xFF141722),
            onSurface: AppColors.pureWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _bedtime = picked);
      _recalculateFromTimes();
    }
  }

  Future<void> _pickWakeTime() async {
    HapticFeedback.lightImpact();
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: Color(0xFF141722),
            onSurface: AppColors.pureWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _wakeTime = picked);
      _recalculateFromTimes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.telemetry;
    final progressPct = ((_sleepHours / t.sleepGoalHours) * 100).toInt().clamp(0, 150);

    final deepSleepMinutes = (_sleepHours * 60 * 0.23).round();
    final deepStr = '${deepSleepMinutes ~/ 60}h ${deepSleepMinutes % 60}m';

    final remSleepMinutes = (_sleepHours * 60 * 0.25).round();
    final remStr = '${remSleepMinutes ~/ 60}h ${remSleepMinutes % 60}m';

    const qualityLabels = ['Restless', 'Light', 'Good', 'Optimal'];
    const qualityEmoji = ['😴', '🥱', '⚡', '💎'];
    final scorePct = math.min(100, ((_sleepHours / t.sleepGoalHours) * 100).toInt());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Title + Close ──────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bedtime_rounded,
                  color: AppColors.pureWhite,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sleep Log',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: AppColors.platinum, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'REST ARCHITECTURE & RECOVERY',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        // ── Hero Stat Readout ─────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _sleepHours.toStringAsFixed(1),
              style: AppTypography.headlineLarge.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'HOURS',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.platinum,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.steel),
              ),
              child: Text(
                '$progressPct% of ${t.sleepGoalHours.toInt()}h target',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_sleepHours / t.sleepGoalHours).clamp(0.0, 1.0),
            backgroundColor: AppColors.steel,
            valueColor: const AlwaysStoppedAnimation(AppColors.pureWhite),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 18),

        // ── Dynamic Sleep Stages Breakdown ────────────────────────────
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'DEEP SLEEP',
                value: deepStr,
                icon: Icons.waves_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'REM SLEEP',
                value: remStr,
                icon: Icons.remove_red_eye_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'SCORE',
                value: '$scorePct% ${qualityLabels[_qualityIndex]}',
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // ── MANUAL SLEEP SETTER SECTION ───────────────────────────────
        Text(
          'MANUAL SLEEP SETTER',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.platinum,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // 1. Bedtime & Wake Time Selectors
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickBedtime,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.steel),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bedtime_outlined, size: 13, color: AppColors.textMuted),
                          SizedBox(width: 4),
                          Text(
                            'BEDTIME',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _bedtime.format(context),
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _pickWakeTime,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.steel),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.wb_sunny_outlined, size: 13, color: AppColors.textMuted),
                          SizedBox(width: 4),
                          Text(
                            'WAKE UP',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _wakeTime.format(context),
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Quick Presets Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final preset in [6.0, 7.0, 7.5, 8.0, 8.5, 9.0]) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _sleepHours = preset);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _sleepHours == preset ? AppColors.pureWhite : AppColors.charcoal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _sleepHours == preset ? AppColors.pureWhite : AppColors.steel,
                        ),
                      ),
                      child: Text(
                        '${preset.toStringAsFixed(preset % 1 == 0 ? 0 : 1)}h',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _sleepHours == preset ? Colors.black : AppColors.pureWhite,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Fine Slider Adjuster (- / slider / +)
        Row(
          children: [
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _sleepHours = math.max(3.0, _sleepHours - 0.5));
              },
              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.platinum, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.pureWhite,
                  inactiveTrackColor: AppColors.steel,
                  thumbColor: AppColors.pureWhite,
                  overlayColor: Colors.white.withValues(alpha: 0.1),
                  trackHeight: 3.5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: _sleepHours.clamp(3.0, 12.0),
                  min: 3.0,
                  max: 12.0,
                  divisions: 36, // 15-minute steps
                  onChanged: (val) {
                    setState(() => _sleepHours = double.parse(val.toStringAsFixed(1)));
                  },
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _sleepHours = math.min(12.0, _sleepHours + 0.5));
              },
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.platinum, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 4. Sleep Quality Rating
        Row(
          children: [
            for (int i = 0; i < qualityLabels.length; i++) ...[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < qualityLabels.length - 1 ? 6 : 0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _qualityIndex = i);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _qualityIndex == i ? AppColors.pureWhite : AppColors.charcoal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _qualityIndex == i ? AppColors.pureWhite : AppColors.steel,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(qualityEmoji[i], style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            qualityLabels[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _qualityIndex == i ? Colors.black : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // 5. Save Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(dailyTelemetryProvider.notifier).updateSleep(_sleepHours);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.charcoal,
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Sleep record saved: ${_sleepHours.toStringAsFixed(1)} hrs',
                    style: const TextStyle(color: AppColors.pureWhite),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pureWhite,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'LOG SLEEP',
              style: TextStyle(
                fontFamily: AppTypography.fontDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE METRIC TILE
// ─────────────────────────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.steel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.platinum),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.fontMono,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: AppColors.pureWhite,
            ),
          ),
        ],
      ),
    );
  }
}
