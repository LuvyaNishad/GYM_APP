/// Progressive Overload Tab View for LEON History:
/// 1RM progression trajectory with fl_chart, volume trends, and PR trophy wall.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/strength_math.dart';
import '../models/exercise_progress_model.dart';
import '../providers/history_provider.dart';

class OverloadTabView extends ConsumerStatefulWidget {
  const OverloadTabView({super.key});

  @override
  ConsumerState<OverloadTabView> createState() => _OverloadTabViewState();
}

class _OverloadTabViewState extends ConsumerState<OverloadTabView> {
  String _selectedRange = 'ALL';

  List<StrengthDataPoint> _getFilteredPoints(List<StrengthDataPoint> points) {
    if (points.isEmpty) return points;
    final now = DateTime.now();
    final Duration? duration = switch (_selectedRange) {
      '1M' => const Duration(days: 30),
      '3M' => const Duration(days: 90),
      '6M' => const Duration(days: 180),
      '1Y' => const Duration(days: 365),
      _ => null,
    };
    if (duration == null) return points;
    final cutoff = now.subtract(duration);
    final filtered = points.where((p) => p.date.isAfter(cutoff)).toList();
    if (filtered.length < 2 && points.length >= 2) {
      return points.sublist(points.length - 2);
    }
    return filtered;
  }
  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(availableOverloadExercisesProvider);
    final selectedId = ref.watch(selectedOverloadExerciseIdProvider);
    final prMilestones = ref.watch(recentPrMilestonesProvider);

    final currentEx = exercises.firstWhere(
      (e) => e.exerciseId == selectedId,
      orElse: () => exercises.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Exercise Selector Carousel ─────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final ex in exercises) ...[
                GestureDetector(
                  onTap: () {
                    ref
                        .read(selectedOverloadExerciseIdProvider.notifier)
                        .select(ex.exerciseId);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: ex.exerciseId == selectedId
                          ? AppColors.pureWhite
                          : AppColors.charcoal,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ex.exerciseId == selectedId
                            ? AppColors.pureWhite
                            : AppColors.steel.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      ex.exerciseName,
                      style: TextStyle(
                        fontFamily: AppTypography.fontDisplay,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: ex.exerciseId == selectedId
                            ? AppColors.onyx
                            : AppColors.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── 2. Hero 1RM Metric Card ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.steel.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATED 1RM',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${currentEx.allTimeBest1RM}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 28.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.pureWhite,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'KG',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Progress pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          size: 16,
                          color: Color(0xFF00E5FF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${currentEx.recentDeltaPercent}%',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12.0,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Time Range Filter Row ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PROGRESSION CURVE',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Row(
                    children: [
                      for (final range in ['1M', '3M', '6M', '1Y', 'ALL']) ...[
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedRange = range);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _selectedRange == range
                                  ? const Color(0xFF00E5FF)
                                  : AppColors.onyx,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _selectedRange == range
                                    ? const Color(0xFF00E5FF)
                                    : AppColors.steel.withValues(alpha: 0.4),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              range,
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: _selectedRange == range
                                    ? AppColors.onyx
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── fl_chart Line Chart ──────────────────────────────────────
              SizedBox(
                height: 160,
                child: _buildStrengthLineChart(currentEx),
              ),

              const SizedBox(height: 12),

              // Chart footer with interactive scientific formula dialog
              GestureDetector(
                onTap: () => _showEpleyFormulaDialog(context, currentEx),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 13,
                        color: Color(0xFF00E5FF),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Estimated 1RM calculated via Epley formula: Weight × (1 + Reps / 30)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 11.0,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.steel,
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

        const SizedBox(height: 16),

        // ── 3. PR Trophy Wall ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.steel.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🏆 ', style: TextStyle(fontSize: 16)),
                      Text(
                        'PR TROPHY WALL',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pureWhite,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.steel.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${prMilestones.length} ACHIEVED',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.platinum,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              for (final pr in prMilestones)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.onyx,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.steel.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pr.exerciseName,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontBody,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pureWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pr.recordType.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              pr.valueFormatted,
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 13.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.pureWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pr.deltaFormatted,
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00E676),
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
        ),
      ],
    );
  }

  Widget _buildStrengthLineChart(ExerciseProgressModel ex) {
    final points = _getFilteredPoints(ex.dataPoints);
    if (points.isEmpty) {
      return const Center(
        child: Text(
          'No data recorded in this time range',
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 12.0,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = 0;

    for (int i = 0; i < points.length; i++) {
      final y = points[i].estimated1RM;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
      spots.add(FlSpot(i.toDouble(), y));
    }

    final bufferY = (maxY - minY) * 0.2;
    final finalMinY = (minY - bufferY).clamp(0.0, double.infinity);
    final finalMaxY = maxY + (bufferY > 0 ? bufferY : 10.0);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((finalMaxY - finalMinY) / 3).clamp(5.0, 50.0),
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.steel.withValues(alpha: 0.3),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'W${idx + 1}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (val, meta) {
                return Text(
                  '${val.toInt()}k',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (points.length - 1).toDouble().clamp(1.0, 10.0),
        minY: finalMinY,
        maxY: finalMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF00E5FF),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4.0,
                color: AppColors.pureWhite,
                strokeWidth: 2,
                strokeColor: const Color(0xFF00E5FF),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  const Color(0xFF00E5FF).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEpleyFormulaDialog(BuildContext context, ExerciseProgressModel ex) {
    HapticFeedback.lightImpact();
    final repTable = StrengthMath.repMaxTable(ex.allTimeBest1RM);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.onyx,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.steel),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.calculate_outlined,
              color: Color(0xFF00E5FF),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'SCIENTIFIC 1RM FORMULA',
              style: AppTypography.headlineSmall.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.pureWhite,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.steel.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'EPLEY EQUATION',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1RM = Weight × (1 + Reps / 30)',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 13.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Standard evidence-based equation used in exercise physiology to predict maximal single-repetition capacity from submaximal sets.',
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${ex.exerciseName.toUpperCase()} REP-MAX TARGETS',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.steel.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < repTable.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${repTable[i]['percent']}% (${repTable[i]['reps']} rep${repTable[i]['reps'] > 1 ? 's' : ''})',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11.5,
                                color: AppColors.platinum,
                              ),
                            ),
                            Text(
                              '${repTable[i]['weightKg']} KG',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < repTable.length - 1)
                        const Divider(
                          color: AppColors.steel,
                          height: 1,
                          indent: 12,
                          endIndent: 12,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'CLOSE',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
