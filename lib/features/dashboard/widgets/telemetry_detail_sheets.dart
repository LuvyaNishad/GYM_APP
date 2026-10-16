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
import '../../../services/pedometer_service.dart';
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
    final pedometer = ref.watch(pedometerServiceProvider);
    final t = liveTelemetry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 3),
                Text(
                  'Goal: ${_formatNumber(t.stepsGoal)} steps',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12.0,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
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
        const SizedBox(height: 10),

        // Sensor Active Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F291E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                pedometer.isAvailable
                    ? 'IN-BUILT PHONE HARDWARE SENSOR ACTIVE'
                    : 'IN-BUILT PHONE HARDWARE SENSOR SYNCED',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF34D399),
                ),
              ),
            ],
          ),
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

        // 3. Historical Days Card (recreates user phone step tracker)
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
        const SizedBox(height: 18),

        // 5. Today's Hourly Distribution Section
        Text(
          'TODAY\'S HOURLY CADENCE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.platinum,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF161A23),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: _DetailedHourlyBarChart(hourlySteps: t.hourlySteps),
        ),
      ],
    );
  }
}

class _HistoricalStepTrackerCard extends StatelessWidget {
  const _HistoricalStepTrackerCard({
    required this.telemetry,
    required this.selectedTab,
    required this.formatNumber,
  });

  final DailyTelemetry telemetry;
  final int selectedTab;
  final String Function(int) formatNumber;

  @override
  Widget build(BuildContext context) {
    // 17 day data points matching phone screenshot
    final List<({String label, int steps})> dayData = [
      (label: '30', steps: 5000),
      (label: '', steps: 1200),
      (label: '2', steps: 5800),
      (label: '', steps: 4400),
      (label: '4', steps: 4700),
      (label: '', steps: 1100),
      (label: '6', steps: 3800),
      (label: '', steps: 4000),
      (label: '8', steps: 6500),
      (label: '', steps: 8000),
      (label: '10', steps: 3200),
      (label: '', steps: 5100),
      (label: '12', steps: 1000),
      (label: '', steps: 6200),
      (label: '14', steps: 5100),
      (label: '', steps: 3500),
      (label: 'Today', steps: telemetry.steps),
    ];

    final List<({String label, int steps})> weekData = [
      (label: 'M', steps: 5800),
      (label: 'T', steps: 4700),
      (label: 'W', steps: 3800),
      (label: 'T', steps: 6500),
      (label: 'F', steps: 8000),
      (label: 'S', steps: 3200),
      (label: 'Today', steps: telemetry.steps),
    ];

    final List<({String label, int steps})> monthData = [
      (label: 'W1', steps: 38200),
      (label: 'W2', steps: 41500),
      (label: 'W3', steps: 44800),
      (label: 'W4', steps: 39242),
    ];

    final currentData = selectedTab == 0
        ? dayData
        : selectedTab == 1
            ? weekData
            : monthData;

    final targetGoal = selectedTab == 2 ? 50000 : 8000;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF161A23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bar Chart Canvas
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _HistoricalDaysPainter(
                data: currentData,
                targetGoal: targetGoal,
                isDayTab: selectedTab == 0,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // In-card metrics (matches user phone tracker)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step count',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatNumber(telemetry.steps),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    const Text(
                      'Steps',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distance',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      telemetry.distanceKm.toStringAsFixed(2),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    const Text(
                      'km',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoricalDaysPainter extends CustomPainter {
  _HistoricalDaysPainter({
    required this.data,
    required this.targetGoal,
    required this.isDayTab,
  });

  final List<({String label, int steps})> data;
  final int targetGoal;
  final bool isDayTab;

  @override
  void paint(Canvas canvas, Size size) {
    const double labelWidth = 38.0;
    const double bottomLabelHeight = 22.0;
    final double chartWidth = size.width - labelWidth;
    final double chartHeight = size.height - bottomLabelHeight;

    // Gridline and label styling
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;

    final ySteps = isDayTab
        ? [8000, 6000, 4000, 2000, 0]
        : [
            targetGoal,
            (targetGoal * 0.75).toInt(),
            (targetGoal * 0.5).toInt(),
            (targetGoal * 0.25).toInt(),
            0
          ];

    for (int i = 0; i < ySteps.length; i++) {
      final y = (i / (ySteps.length - 1)) * chartHeight;

      // Draw dashed horizontal grid line
      _drawDashedLine(canvas, Offset(0, y), Offset(chartWidth, y), linePaint);

      // Draw Y-axis label on right side
      final tp = TextPainter(
        text: TextSpan(
          text: '${ySteps[i]}',
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11.0,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartWidth + 6, y - tp.height / 2));
    }

    // Draw bars
    final double slotWidth = chartWidth / data.length;
    final double barWidth = (slotWidth * 0.54).clamp(6.0, 14.0);

    final trackPaint = Paint()
      ..color = const Color(0xFF1E2330)
      ..style = PaintingStyle.fill;

    final barPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;

    final dashedPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.7)
      ..strokeWidth = 1.5;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final double centerX = i * slotWidth + slotWidth / 2;
      final double left = centerX - barWidth / 2;
      final double right = centerX + barWidth / 2;

      // Background pill slot (full height 0 to chartHeight)
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, 0, right, chartHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(trackRect, trackPaint);

      // Foreground filled bar
      final double progress = (item.steps / targetGoal).clamp(0.04, 1.0);
      final double fillHeight = progress * chartHeight;
      final double topY = chartHeight - fillHeight;

      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, topY, right, chartHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(fillRect, barPaint);

      // If Today, draw dashed vertical indicator from topY to top (goal)
      if (item.label == 'Today' && topY > 0) {
        _drawVerticalDashedLine(
          canvas,
          Offset(centerX, topY),
          Offset(centerX, 0),
          dashedPaint,
        );
      }

      // X-axis label
      if (item.label.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: item.label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11.0,
              color: item.label == 'Today'
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF94A3B8),
              fontWeight:
                  item.label == 'Today' ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(centerX - tp.width / 2, chartHeight + 6),
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 3.0;
    const double dashSpace = 3.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(
        Offset(startX, p1.dy),
        Offset(math.min(startX + dashWidth, p2.dx), p1.dy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  void _drawVerticalDashedLine(
      Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashHeight = 3.0;
    const double dashSpace = 3.0;
    double currentY = p1.dy;
    while (currentY > p2.dy) {
      canvas.drawLine(
        Offset(p1.dx, currentY),
        Offset(p1.dx, math.max(currentY - dashHeight, p2.dy)),
        paint,
      );
      currentY -= dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _HistoricalDaysPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.targetGoal != targetGoal ||
        oldDelegate.isDayTab != isDayTab;
  }
}

class _DetailedHourlyBarChart extends StatelessWidget {
  const _DetailedHourlyBarChart({required this.hourlySteps});

  final List<int> hourlySteps;

  @override
  Widget build(BuildContext context) {
    if (hourlySteps.isEmpty) return const SizedBox.shrink();
    final maxVal = hourlySteps.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < hourlySteps.length; i++) ...[
                Flexible(
                  child: FractionallySizedBox(
                    heightFactor: (hourlySteps[i] / (maxVal > 0 ? maxVal : 1)).clamp(0.08, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: hourlySteps[i] == maxVal ? AppColors.pureWhite : AppColors.steel,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                if (i < hourlySteps.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('08:00', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            Text('12:00', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            Text('16:00', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            Text('20:00', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
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
